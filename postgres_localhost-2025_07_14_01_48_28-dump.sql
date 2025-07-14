--
-- PostgreSQL database dump
--

-- Dumped from database version 17.4
-- Dumped by pg_dump version 17.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE the_zone_core;
--
-- Name: the_zone_core; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE the_zone_core WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en-US';


ALTER DATABASE the_zone_core OWNER TO postgres;

\connect the_zone_core

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: friend_request_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.friend_request_status AS ENUM (
    'pending',
    'accepted',
    'declined',
    'canceled'
);


ALTER TYPE public.friend_request_status OWNER TO postgres;

--
-- Name: group_chat_role; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.group_chat_role AS ENUM (
    'owner',
    'admin',
    'member',
    'muted',
    'banned'
);


ALTER TYPE public.group_chat_role OWNER TO postgres;

--
-- Name: user_role; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.user_role AS ENUM (
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


ALTER TYPE public.user_role OWNER TO postgres;

--
-- Name: encrypt_card_data(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.encrypt_card_data() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.encrypted_card_number := PGP_SYM_ENCRYPT(NEW.encrypted_card_number, 'card_secret_key');
    NEW.encrypted_expiry_date := PGP_SYM_ENCRYPT(NEW.encrypted_expiry_date, 'card_secret_key');
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.encrypt_card_data() OWNER TO postgres;

--
-- Name: encrypt_sensitive_data(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.encrypt_sensitive_data() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Check if email needs encryption
  BEGIN
    PERFORM pgp_sym_decrypt(NEW.email, 'NTb3b7lQNehAteG3PBdJmCMTLVgp24AYJ1-afRCgX1hAIH9PGEKAC15RTUQXyTQ69XsTTHhx1Z6doVZ1VLfNaw');
  EXCEPTION WHEN others THEN
    -- It's not decryptable → encrypt it
    NEW.email := pgp_sym_encrypt(convert_from(NEW.email, 'UTF8'), 'NTb3b7lQNehAteG3PBdJmCMTLVgp24AYJ1-afRCgX1hAIH9PGEKAC15RTUQXyTQ69XsTTHhx1Z6doVZ1VLfNaw');
  END;

  -- Same for phone
  IF NEW.phone IS NOT NULL THEN
    BEGIN
      PERFORM pgp_sym_decrypt(NEW.phone, 'NTb3b7lQNehAteG3PBdJmCMTLVgp24AYJ1-afRCgX1hAIH9PGEKAC15RTUQXyTQ69XsTTHhx1Z6doVZ1VLfNaw');
    EXCEPTION WHEN others THEN
      NEW.phone := pgp_sym_encrypt(convert_from(NEW.phone, 'UTF8'), 'NTb3b7lQNehAteG3PBdJmCMTLVgp24AYJ1-afRCgX1hAIH9PGEKAC15RTUQXyTQ69XsTTHhx1Z6doVZ1VLfNaw');
    END;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION public.encrypt_sensitive_data() OWNER TO postgres;

--
-- Name: prevent_duplicate_friend_requests(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.prevent_duplicate_friend_requests() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM friend_requests 
        WHERE sender_id = NEW.sender_id 
          AND receiver_id = NEW.receiver_id 
          AND status = 'pending'
    ) THEN
        RAISE EXCEPTION 'Friend request already sent.';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.prevent_duplicate_friend_requests() OWNER TO postgres;

--
-- Name: set_default_role(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_default_role() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Assign the Explorer role_level_id if it's NULL
    IF NEW.role_level_id IS NULL THEN
        SELECT role_level_id INTO NEW.role_level_id
        FROM user_roles_levels
        WHERE role_name = 'Explorer'
        LIMIT 1;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.set_default_role() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: brands; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.brands (
    brand_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    brand_name character varying(100) NOT NULL,
    description text
);


ALTER TABLE public.brands OWNER TO postgres;

--
-- Name: categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categories (
    category_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(100) NOT NULL,
    parent_category_id uuid,
    path text
);


ALTER TABLE public.categories OWNER TO postgres;

--
-- Name: conversation_members; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.conversation_members (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    conversation_id uuid,
    user_id uuid,
    role public.group_chat_role DEFAULT 'member'::public.group_chat_role,
    joined_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.conversation_members OWNER TO postgres;

--
-- Name: conversations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.conversations (
    conversation_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    is_group boolean DEFAULT false,
    group_name character varying(100),
    created_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.conversations OWNER TO postgres;

--
-- Name: friend_requests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.friend_requests (
    request_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    sender_id uuid,
    receiver_id uuid,
    status public.friend_request_status DEFAULT 'pending'::public.friend_request_status,
    sent_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    responded_at timestamp without time zone
);


ALTER TABLE public.friend_requests OWNER TO postgres;

--
-- Name: friends; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.friends (
    friendship_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    friend_id uuid,
    became_friends_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    is_blocked boolean DEFAULT false,
    is_removed boolean DEFAULT false,
    unread_count integer DEFAULT 0,
    pinned boolean DEFAULT false,
    last_message_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.friends OWNER TO postgres;

--
-- Name: inventory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inventory (
    inventory_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    product_variation_id uuid,
    stock_quantity integer NOT NULL,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT inventory_stock_quantity_check CHECK ((stock_quantity >= 0))
);


ALTER TABLE public.inventory OWNER TO postgres;

--
-- Name: message_reactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.message_reactions (
    reaction_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    message_id uuid,
    user_id uuid,
    reaction character varying(50) NOT NULL,
    reacted_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.message_reactions OWNER TO postgres;

--
-- Name: message_requests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.message_requests (
    request_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    sender_id uuid,
    receiver_id uuid,
    content text NOT NULL,
    sent_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    status character varying(20) DEFAULT 'pending'::character varying,
    CONSTRAINT message_requests_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'accepted'::character varying, 'declined'::character varying])::text[])))
);


ALTER TABLE public.message_requests OWNER TO postgres;

--
-- Name: messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.messages (
    message_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    conversation_id uuid,
    sender_id uuid,
    content text NOT NULL,
    is_deleted boolean DEFAULT false,
    sent_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    reply_to_id uuid,
    replied_to uuid
);


ALTER TABLE public.messages OWNER TO postgres;

--
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notifications (
    notification_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    type character varying(50) NOT NULL,
    content text NOT NULL,
    is_read boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    link text,
    data jsonb,
    additional_info text
);


ALTER TABLE public.notifications OWNER TO postgres;

--
-- Name: order_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_items (
    item_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    order_id uuid,
    product_id uuid,
    variation_id uuid,
    quantity integer NOT NULL,
    price_each numeric(10,2) NOT NULL,
    CONSTRAINT order_items_price_each_check CHECK ((price_each >= (0)::numeric)),
    CONSTRAINT order_items_quantity_check CHECK ((quantity > 0))
);


ALTER TABLE public.order_items OWNER TO postgres;

--
-- Name: orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.orders (
    order_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    total_price numeric(10,2) NOT NULL,
    earned_points integer DEFAULT 0,
    payment_status character varying(50) DEFAULT 'pending'::character varying,
    order_status character varying(50) DEFAULT 'processing'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT orders_total_price_check CHECK ((total_price >= (0)::numeric))
);


ALTER TABLE public.orders OWNER TO postgres;

--
-- Name: privacy_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.privacy_settings (
    user_id uuid NOT NULL,
    allow_friend_requests boolean DEFAULT true,
    allow_messages boolean DEFAULT true,
    profile_visibility character varying(20) DEFAULT 'public'::character varying,
    show_wishlist boolean DEFAULT true,
    show_recent_purchases boolean DEFAULT true,
    appear_offline boolean DEFAULT false,
    CONSTRAINT privacy_settings_profile_visibility_check CHECK (((profile_visibility)::text = ANY ((ARRAY['public'::character varying, 'private'::character varying, 'friends-only'::character varying])::text[])))
);


ALTER TABLE public.privacy_settings OWNER TO postgres;

--
-- Name: product_images; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product_images (
    image_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    product_id uuid,
    image_url text NOT NULL,
    is_main boolean DEFAULT false,
    uploaded_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.product_images OWNER TO postgres;

--
-- Name: product_variations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product_variations (
    variation_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    product_id uuid,
    size character varying(50),
    color character varying(50),
    special_edition character varying(100),
    stock_quantity integer DEFAULT 0 NOT NULL,
    additional_price numeric(10,2) DEFAULT 0,
    CONSTRAINT product_variations_additional_price_check CHECK ((additional_price >= (0)::numeric)),
    CONSTRAINT product_variations_stock_quantity_check CHECK ((stock_quantity >= 0))
);


ALTER TABLE public.product_variations OWNER TO postgres;

--
-- Name: products; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.products (
    product_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    brand_id uuid,
    name character varying(100) NOT NULL,
    description text,
    base_price numeric(10,2) NOT NULL,
    currency_code character varying(3) DEFAULT 'USD'::character varying,
    is_exclusive boolean DEFAULT false,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    exclusive_to_niche character varying(50),
    CONSTRAINT products_base_price_check CHECK ((base_price > (0)::numeric))
);


ALTER TABLE public.products OWNER TO postgres;

--
-- Name: shopping_cart; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.shopping_cart (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    product_variation_id uuid,
    quantity integer NOT NULL,
    added_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT shopping_cart_quantity_check CHECK ((quantity > 0))
);


ALTER TABLE public.shopping_cart OWNER TO postgres;

--
-- Name: subscription_plans; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subscription_plans (
    plan_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    niche_code character varying(50),
    tier_type character varying(20),
    price numeric(10,2),
    discount_percentage numeric(5,2),
    points_multiplier numeric(3,2)
);


ALTER TABLE public.subscription_plans OWNER TO postgres;

--
-- Name: user_points; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_points (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    points integer NOT NULL,
    earned_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT user_points_points_check CHECK ((points >= 0))
);


ALTER TABLE public.user_points OWNER TO postgres;

--
-- Name: user_preferences; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_preferences (
    user_id uuid NOT NULL,
    theme_mode character varying(20) DEFAULT 'system'::character varying,
    language character varying(10) DEFAULT 'en'::character varying,
    preferred_currency character varying(3) DEFAULT 'USD'::character varying,
    email_notifications boolean DEFAULT true,
    CONSTRAINT user_preferences_theme_mode_check CHECK (((theme_mode)::text = ANY ((ARRAY['light'::character varying, 'dark'::character varying, 'system'::character varying])::text[])))
);


ALTER TABLE public.user_preferences OWNER TO postgres;

--
-- Name: user_roles_levels; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_roles_levels (
    role_level_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    role_name public.user_role NOT NULL,
    required_points integer DEFAULT 0,
    discount_percentage numeric(5,2) DEFAULT 0.00,
    is_staff boolean DEFAULT false,
    permissions jsonb DEFAULT '{}'::jsonb,
    CONSTRAINT user_roles_levels_discount_percentage_check CHECK (((discount_percentage >= (0)::numeric) AND (discount_percentage <= (100)::numeric))),
    CONSTRAINT user_roles_levels_required_points_check CHECK ((required_points >= 0))
);


ALTER TABLE public.user_roles_levels OWNER TO postgres;

--
-- Name: user_subscriptions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_subscriptions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    niche_code character varying(50),
    tier_type character varying(20),
    start_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    end_date timestamp without time zone,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.user_subscriptions OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    user_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    username character varying(50) NOT NULL,
    password text NOT NULL,
    email bytea NOT NULL,
    phone bytea,
    first_name character varying(50),
    last_name character varying(50),
    biography text,
    profile_picture text,
    role_level_id uuid,
    store_credit numeric(10,2) DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    points integer DEFAULT 0,
    birthday date,
    birthday_reward_year integer DEFAULT 0,
    CONSTRAINT users_points_check CHECK ((points >= 0)),
    CONSTRAINT users_store_credit_check CHECK ((store_credit >= (0)::numeric))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: wishlist; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.wishlist (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    product_id uuid,
    added_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.wishlist OWNER TO postgres;

--
-- Data for Name: brands; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.brands (brand_id, brand_name, description) VALUES ('8b46a305-a36f-41d7-97c9-ad407cb4d62f', 'OtakuSquad', 'Anime lifestyle and emotional expression.');
INSERT INTO public.brands (brand_id, brand_name, description) VALUES ('9f1d9946-61bf-4dde-bff1-58a2963b6645', 'StoikrClub', 'Strength, discipline, warrior culture.');
INSERT INTO public.brands (brand_id, brand_name, description) VALUES ('8e7407df-22f4-411b-b8ca-85c588803f80', 'WD Crew', 'Car culture, speed, brotherhood of the road.');
INSERT INTO public.brands (brand_id, brand_name, description) VALUES ('871c1756-f7d8-49e1-a6a6-f95f0f185f93', 'PerOs Pack', 'Motorcycle rebellion and freedom.');
INSERT INTO public.brands (brand_id, brand_name, description) VALUES ('5e53fd68-885d-4a2a-bbd0-570fbcecc694', 'CritHit Team', 'Gaming hype and skill.');
INSERT INTO public.brands (brand_id, brand_name, description) VALUES ('acd0a275-cf77-4d28-bb41-f0e3f8dc6b4f', 'The Grid Opus', 'Coders, hackers, and digital architects.');
INSERT INTO public.brands (brand_id, brand_name, description) VALUES ('9fc57790-aac5-4f75-ad13-353e65eb7df4', 'The Syndicate', 'Old money luxury rebellion.');


--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('2c76b528-85a5-4c73-80e6-cd38ffd484bf', 'Clothing', NULL, NULL);
INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('00c0e53a-e09d-4105-889d-4031786fab58', 'Lifestyle Accessories', NULL, NULL);
INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('3250be95-ae9f-49f3-bd55-dd67fb20768b', 'Desk Figures', NULL, NULL);
INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('2fb4d3b0-99f6-42c6-b64b-7185c0715cab', 'Desk Gear', NULL, NULL);
INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('a552abf9-bbc1-483a-92cc-e144e2230025', 'Mystery Boxes', NULL, NULL);
INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('3786033b-0c53-4a0f-a295-3c88f998b57d', 'Car Gear', NULL, NULL);
INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('89e6c28b-9d9b-4fab-a9fe-3b6cb3d40559', 'Motorcycle Gear', NULL, NULL);
INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('1ee77ae4-2576-4aee-aac0-858942643e67', 'Keychains', '00c0e53a-e09d-4105-889d-4031786fab58', NULL);
INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('525cc0dd-3e06-4570-bc4d-562f79bd7412', 'Chains', '00c0e53a-e09d-4105-889d-4031786fab58', NULL);
INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('c44704ba-1206-463c-b582-367707b6f404', 'Bracelets', '00c0e53a-e09d-4105-889d-4031786fab58', NULL);
INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('930cd125-1912-4440-b5dc-4d465a0366f8', 'Rings', '00c0e53a-e09d-4105-889d-4031786fab58', NULL);
INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('732eb52b-6e33-4ca8-bbf3-44fb2f4f5b3b', 'Necklaces', '00c0e53a-e09d-4105-889d-4031786fab58', NULL);
INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('61631bca-4134-45e3-89a8-d87076a61598', 'Hats (Caps)', '00c0e53a-e09d-4105-889d-4031786fab58', NULL);
INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('268a5205-256a-4d62-b677-562a71d7a9a3', 'Bandanas & Scarves', '00c0e53a-e09d-4105-889d-4031786fab58', NULL);
INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('b0507b73-2b8a-48a0-8589-04de6f4b3609', 'Watches', '00c0e53a-e09d-4105-889d-4031786fab58', NULL);
INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('7498715c-946b-436b-a0a2-85674369deed', 'Hoodies', '2c76b528-85a5-4c73-80e6-cd38ffd484bf', NULL);
INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('48b37efa-23b0-4040-a0d5-d79508d035ae', 'T-Shirts', '2c76b528-85a5-4c73-80e6-cd38ffd484bf', NULL);
INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('e7213337-0ea8-45b6-acd4-5d6a752d8941', 'Pants', '2c76b528-85a5-4c73-80e6-cd38ffd484bf', NULL);
INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('318deea4-18cf-45db-9e77-683212c077f6', 'Shorts', '2c76b528-85a5-4c73-80e6-cd38ffd484bf', NULL);
INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('47bad852-8842-4b00-86fd-a4acede45670', 'Gym Tops', '2c76b528-85a5-4c73-80e6-cd38ffd484bf', NULL);
INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('8526c472-9f41-414f-9da7-0acf91cadc77', 'Gym Pants', '2c76b528-85a5-4c73-80e6-cd38ffd484bf', NULL);
INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('42a2e027-3079-41bf-a93e-dd50581b55eb', 'Suits & Tuxedos', '2c76b528-85a5-4c73-80e6-cd38ffd484bf', NULL);
INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('68d293f3-d393-47e9-bfe5-6fa519b647ac', 'Luxury Coats', '2c76b528-85a5-4c73-80e6-cd38ffd484bf', NULL);
INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('fe7ed8ad-0190-4b4d-aadd-d848c55b0dff', 'Formal Shirts', '2c76b528-85a5-4c73-80e6-cd38ffd484bf', NULL);
INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('189eca7d-3416-4643-8e29-df222900f984', 'Anime Figures', '3250be95-ae9f-49f3-bd55-dd67fb20768b', NULL);
INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('8c6fbfc7-5bdb-4125-8220-1f39a34871e0', 'Gaming Figures', '3250be95-ae9f-49f3-bd55-dd67fb20768b', NULL);
INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('22ccea9a-048f-48ad-aec2-2f640185e84f', 'Racing Models', '3250be95-ae9f-49f3-bd55-dd67fb20768b', NULL);
INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('2fe8e7f7-2049-43e9-aa8a-6bde57245ac3', 'Motorcycle Models', '3250be95-ae9f-49f3-bd55-dd67fb20768b', NULL);
INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('11ff8de9-9875-47e1-a8cb-06e989ac5a48', 'Tech Displays', '3250be95-ae9f-49f3-bd55-dd67fb20768b', NULL);
INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('a2223496-48fa-4be0-881a-e6fc8608f2e6', 'Mousepads', '2fb4d3b0-99f6-42c6-b64b-7185c0715cab', NULL);
INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('9fdd3f6b-a23b-47b3-b053-cd3d479c1e34', 'Desk Mats', '2fb4d3b0-99f6-42c6-b64b-7185c0715cab', NULL);
INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('e4a258f6-5c25-48d5-98ec-e3fdcadbcd2a', 'Stickers', '2fb4d3b0-99f6-42c6-b64b-7185c0715cab', NULL);
INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('bf5102be-f273-48b1-afaa-26c5ce39b194', 'LED Light Accessories', '2fb4d3b0-99f6-42c6-b64b-7185c0715cab', NULL);
INSERT INTO public.categories (category_id, name, parent_category_id, path) VALUES ('8f32162a-fcdf-4c8b-bbe1-51bba5404235', 'Poster Prints', '2fb4d3b0-99f6-42c6-b64b-7185c0715cab', NULL);


--
-- Data for Name: conversation_members; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.conversation_members (id, conversation_id, user_id, role, joined_at) VALUES ('a57ea306-69c0-4b02-80ec-9e00c7580925', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'owner', '2025-07-12 10:07:39.494237');
INSERT INTO public.conversation_members (id, conversation_id, user_id, role, joined_at) VALUES ('27d39467-8ace-4114-8628-ae6d5cb23890', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', 'member', '2025-07-12 10:07:39.495476');


--
-- Data for Name: conversations; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.conversations (conversation_id, is_group, group_name, created_by, created_at) VALUES ('3264cc97-4592-444e-b6a6-90a5bd63fa94', false, NULL, 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', '2025-07-12 10:07:39.48989');


--
-- Data for Name: friend_requests; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('5d18393a-eb7f-40f0-9d59-2650951cba5a', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'bb8051bf-3d7c-47e1-a22f-f0d175c0e7d0', 'declined', '2025-07-05 17:49:31.137041', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('9a48ae59-b1c8-4672-882e-81dcba4482cd', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'bb8051bf-3d7c-47e1-a22f-f0d175c0e7d0', 'accepted', '2025-07-05 17:59:20.713342', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('aa83026e-c47e-485d-914f-69adcf98b598', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', 'accepted', '2025-06-16 03:35:05.76267', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('1ddeaad7-0cd1-4f5c-99e0-692a69eb8758', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', '68d3c52f-05e6-407e-ad0e-09c93dcc9c65', 'accepted', '2025-06-16 03:42:32.114838', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('8dd30513-2025-46dd-8aec-b0f7b7b20773', '68d3c52f-05e6-407e-ad0e-09c93dcc9c65', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', 'accepted', '2025-06-16 10:28:39.838473', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('97221380-1b34-4e6e-8c30-3349e0437a97', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'bb8051bf-3d7c-47e1-a22f-f0d175c0e7d0', 'declined', '2025-07-05 16:03:07.382171', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('e69e5467-f06a-415b-8cd4-5ea32fcb00a1', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'bb8051bf-3d7c-47e1-a22f-f0d175c0e7d0', 'declined', '2025-07-05 16:03:27.970558', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('be4e6b28-1d89-4008-9c43-abf0d7c14588', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'bb8051bf-3d7c-47e1-a22f-f0d175c0e7d0', 'declined', '2025-07-05 16:10:49.827418', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('0b0653c1-9001-49e3-9c63-b9184933308e', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'bb8051bf-3d7c-47e1-a22f-f0d175c0e7d0', 'declined', '2025-07-05 16:15:44.778499', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('163202ea-6923-4c72-b67a-175a9d782977', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'bb8051bf-3d7c-47e1-a22f-f0d175c0e7d0', 'declined', '2025-07-05 16:24:17.406257', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('e4c70745-710d-4062-bca5-68fea6b23ae4', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'bb8051bf-3d7c-47e1-a22f-f0d175c0e7d0', 'declined', '2025-07-05 17:00:19.004376', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('3e36bc22-3117-4739-a2e6-f905695ff74e', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'bb8051bf-3d7c-47e1-a22f-f0d175c0e7d0', 'declined', '2025-07-05 17:17:10.39616', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('b5331917-fe42-464c-bba7-1b35e1af67b9', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'bb8051bf-3d7c-47e1-a22f-f0d175c0e7d0', 'declined', '2025-07-05 17:17:51.907942', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('db90c01c-4b7b-484f-8a8e-7c8b7d501205', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'bb8051bf-3d7c-47e1-a22f-f0d175c0e7d0', 'declined', '2025-07-05 17:20:47.059799', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('a922fe4a-dd9a-4b71-b9bd-bce74c8eb31e', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'bb8051bf-3d7c-47e1-a22f-f0d175c0e7d0', 'declined', '2025-07-05 17:23:16.923244', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('19234e28-c043-43af-8e57-2f2a49cb6c04', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'bb8051bf-3d7c-47e1-a22f-f0d175c0e7d0', 'declined', '2025-07-05 17:23:23.957057', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('23bde083-36a0-43da-804f-78fa3be7faf7', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'bb8051bf-3d7c-47e1-a22f-f0d175c0e7d0', 'declined', '2025-07-05 17:23:28.389018', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('dbb2ee6c-f6d9-4b09-9c12-4c2ff5e09907', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'bb8051bf-3d7c-47e1-a22f-f0d175c0e7d0', 'declined', '2025-07-05 17:23:30.502354', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('9325f3ad-572d-4d6e-bfef-37a69ebd8ab2', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', '2cc01e8f-34c9-466d-8bdf-56daffc19d7a', 'accepted', '2025-07-05 17:25:35.096979', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('b211dacf-1ae6-4b52-a5cf-f29c4e70add9', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', '2cc01e8f-34c9-466d-8bdf-56daffc19d7a', 'accepted', '2025-07-05 17:29:37.637283', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('74953751-2d1a-4a34-8f91-7f3d081686e6', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', '2cc01e8f-34c9-466d-8bdf-56daffc19d7a', 'accepted', '2025-07-05 17:29:47.43047', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('75c61b20-8822-4716-9ff1-3d956b4414a8', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', '2cc01e8f-34c9-466d-8bdf-56daffc19d7a', 'accepted', '2025-07-05 17:31:23.528328', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('3d13ca0c-fc98-4b3c-9cb7-547a33ec0f4d', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', '2cc01e8f-34c9-466d-8bdf-56daffc19d7a', 'accepted', '2025-07-05 17:32:25.890688', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('3dfe2752-4311-4030-ac59-c4179715a847', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', '2cc01e8f-34c9-466d-8bdf-56daffc19d7a', 'accepted', '2025-07-05 17:35:17.66938', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('1645ab10-03e0-4f5c-a724-228d77274f34', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', '2cc01e8f-34c9-466d-8bdf-56daffc19d7a', 'accepted', '2025-07-05 17:36:36.728012', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('c6e138de-4501-475e-84e4-a977b21f5214', '2cc01e8f-34c9-466d-8bdf-56daffc19d7a', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'accepted', '2025-07-05 17:36:37.432365', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('828001dd-26ee-4d6c-9a5e-e863a788a429', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', '2cc01e8f-34c9-466d-8bdf-56daffc19d7a', 'accepted', '2025-07-05 17:39:40.427871', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('8e3fd286-8ead-4a40-ab85-6ccaaf0fbc3e', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', '2cc01e8f-34c9-466d-8bdf-56daffc19d7a', 'accepted', '2025-07-05 17:39:59.793158', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('c3d24b94-ac4b-4c67-b86c-271794164066', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', '2cc01e8f-34c9-466d-8bdf-56daffc19d7a', 'accepted', '2025-07-05 17:44:43.381159', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('746fb884-eb51-4ec2-905b-7000f0f8fb22', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', 'accepted', '2025-07-05 17:45:07.072958', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('a1153408-e825-4581-a650-118b94db49ed', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'bb8051bf-3d7c-47e1-a22f-f0d175c0e7d0', 'accepted', '2025-07-05 17:46:17.834329', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('d5545fc3-25b7-4de0-870d-98952241dbe5', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'bb8051bf-3d7c-47e1-a22f-f0d175c0e7d0', 'declined', '2025-07-05 17:49:14.400042', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('d2cb4d21-79c3-43b7-80c5-979aa4b4baed', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'bb8051bf-3d7c-47e1-a22f-f0d175c0e7d0', 'declined', '2025-07-05 17:59:53.134707', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('d0088ec3-4e6a-4c5d-b2fd-5e206dcdea10', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'bb8051bf-3d7c-47e1-a22f-f0d175c0e7d0', 'accepted', '2025-07-05 18:01:32.682975', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('2be82c05-157f-4d6d-9320-fa8013e3ebe0', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'accepted', '2025-07-06 22:17:32.383088', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('0729b4fb-46c5-4214-ad2e-e171cc490faf', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', 'declined', '2025-07-12 10:06:33.629521', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('d4a1c9fa-8bfd-40ec-bf88-0b97118ad0d9', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', 'declined', '2025-07-12 10:06:41.889313', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('83682c33-f4a9-4f5e-8111-c99e07a59204', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', 'accepted', '2025-07-12 10:07:04.868833', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('9d524b30-1373-43f0-b987-fa7ad4dac520', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'declined', '2025-07-12 10:18:23.193517', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('489b1fd3-1f43-450e-8204-e568fe023b75', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'declined', '2025-07-12 10:18:37.823709', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('a51edc5c-ddb4-40ad-8991-ef7eb413ef51', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'accepted', '2025-07-12 10:19:14.35528', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('04da70dc-c9e7-4e07-9715-5f6e08e417dc', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', 'declined', '2025-07-13 23:34:53.506907', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('49c9b35b-ed54-47ac-a4cd-469be27ba0eb', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'declined', '2025-07-13 23:40:46.592289', NULL);
INSERT INTO public.friend_requests (request_id, sender_id, receiver_id, status, sent_at, responded_at) VALUES ('e16f4e1a-18df-4bbd-93e4-3f84b29cf305', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'accepted', '2025-07-14 00:23:17.506552', NULL);


--
-- Data for Name: friends; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.friends (friendship_id, user_id, friend_id, became_friends_at, is_blocked, is_removed, unread_count, pinned, last_message_time) VALUES ('14b42d14-89fd-4b05-a767-82f4bfccd529', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', '2025-07-14 00:23:19.69932', false, false, 0, false, '2025-07-14 01:39:55.40491');
INSERT INTO public.friends (friendship_id, user_id, friend_id, became_friends_at, is_blocked, is_removed, unread_count, pinned, last_message_time) VALUES ('2539fdf6-6d98-49a3-8852-fffcff6f3924', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', '2025-07-14 00:23:19.69932', false, false, 0, false, '2025-07-14 01:39:55.40542');


--
-- Data for Name: inventory; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: message_reactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.message_reactions (reaction_id, message_id, user_id, reaction, reacted_at) VALUES ('dcfab977-ec3d-449f-b00c-46953fc315e3', 'c54b8567-55a9-4390-afe9-d62ae7ac20ce', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', '❤️', '2025-07-14 00:49:48.252235');


--
-- Data for Name: message_requests; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('00c8fffe-5df5-438e-a2a4-79e0d7154f22', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'zdr kopr bepce', false, '2025-07-12 10:07:45.400854', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('4014173a-ff36-48bf-8b2e-41b1906fc528', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', 'zdr', false, '2025-07-12 10:07:55.322663', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('012c4970-67f4-437e-980d-9b4e3316920b', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', 'ko pr', false, '2025-07-12 10:08:00.758251', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('4047936e-909b-4f40-a188-6dfe246e63de', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'adwawd', false, '2025-07-12 10:08:54.8419', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('9e086960-acb3-4728-a028-f915a434ee91', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'dwadwaaw', false, '2025-07-12 10:09:06.605407', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('2a2e866e-edaa-4649-8b17-d589e8bbfe8a', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'd', false, '2025-07-12 10:09:06.747727', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('4d1191b2-646f-441e-bdfd-ba664c716711', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'aw', false, '2025-07-12 10:09:06.889648', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('3196af72-1a7b-447e-b9ff-bc56effc6f37', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'd', false, '2025-07-12 10:09:07.031674', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('3df87543-04a3-4e9a-8c95-4ab960567507', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'aw', false, '2025-07-12 10:09:07.165985', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('2fb32bc9-b0d9-416c-9fce-936fefcc3a21', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'daw', false, '2025-07-12 10:09:07.307568', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('55e32049-083c-4e76-906f-91a236be0efa', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'd', false, '2025-07-12 10:09:07.428584', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('ae510431-4294-4f72-a9f8-55eea9e6a9fe', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'aw', false, '2025-07-12 10:09:07.548469', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('8ee88ccb-ac06-46d7-8630-f66382ae5969', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'd', false, '2025-07-12 10:09:07.67172', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('da3acffc-8cc1-48d4-9383-ffb8254cbb02', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'aw', false, '2025-07-12 10:09:07.870338', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('a5880962-ac29-4b9c-b9bf-b826d4d2ebb8', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'aw', false, '2025-07-12 10:09:08.110228', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('56462a7c-a9fc-4a77-833d-ba381f97322f', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'aw', false, '2025-07-12 10:09:08.3299', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('3cdd2163-f859-4e36-bc8f-a7a8c02c4ba9', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'd', false, '2025-07-12 10:09:08.439469', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('093284c6-c8c4-4e1f-b3f4-915301c4d789', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'aw', false, '2025-07-12 10:09:08.552262', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('97e41cd3-b251-4e06-91d2-7262147ac21e', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'daw', false, '2025-07-12 10:09:08.747796', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('78166267-61b7-4696-8c8d-214c7c511c48', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'dwa', false, '2025-07-12 10:20:07.475348', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('c89e9f8f-9d96-4e81-83cd-f6aba73a6eb6', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'dwad', false, '2025-07-12 10:20:29.07477', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('5d98bc80-ccb8-40be-b281-cb972388b124', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'wad', false, '2025-07-12 10:20:29.275013', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('8587ace6-a13f-4398-bae9-16c34c658b3b', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'a', false, '2025-07-12 10:20:29.413141', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('f329fbfe-a0ac-4f99-8fef-a1d7b50b9f6b', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'd', false, '2025-07-12 10:20:29.541339', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('06806527-9afa-40fa-b53c-6d49aa31fa4f', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'wa', false, '2025-07-12 10:20:29.674859', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('2c7f9a3c-38f1-421c-b91a-5362d29e4e45', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'd', false, '2025-07-12 10:20:29.820801', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('f24eb873-866f-4fc5-bd0c-c56a5fbb7d64', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'dwa', false, '2025-07-12 10:22:39.812041', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('48c067d9-c1d8-4f0a-a10a-59b15b5e073a', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', 'dwa', false, '2025-07-12 10:22:47.021701', 'f24eb873-866f-4fc5-bd0c-c56a5fbb7d64', NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('fb5b986f-5239-4be3-9d5a-7ec82bd5dd3b', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', 'awd', false, '2025-07-12 10:22:47.894301', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('0776313d-52d9-44d6-9aa7-6f4810b5467c', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'eee', false, '2025-07-12 10:22:55.410368', '4014173a-ff36-48bf-8b2e-41b1906fc528', NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('891830e0-3586-426f-b77e-38ab37a9d169', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'dwa', false, '2025-07-12 10:23:06.7077', '4014173a-ff36-48bf-8b2e-41b1906fc528', NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('1121fd3b-b989-4143-98d3-a798701a977f', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', '👍', false, '2025-07-12 10:23:30.458979', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('c54b8567-55a9-4390-afe9-d62ae7ac20ce', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'eee', false, '2025-07-14 00:23:25.749497', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('5bab7861-34b7-4875-a369-dccbd9699383', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'ee', false, '2025-07-14 00:25:21.722173', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('45c59ce8-345e-47a0-a998-21787db6605e', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'dwa', false, '2025-07-14 00:28:29.247911', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('87e37533-a079-44e1-aaf3-c6517beb9ac8', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'dwadaw', false, '2025-07-14 00:29:09.426565', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('8517ee95-69e3-4bb6-b0d5-0cb4e869d8d2', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'dwa', false, '2025-07-14 00:30:35.377584', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('8b9503e7-5f1d-4fa3-bd14-640a6c752bad', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'dwa', false, '2025-07-14 00:30:47.144002', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('898d3ae4-45ed-4f4e-92f1-b817fc685ccc', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'dwa', false, '2025-07-14 00:36:35.901959', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('ffffd3c9-3539-4ebc-bc10-b6b7ab76690e', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'dwa', false, '2025-07-14 00:36:41.378501', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('67484e63-4eda-420c-be0a-a87c9f0d0423', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'dwa', false, '2025-07-14 00:39:49.601601', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('eb5480cd-1086-4818-b361-67b18334e187', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'awd', false, '2025-07-14 00:41:59.131193', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('a33abf13-2e0f-49fc-b540-e35237aa9040', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'awddd', false, '2025-07-14 00:42:23.912653', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('c5ffe285-6806-45cf-b9f8-4ccf5f95dcb3', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'dwa', false, '2025-07-14 00:44:36.430264', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('9eb3ebc0-fc70-4621-939d-4f1c8d0ec4d1', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'daw', false, '2025-07-14 00:44:46.646212', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('1d020b7e-e639-44c7-b964-2a5e6e3a1cab', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'dwa', false, '2025-07-14 00:45:48.347493', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('87eef13a-ed94-4441-8b00-dfee2b49d1a0', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', 'p;k;''ljp', false, '2025-07-14 00:49:55.156688', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('5fd4f0a1-332c-4b0a-a6c1-22dd16b0e1d5', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', 'maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba maika ti deeba ', false, '2025-07-14 00:50:11.756561', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('d6513634-0a89-47f7-bc3d-db55a71b2265', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', 'dwa', false, '2025-07-14 00:52:23.166615', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('ce00b5fe-5011-4941-b404-e663e3a7ec1b', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', 'aw', false, '2025-07-14 00:52:23.627293', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('bfb5900e-c7b5-479f-85a1-a60cedc0f2e6', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', 'daw', false, '2025-07-14 00:52:24.166606', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('7b4aaf88-3d50-44ae-bd4f-07352766738a', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', 'wad', false, '2025-07-14 00:52:24.571765', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('6fcffdd4-d46b-45d3-9e6b-975bafe78e0b', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', 'aw', false, '2025-07-14 00:52:24.752968', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('7a2ed32b-407c-49eb-b9f1-e605d6ac420e', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', 'd', false, '2025-07-14 00:52:24.86863', NULL, NULL);
INSERT INTO public.messages (message_id, conversation_id, sender_id, content, is_deleted, sent_at, reply_to_id, replied_to) VALUES ('eb5f0533-f2b6-4b1f-aaae-00b197536db9', '3264cc97-4592-444e-b6a6-90a5bd63fa94', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'daw', false, '2025-07-14 01:39:55.393208', NULL, NULL);


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.notifications (notification_id, user_id, type, content, is_read, created_at, link, data, additional_info) VALUES ('f5d4739d-6db2-401d-89a1-66993d3086c0', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', 'message', 'macmma322 sent you a message.', true, '2025-07-14 00:45:48.356255', '/chat/3264cc97-4592-444e-b6a6-90a5bd63fa94', '{}', 'Preview: dwa');
INSERT INTO public.notifications (notification_id, user_id, type, content, is_read, created_at, link, data, additional_info) VALUES ('bcbd7548-0600-4c9c-9d08-bb40fb63680a', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'reaction', 'testuser1 reacted to your message.', false, '2025-07-14 00:49:48.255115', '/chat/3264cc97-4592-444e-b6a6-90a5bd63fa94', '{}', NULL);
INSERT INTO public.notifications (notification_id, user_id, type, content, is_read, created_at, link, data, additional_info) VALUES ('25d7f52f-061b-4bb9-a022-4075788e999a', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'message', 'testuser1 sent you a message.', false, '2025-07-14 00:49:55.161128', '/chat/3264cc97-4592-444e-b6a6-90a5bd63fa94', '{}', 'Preview: p;k;''ljp');
INSERT INTO public.notifications (notification_id, user_id, type, content, is_read, created_at, link, data, additional_info) VALUES ('cb628519-d1a1-47e1-973d-9c38c4ac3cb5', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'message', 'testuser1 sent you a message.', false, '2025-07-14 00:52:23.183816', '/chat/3264cc97-4592-444e-b6a6-90a5bd63fa94', '{}', 'Preview: dwa');
INSERT INTO public.notifications (notification_id, user_id, type, content, is_read, created_at, link, data, additional_info) VALUES ('2ec8f41e-e2b2-4582-96dd-396171f6f484', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'message', 'testuser1 sent you a message.', false, '2025-07-14 00:52:23.632033', '/chat/3264cc97-4592-444e-b6a6-90a5bd63fa94', '{}', 'Preview: aw');
INSERT INTO public.notifications (notification_id, user_id, type, content, is_read, created_at, link, data, additional_info) VALUES ('7253b029-b9c9-4a64-a3bd-a9a004d09125', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'message', 'testuser1 sent you a message.', false, '2025-07-14 00:52:24.171249', '/chat/3264cc97-4592-444e-b6a6-90a5bd63fa94', '{}', 'Preview: daw');
INSERT INTO public.notifications (notification_id, user_id, type, content, is_read, created_at, link, data, additional_info) VALUES ('0a867c4b-361a-42ac-9407-b77935bf58b4', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'message', 'testuser1 sent you a message.', false, '2025-07-14 00:52:24.580668', '/chat/3264cc97-4592-444e-b6a6-90a5bd63fa94', '{}', 'Preview: wad');
INSERT INTO public.notifications (notification_id, user_id, type, content, is_read, created_at, link, data, additional_info) VALUES ('eb77e57c-e984-4ab4-a1a8-d8fbb514d334', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'message', 'testuser1 sent you a message.', false, '2025-07-14 00:52:24.757895', '/chat/3264cc97-4592-444e-b6a6-90a5bd63fa94', '{}', 'Preview: aw');
INSERT INTO public.notifications (notification_id, user_id, type, content, is_read, created_at, link, data, additional_info) VALUES ('b5538b5e-d865-475d-84ac-f92c477a93a5', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'message', 'testuser1 sent you a message.', false, '2025-07-14 00:52:24.873681', '/chat/3264cc97-4592-444e-b6a6-90a5bd63fa94', '{}', 'Preview: d');
INSERT INTO public.notifications (notification_id, user_id, type, content, is_read, created_at, link, data, additional_info) VALUES ('bd32e7ab-a5cd-43d7-bd64-413119839cb4', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', 'reaction', 'macmma322 reacted to your message.', true, '2025-07-14 00:48:05.618365', '/chat/3264cc97-4592-444e-b6a6-90a5bd63fa94', '{}', NULL);
INSERT INTO public.notifications (notification_id, user_id, type, content, is_read, created_at, link, data, additional_info) VALUES ('d7d5a3aa-3ffc-4f90-b6c2-ecb097b29bd0', 'df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'message', 'testuser1 sent you a message.', false, '2025-07-14 00:50:11.769474', '/chat/3264cc97-4592-444e-b6a6-90a5bd63fa94', '{}', 'Preview: maika ti deeba maika ti deeba maika ti d...');
INSERT INTO public.notifications (notification_id, user_id, type, content, is_read, created_at, link, data, additional_info) VALUES ('d8e3bb8d-af95-4d90-b81b-8b7571913e6f', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', 'message', 'macmma322 sent you a message.', false, '2025-07-14 01:39:55.407732', '/chat/3264cc97-4592-444e-b6a6-90a5bd63fa94', '{}', 'Preview: daw');


--
-- Data for Name: order_items; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: privacy_settings; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: product_images; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: product_variations; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.product_variations (variation_id, product_id, size, color, special_edition, stock_quantity, additional_price) VALUES ('af4a4c3d-f323-4611-9f33-82ad91eef6d0', '0f7075e1-f45c-4833-8bf1-1b50e0807a8c', 'M', 'Black', 'Standard', 10, 0.00);
INSERT INTO public.product_variations (variation_id, product_id, size, color, special_edition, stock_quantity, additional_price) VALUES ('62639294-3214-423a-a26f-84a00d1fe837', '0f7075e1-f45c-4833-8bf1-1b50e0807a8c', 'L', 'Black', 'Standard', 8, 0.00);
INSERT INTO public.product_variations (variation_id, product_id, size, color, special_edition, stock_quantity, additional_price) VALUES ('657c44d7-7151-4fe9-b7be-7d7e742ec043', '0f7075e1-f45c-4833-8bf1-1b50e0807a8c', 'M', 'White', 'Limited Edition', 5, 5.00);
INSERT INTO public.product_variations (variation_id, product_id, size, color, special_edition, stock_quantity, additional_price) VALUES ('ddebb8cb-04c2-4fbf-a396-a439bcb13d25', '0f7075e1-f45c-4833-8bf1-1b50e0807a8c', 'XL', 'Red', NULL, 6, 0.00);


--
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.products (product_id, brand_id, name, description, base_price, currency_code, is_exclusive, is_active, created_at, exclusive_to_niche) VALUES ('0f7075e1-f45c-4833-8bf1-1b50e0807a8c', '8b46a305-a36f-41d7-97c9-ad407cb4d62f', 'Uchiha Legacy Hoodie', 'Limited edition OtakuSquad hoodie inspired by the Uchiha clan.', 69.99, 'USD', true, true, '2025-04-26 17:39:31.501961', 'OtakuSquad');
INSERT INTO public.products (product_id, brand_id, name, description, base_price, currency_code, is_exclusive, is_active, created_at, exclusive_to_niche) VALUES ('c220b745-d0bd-4df6-b5e5-3131a11d694a', NULL, 'Test Hoodie 4', 'A stylish Zone 25-14 hoodie for testers.', 49.99, NULL, false, true, '2025-04-27 20:58:07.547624', NULL);
INSERT INTO public.products (product_id, brand_id, name, description, base_price, currency_code, is_exclusive, is_active, created_at, exclusive_to_niche) VALUES ('f76d1477-d65d-4125-a2ba-43261fac0660', '8b46a305-a36f-41d7-97c9-ad407cb4d62f', 'Updated Hoodie Name', 'Limited edition OtakuSquad hoodie inspired by the Uchiha clan.', 44.99, 'USD', true, false, '2025-04-26 18:22:53.518292', 'OtakuSquad');


--
-- Data for Name: shopping_cart; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: subscription_plans; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.subscription_plans (plan_id, niche_code, tier_type, price, discount_percentage, points_multiplier) VALUES ('35077137-e107-48de-9b7d-c4c1db5f2fcc', 'OtakuSquad', 'monthly', 9.99, 5.00, 1.50);
INSERT INTO public.subscription_plans (plan_id, niche_code, tier_type, price, discount_percentage, points_multiplier) VALUES ('cb63f343-7da4-4b92-87b4-a55809666ce4', 'OtakuSquad', 'quarterly', 24.99, 8.00, 1.50);
INSERT INTO public.subscription_plans (plan_id, niche_code, tier_type, price, discount_percentage, points_multiplier) VALUES ('f7f478fe-2cff-466f-bfdf-aad9a4d9a3a3', 'OtakuSquad', 'half-yearly', 44.99, 10.00, 1.50);
INSERT INTO public.subscription_plans (plan_id, niche_code, tier_type, price, discount_percentage, points_multiplier) VALUES ('79e64523-a339-4438-9508-662bc6696779', 'OtakuSquad', 'yearly', 79.99, 15.00, 1.50);
INSERT INTO public.subscription_plans (plan_id, niche_code, tier_type, price, discount_percentage, points_multiplier) VALUES ('5e78c6d6-cf4e-4a86-a5c1-5d4dcc6dc6c6', 'StoikrClub', 'monthly', 9.99, 5.00, 1.50);
INSERT INTO public.subscription_plans (plan_id, niche_code, tier_type, price, discount_percentage, points_multiplier) VALUES ('86c58ed5-a1d3-4c4a-807d-17a6d83c8dd7', 'StoikrClub', 'quarterly', 24.99, 8.00, 1.50);
INSERT INTO public.subscription_plans (plan_id, niche_code, tier_type, price, discount_percentage, points_multiplier) VALUES ('f36acd51-edba-4a52-82fe-863a55f9d92d', 'StoikrClub', 'half-yearly', 44.99, 10.00, 1.50);
INSERT INTO public.subscription_plans (plan_id, niche_code, tier_type, price, discount_percentage, points_multiplier) VALUES ('5919ce04-f8b2-479b-b948-bcc071374497', 'StoikrClub', 'yearly', 79.99, 15.00, 1.50);


--
-- Data for Name: user_points; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: user_preferences; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: user_roles_levels; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.user_roles_levels (role_level_id, role_name, required_points, discount_percentage, is_staff, permissions) VALUES ('c8dc2469-8556-4892-83b0-49acb5cb6e41', 'Supporter', 500, 5.00, false, '{}');
INSERT INTO public.user_roles_levels (role_level_id, role_name, required_points, discount_percentage, is_staff, permissions) VALUES ('d6dfaf48-f1b0-47fc-a369-afac2082e50c', 'Elite Member', 1500, 10.00, false, '{}');
INSERT INTO public.user_roles_levels (role_level_id, role_name, required_points, discount_percentage, is_staff, permissions) VALUES ('961e072b-6f5f-4716-a2a6-1ed9c7e0e050', 'Legend', 3000, 15.00, false, '{}');
INSERT INTO public.user_roles_levels (role_level_id, role_name, required_points, discount_percentage, is_staff, permissions) VALUES ('853430cf-6dd8-4d34-b06d-b66ea19b7e3a', 'Ultimate', 5000, 20.00, false, '{}');
INSERT INTO public.user_roles_levels (role_level_id, role_name, required_points, discount_percentage, is_staff, permissions) VALUES ('245837b5-358c-4ea6-8e6c-99af3f0bc673', 'Moderator', 0, 25.00, true, '{"manage_posts": true, "can_ban_users": true}');
INSERT INTO public.user_roles_levels (role_level_id, role_name, required_points, discount_percentage, is_staff, permissions) VALUES ('ea5ff4b8-d53a-4d62-8e4e-13ccc73a15b1', 'Store Chief', 0, 30.00, true, '{"manage_orders": true, "manage_inventory": true}');
INSERT INTO public.user_roles_levels (role_level_id, role_name, required_points, discount_percentage, is_staff, permissions) VALUES ('de245885-edf6-4e7d-b07e-3b8aacdf2881', 'Hype Lead', 0, 30.00, true, '{"create_events": true}');
INSERT INTO public.user_roles_levels (role_level_id, role_name, required_points, discount_percentage, is_staff, permissions) VALUES ('4534204b-03e7-4b8c-bfe2-3462b0e3ebc7', 'Founder', 0, 30.00, true, '{"full_access": true}');
INSERT INTO public.user_roles_levels (role_level_id, role_name, required_points, discount_percentage, is_staff, permissions) VALUES ('0b0f1d49-2607-476e-877c-d48568679637', 'Explorer', 0, 0.00, false, '{}');


--
-- Data for Name: user_subscriptions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.user_subscriptions (id, user_id, niche_code, tier_type, start_date, end_date, is_active, created_at) VALUES ('c16b6f5f-5676-4824-aabb-dd675035cf05', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', 'OtakuSquad', 'monthly', '2025-05-29 19:32:40.802', '2025-06-29 19:32:40.802', true, '2025-05-29 19:32:40.804045');
INSERT INTO public.user_subscriptions (id, user_id, niche_code, tier_type, start_date, end_date, is_active, created_at) VALUES ('48853baa-e937-4af2-96e2-67d7c52ed4bb', 'e2487b17-b576-4793-b0e3-6ede06d17a8f', 'StoikrClub', 'quarterly', '2025-05-29 19:32:40.806', '2025-08-29 19:32:40.806', true, '2025-05-29 19:32:40.807048');
INSERT INTO public.user_subscriptions (id, user_id, niche_code, tier_type, start_date, end_date, is_active, created_at) VALUES ('6c025d00-c43c-4c66-b559-2d89408cf971', NULL, 'OtakuSquad', 'monthly', '2025-07-05 18:15:03.438', '2025-08-05 18:15:03.438', true, '2025-07-05 18:15:03.439419');
INSERT INTO public.user_subscriptions (id, user_id, niche_code, tier_type, start_date, end_date, is_active, created_at) VALUES ('54122b44-20d3-4df3-8219-e29966a8f379', NULL, 'StoikrClub', 'quarterly', '2025-07-05 18:15:03.441', '2025-10-05 18:15:03.441', true, '2025-07-05 18:15:03.441612');
INSERT INTO public.user_subscriptions (id, user_id, niche_code, tier_type, start_date, end_date, is_active, created_at) VALUES ('65b4e430-99e8-4334-bb52-da282f75f8b2', NULL, 'OtakuSquad', 'monthly', '2025-07-05 19:42:29.303', '2025-08-05 19:42:29.303', true, '2025-07-05 19:42:29.304512');
INSERT INTO public.user_subscriptions (id, user_id, niche_code, tier_type, start_date, end_date, is_active, created_at) VALUES ('94c6a07f-8ed0-4aa1-b806-78acbab3311e', NULL, 'StoikrClub', 'quarterly', '2025-07-05 19:42:29.31', '2025-10-05 19:42:29.31', true, '2025-07-05 19:42:29.311321');


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.users (user_id, username, password, email, phone, first_name, last_name, biography, profile_picture, role_level_id, store_credit, created_at, points, birthday, birthday_reward_year) VALUES ('df292a8d-2b9e-4c23-ba19-3e0a25f6e8c8', 'macmma322', '$2b$12$ahCD2Hjzit4hPvdB9.trbu3whSFpqn2tNh.oyB2OVZq/dxsrFi8Ke', '\xc30d040703021ee467f043cd8f8360d24a016645e2e5fa6be41597ef763fd6e625140c83d9c19a788ab3698f7a040a81c3c7087edbd5b2142d7fdddc28efd75f1b7e2fcdd8a8f89965591dcb950bd0bed92b752375c399f50c9868', NULL, 'Nikolay', 'Georgiev', 'None <3', NULL, '4534204b-03e7-4b8c-bfe2-3462b0e3ebc7', 0.00, '2025-05-01 19:07:46.565766', 0, NULL, 0);
INSERT INTO public.users (user_id, username, password, email, phone, first_name, last_name, biography, profile_picture, role_level_id, store_credit, created_at, points, birthday, birthday_reward_year) VALUES ('bb8051bf-3d7c-47e1-a22f-f0d175c0e7d0', 'firstuser', '$2b$12$opnRI74fHUkITqGY0s4dAedXucUzZZUeGNlWtLf0biYyJKnVouAAK', '\xc30d040703021c554c7bd5bc44f77ad24601542a3ed289185d3e16c96c524ff06be0bd32f79cf6f6dd4af9e628a1ca8115dc49d30a807426ce67bc37d6319c15d2b2b5a207673c788ebe7c5b9f1e419bb8beb39d1cc01f', '\xc30d04070302fb4df3309b8b633067d23a01d15005db5129fde4fd26625666d6ecc991a3acbfb912566d8033c421ee48c8b1d3c8bfd4fad66ec2ea7be8f6f30aee591143b7eaf5fdfcd137', 'First', 'User', NULL, NULL, '0b0f1d49-2607-476e-877c-d48568679637', 0.00, '2025-05-01 20:10:09.112107', 358, NULL, 0);
INSERT INTO public.users (user_id, username, password, email, phone, first_name, last_name, biography, profile_picture, role_level_id, store_credit, created_at, points, birthday, birthday_reward_year) VALUES ('e2487b17-b576-4793-b0e3-6ede06d17a8f', 'testuser1', '$2b$12$owiT8l3W005ddPn2GNelcekFg7HM041BgokDRcJkR7WjgJfV7T8yy', '\xc30d04070302df836a688e26befd6dd247012c356e36c03e9256ac33249a3e8a7c43702f5170021be97940c323119a69b95b43d8c833e2aa866c7dffe1817c00b3585321741bf918e325eadac7f81645ec2eb91b0059ff5d', NULL, NULL, NULL, NULL, NULL, '0b0f1d49-2607-476e-877c-d48568679637', 0.00, '2025-05-01 20:00:24.818317', 358, NULL, 0);
INSERT INTO public.users (user_id, username, password, email, phone, first_name, last_name, biography, profile_picture, role_level_id, store_credit, created_at, points, birthday, birthday_reward_year) VALUES ('68d3c52f-05e6-407e-ad0e-09c93dcc9c65', 'testuser2', '$2b$12$iJv2FHmbuWRoLxNIRgTjnuo52Hxz7y/2kCNq5leIwTSmGwtVWHjAm', '\xc30d04070302985e0fffdf6c919076d24401cd359fa109984086c6e1ce3e666e193050243018ad24e9059db6965d5db1d96f46de9c9e3cae838a748564563b10780a48923c0349e95177502459f05988e118f03475', NULL, NULL, NULL, NULL, NULL, '0b0f1d49-2607-476e-877c-d48568679637', 0.00, '2025-06-13 18:22:05.494349', 0, NULL, 0);
INSERT INTO public.users (user_id, username, password, email, phone, first_name, last_name, biography, profile_picture, role_level_id, store_credit, created_at, points, birthday, birthday_reward_year) VALUES ('2cc01e8f-34c9-466d-8bdf-56daffc19d7a', 'seconduser', '$2b$12$ua.QEyQZh3PZU/Gtd2yCYuFUY2xUlZvTj3XJ.6DZnOb53PhZgIxlO', '\xc30d04070302bd946b6453d9de7462d24701d066d9583e2a93b0e37d25fd25f27e0e58dd07d49081267c2c75af17a8c896629526b69e7f21a06e03e3b0b53c11ec60355fd3b2d7b941172d4089a6928ded0c445cbe2fa96e', '\xc30d04070302ce86a6e30678f04e64d23a014aafbd8b75de1dfbe2762725a289682b81e36c52e7bbad1ecb7de0a2c7e2f17f24ac9233a1330201e8d5db113d215d0dbcc8fc513eb7a12243', 'Second', 'User', NULL, NULL, '0b0f1d49-2607-476e-877c-d48568679637', 0.00, '2025-07-05 17:24:57.246077', 0, NULL, 0);


--
-- Data for Name: wishlist; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: brands brands_brand_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.brands
    ADD CONSTRAINT brands_brand_name_key UNIQUE (brand_name);


--
-- Name: brands brands_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.brands
    ADD CONSTRAINT brands_pkey PRIMARY KEY (brand_id);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (category_id);


--
-- Name: conversation_members conversation_members_conversation_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conversation_members
    ADD CONSTRAINT conversation_members_conversation_id_user_id_key UNIQUE (conversation_id, user_id);


--
-- Name: conversation_members conversation_members_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conversation_members
    ADD CONSTRAINT conversation_members_pkey PRIMARY KEY (id);


--
-- Name: conversations conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_pkey PRIMARY KEY (conversation_id);


--
-- Name: friend_requests friend_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.friend_requests
    ADD CONSTRAINT friend_requests_pkey PRIMARY KEY (request_id);


--
-- Name: friends friends_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.friends
    ADD CONSTRAINT friends_pkey PRIMARY KEY (friendship_id);


--
-- Name: friends friends_user_id_friend_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.friends
    ADD CONSTRAINT friends_user_id_friend_id_key UNIQUE (user_id, friend_id);


--
-- Name: inventory inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_pkey PRIMARY KEY (inventory_id);


--
-- Name: message_reactions message_reactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.message_reactions
    ADD CONSTRAINT message_reactions_pkey PRIMARY KEY (reaction_id);


--
-- Name: message_requests message_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.message_requests
    ADD CONSTRAINT message_requests_pkey PRIMARY KEY (request_id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (message_id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (notification_id);


--
-- Name: order_items order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_pkey PRIMARY KEY (item_id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (order_id);


--
-- Name: privacy_settings privacy_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.privacy_settings
    ADD CONSTRAINT privacy_settings_pkey PRIMARY KEY (user_id);


--
-- Name: product_images product_images_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_images
    ADD CONSTRAINT product_images_pkey PRIMARY KEY (image_id);


--
-- Name: product_variations product_variations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_variations
    ADD CONSTRAINT product_variations_pkey PRIMARY KEY (variation_id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (product_id);


--
-- Name: shopping_cart shopping_cart_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shopping_cart
    ADD CONSTRAINT shopping_cart_pkey PRIMARY KEY (id);


--
-- Name: subscription_plans subscription_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscription_plans
    ADD CONSTRAINT subscription_plans_pkey PRIMARY KEY (plan_id);


--
-- Name: shopping_cart unique_cart_item; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shopping_cart
    ADD CONSTRAINT unique_cart_item UNIQUE (user_id, product_variation_id);


--
-- Name: user_points user_points_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_points
    ADD CONSTRAINT user_points_pkey PRIMARY KEY (id);


--
-- Name: user_preferences user_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_preferences
    ADD CONSTRAINT user_preferences_pkey PRIMARY KEY (user_id);


--
-- Name: user_roles_levels user_roles_levels_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles_levels
    ADD CONSTRAINT user_roles_levels_pkey PRIMARY KEY (role_level_id);


--
-- Name: user_roles_levels user_roles_levels_role_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles_levels
    ADD CONSTRAINT user_roles_levels_role_name_key UNIQUE (role_name);


--
-- Name: user_subscriptions user_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_subscriptions
    ADD CONSTRAINT user_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: wishlist wishlist_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wishlist
    ADD CONSTRAINT wishlist_pkey PRIMARY KEY (id);


--
-- Name: idx_convo_members; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_convo_members ON public.conversation_members USING btree (conversation_id);


--
-- Name: idx_friends_friend; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_friends_friend ON public.friends USING btree (friend_id);


--
-- Name: idx_friends_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_friends_user ON public.friends USING btree (user_id);


--
-- Name: idx_messages_convo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_messages_convo ON public.messages USING btree (conversation_id);


--
-- Name: idx_requests_receiver; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_requests_receiver ON public.friend_requests USING btree (receiver_id);


--
-- Name: idx_requests_sender; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_requests_sender ON public.friend_requests USING btree (sender_id);


--
-- Name: one_reaction_per_user_per_emoji; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX one_reaction_per_user_per_emoji ON public.message_reactions USING btree (message_id, user_id, reaction);


--
-- Name: users encrypt_user_data; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER encrypt_user_data BEFORE INSERT OR UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.encrypt_sensitive_data();


--
-- Name: friend_requests trigger_check_duplicate_friend_requests; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_check_duplicate_friend_requests BEFORE INSERT ON public.friend_requests FOR EACH ROW EXECUTE FUNCTION public.prevent_duplicate_friend_requests();


--
-- Name: categories categories_parent_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_parent_category_id_fkey FOREIGN KEY (parent_category_id) REFERENCES public.categories(category_id);


--
-- Name: conversation_members conversation_members_conversation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conversation_members
    ADD CONSTRAINT conversation_members_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(conversation_id) ON DELETE CASCADE;


--
-- Name: conversation_members conversation_members_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conversation_members
    ADD CONSTRAINT conversation_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: conversations conversations_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id) ON DELETE SET NULL;


--
-- Name: friend_requests friend_requests_receiver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.friend_requests
    ADD CONSTRAINT friend_requests_receiver_id_fkey FOREIGN KEY (receiver_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: friend_requests friend_requests_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.friend_requests
    ADD CONSTRAINT friend_requests_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: friends friends_friend_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.friends
    ADD CONSTRAINT friends_friend_id_fkey FOREIGN KEY (friend_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: friends friends_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.friends
    ADD CONSTRAINT friends_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: inventory inventory_product_variation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_product_variation_id_fkey FOREIGN KEY (product_variation_id) REFERENCES public.product_variations(variation_id) ON DELETE CASCADE;


--
-- Name: message_reactions message_reactions_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.message_reactions
    ADD CONSTRAINT message_reactions_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(message_id) ON DELETE CASCADE;


--
-- Name: message_reactions message_reactions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.message_reactions
    ADD CONSTRAINT message_reactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: message_requests message_requests_receiver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.message_requests
    ADD CONSTRAINT message_requests_receiver_id_fkey FOREIGN KEY (receiver_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: message_requests message_requests_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.message_requests
    ADD CONSTRAINT message_requests_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: messages messages_conversation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(conversation_id) ON DELETE CASCADE;


--
-- Name: messages messages_replied_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_replied_to_fkey FOREIGN KEY (replied_to) REFERENCES public.messages(message_id) ON DELETE SET NULL;


--
-- Name: messages messages_reply_to_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_reply_to_id_fkey FOREIGN KEY (reply_to_id) REFERENCES public.messages(message_id) ON DELETE CASCADE;


--
-- Name: messages messages_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: order_items order_items_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(order_id) ON DELETE CASCADE;


--
-- Name: order_items order_items_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id) ON DELETE SET NULL;


--
-- Name: order_items order_items_variation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_variation_id_fkey FOREIGN KEY (variation_id) REFERENCES public.product_variations(variation_id) ON DELETE SET NULL;


--
-- Name: orders orders_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: privacy_settings privacy_settings_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.privacy_settings
    ADD CONSTRAINT privacy_settings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: product_images product_images_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_images
    ADD CONSTRAINT product_images_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id) ON DELETE CASCADE;


--
-- Name: product_variations product_variations_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_variations
    ADD CONSTRAINT product_variations_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id) ON DELETE CASCADE;


--
-- Name: products products_brand_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_brand_id_fkey FOREIGN KEY (brand_id) REFERENCES public.brands(brand_id) ON DELETE SET NULL;


--
-- Name: shopping_cart shopping_cart_product_variation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shopping_cart
    ADD CONSTRAINT shopping_cart_product_variation_id_fkey FOREIGN KEY (product_variation_id) REFERENCES public.product_variations(variation_id) ON DELETE CASCADE;


--
-- Name: shopping_cart shopping_cart_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shopping_cart
    ADD CONSTRAINT shopping_cart_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: user_points user_points_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_points
    ADD CONSTRAINT user_points_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: user_preferences user_preferences_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_preferences
    ADD CONSTRAINT user_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: user_subscriptions user_subscriptions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_subscriptions
    ADD CONSTRAINT user_subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: users users_role_level_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_role_level_id_fkey FOREIGN KEY (role_level_id) REFERENCES public.user_roles_levels(role_level_id);


--
-- Name: wishlist wishlist_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wishlist
    ADD CONSTRAINT wishlist_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id) ON DELETE CASCADE;


--
-- Name: wishlist wishlist_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wishlist
    ADD CONSTRAINT wishlist_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

