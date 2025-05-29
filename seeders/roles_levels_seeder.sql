-- Roles Levels Seeder — Zone 25-14 Seeder
INSERT INTO
    public.user_roles_levels (
        role_name,
        required_points,
        discount_percentage,
        is_staff
    )
VALUES
    ('Explorer', 0, 0.00, false),
    ('Supporter', 200, 2.00, false),
    ('Elite Member', 500, 4.00, false),
    ('Legend', 1000, 6.00, false),
    ('Ultimate', 2000, 8.00, false),
    ('Moderator', 0, 30.00, true),
    ('Store Chief', 0, 30.00, true),
    ('Hype Lead', 0, 25.00, true),
    ('Founder', 0, 35.00, true) ON CONFLICT (role_name) DO NOTHING;