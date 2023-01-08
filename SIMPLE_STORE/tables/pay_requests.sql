CREATE TABLE pay_requests (
    request_id                      NUMBER(10,0)    CONSTRAINT nn_pay_requests_id NOT NULL,
    cart_id                         NUMBER(10,0)    CONSTRAINT nn_pay_requests_cart_id NOT NULL,
    customer_id                     NUMBER(10,0)    CONSTRAINT nn_pay_requests_customer_id NOT NULL,
    session_id                      NUMBER(16,0),
    api_token                       VARCHAR2(64),
    api_response                    CLOB,
    is_success                      CHAR(1),
    requested_at                    DATE            CONSTRAINT nn_pay_requests_requested NOT NULL,
    response_at                     DATE,
    --
    CONSTRAINT ch_pay_requests_success
        CHECK (is_success IS NULL OR is_success = 'Y' OR is_success = 'N'),
    --
    CONSTRAINT pk_pay_requests
        PRIMARY KEY (request_id),
    --
    CONSTRAINT fk_pay_requests_cart
        FOREIGN KEY (cart_id)
        REFERENCES pay_shopping_carts (cart_id),
    --
    CONSTRAINT fk_pay_requests_customer
        FOREIGN KEY (customer_id)
        REFERENCES pay_customers (customer_id)
);
--
COMMENT ON TABLE pay_requests IS '';
--
COMMENT ON COLUMN pay_requests.request_id       IS '';
COMMENT ON COLUMN pay_requests.cart_id          IS '';
COMMENT ON COLUMN pay_requests.customer_id      IS '';
COMMENT ON COLUMN pay_requests.session_id       IS '';
COMMENT ON COLUMN pay_requests.api_token        IS '';
COMMENT ON COLUMN pay_requests.api_response     IS '';
COMMENT ON COLUMN pay_requests.is_success       IS '';
COMMENT ON COLUMN pay_requests.requested_at     IS '';
COMMENT ON COLUMN pay_requests.response_at      IS '';

