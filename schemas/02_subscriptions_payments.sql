-- 02 Subscriptions & Payments — Zone 25-14 Schema
CREATE TABLE
    public.subscription_plans (
        plan_id uuid DEFAULT uuid_generate_v4 () NOT NULL,
        niche_code varchar(50) NULL,
        tier_type varchar(20) NULL,
        price numeric(10, 2) NULL,
        discount_percentage numeric(5, 2) NULL,
        points_multiplier numeric(3, 2) NULL,
        CONSTRAINT subscription_plans_pkey PRIMARY KEY (plan_id)
    );

CREATE TABLE
    public.user_subscriptions (
        id uuid DEFAULT uuid_generate_v4 () NOT NULL,
        user_id uuid NULL,
        niche_code varchar(50) NULL,
        tier_type varchar(20) NULL,
        start_date timestamp DEFAULT CURRENT_TIMESTAMP NULL,
        end_date timestamp NULL,
        is_active bool DEFAULT true NULL,
        created_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
        CONSTRAINT user_subscriptions_pkey PRIMARY KEY (id),
        CONSTRAINT user_subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users (user_id) ON DELETE CASCADE
    );