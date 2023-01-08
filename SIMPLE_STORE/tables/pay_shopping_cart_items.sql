CREATE TABLE pay_shopping_cart_items (
    cart_id                         NUMBER(10,0)    CONSTRAINT nn_pay_shopitem_cart_id NOT NULL,
    product_id                      NUMBER(10,0)    CONSTRAINT nn_pay_shopitem_product_id NOT NULL,
    amount                          NUMBER(16,4)    CONSTRAINT nn_pay_shopitem_amount NOT NULL,
    created_at                      DATE,
    updated_at                      DATE,
    --
    CONSTRAINT pk_shopping_carts_items
        PRIMARY KEY (cart_id, product_id),
    --
    CONSTRAINT fk_pay_shopitem_cart
        FOREIGN KEY (cart_id)
        REFERENCES pay_shopping_carts (cart_id),
    --
    CONSTRAINT fk_pay_shopitem_product
        FOREIGN KEY (product_id)
        REFERENCES pay_products (product_id)
);
--
COMMENT ON TABLE pay_shopping_cart_items IS '';
--
COMMENT ON COLUMN pay_shopping_cart_items.cart_id       IS '';
COMMENT ON COLUMN pay_shopping_cart_items.product_id    IS '';
COMMENT ON COLUMN pay_shopping_cart_items.amount        IS '';

