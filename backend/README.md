# VoiceTrace — Backend (Person 2)

FastAPI backend for VoiceTrace: a voice-first, traceable marketplace connecting
Tunisian women producers to nearby buyers.

This folder is the **backend slice**: API skeleton, configuration, SQLAlchemy
models mapped to the team's PostgreSQL + PostGIS schema, and automated tests.

---

## Stack

| Layer | Technology |
|---|---|
| API framework | FastAPI + Uvicorn |
| Validation | Pydantic v2 + pydantic-settings |
| ORM | SQLAlchemy 2.0 (typed `Mapped` models) |
| Spatial ORM | GeoAlchemy2 + Shapely |
| Database | PostgreSQL 16 + PostGIS 3.4 (Docker: `postgis/postgis:16-3.4`) |
| Driver | psycopg 3 |
| Tests | pytest + FastAPI TestClient |

The database schema, seed data and reference queries are owned by Nour and live
in the repo root [`database/`](../database/) folder — see `DATABASE_SPEC.md`,
`schema.sql`, `seed.sql`, `queries.sql`.

---

## Project structure

```
backend/
├── app/
│   ├── main.py              # FastAPI app, CORS, /health
│   ├── core/
│   │   ├── config.py        # .env → Settings (DATABASE_URL, SECRET_KEY)
│   │   └── database.py      # engine, SessionLocal, Base, get_db
│   ├── models/
│   │   └── models.py        # 8 tables: Product, User, Producer, Lot,
│   │                        # LotEvent, ProductSynonym, Request, VoiceTurn
│   ├── api/                 # routers (search, lots, voice — upcoming)
│   ├── schemas/             # Pydantic request/response models (upcoming)
│   └── services/            # business logic (upcoming)
├── database/                # LOCAL copy of ../database/ — git-ignored
├── docs/API_CONTRACT.md     # endpoint contract (planned + current)
├── tests/
│   ├── test_health.py       # /health smoke test
│   ├── test_models.py       # DB integration: read, spatial search, write
│   └── db_check.py          # manual PostGIS connectivity check
├── pytest.ini               # pythonpath = .
├── requirements.txt
└── .env.example             # copy to .env and fill in real values
```

---

## Getting started

### 1. Virtual environment + packages
```powershell
py -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### 2. Environment
```powershell
Copy-Item .env.example .env   # then edit real values
```
`DATABASE_URL=postgresql+psycopg://voicetrace:<password>@localhost:5433/voicetrace`

> The app's PostGIS container maps host port **5433** (5432 is taken by a local
> PostgreSQL install). `.env` is git-ignored — never commit real credentials.

### 3. Database (Docker)
```powershell
docker start voicetrace-db     # container: postgis/postgis:16-3.4, port 5433
```
Schema + seed are applied from the root [`database/`](../database/) folder
(`schema.sql`, then `seed.sql`).

### 4. Run
```powershell
uvicorn app.main:app --reload
```
- API: http://127.0.0.1:8000
- Health: http://127.0.0.1:8000/health
- Swagger: http://127.0.0.1:8000/docs

### 5. Tests
```powershell
pytest -v
```
Current suite: **4 passing**
- `/health` smoke test
- ORM reads seeded lots from PostgreSQL
- PostGIS nearest-first spatial search (olive oil near Sfax, distance in meters)
- Geography insert round-trip (WKT → `GEOGRAPHY(Point,4326)`) with rollback

---

## Design decisions

- **The schema is owned by SQL, not the ORM.** Models mirror `database/schema.sql`
  exactly; no `Base.metadata.create_all()` — tables are created only by Nour's
  scripts (plain SQL migrations, no Alembic for Phase 1).
- **Spatial columns** use `Geography("POINT", srid=4326, spatial_index=False)` —
  the GiST indexes (`lots_location_gix`, `users_location_gix`) are defined in
  `schema.sql`; distances therefore come back in **meters** directly.
- **Location handling** follows `DATABASE_SPEC.md §10b`: location is never part
  of the voice flow — `lots.location` / `requests.location` are copied from the
  account's saved `users.location` (see `database/queries.sql`).
- **No `listings` table** — a `lot` is both the offer and the traceable batch
  (`public_id` e.g. `LOT-2026-SFX-001` is the QR passport code).

---

## Current status

| Item | Status |
|---|---|
| App skeleton + `/health` | ✅ working |
| Config / DB engine / sessions | ✅ working |
| SQLAlchemy models (8 tables) | ✅ tested against live PostGIS |
| PostGIS integration | ✅ PostGIS 3.4 verified from Python |
| Seed data (7 users, 14 products, 10 lots, 6 events) | ✅ loaded |
| `GET /search` (nearest-first buyer search) | 🚧 next |
| `POST /lots`, voice endpoint, passport endpoint | 🚧 planned — see `docs/API_CONTRACT.md` |

See [`docs/API_CONTRACT.md`](docs/API_CONTRACT.md) for the endpoint contract.
