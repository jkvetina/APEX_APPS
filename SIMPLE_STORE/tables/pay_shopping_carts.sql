CREATE TABLE pay_shopping_carts (
    cart_id                         NUMBER(10,0)    CONSTRAINT nn_pay_shopcart_cart_id NOT NULL,
    customer_id                     NUMBER(10,0)    CONSTRAINT nn_pay_shopcart_customer_id NOT NULL,
    is_closed                       CHAR(1),
    created_at                      DATE,
    --
    CONSTRAINT ch_pay_shopping_carts_closed
        CHECK (is_closed IS NULL OR is_closed = 'Y'),
    --
    CONSTRAINT pk_pay_shopping_carts
        PRIMARY KEY (cart_id),
    --
    CONSTRAINT fk_pay_shopping_carts_customer
        FOREIGN KEY (customer_id)
        REFERENCES pay_customers (customer_id)
);
--
COMMENT ON TABLE pay_shopping_carts IS '';
--
COMMENT ON COLUMN pay_shopping_carts.cart_id        IS '';
COMMENT ON COLUMN pay_shopping_carts.customer_id    IS '';
COMMENT ON COLUMN pay_shopping_carts.is_closed      IS '';

