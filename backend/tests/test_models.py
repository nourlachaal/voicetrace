from decimal import Decimal

from geoalchemy2.elements import WKTElement
from sqlalchemy import select, text
from sqlalchemy.orm import Session

from app.core.database import SessionLocal
from app.models import Lot, Product


def test_read_lots_from_db():
    with SessionLocal() as session:
        lots = session.scalars(select(Lot)).all()
    assert len(lots) >= 4
    assert all(lot.public_id.startswith("LOT-") for lot in lots)


def test_nearest_first_search():
    with SessionLocal() as session:
        rows = session.execute(
            text(
                "SELECT l.public_id, ROUND(ST_Distance(l.location, "
                "ST_SetSRID(ST_MakePoint(10.76, 34.7404), 4326)::geography))::int AS dist_m "
                "FROM lots l JOIN products p ON p.id = l.product_id "
                "WHERE p.canonical_name = 'olive_oil' AND l.status = 'AVAILABLE' "
                "ORDER BY dist_m"
            )
        ).all()
    assert rows[0][0] == "LOT-2026-SFX-001"
    assert rows[0][1] < 3000


def test_insert_lot_geography_and_rollback():
    with SessionLocal() as session:
        try:
            product = session.scalars(
                select(Product).where(Product.canonical_name == "olive_oil")
            ).one()
            lot = Lot(
                public_id="LOT-TEST-ROLLBACK",
                product_id=product.id,
                quantity=Decimal("5"),
                unit="liter",
                price=Decimal("10"),
                location=WKTElement("POINT(10.76 34.74)", srid=4326),
            )
            session.add(lot)
            session.flush()
            dist = session.execute(
                text(
                    "SELECT ST_Distance(location, "
                    "ST_SetSRID(ST_MakePoint(10.76, 34.74), 4326)::geography) "
                    "FROM lots WHERE public_id = 'LOT-TEST-ROLLBACK'"
                )
            ).scalar()
            assert float(dist) < 1.0
        finally:
            session.rollback()

    with SessionLocal() as session:
        leftover = session.scalars(
            select(Lot).where(Lot.public_id == "LOT-TEST-ROLLBACK")
        ).first()
        assert leftover is None
