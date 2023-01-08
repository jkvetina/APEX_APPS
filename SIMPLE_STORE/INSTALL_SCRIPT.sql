
@@"./sequences/pay_cart_id.sql"
@@"./sequences/pay_customer_id.sql"
@@"./sequences/pay_product_id.sql"
@@"./sequences/pay_request_id.sql"

@@"./tables/pay_secrets.sql"
@@"./tables/pay_customers.sql"
@@"./tables/pay_products.sql"
@@"./tables/pay_shopping_carts.sql"
@@"./tables/pay_shopping_cart_items.sql"
@@"./tables/pay_requests.sql"

INSERT INTO pay_secrets (id, value)
VALUES (
    'STRIPE_PRIVATE_KEY',
    'sk_............................USE_YOUR_KEY'
);
--
COMMIT;

@@"./packages/pay_app.spec.sql"
@@"./packages/pay_app.sql"

@@"./apex/f610.sql"

