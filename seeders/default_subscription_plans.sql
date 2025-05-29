-- Default(Examples) Subscription Plans — Zone 25-14 Seeder
INSERT INTO
    public.subscription_plans (
        niche_code,
        tier_type,
        price,
        discount_percentage,
        points_multiplier
    )
VALUES
    ('anime', 'Basic', 4.99, 0, 1.0),
    ('anime', 'Plus', 9.99, 5, 1.2),
    ('anime', 'Elite', 19.99, 10, 1.5),
    ('gym', 'Basic', 4.99, 0, 1.0),
    ('cars', 'Plus', 9.99, 5, 1.2),
    ('luxury', 'Elite', 29.99, 15, 2.0) ON CONFLICT DO NOTHING;