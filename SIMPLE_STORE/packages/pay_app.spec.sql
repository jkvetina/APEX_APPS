CREATE OR REPLACE PACKAGE pay_app AS

    c_default_currency      CONSTANT CHAR(3)        := 'USD';
    c_default_splitter      CONSTANT CHAR(1)        := ':';
    c_alt_splitter          CONSTANT CHAR(1)        := '^';
    --
    c_result_server         CONSTANT VARCHAR2(256)  := 'denim.maxapex.net';
    c_result_page_id        CONSTANT NUMBER(8)      := 200;
    --
    c_type_success          CONSTANT VARCHAR2(8)    := 'SUCCESS';
    c_type_cancel           CONSTANT VARCHAR2(8)    := 'CANCEL';



    FUNCTION get_user_id
    RETURN VARCHAR2;



    FUNCTION get_session_id
    RETURN NUMBER;



    FUNCTION get_private_key
    RETURN pay_secrets.value%TYPE;



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
    RETURN VARCHAR2;



    FUNCTION get_rest_response (
        in_url              VARCHAR2,
        in_params           VARCHAR2,
        in_values           VARCHAR2,
        in_splitter         CHAR            := NULL
    )
    RETURN CLOB;



    FUNCTION get_api_product_id (
        in_rec          pay_products%ROWTYPE
    )
    RETURN pay_products.api_product_id%TYPE;



    FUNCTION get_api_price_id (
        in_rec          pay_products%ROWTYPE
    )
    RETURN pay_products.api_price_id%TYPE;



    FUNCTION get_success_token
    RETURN VARCHAR2;



    FUNCTION get_success_url (
        in_cart_id          VARCHAR2,
        in_token            VARCHAR2,
        in_session_id       NUMBER      := NULL
    )
    RETURN VARCHAR2;



    FUNCTION get_cancel_url (
        in_cart_id          VARCHAR2,
        in_session_id       NUMBER      := NULL
    )
    RETURN VARCHAR2;



    FUNCTION get_customer_mail (
        in_customer_id      pay_customers.customer_id%TYPE
    )
    RETURN pay_customers.customer_mail%TYPE;



    FUNCTION get_customer_id (
        in_customer_mail    pay_customers.customer_mail%TYPE    := NULL
    )
    RETURN pay_customers.customer_id%TYPE;



    FUNCTION get_customer_cart_id (
        in_customer_id      pay_customers.customer_id%TYPE      := NULL,
        in_customer_mail    pay_customers.customer_mail%TYPE    := NULL
    )
    RETURN pay_shopping_carts.cart_id%TYPE;



    FUNCTION get_cart_checkout_url (
        in_cart_id          pay_shopping_carts.cart_id%TYPE,
        in_customer_id      pay_shopping_carts.customer_id%TYPE
    )
    RETURN VARCHAR2;



    FUNCTION get_checkout_url (
        rec             IN OUT NOCOPY   pay_requests%ROWTYPE,
        in_params                       VARCHAR2,
        in_values                       VARCHAR2
    )
    RETURN VARCHAR2;



    PROCEDURE create_customer (
        in_name         pay_customers.customer_name%TYPE,
        in_mail         pay_customers.customer_mail%TYPE
    );



    PROCEDURE create_product (
        in_name         pay_products.product_name%TYPE,
        in_desc         pay_products.product_desc%TYPE,
        in_price        pay_products.price%TYPE,
        in_currency     pay_products.currency_code%TYPE     := NULL
    );



    FUNCTION create_cart (
        in_customer_id      pay_shopping_carts.customer_id%TYPE
    )
    RETURN pay_shopping_carts.cart_id%TYPE;



    PROCEDURE update_cart (
        in_customer_id      pay_shopping_carts.customer_id%TYPE,
        in_cart_id          pay_shopping_carts.cart_id%TYPE,
        in_product_id       pay_shopping_cart_items.product_id%TYPE,
        in_amount           pay_shopping_cart_items.amount%TYPE     := NULL,
        in_amount_total     pay_shopping_cart_items.amount%TYPE     := NULL
    );



    PROCEDURE close_cart (
        in_customer_id      pay_shopping_carts.customer_id%TYPE
    );



    PROCEDURE verify_checkout (
        in_cart_id          pay_requests.cart_id%TYPE,
        in_session_id       pay_requests.session_id%TYPE,
        in_token            pay_requests.api_token%TYPE
    );

END;
/

