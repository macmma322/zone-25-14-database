-- 01 User Management — Zone 25-14 Schema

-- ENUM TYPES
CREATE TYPE public."user_role" AS ENUM (
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

-- ROLES LEVELS TABLE
CREATE TABLE public.user_roles_levels (
	role_level_id uuid DEFAULT uuid_generate_v4() NOT NULL,
	role_name public."user_role" NOT NULL,
	required_points int4 DEFAULT 0 NULL,
	discount_percentage numeric(5, 2) DEFAULT 0.00 NULL,
	is_staff bool DEFAULT false NULL,
	permissions jsonb DEFAULT '{}'::jsonb NULL,
	CONSTRAINT user_roles_levels_discount_percentage_check CHECK (((discount_percentage >= (0)::numeric) AND (discount_percentage <= (100)::numeric))),
	CONSTRAINT user_roles_levels_pkey PRIMARY KEY (role_level_id),
	CONSTRAINT user_roles_levels_required_points_check CHECK ((required_points >= 0)),
	CONSTRAINT user_roles_levels_role_name_key UNIQUE (role_name)
);

-- USERS TABLE
CREATE TABLE public.users (
	user_id uuid DEFAULT uuid_generate_v4() NOT NULL,
	username varchar(50) NOT NULL,
	"password" text NOT NULL,
	email bytea NOT NULL,
	phone bytea NULL,
	first_name varchar(50) NULL,
	last_name varchar(50) NULL,
	biography text NULL,
	profile_picture text NULL,
	role_level_id uuid NULL,
	store_credit numeric(10, 2) DEFAULT 0 NULL,
	created_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	points int4 DEFAULT 0 NULL,
	birthday date NULL,
	birthday_reward_year int4 DEFAULT 0 NULL,
	CONSTRAINT users_pkey PRIMARY KEY (user_id),
	CONSTRAINT users_points_check CHECK ((points >= 0)),
	CONSTRAINT users_store_credit_check CHECK ((store_credit >= (0)::numeric)),
	CONSTRAINT users_username_key UNIQUE (username),
	CONSTRAINT users_role_level_id_fkey FOREIGN KEY (role_level_id) REFERENCES public.user_roles_levels(role_level_id)
);

-- TRIGGERS
CREATE TRIGGER encrypt_user_data
BEFORE INSERT OR UPDATE ON public.users
FOR EACH ROW
EXECUTE FUNCTION encrypt_sensitive_data();

-- PRIVACY SETTINGS
CREATE TABLE public.privacy_settings (
	user_id uuid NOT NULL,
	allow_friend_requests bool DEFAULT true NULL,
	allow_messages bool DEFAULT true NULL,
	profile_visibility varchar(20) DEFAULT 'public'::character varying NULL,
	show_wishlist bool DEFAULT true NULL,
	show_recent_purchases bool DEFAULT true NULL,
	appear_offline bool DEFAULT false NULL,
	CONSTRAINT privacy_settings_pkey PRIMARY KEY (user_id),
	CONSTRAINT privacy_settings_profile_visibility_check CHECK (((profile_visibility)::text = ANY ((ARRAY['public', 'private', 'friends-only'])::text[]))),
	CONSTRAINT privacy_settings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE
);

-- PREFERENCES
CREATE TABLE public.user_preferences (
	user_id uuid NOT NULL,
	theme_mode varchar(20) DEFAULT 'system'::character varying NULL,
	"language" varchar(10) DEFAULT 'en'::character varying NULL,
	preferred_currency varchar(3) DEFAULT 'USD'::character varying NULL,
	email_notifications bool DEFAULT true NULL,
	CONSTRAINT user_preferences_pkey PRIMARY KEY (user_id),
	CONSTRAINT user_preferences_theme_mode_check CHECK (((theme_mode)::text = ANY ((ARRAY['light', 'dark', 'system'])::text[]))),
	CONSTRAINT user_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE
);

-- POINTS LOG
CREATE TABLE public.user_points (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	user_id uuid NULL,
	points int4 NOT NULL,
	earned_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	CONSTRAINT user_points_pkey PRIMARY KEY (id),
	CONSTRAINT user_points_points_check CHECK ((points >= 0)),
	CONSTRAINT user_points_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE
);
