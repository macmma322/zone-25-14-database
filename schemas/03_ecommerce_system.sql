-- ##########################################################
-- #           SCHEMA 02: SUBSCRIPTIONS & PAYMENTS          #
-- #  Manages subscription niches, plans, user purchases,  #
-- #  mystery boxes, and transaction records.              #
-- ##########################################################
-- ENUM: Billing Cycle
CREATE TYPE billing_cycle AS ENUM ('monthly', 'quarterly', 'half_yearly', 'yearly');

-- ENUM: Payment Status
CREATE TYPE payment_status AS ENUM ('pending', 'completed', 'failed', 'refunded');

-- ENUM: Mystery Box Shipment Status
CREATE TYPE shipment_status AS ENUM ('pending', 'shipped', 'delivered', 'failed');

-- TABLE: Subscription Niches
CREATE TABLE
	subscription_niches (
		niche_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
		name VARCHAR(100) UNIQUE NOT NULL
		-- Optional: add theme fields later (dark_color, accent_color, etc.)
	);

-- TABLE: Subscription Plans
CREATE TABLE
	subscription_plans (
		plan_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
		niche_id UUID REFERENCES subscription_niches (niche_id) ON DELETE CASCADE,
		name VARCHAR(100) NOT NULL,
		base_price DECIMAL(10, 2) NOT NULL CHECK (base_price > 0),
		currency_code VARCHAR(3) REFERENCES currencies (currency_code),
		billing_cycle billing_cycle NOT NULL DEFAULT 'monthly',
		perks JSONB DEFAULT '{}' -- Example: { "free_shipping": true }
	);

-- TABLE: User Subscriptions
CREATE TABLE
	user_subscriptions (
		subscription_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
		user_id UUID REFERENCES users (user_id) ON DELETE CASCADE,
		plan_id UUID REFERENCES subscription_plans (plan_id) ON DELETE CASCADE,
		start_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		duration_months INTEGER CHECK (duration_months IN (1, 3, 6, 12)),
		end_date TIMESTAMP GENERATED ALWAYS AS (
			start_date + (duration_months * INTERVAL '1 month')
		) STORED,
		is_active BOOLEAN DEFAULT TRUE
	);

-- TABLE: Mystery Box Shipments
CREATE TABLE
	mystery_box_shipments (
		shipment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
		subscription_id UUID REFERENCES user_subscriptions (subscription_id) ON DELETE CASCADE,
		user_id UUID REFERENCES users (user_id) ON DELETE CASCADE,
		niche_id UUID REFERENCES subscription_niches (niche_id) ON DELETE CASCADE,
		shipment_status shipment_status DEFAULT 'pending',
		tracking_number VARCHAR(50) UNIQUE,
		courier VARCHAR(100),
		shipped_at TIMESTAMP,
		delivered_at TIMESTAMP,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);

-- TABLE: Mystery Box Items
CREATE TABLE
	mystery_box_items (
		id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
		shipment_id UUID REFERENCES mystery_box_shipments (shipment_id) ON DELETE CASCADE,
		product_id UUID REFERENCES products (product_id) ON DELETE SET NULL,
		is_custom_keychain BOOLEAN DEFAULT FALSE,
		is_custom_quote BOOLEAN DEFAULT FALSE
	);

-- TABLE: Predefined Niche Quotes
CREATE TABLE
	niche_quotes (
		quote_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
		niche_id UUID REFERENCES subscription_niches (niche_id) ON DELETE CASCADE,
		quote TEXT NOT NULL
	);

-- TABLE: Currencies (Used Globally)
CREATE TABLE
	currencies (
		currency_code VARCHAR(3) PRIMARY KEY, -- e.g., "USD"
		currency_name VARCHAR(50) NOT NULL, -- e.g., "US Dollar"
		symbol VARCHAR(5) NOT NULL, -- e.g., "$"
		conversion_rate DECIMAL(10, 4) NOT NULL CHECK (conversion_rate > 0),
		last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);

-- TABLE: Payment Transactions
CREATE TABLE
	payment_transactions (
		transaction_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
		user_id UUID REFERENCES users (user_id) ON DELETE CASCADE,
		subscription_id UUID REFERENCES user_subscriptions (subscription_id) ON DELETE CASCADE,
		amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
		currency_code VARCHAR(3) REFERENCES currencies (currency_code) DEFAULT 'USD',
		payment_status payment_status DEFAULT 'pending',
		payment_method VARCHAR(50) NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);