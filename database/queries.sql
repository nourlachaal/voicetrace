-- VoiceTrace reference queries
-- Matches Person 1's Intent enum (CREATE_LISTING, SEARCH_PRODUCTS, UPDATE_LISTING,
-- GET_MY_STOCK, GET_MY_SALES, CREATE_REQUEST, UNKNOWN) plus the QR passport query
-- and location management.
-- $1, $2, ... = parameters your FastAPI code fills in (psycopg/SQLAlchemy style).

-- =========================================================
-- CREATE_LISTING — producer creates a new lot
-- Location is pulled automatically from the producer's user profile,
-- never asked by voice.
-- $1 public_id, $2 product_id, $3 producer_id, $4 quantity,
-- $5 unit, $6 price, $7 harvest_date, $8 user_id (of the producer)
-- =========================================================
INSERT INTO lots (public_id, product_id, producer_id, quantity, unit, price, harvest_date, location)
SELECT $1, $2, $3, $4, $5, $6, $7, location FROM users WHERE id = $8;

-- =========================================================
-- SEARCH_PRODUCTS — nearest available lots for a product
-- Uses the logged-in buyer's saved location automatically.
-- $1 buyer's user_id, $2 product canonical_name
-- =========================================================
SELECT l.public_id, p.canonical_name, l.quantity, l.unit, l.price,
  ROUND((ST_Distance(l.location, u.location) / 1000)::numeric, 2) AS distance_km
FROM lots l
JOIN products p ON p.id = l.product_id
JOIN users u ON u.id = $1
WHERE p.canonical_name = $2 AND l.status = 'AVAILABLE'
ORDER BY distance_km
LIMIT 10;

-- =========================================================
-- UPDATE_LISTING — change quantity and/or status of an existing lot
-- $1 quantity, $2 status, $3 public_id
-- =========================================================
UPDATE lots
SET quantity = $1, status = $2
WHERE public_id = $3;

-- =========================================================
-- GET_MY_STOCK — producer's currently available lots
-- $1 producer_id
-- =========================================================
SELECT public_id, p.canonical_name, quantity, unit, price, status
FROM lots l
JOIN products p ON p.id = l.product_id
WHERE l.producer_id = $1 AND l.status = 'AVAILABLE';

-- =========================================================
-- GET_MY_SALES — producer's sold lots
-- $1 producer_id
-- =========================================================
SELECT public_id, p.canonical_name, quantity, unit, price, status
FROM lots l
JOIN products p ON p.id = l.product_id
WHERE l.producer_id = $1 AND l.status = 'SOLD';

-- =========================================================
-- CREATE_REQUEST — buyer posts demand for a product
-- Location auto-filled from the buyer's profile, not asked by voice.
-- $1 buyer's user_id, $2 product_id, $3 quantity, $4 unit
-- =========================================================
INSERT INTO requests (buyer_id, product_id, quantity, unit, location)
SELECT $1, $2, $3, $4, location FROM users WHERE id = $1;

-- =========================================================
-- SET_LOCATION — called once at signup, or whenever the user edits
-- their location from the platform UI. Never called from the voice flow.
-- $1 longitude, $2 latitude, $3 user_id
-- =========================================================
UPDATE users
SET location = ST_SetSRID(ST_MakePoint($1, $2), 4326)
WHERE id = $3;

-- =========================================================
-- PASSPORT — public QR traceability page
-- $1 lot public_id
-- Public fields only: public_id, product name, quantity, unit,
-- harvest_date, producer region, event timeline.
-- Never expose: producer phone, user_id, exact lot location, internal id.
-- =========================================================
SELECT l.public_id, p.canonical_name, l.quantity, l.unit, l.harvest_date,
       pr.region, le.event_type, le.event_time
FROM lots l
JOIN products p ON p.id = l.product_id
JOIN producers pr ON pr.id = l.producer_id
LEFT JOIN lot_events le ON le.lot_id = l.id
WHERE l.public_id = $1
ORDER BY le.event_time;

-- UNKNOWN intent: no database action.