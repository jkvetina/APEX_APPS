CREATE TABLE pay_customers (
    customer_id                     NUMBER(10,0)    CONSTRAINT nn_pay_customers_id NOT NULL,
    customer_name                   VARCHAR2(256)   CONSTRAINT nn_pay_customers_name NOT NULL,
    customer_mail                   VARCHAR2(256)   CONSTRAINT nn_pay_customers_mail NOT NULL,
    api_customer_id                 VARCHAR2(64),
    created_by                      VARCHAR2(128),
    created_at                      DATE,
    --
    CONSTRAINT pk_pay_customers
        PRIMARY KEY (customer_id),
    --
    CONSTRAINT fk_pay_customers_mail
        UNIQUE (customer_mail),
    --
    CONSTRAINT fk_pay_customers_customer
        UNIQUE (api_customer_id)
);
--
COMMENT ON TABLE pay_customers IS '';
--
COMMENT ON COLUMN pay_customers.customer_id         IS '';
COMMENT ON COLUMN pay_customers.customer_name       IS '';
COMMENT ON COLUMN pay_customers.customer_mail       IS '';
COMMENT ON COLUMN pay_customers.api_customer_id     IS '';

