-- Niche Seeder — Zone 25-14 Seeder
INSERT INTO
    public.categories (name, path)
VALUES
    ('OtakuSquad', 'anime'),
    ('ᛋᛏᛟᛁᚲ (StoikrClub)', 'gym'),
    ('WD Crew', 'cars'),
    ('PerOs Pack', 'motorcycles'),
    ('CritHit Team', 'gaming'),
    ('The Grid Opus', 'tech'),
    ('The Syndicate', 'luxury') ON CONFLICT DO NOTHING;