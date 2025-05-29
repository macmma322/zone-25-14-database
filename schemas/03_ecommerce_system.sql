-- 03 Ecommerce System — Zone 25-14 Schema

CREATE TABLE public.brands (
	brand_id uuid DEFAULT uuid_generate_v4() NOT NULL,
	brand_name varchar(100) NOT NULL,
	description text NULL,
	CONSTRAINT brands_brand_name_key UNIQUE (brand_name),
	CONSTRAINT brands_pkey PRIMARY KEY (brand_id)
);

CREATE TABLE public.categories (
	category_id uuid DEFAULT uuid_generate_v4() NOT NULL,
	"name" varchar(100) NOT NULL,
	parent_category_id uuid NULL,
	"path" text NULL,
	CONSTRAINT categories_pkey PRIMARY KEY (category_id),
	CONSTRAINT categories_parent_category_id_fkey FOREIGN KEY (parent_category_id) REFERENCES public.categories(category_id)
);

CREATE TABLE public.products (
	product_id uuid DEFAULT uuid_generate_v4() NOT NULL,
	brand_id uuid NULL,
	"name" varchar(100) NOT NULL,
	description text NULL,
	base_price numeric(10, 2) NOT NULL,
	currency_code varchar(3) DEFAULT 'USD'::character varying NULL,
	is_exclusive bool DEFAULT false NULL,
	is_active bool DEFAULT true NULL,
	created_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	exclusive_to_niche varchar(50) NULL,
	CONSTRAINT products_base_price_check CHECK ((base_price > (0)::numeric)),
	CONSTRAINT products_pkey PRIMARY KEY (product_id),
	CONSTRAINT products_brand_id_fkey FOREIGN KEY (brand_id) REFERENCES public.brands(brand_id) ON DELETE SET NULL
);

CREATE TABLE public.product_images (
	image_id uuid DEFAULT uuid_generate_v4() NOT NULL,
	product_id uuid NULL,
	image_url text NOT NULL,
	is_main bool DEFAULT false NULL,
	uploaded_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	CONSTRAINT product_images_pkey PRIMARY KEY (image_id),
	CONSTRAINT product_images_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id) ON DELETE CASCADE
);

CREATE TABLE public.product_variations (
	variation_id uuid DEFAULT uuid_generate_v4() NOT NULL,
	product_id uuid NULL,
	"size" varchar(50) NULL,
	color varchar(50) NULL,
	special_edition varchar(100) NULL,
	stock_quantity int4 DEFAULT 0 NOT NULL,
	additional_price numeric(10, 2) DEFAULT 0 NULL,
	CONSTRAINT product_variations_additional_price_check CHECK ((additional_price >= (0)::numeric)),
	CONSTRAINT product_variations_pkey PRIMARY KEY (variation_id),
	CONSTRAINT product_variations_stock_quantity_check CHECK ((stock_quantity >= 0)),
	CONSTRAINT product_variations_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id) ON DELETE CASCADE
);

CREATE TABLE public.inventory (
	inventory_id uuid DEFAULT uuid_generate_v4() NOT NULL,
	product_variation_id uuid NULL,
	stock_quantity int4 NOT NULL,
	last_updated timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	CONSTRAINT inventory_pkey PRIMARY KEY (inventory_id),
	CONSTRAINT inventory_stock_quantity_check CHECK ((stock_quantity >= 0)),
	CONSTRAINT inventory_product_variation_id_fkey FOREIGN KEY (product_variation_id) REFERENCES public.product_variations(variation_id) ON DELETE CASCADE
);
