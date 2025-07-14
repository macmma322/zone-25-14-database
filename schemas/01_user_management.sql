-- ##########################################################
-- #               USER MANAGEMENT & AUTH                   #
-- # Users, Roles, Linked Accounts, Preferences, Security  #
-- ##########################################################
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ENUM: User Roles
CREATE TYPE user_role AS ENUM (
	'Explorer',
	'Supporter',
	'Elite Member',
	'Legend',
	'Ultimate',
	'Moderator',
	'Store Chief',
	'Hype Lead',
	'Founder'
);

-- TABLE: Role Definitions
CREATE TABLE
	user_roles_levels (
		role_level_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
		role_name user_role UNIQUE NOT NULL,
		required_points INTEGER DEFAULT 0 CHECK (required_points >= 0),
		discount_percentage DECIMAL(5, 2) DEFAULT 0 CHECK (
			discount_percentage >= 0
			AND discount_percentage <= 100
		),
		is_staff BOOLEAN DEFAULT FALSE,
		permissions JSONB DEFAULT '{}'
	);

-- TABLE: Main User Accounts
CREATE TABLE
	users (
		user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
		username VARCHAR(50) UNIQUE NOT NULL,
		password TEXT NOT NULL, -- bcrypt
		email TEXT UNIQUE NOT NULL,
		phone TEXT,
		first_name VARCHAR(50),
		last_name VARCHAR(50),
		biography TEXT,
		profile_picture TEXT,
		role_level_id UUID REFERENCES user_roles_levels (role_level_id) DEFAULT (
			SELECT
				role_level_id
			FROM
				user_roles_levels
			WHERE
				role_name = 'Explorer'
		),
		store_credit DECIMAL(10, 2) DEFAULT 0 CHECK (store_credit >= 0),
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);

-- TABLE: OAuth / Linked Accounts
CREATE TABLE
	linked_accounts (
		id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
		user_id UUID REFERENCES users (user_id) ON DELETE CASCADE,
		platform VARCHAR(50) NOT NULL,
		username VARCHAR(255) NOT NULL,
		profile_url TEXT NOT NULL,
		access_token TEXT,
		refresh_token TEXT,
		linked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);

-- TABLE: Saved Cards (Encrypted)
CREATE TABLE
	saved_cards (
		card_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
		user_id UUID REFERENCES users (user_id) ON DELETE CASCADE,
		encrypted_card_number TEXT NOT NULL,
		encrypted_expiry_date TEXT NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);

-- TABLE: Privacy Settings
CREATE TABLE
	privacy_settings (
		user_id UUID PRIMARY KEY REFERENCES users (user_id) ON DELETE CASCADE,
		allow_friend_requests BOOLEAN DEFAULT TRUE,
		allow_messages BOOLEAN DEFAULT TRUE,
		profile_visibility VARCHAR(20) CHECK (
			profile_visibility IN ('public', 'private', 'friends-only')
		),
		show_wishlist BOOLEAN DEFAULT TRUE,
		show_recent_purchases BOOLEAN DEFAULT TRUE,
		appear_offline BOOLEAN DEFAULT FALSE
	);

-- TABLE: User Preferences
CREATE TABLE
	user_preferences (
		user_id UUID PRIMARY KEY REFERENCES users (user_id) ON DELETE CASCADE,
		theme_mode VARCHAR(20) CHECK (theme_mode IN ('light', 'dark', 'system')) DEFAULT 'system',
		language VARCHAR(10) DEFAULT 'en',
		preferred_currency VARCHAR(3) DEFAULT 'USD',
		email_notifications BOOLEAN DEFAULT TRUE
	);

-- TABLE: Notification Settings
CREATE TABLE
	notification_settings (
		user_id UUID PRIMARY KEY REFERENCES users (user_id) ON DELETE CASCADE,
		notify_on_new_message BOOLEAN DEFAULT TRUE,
		notify_on_friend_request BOOLEAN DEFAULT TRUE,
		notify_on_announcement BOOLEAN DEFAULT TRUE
	);

-- TABLE: IP Usage (Anti-Abuse)
CREATE TABLE
	ip_usage (
		ip_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
		user_id UUID REFERENCES users (user_id) ON DELETE CASCADE,
		ip_address VARCHAR(45) NOT NULL,
		detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);

-- TABLE: Login Fail Logs
CREATE TABLE
	failed_logins (
		fail_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
		user_id UUID REFERENCES users (user_id) ON DELETE CASCADE,
		ip_address VARCHAR(45) NOT NULL,
		attempt_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		reason TEXT NOT NULL CHECK (
			reason IN (
				'wrong_password',
				'account_locked',
				'suspicious_activity'
			)
		)
	);

-- TABLE: Device Detection
CREATE TABLE
	user_devices (
		device_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
		user_id UUID REFERENCES users (user_id) ON DELETE CASCADE,
		device_fingerprint TEXT NOT NULL,
		country VARCHAR(100) NOT NULL,
		city VARCHAR(100) NOT NULL,
		detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);