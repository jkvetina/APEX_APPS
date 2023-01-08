CREATE TABLE pay_products (
    product_id                      NUMBER(10,0)    CONSTRAINT nn_pay_products_id NOT NULL,
    product_name                    VARCHAR2(256)   CONSTRAINT nn_pay_products_name NOT NULL,
    product_desc                    VARCHAR2(4000),
    price                           NUMBER(16,4)    CONSTRAINT nn_pay_products_price NOT NULL,
    currency_code                   CHAR(3),
    api_product_id                  VARCHAR2(64),
    api_price_id                    VARCHAR2(64),
    created_by                      VARCHAR2(128),
    created_at                      DATE,
    --
    CONSTRAINT pk_pay_products
        PRIMARY KEY (product_id),
    --
    CONSTRAINT uq_pay_products_api_product
        UNIQUE (api_product_id),
    --
    CONSTRAINT pk_pay_products_api_price
        UNIQUE (api_price_id)
);
--
COMMENT ON TABLE pay_products IS '';
--
COMMENT ON COLUMN pay_products.product_id       IS '';
COMMENT ON COLUMN pay_products.product_name     IS '';
COMMENT ON COLUMN pay_products.product_desc     IS '';
COMMENT ON COLUMN pay_products.price            IS '';
COMMENT ON COLUMN pay_products.currency_code    IS '';
COMMENT ON COLUMN pay_products.api_product_id   IS '';
COMMENT ON COLUMN pay_products.api_price_id     IS '';

