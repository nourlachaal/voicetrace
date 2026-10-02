# VoiceTrace — Database Specification

## 1. ERD
See `erd.png` in this folder (generated from DBeaver, reflects current schema).
Status: stable for Phase 1 — will only add columns, not remove, without notice.

## 2. Final Phase 1 tables
products, users, producers, lots, lot_events, product_synonyms, requests, voice_turns
(No separate `listings` table — a `lot` IS the offer + the traceable batch, combined.)

## 3. Columns per table

### products
| Column | Type | Null | Key | Default | Description |
|---|---|---|---|---|---|
| id | SERIAL | NO | PK | auto | Product ID |
| canonical_name | TEXT | NO | UNIQUE | — | e.g. olive_oil |
| category | TEXT | YES | — | — | e.g. oil, dates |

### users
| Column | Type | Null | Key | Default | Description |
|---|---|---|---|---|---|
| id | SERIAL | NO | PK | auto | User ID |
| role | TEXT | NO | — CHECK IN ('producer','buyer') | — | Account role |
| name | TEXT | NO | — | — | Full name |
| phone | TEXT | YES | — | — | Contact |
| created_at | TIMESTAMP | NO | — | now() | — |

### producers
| Column | Type | Null | Key | Default | Description |
|---|---|---|---|---|---|
| id | SERIAL | NO | PK | auto | Producer ID |
| user_id | INT | YES | FK → users.id | — | Linked account |
| name | TEXT | NO | — | — | Display name |
| phone | TEXT | YES | — | — | — |
| region | TEXT | YES | — | — | e.g. Sfax |

### lots
| Column | Type | Null | Key | Default | Description |
|---|---|---|---|---|---|
| id | SERIAL | NO | PK | auto | Internal ID |
| public_id | TEXT | NO | UNIQUE | — | e.g. LOT-2026-SFX-001, used in QR |
| product_id | INT | NO | FK → products.id | — | — |
| producer_id | INT | YES | FK → producers.id | — | — |
| quantity | NUMERIC | NO | — CHECK > 0 | — | — |
| unit | TEXT | NO | — | — | e.g. liter, kg |
| price | NUMERIC | NO | — CHECK >= 0 | 0 | Price for the lot |
| harvest_date | DATE | YES | — | — | — |
| status | TEXT | NO | — CHECK IN ('AVAILABLE','SOLD','EXPIRED') | 'AVAILABLE' | — |
| location | GEOGRAPHY(Point,4326) | NO | — | — | GPS point, see §5 |

### lot_events
| Column | Type | Null | Key | Default | Description |
|---|---|---|---|---|---|
| id | SERIAL | NO | PK | auto | — |
| lot_id | INT | NO | FK → lots.id | — | — |
| event_type | TEXT | NO | — | — | See §9 for allowed values |
| event_time | TIMESTAMP | NO | — | now() | — |
| previous_hash | TEXT | YES | — | — | Tamper-evidence chain |
| event_hash | TEXT | YES | — | — | Tamper-evidence chain |

### product_synonyms
| Column | Type | Null | Key | Default | Description |
|---|---|---|---|---|---|
| id | SERIAL | NO | PK | auto | — |
| product_id | INT | NO | FK → products.id | — | — |
| term | TEXT | NO | — | — | Derja/Arabic/French alias |
| language | TEXT | NO | — | — | e.g. 'ar', 'fr' |

### requests (buyer demand)
| Column | Type | Null | Key | Default | Description |
|---|---|---|---|---|---|
| id | SERIAL | NO | PK | auto | — |
| buyer_id | INT | NO | FK → users.id | — | — |
| product_id | INT | NO | FK → products.id | — | — |
| quantity | NUMERIC | NO | — CHECK > 0 | — | — |
| unit | TEXT | NO | — | — | — |
| location | GEOGRAPHY(Point,4326) | NO | — | — | — |
| created_at | TIMESTAMP | NO | — | now() | — |

### voice_turns
| Column | Type | Null | Key | Default | Description |
|---|---|---|---|---|---|
| id | SERIAL | NO | PK | auto | — |
| transcript | TEXT | YES | — | — | — |
| intent | TEXT | YES | — | — | — |
| confidence | NUMERIC | YES | — | — | — |
| latency_ms | INT | YES | — | — | — |
| created_at | TIMESTAMP | NO | — | now() | — |

## 4. Relationships
- users (1) → producers (1) — a producer optionally links to one user account
- producers (1) → lots (many)
- products (1) → lots (many)
- products (1) → product_synonyms (many)
- lots (1) → lot_events (many)
- users (1) → requests (many), as buyer
- products (1) → requests (many)

## 5. PostGIS setup
- Tables with location: `lots.location`, `requests.location`
- Type: `GEOGRAPHY(Point, 4326)` — final choice, confirmed
- SRID: 4326 (standard GPS)
- We use `geography`, not `geometry`, so distances return directly in meters
- No separate lat/lon columns — extract with `ST_Y(location::geometry)` (lat) / `ST_X(location::geometry)` (lon) when needed for the frontend map

## 6. Search requirements supported in Phase 1
- Search by product (join on `products.canonical_name` or `product_synonyms.term`)
- Search within radius: `ST_DWithin(location, point, radius_meters)`
- Nearest-first: `ORDER BY ST_Distance(location, point)`
- Filter by availability: `WHERE status = 'AVAILABLE'`
- Filter by price: plain `WHERE price BETWEEN x AND y` (no index needed at this scale)

## 7. Indexes
- `lots_location_gix` — GIST index on `lots.location` (spatial search)
- `lots_status_idx` — on `lots.status`
- `lots_product_id_idx` — on `lots.product_id`
- `lot_events_lot_id_idx` — on `lot_events.lot_id`
- `requests_product_id_idx` — on `requests.product_id`

## 8. Statuses / enums
- `lots.status`: `AVAILABLE`, `SOLD`, `EXPIRED`
- `users.role`: `producer`, `buyer`
- `lot_events.event_type` (see §9)

## 9. Lot & traceability structure
Flow: producer creates a **lot** directly (no separate listing step) → `lots.public_id` is the public code used in the QR → each state change appends a row to `lot_events`.

Public fields (shown on QR passport page): `public_id`, product name, `quantity`, `unit`, `harvest_date`, producer `region` (not exact address), event timeline (`event_type` + `event_time`).
Private fields (never public): `producer.phone`, `producer.user_id`, exact `location` coordinates, internal `id`.

Initial `event_type` values: `CREATED`, `HARVEST_DECLARED`, `LISTED`, `QUANTITY_UPDATED`, `SOLD`.

## 10. User / producer structure
- Not every producer requires a user account in Phase 1 (kept nullable for demo flexibility) — final decision pending team confirmation.
- `producers.user_id` is nullable, references `users.id`
- Auth info lives in `users` (role, name, phone)
- Producer profile info lives in `producers` (region, business name)
- Roles: `producer`, `buyer` (enforced via CHECK constraint on `users.role`)

## 11. Development connection info
- Host: localhost
- Port: 5432
- Database: voicetrace
- Username: voicetrace
- Schema: public
- PostgreSQL version: 16 (postgis/postgis:16-3.4 Docker image)
- Environment: local Docker (docker-compose.yml in repo root)
- Password: set locally in your own .env, ask me directly (not committed to repo)

## 12. Seed/test data
See `seed.sql` (coming next — not ready yet, will follow by [give a date]).

## 13. Migrations
Using plain SQL scripts (`schema.sql`) for Phase 1, not Alembic. Changes will be communicated directly; will re-export `schema.sql` after any structural change.

## 14. Status of this document
Stable for Week 1. Will flag any changes directly.