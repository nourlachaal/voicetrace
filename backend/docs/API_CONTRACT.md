# VoiceTrace API Contract

## Auth
- POST /auth/register
- POST /auth/login
- GET  /auth/me

## Profile / location (platform UI only — never via voice, see DATABASE_SPEC §10b)
- PUT  /users/{id}/location     # body: {lat, lng} → SET_LOCATION in queries.sql

## Lots (NOTE: no `listings` table — a lot IS the listing + traceable batch)
- POST /lots                    # location NOT in body: copied from producer's users.location
                                # mirrors CREATE_LISTING in database/queries.sql
- GET  /lots/me                 # GET_MY_STOCK / GET_MY_SALES (?status=AVAILABLE|SOLD)
- GET  /lots/{id}
- PATCH /lots/{id}              # UPDATE_LISTING: {quantity?, status?}

## Search (PostGIS — location from buyer's users.location, never spoken)
- GET  /search?product=olive_oil&buyer_id=6
  Response (mirrors SEARCH_PRODUCTS in database/queries.sql):
  ```json
  {
    "product": "olive_oil",
    "count": 2,
    "results": [
      {"public_id": "LOT-2026-SFX-001", "canonical_name": "olive_oil",
       "quantity": 40, "unit": "liter", "price": 12.00, "distance_km": 0.00}
    ]
  }
  ```
  nearest-first, LIMIT 10, buyer location read automatically from users.location

## Voice
- POST /voice/turn

## Traceability
- GET  /lots/{public_id}/passport   # mirrors PASSPORT query; public fields only

## Assistant
- POST /assistant/ask

## Health
- GET  /health
