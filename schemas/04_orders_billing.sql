-- ##########################################################
-- #                    ORDERS & BILLING                   #
-- # Checkout, shipping, billing addresses, order status   #
-- ##########################################################
-- ENUM: Order Status
CREATE TYPE order_status AS ENUM (
	'pending',
	'processing',
	'shipped',
	'delivered',
	'canceled',
	'refunded'
);

-- TABLE: Orders (Main Purchase Records)
CREATE TABLE
	orders (
		order_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
		user_id UUID REFERENCES users (user_id) ON DELETE CASCADE,
		total_price DECIMAL(10, 2) NOT NULL CHECK (total_price > 0),
		currency_code VARCHAR(3) REFERENCES currencies (currency_code),
		payment_status payment_status DEFAULT 'pending',
		order_status order_status DEFAULT 'pending',
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);

-- TABLE: Order Items (Tracks What Was Bought)
CREATE TABLE
	order_items (
		id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
		order_id UUID REFERENCES orders (order_id) ON DELETE CASCADE,
		product_variation_id UUID REFERENCES product_variations (variation_id) ON DELETE CASCADE,
		quantity INTEGER NOT NULL CHECK (quantity > 0),
		price_at_purchase DECIMAL(10, 2) NOT NULL CHECK (price_at_purchase > 0)
	);

-- TABLE: Shipping Addresses
CREATE TABLE
	shipping_addresses (
		address_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
		user_id UUID REFERENCES users (user_id) ON DELETE CASCADE,
		full_name VARCHAR(255) NOT NULL,
		street_address TEXT NOT NULL,
		city VARCHAR(100) NOT NULL,
		state VARCHAR(100) NOT NULL,
		postal_code VARCHAR(20) NOT NULL,
		country VARCHAR(100) NOT NULL,
		phone_number TEXT NOT NULL,
		is_default BOOLEAN DEFAULT FALSE
	);

-- TABLE: Billing Addresses (Separate)
CREATE TABLE
	billing_addresses (
		address_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
		user_id UUID REFERENCES users (user_id) ON DELETE CASCADE,
		full_name VARCHAR(255) NOT NULL,
		street_address TEXT NOT NULL,
		city VARCHAR(100) NOT NULL,
		state VARCHAR(100) NOT NULL,
		postal_code VARCHAR(20) NOT NULL,
		country VARCHAR(100) NOT NULL,
		phone_number TEXT NOT NULL,
		is_default BOOLEAN DEFAULT FALSE
	);

-- TABLE: Order Status History (For Audit Trail)
CREATE TABLE
	order_status_updates (
		update_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
		order_id UUID REFERENCES orders (order_id) ON DELETE CASCADE,
		previous_status order_status NOT NULL,
		new_status order_status NOT NULL,
		updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);