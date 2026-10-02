-- VoiceTrace seed data
-- Run this on a freshly created schema (schema.sql already applied).
-- To reload clean: TRUNCATE lots, lot_events, requests, product_synonyms,
-- producers, products, users RESTART IDENTITY CASCADE; then re-run this file.

-- USERS & PRODUCERS
INSERT INTO users (role, name, phone) VALUES
('producer', 'Amira Ben Salah', '21621111111'),
('producer', 'Fatma Trabelsi', '21621111112'),
('producer', 'Salma Gharbi', '21621111113'),
('producer', 'Hela Mansour', '21621111114'),
('producer', 'Rim Jlassi', '21621111115'),
('buyer', 'Karim Bouzid', '21622222221'),
('buyer', 'Youssef Chaabane', '21622222222');

INSERT INTO producers (name, phone, region, user_id) VALUES
('Amira Ben Salah', '21621111111', 'Sfax', 1),
('Fatma Trabelsi', '21621111112', 'Sousse', 2),
('Salma Gharbi', '21621111113', 'Kairouan', 3),
('Hela Mansour', '21621111114', 'Mahdia', 4),
('Rim Jlassi', '21621111115', 'Sfax', 5);

-- PRODUCTS
INSERT INTO products (canonical_name, category) VALUES
('olive_oil', 'oil'),
('dates', 'fruit'),
('almonds', 'nuts'),
('honey', 'bee_products'),
('couscous', 'grain'),
('harissa', 'condiment'),
('figs_dried', 'fruit'),
('tomato_paste', 'condiment'),
('wool_textile', 'textile'),
('argan_oil', 'oil'),
('pepper', 'vegetable'),
('potato', 'vegetable'),
('tomato', 'vegetable'),
('apple', 'fruit');

-- PRODUCT SYNONYMS (Derja / Arabic / French) — used by Person 1's NLU as fallback/validation
INSERT INTO product_synonyms (product_id, term, language) VALUES
((SELECT id FROM products WHERE canonical_name='olive_oil'), 'زيت زيتون', 'ar'),
((SELECT id FROM products WHERE canonical_name='olive_oil'), 'huile d''olive', 'fr'),
((SELECT id FROM products WHERE canonical_name='dates'), 'تمر', 'ar'),
((SELECT id FROM products WHERE canonical_name='dates'), 'dattes', 'fr'),
((SELECT id FROM products WHERE canonical_name='almonds'), 'لوز', 'ar'),
((SELECT id FROM products WHERE canonical_name='almonds'), 'amandes', 'fr'),
((SELECT id FROM products WHERE canonical_name='honey'), 'عسل', 'ar'),
((SELECT id FROM products WHERE canonical_name='honey'), 'miel', 'fr'),
((SELECT id FROM products WHERE canonical_name='couscous'), 'كسكسي', 'ar'),
((SELECT id FROM products WHERE canonical_name='harissa'), 'هريسة', 'ar'),
((SELECT id FROM products WHERE canonical_name='pepper'), 'فلفل', 'ar'),
((SELECT id FROM products WHERE canonical_name='pepper'), 'poivron', 'fr'),
((SELECT id FROM products WHERE canonical_name='potato'), 'بطاطا', 'ar'),
((SELECT id FROM products WHERE canonical_name='potato'), 'pomme de terre', 'fr'),
((SELECT id FROM products WHERE canonical_name='tomato'), 'طماطم', 'ar'),
((SELECT id FROM products WHERE canonical_name='tomato'), 'tomate', 'fr'),
((SELECT id FROM products WHERE canonical_name='apple'), 'تفاح', 'ar'),
((SELECT id FROM products WHERE canonical_name='apple'), 'pomme', 'fr');

-- LOTS (spread across Sfax, Sousse, Kairouan, Mahdia)
INSERT INTO lots (public_id, product_id, producer_id, quantity, unit, price, harvest_date, status, location) VALUES
('LOT-2026-SFX-001', (SELECT id FROM products WHERE canonical_name='olive_oil'), 1, 40, 'liter', 12, '2026-06-15', 'AVAILABLE', ST_SetSRID(ST_MakePoint(10.76, 34.74), 4326)::geography),
('LOT-2026-SFX-002', (SELECT id FROM products WHERE canonical_name='olive_oil'), 5, 25, 'liter', 13, '2026-06-20', 'AVAILABLE', ST_SetSRID(ST_MakePoint(10.80, 34.70), 4326)::geography),
('LOT-2026-SOU-003', (SELECT id FROM products WHERE canonical_name='dates'), 2, 60, 'kg', 8, '2026-08-01', 'AVAILABLE', ST_SetSRID(ST_MakePoint(10.64, 35.83), 4326)::geography),
('LOT-2026-KAI-004', (SELECT id FROM products WHERE canonical_name='almonds'), 3, 15, 'kg', 20, '2026-07-10', 'AVAILABLE', ST_SetSRID(ST_MakePoint(10.10, 35.68), 4326)::geography),
('LOT-2026-MAH-005', (SELECT id FROM products WHERE canonical_name='honey'), 4, 10, 'kg', 25, '2026-05-01', 'AVAILABLE', ST_SetSRID(ST_MakePoint(11.06, 35.50), 4326)::geography),
('LOT-2026-SFX-007', (SELECT id FROM products WHERE canonical_name='harissa'), 5, 20, 'kg', 7, '2026-06-05', 'SOLD', ST_SetSRID(ST_MakePoint(10.75, 34.73), 4326)::geography),
('LOT-2026-SFX-011', (SELECT id FROM products WHERE canonical_name='tomato'), 1, 50, 'kg', 2.5, '2026-09-01', 'AVAILABLE', ST_SetSRID(ST_MakePoint(10.76, 34.74), 4326)::geography),
('LOT-2026-SOU-012', (SELECT id FROM products WHERE canonical_name='pepper'), 2, 30, 'kg', 3, '2026-09-05', 'AVAILABLE', ST_SetSRID(ST_MakePoint(10.64, 35.83), 4326)::geography),
('LOT-2026-KAI-013', (SELECT id FROM products WHERE canonical_name='potato'), 3, 100, 'kg', 1.8, '2026-08-20', 'AVAILABLE', ST_SetSRID(ST_MakePoint(10.10, 35.68), 4326)::geography),
('LOT-2026-MAH-014', (SELECT id FROM products WHERE canonical_name='apple'), 4, 40, 'kg', 2.2, '2026-09-10', 'AVAILABLE', ST_SetSRID(ST_MakePoint(11.06, 35.50), 4326)::geography);

-- LOT EVENTS (traceability timeline for 2 lots — demo proof for the QR passport)
INSERT INTO lot_events (lot_id, event_type, previous_hash, event_hash)
SELECT id, 'CREATED', NULL, 'h001' FROM lots WHERE public_id='LOT-2026-SFX-001';
INSERT INTO lot_events (lot_id, event_type, previous_hash, event_hash)
SELECT id, 'HARVEST_DECLARED', 'h001', 'h002' FROM lots WHERE public_id='LOT-2026-SFX-001';
INSERT INTO lot_events (lot_id, event_type, previous_hash, event_hash)
SELECT id, 'LISTED', 'h002', 'h003' FROM lots WHERE public_id='LOT-2026-SFX-001';
INSERT INTO lot_events (lot_id, event_type, previous_hash, event_hash)
SELECT id, 'CREATED', NULL, 'h101' FROM lots WHERE public_id='LOT-2026-SFX-007';
INSERT INTO lot_events (lot_id, event_type, previous_hash, event_hash)
SELECT id, 'LISTED', 'h101', 'h102' FROM lots WHERE public_id='LOT-2026-SFX-007';
INSERT INTO lot_events (lot_id, event_type, previous_hash, event_hash)
SELECT id, 'SOLD', 'h102', 'h103' FROM lots WHERE public_id='LOT-2026-SFX-007';

-- BUYER LOCATIONS (set once, as if during signup — chatbot never asks for this)
UPDATE users SET location = ST_SetSRID(ST_MakePoint(10.76, 34.74), 4326) WHERE phone='21622222221';
UPDATE users SET location = ST_SetSRID(ST_MakePoint(10.64, 35.83), 4326) WHERE phone='21622222222';

-- SAMPLE BUYER REQUEST
INSERT INTO requests (buyer_id, product_id, quantity, unit, location)
SELECT id, (SELECT id FROM products WHERE canonical_name='olive_oil'), 50, 'liter', location
FROM users WHERE phone='21622222221';