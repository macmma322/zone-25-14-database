-- 04 Orders & Billing — Zone 25-14 Schema

CREATE TABLE public.orders (
	order_id uuid DEFAULT uuid_generate_v4() NOT NULL,
	user_id uuid NULL,
	total_price numeric(10, 2) NOT NULL,
	earned_points int4 DEFAULT 0 NULL,
	payment_status varchar(50) DEFAULT 'pending'::character varying NULL,
	order_status varchar(50) DEFAULT 'processing'::character varying NULL,
	created_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	CONSTRAINT orders_pkey PRIMARY KEY (order_id),
	CONSTRAINT orders_total_price_check CHECK ((total_price >= (0)::numeric)),
	CONSTRAINT orders_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE
);

CREATE TABLE public.order_items (
	item_id uuid DEFAULT uuid_generate_v4() NOT NULL,
	order_id uuid NULL,
	product_id uuid NULL,
	variation_id uuid NULL,
	quantity int4 NOT NULL,
	price_each numeric(10, 2) NOT NULL,
	CONSTRAINT order_items_pkey PRIMARY KEY (item_id),
	CONSTRAINT order_items_price_each_check CHECK ((price_each >= (0)::numeric)),
	CONSTRAINT order_items_quantity_check CHECK ((quantity > 0)),
	CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(order_id) ON DELETE CASCADE,
	CONSTRAINT order_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id) ON DELETE SET NULL,
	CONSTRAINT order_items_variation_id_fkey FOREIGN KEY (variation_id) REFERENCES public.product_variations(variation_id) ON DELETE SET NULL
);

CREATE TABLE public.shopping_cart (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	user_id uuid NULL,
	product_variation_id uuid NULL,
	quantity int4 NOT NULL,
	added_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	CONSTRAINT shopping_cart_pkey PRIMARY KEY (id),
	CONSTRAINT shopping_cart_quantity_check CHECK ((quantity > 0)),
	CONSTRAINT unique_cart_item UNIQUE (user_id, product_variation_id),
	CONSTRAINT shopping_cart_product_variation_id_fkey FOREIGN KEY (product_variation_id) REFERENCES public.product_variations(variation_id) ON DELETE CASCADE,
	CONSTRAINT shopping_cart_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE
);
