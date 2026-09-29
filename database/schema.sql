CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  canonical_name TEXT NOT NULL UNIQUE,
  category TEXT
);

CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  role TEXT NOT NULL CHECK (role IN ('producer', 'buyer')),
  name TEXT NOT NULL,
  phone TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE producers (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT,
  region TEXT,
  user_id INT REFERENCES users(id)
);

CREATE TABLE lots (
  id SERIAL PRIMARY KEY,
  public_id TEXT UNIQUE NOT NULL,
  product_id INT NOT NULL REFERENCES products(id),
  producer_id INT REFERENCES producers(id),
  quantity NUMERIC NOT NULL CHECK (quantity > 0),
  unit TEXT NOT NULL,
  price NUMERIC NOT NULL DEFAULT 0 CHECK (price >= 0),
  harvest_date DATE,
  status TEXT NOT NULL DEFAULT 'AVAILABLE'
    CHECK (status IN ('AVAILABLE', 'SOLD', 'EXPIRED')),
  location GEOGRAPHY(Point, 4326) NOT NULL
);

CREATE INDEX lots_location_gix ON lots USING GIST (location);
CREATE INDEX lots_status_idx ON lots(status);
CREATE INDEX lots_product_id_idx ON lots(product_id);

CREATE TABLE lot_events (
  id SERIAL PRIMARY KEY,
  lot_id INT NOT NULL REFERENCES lots(id),
  event_type TEXT NOT NULL,
  event_time TIMESTAMP NOT NULL DEFAULT now(),
  previous_hash TEXT,
  event_hash TEXT
);

CREATE INDEX lot_events_lot_id_idx ON lot_events(lot_id);

CREATE TABLE product_synonyms (
  id SERIAL PRIMARY KEY,
  product_id INT NOT NULL REFERENCES products(id),
  term TEXT NOT NULL,
  language TEXT NOT NULL
);

CREATE TABLE requests (
  id SERIAL PRIMARY KEY,
  buyer_id INT NOT NULL REFERENCES users(id),
  product_id INT NOT NULL REFERENCES products(id),
  quantity NUMERIC NOT NULL CHECK (quantity > 0),
  unit TEXT NOT NULL,
  location GEOGRAPHY(Point, 4326) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX requests_product_id_idx ON requests(product_id);

CREATE TABLE voice_turns (
  id SERIAL PRIMARY KEY,
  transcript TEXT,
  intent TEXT,
  confidence NUMERIC,
  latency_ms INT,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);
