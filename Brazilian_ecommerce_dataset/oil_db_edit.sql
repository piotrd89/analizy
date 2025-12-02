ALTER TABLE olist_order_reviews DROP CONSTRAINT olist_order_reviews_pkey;
ALTER TABLE olist_order_reviews ADD COLUMN id SERIAL PRIMARY KEY;

TRUNCATE TABLE olist_order_reviews;

ALTER TABLE olist_order_reviews
ALTER COLUMN review_id TYPE VARCHAR(128);

ALTER TABLE olist_order_reviews
ALTER COLUMN review_comment_message TYPE TEXT;
ALTER TABLE olist_order_reviews
ALTER COLUMN review_comment_title TYPE TEXT;