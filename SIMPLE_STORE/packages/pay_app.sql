CREATE OR REPLACE PACKAGE BODY pay_app AS

    FUNCTION get_user_id
    RETURN VARCHAR2
    AS
    BEGIN
        RETURN COALESCE (
            LOWER(APEX_APPLICATION.G_USER),
            SYS_CONTEXT('USERENV', 'PROXY_USER'),
            SYS_CONTEXT('USERENV', 'SESSION_USER'),
            USER
        );
    END;



    FUNCTION get_session_id
    RETURN NUMBER
    AS
    BEGIN
        RETURN SYS_CONTEXT('APEX$SESSION', 'APP_SESSION');  -- APEX_APPLICATION.G_INSTANCE
    END;



    FUNCTION get_private_key
    RETURN pay_secrets.value%TYPE
    AS
        out_value       pay_secrets.value%TYPE;
    BEGIN
        SELECT s.value INTO out_value
        FROM pay_secrets s
        WHERE s.id      = 'STRIPE_PRIVATE_KEY';
        --
        RETURN out_value;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    END;



    FUNCTION get_list (
        in_string_1     VARCHAR2 := NULL,
        in_string_2     VARCHAR2 := NULL,
        in_string_3     VARCHAR2 := NULL,
        in_string_4     VARCHAR2 := NULL,
        in_string_5     VARCHAR2 := NULL,
        in_string_6     VARCHAR2 := NULL,
        in_string_7     VARCHAR2 := NULL,
        in_string_8     VARCHAR2 := NULL,
        in_raw          VARCHAR2 := NULL,
        in_splitter     VARCHAR2 := NULL
    )
    RETURN VARCHAR2
    AS
        v_splitter      CONSTANT CHAR := NVL(in_splitter, c_default_splitter);
    BEGIN
        RETURN RTRIM (
            REPLACE(in_string_1, v_splitter, '') || CASE WHEN in_string_2 IS NOT NULL THEN v_splitter END ||
            REPLACE(in_string_2, v_splitter, '') || CASE WHEN in_string_3 IS NOT NULL THEN v_splitter END ||
            REPLACE(in_string_3, v_splitter, '') || CASE WHEN in_string_4 IS NOT NULL THEN v_splitter END ||
            REPLACE(in_string_4, v_splitter, '') || CASE WHEN in_string_5 IS NOT NULL THEN v_splitter END ||
            REPLACE(in_string_5, v_splitter, '') || CASE WHEN in_string_6 IS NOT NULL THEN v_splitter END ||
            REPLACE(in_string_6, v_splitter, '') || CASE WHEN in_string_7 IS NOT NULL THEN v_splitter END ||
            REPLACE(in_string_7, v_splitter, '') || CASE WHEN in_string_8 IS NOT NULL THEN v_splitter END ||
            REPLACE(in_string_8, v_splitter, '') || in_raw,
            v_splitter
        );
    END;



    FUNCTION get_rest_response (
        in_url              VARCHAR2,
        in_params           VARCHAR2,
        in_values           VARCHAR2,
        in_splitter         CHAR            := NULL
    )
    RETURN CLOB
    AS
        out_clob            CLOB;
    BEGIN
        APEX_WEB_SERVICE.G_REQUEST_HEADERS(1).name  := 'Authorization';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS(1).value := 'Bearer ' || pay_app.get_private_key();
        APEX_WEB_SERVICE.G_REQUEST_HEADERS(2).name  := 'Content-Type';
        APEX_WEB_SERVICE.G_REQUEST_HEADERS(2).value := 'application/x-www-form-urlencoded';
        --
        out_clob := APEX_WEB_SERVICE.MAKE_REST_REQUEST (
            p_url           => in_url,
            p_http_method   => 'POST',
            p_parm_name     => APEX_UTIL.STRING_TO_TABLE(in_params, NVL(in_splitter, c_default_splitter)),
            p_parm_value    => APEX_UTIL.STRING_TO_TABLE(in_values, NVL(in_splitter, c_default_splitter))
        );
        --
        RETURN out_clob;
    EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(in_url);
        DBMS_OUTPUT.PUT_LINE(in_params);
        DBMS_OUTPUT.PUT_LINE(in_values);
        DBMS_OUTPUT.PUT_LINE('--');
        DBMS_OUTPUT.PUT_LINE(out_clob);
        DBMS_OUTPUT.PUT_LINE('--');
        RAISE_APPLICATION_ERROR(-20000, in_url || '|' || in_params || '|' || in_values, TRUE);
    END;



    FUNCTION get_api_customer_id (
        in_rec          pay_customers%ROWTYPE
    )
    RETURN pay_customers.api_customer_id%TYPE
    AS
        v_clob          CLOB;
    BEGIN
        v_clob := pay_app.get_rest_response (
            in_url          =>  'https://api.stripe.com/v1/customers',
            in_params       =>  pay_app.get_list('id', 'name', 'email'),
            in_values       =>  pay_app.get_list(in_rec.customer_id, in_rec.customer_name, in_rec.customer_mail)
        );
        --
        APEX_JSON.PARSE(v_clob);
        --
        RETURN APEX_JSON.GET_VARCHAR2(p_path => 'id');
    END;



    PROCEDURE create_customer (
        in_name         pay_customers.customer_name%TYPE,
        in_mail         pay_customers.customer_mail%TYPE
    )
    AS
        rec             pay_customers%ROWTYPE;
        v_clob          CLOB;
    BEGIN
        -- make sure we dont create duplicate customers
        BEGIN
            SELECT c.customer_id, c.api_customer_id
            INTO rec.customer_id, rec.api_customer_id
            FROM pay_customers c
            WHERE c.customer_mail = in_mail;
            --
            IF rec.api_customer_id IS NOT NULL THEN
                RETURN;
            END IF;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            rec.customer_id := pay_customer_id.NEXTVAL;
        END;

        -- create customer on Stripe
        rec.customer_name   := in_name;
        rec.customer_mail   := in_mail;
        rec.created_by      := USER;
        rec.created_at      := SYSDATE;
        --
        rec.api_customer_id := pay_app.get_api_customer_id(rec);

        -- store customer in table
        IF rec.api_customer_id IS NOT NULL THEN
            INSERT INTO pay_customers VALUES rec;
        ELSE
            RAISE_APPLICATION_ERROR(-20000, 'API_ERROR:' || APEX_JSON.GET_VARCHAR2(p_path => 'error.message'), TRUE);
        END IF;
    END;



    FUNCTION get_api_product_id (
        in_rec          pay_products%ROWTYPE
    )
    RETURN pay_products.api_product_id%TYPE
    AS
        v_clob          CLOB;
    BEGIN
        v_clob := pay_app.get_rest_response (
            in_url          =>  'https://api.stripe.com/v1/products',
            in_params       =>  pay_app.get_list('id', 'name', 'description'),
            in_values       =>  pay_app.get_list(in_rec.product_id, in_rec.product_name, in_rec.product_desc)
        );
        --
        APEX_JSON.PARSE(v_clob);
        --
        RETURN APEX_JSON.GET_VARCHAR2(p_path => 'id');
    END;



    FUNCTION get_api_price_id (
        in_rec          pay_products%ROWTYPE
    )
    RETURN pay_products.api_price_id%TYPE
    AS
        v_clob          CLOB;
    BEGIN
        v_clob := pay_app.get_rest_response (
            in_url          =>  'https://api.stripe.com/v1/prices',
            in_params       =>  pay_app.get_list('product', 'unit_amount', 'currency'),
            in_values       =>  pay_app.get_list(in_rec.api_product_id, in_rec.price * 100, in_rec.currency_code)
        );
        --
        APEX_JSON.PARSE(v_clob);
        --
        RETURN APEX_JSON.GET_VARCHAR2(p_path => 'id');
    END;



    PROCEDURE create_product (
        in_name         pay_products.product_name%TYPE,
        in_desc         pay_products.product_desc%TYPE,
        in_price        pay_products.price%TYPE,
        in_currency     pay_products.currency_code%TYPE     := NULL
    )
    AS
        rec             pay_products%ROWTYPE;
    BEGIN
        -- make sure we dont create duplicate products
        BEGIN
            SELECT p.product_id, p.api_price_id
            INTO rec.product_id, rec.api_price_id
            FROM pay_products p
            WHERE p.product_name = in_name;
            --
            IF rec.api_price_id IS NOT NULL THEN
                RETURN;
            END IF;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            rec.product_id  := pay_product_id.NEXTVAL;
        END;

        -- create product on Stripe
        rec.product_name    := in_name;
        rec.product_desc    := in_desc;
        rec.price           := in_price;
        rec.currency_code   := NVL(in_currency, c_default_currency);
        rec.created_by      := USER;
        rec.created_at      := SYSDATE;
        --
        rec.api_product_id  := pay_app.get_api_product_id(rec);
        rec.api_price_id    := pay_app.get_api_price_id(rec);

        -- store product in table
        IF rec.api_price_id IS NOT NULL THEN
            INSERT INTO pay_products VALUES rec;
        ELSE
            RAISE_APPLICATION_ERROR(-20000, 'API_ERROR:' || APEX_JSON.GET_VARCHAR2(p_path => 'error.message'), TRUE);
        END IF;
    END;



    PROCEDURE close_cart (
        in_customer_id      pay_shopping_carts.customer_id%TYPE
    )
    AS
    BEGIN
        /*
        DELETE pay_shopping_cart_items t
        WHERE t.cart_id IN (
            SELECT s.cart_id
            FROM pay_shopping_carts s
            WHERE s.customer_id = in_customer_id
        );
        */
        --
        UPDATE pay_shopping_carts s
        SET s.is_closed         = 'Y'
        WHERE s.customer_id     = in_customer_id
            AND s.is_closed     IS NULL;
    END;



    FUNCTION create_cart (
        in_customer_id      pay_shopping_carts.customer_id%TYPE
    )
    RETURN pay_shopping_carts.cart_id%TYPE
    AS
        out_cart_id         pay_shopping_carts.cart_id%TYPE;
    BEGIN
        pay_app.close_cart(in_customer_id);
        --
        INSERT INTO pay_shopping_carts (cart_id, customer_id, created_at)
        VALUES (
            pay_cart_id.NEXTVAL,
            in_customer_id,
            SYSDATE
        )
        RETURNING cart_id INTO out_cart_id;
        --
        RETURN out_cart_id;
    END;



    PROCEDURE update_cart (
        in_customer_id      pay_shopping_carts.customer_id%TYPE,
        in_cart_id          pay_shopping_carts.cart_id%TYPE,
        in_product_id       pay_shopping_cart_items.product_id%TYPE,
        in_amount           pay_shopping_cart_items.amount%TYPE     := NULL,
        in_amount_total     pay_shopping_cart_items.amount%TYPE     := NULL
    )
    AS
        v_cart_id           pay_shopping_carts.cart_id%TYPE;
        v_new_amount        pay_shopping_cart_items.amount%TYPE     := in_amount_total;
    BEGIN
        -- validate cart, create new if needed
        BEGIN
            SELECT s.cart_id INTO v_cart_id
            FROM pay_shopping_carts s
            WHERE s.cart_id         = in_cart_id
                AND s.customer_id   = in_customer_id
                AND s.is_closed     IS NULL;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_cart_id := pay_app.create_cart (
                in_customer_id      => in_customer_id
            );
        END;

        -- add/remove items
        IF in_amount IS NOT NULL THEN
            SELECT NVL(SUM(t.amount), 0) + NVL(in_amount, 0) INTO v_new_amount
            FROM pay_shopping_cart_items t
            WHERE t.cart_id         = v_cart_id
                AND t.product_id    = in_product_id;
        END IF;
        --
        IF v_new_amount > 0 THEN
            UPDATE pay_shopping_cart_items t
            SET t.amount            = v_new_amount,
                t.updated_at        = SYSDATE
            WHERE t.cart_id         = v_cart_id
                AND t.product_id    = in_product_id;
            --
            IF SQL%ROWCOUNT = 0 THEN
                INSERT INTO pay_shopping_cart_items (cart_id, product_id, amount, created_at, updated_at)
                VALUES (
                    v_cart_id,
                    in_product_id,
                    v_new_amount,
                    SYSDATE,
                    SYSDATE
                );
            END IF;
        ELSE
            DELETE pay_shopping_cart_items t
            WHERE t.cart_id         = v_cart_id
                AND t.product_id    = in_product_id;
        END IF;
    END;



    FUNCTION get_success_token
    RETURN VARCHAR2
    AS
    BEGIN
        RETURN DBMS_RANDOM.STRING('X', 64);
    END;



    FUNCTION get_success_url (
        in_cart_id          VARCHAR2,
        in_token            VARCHAR2,
        in_session_id       NUMBER      := NULL
    )
    RETURN VARCHAR2
    AS
    BEGIN
        RETURN 'https://' || c_result_server ||
            APEX_PAGE.GET_URL (
                p_session           => COALESCE(in_session_id, pay_app.get_session_id()),
                p_page              => c_result_page_id,
                p_clear_cache       => c_result_page_id,
                p_items             => REPLACE('P#_TYPE,P#_CART_ID,P#_TOKEN', '#', c_result_page_id),
                p_values            => c_type_success || ',' || in_cart_id || ',' || in_token
            );
    END;



    FUNCTION get_cancel_url (
        in_cart_id          VARCHAR2,
        in_session_id       NUMBER      := NULL
    )
    RETURN VARCHAR2
    AS
    BEGIN
        RETURN 'https://' || c_result_server ||
            APEX_PAGE.GET_URL (
                p_session           => COALESCE(in_session_id, pay_app.get_session_id()),
                p_page              => c_result_page_id,
                p_clear_cache       => c_result_page_id,
                p_items             => REPLACE('P#_TYPE,P#_CART_ID,P#_TOKEN', '#', c_result_page_id),
                p_values            => c_type_cancel || ',' || in_cart_id || ',' || '0'
            );
    END;



    FUNCTION get_checkout_url (
        rec             IN OUT NOCOPY   pay_requests%ROWTYPE,
        in_params                       VARCHAR2,
        in_values                       VARCHAR2
    )
    RETURN VARCHAR2
    AS
    BEGIN
        -- https://docs.oracle.com/database/121/AEAPI/apex_web_service.htm#AEAPI1955
        -- https://stripe.com/docs/api/checkout/sessions/object
        -- you can check the response for possible tags (or read the doc^)
        rec.api_response := pay_app.get_rest_response (
            in_url          =>  'https://api.stripe.com/v1/checkout/sessions',
            in_params       =>  pay_app.get_list('mode', 'client_reference_id', 'customer_email', 'success_url', 'cancel_url', in_raw => in_params, in_splitter => c_alt_splitter),
            in_values       =>  pay_app.get_list(
                'payment',
                rec.cart_id,
                pay_app.get_customer_mail(rec.customer_id),
                pay_app.get_success_url(rec.cart_id, rec.api_token),
                pay_app.get_cancel_url(rec.cart_id),
                --
                in_raw      => in_values,
                in_splitter => c_alt_splitter
            ),
            in_splitter => c_alt_splitter
        );
        --
        APEX_JSON.PARSE(rec.api_response);
        --
        RETURN APEX_JSON.GET_VARCHAR2(p_path => 'url');
    END;



    FUNCTION get_customer_mail (
        in_customer_id      pay_customers.customer_id%TYPE
    )
    RETURN pay_customers.customer_mail%TYPE
    AS
        out_mail            pay_customers.customer_mail%TYPE;
    BEGIN
        SELECT c.customer_mail INTO out_mail
        FROM pay_customers c
        WHERE c.customer_id     = in_customer_id;
        --
        RETURN out_mail;
    END;



    FUNCTION get_customer_id (
        in_customer_mail    pay_customers.customer_mail%TYPE    := NULL
    )
    RETURN pay_customers.customer_id%TYPE
    AS
        out_id              pay_customers.customer_id%TYPE;
    BEGIN
        SELECT c.customer_id INTO out_id
        FROM pay_customers c
        WHERE c.customer_mail   = COALESCE(in_customer_mail, pay_app.get_user_id());
        --
        RETURN out_id;
    END;



    FUNCTION get_customer_cart_id (
        in_customer_id      pay_customers.customer_id%TYPE      := NULL,
        in_customer_mail    pay_customers.customer_mail%TYPE    := NULL
    )
    RETURN pay_shopping_carts.cart_id%TYPE
    AS
        out_cart_id         pay_shopping_carts.cart_id%TYPE;
        v_customer_id       pay_shopping_carts.customer_id%TYPE;
    BEGIN
        BEGIN
            SELECT c.customer_id INTO v_customer_id
            FROM pay_customers c
            WHERE (c.customer_id    = in_customer_id OR c.customer_mail = COALESCE(in_customer_mail, pay_app.get_user_id()));
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20000, 'UNKNOWN_CUSTOMER', TRUE);
        END;
        --
        SELECT MAX(s.cart_id) INTO out_cart_id
        FROM pay_shopping_carts s
        WHERE s.customer_id     = v_customer_id
            AND s.is_closed     IS NULL;
        --
        IF out_cart_id IS NULL THEN
            out_cart_id := pay_app.create_cart (
                in_customer_id      => v_customer_id
            );
        END IF;
        --
        RETURN out_cart_id;
    END;



    FUNCTION get_cart_checkout_url (
        in_cart_id          pay_shopping_carts.cart_id%TYPE,
        in_customer_id      pay_shopping_carts.customer_id%TYPE
    )
    RETURN VARCHAR2
    AS
        rec                 pay_requests%ROWTYPE;
        --
        v_target_url        VARCHAR2(32767);
        v_param_names       VARCHAR2(32767);
        v_param_values      VARCHAR2(32767);
    BEGIN
        rec.request_id      := pay_request_id.NEXTVAL;
        rec.cart_id         := in_cart_id;
        rec.customer_id     := in_customer_id;
        rec.session_id      := SYS_CONTEXT('APEX$SESSION', 'APP_SESSION');
        rec.api_token       := get_success_token();
        rec.requested_at    := SYSDATE;

        -- process shopping cart
        FOR c IN (
            SELECT
                ROW_NUMBER() OVER (ORDER BY t.created_at) AS line_id,
                p.api_price_id,
                t.amount
            FROM pay_shopping_cart_items t
            JOIN pay_products p
                ON p.product_id     = t.product_id
            WHERE t.cart_id         = in_cart_id
        )
        LOOP
            v_param_names   := v_param_names    || c_alt_splitter || 'line_items[' || (c.line_id - 1) || '][price]'
                                                || c_alt_splitter || 'line_items[' || (c.line_id - 1) || '][quantity]';
            v_param_values  := v_param_values   || c_alt_splitter || c.api_price_id
                                                || c_alt_splitter || c.amount;
        END LOOP;

        -- make request to the server
        v_target_url := pay_app.get_checkout_url(rec, v_param_names, v_param_values);
        --
        DBMS_OUTPUT.PUT_LINE('STRIPE URL  = ' || v_target_url);
        DBMS_OUTPUT.PUT_LINE('--');
        --
        IF v_target_url IS NULL THEN
            RAISE_APPLICATION_ERROR(-20000, 'API_ERROR:' || APEX_JSON.GET_VARCHAR2(p_path => 'error.message'), TRUE);
        END IF;

        -- store the tokens and transaction id in a table
        -- verify on the return that these tokens match
        INSERT INTO pay_requests VALUES rec;
        --
        RETURN v_target_url;
    END;



    PROCEDURE verify_checkout (
        in_cart_id          pay_requests.cart_id%TYPE,
        in_session_id       pay_requests.session_id%TYPE,
        in_token            pay_requests.api_token%TYPE
    )
    AS
        v_request_id        pay_requests.request_id%TYPE;
        v_customer_id       pay_requests.customer_id%TYPE;
    BEGIN
        UPDATE pay_requests r
        SET r.is_success            = 'Y',
            r.response_at           = SYSDATE
        WHERE r.cart_id             = in_cart_id
            AND (r.session_id       = in_session_id OR r.session_id IS NULL)
            AND r.api_token         = in_token
            AND r.requested_at      >= SYSDATE - 1/24
            AND r.is_success        IS NULL;
        --
        IF SQL%ROWCOUNT = 0 THEN
            UPDATE pay_requests r
            SET r.is_success            = 'N',
                r.response_at           = SYSDATE
            WHERE r.cart_id             = in_cart_id
                AND r.is_success        IS NULL;
            --
            RAISE PROGRAM_ERROR;
        END IF;
        --
        SELECT MAX(r.customer_id) INTO v_customer_id
        FROM pay_requests r
        WHERE r.cart_id         = in_cart_id;
        --
        pay_app.close_cart(v_customer_id);
    END;

END;
/

