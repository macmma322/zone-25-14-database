-- 09 Additional Tables & Unsorted — Zone 25-14 Schema
-- WISHLIST
CREATE TABLE
    public.wishlist (
        id uuid DEFAULT uuid_generate_v4 () NOT NULL,
        user_id uuid NULL,
        product_id uuid NULL,
        added_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
        CONSTRAINT wishlist_pkey PRIMARY KEY (id),
        CONSTRAINT wishlist_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products (product_id) ON DELETE CASCADE,
        CONSTRAINT wishlist_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users (user_id) ON DELETE CASCADE
    );