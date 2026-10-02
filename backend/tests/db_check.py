from sqlalchemy import text

from app.core.database import engine

with engine.connect() as conn:
    print("PostGIS from Python:", conn.execute(text("SELECT PostGIS_Version()")).scalar())
    n = conn.execute(
        text(
            "SELECT count(*) FROM information_schema.tables "
            "WHERE table_schema = 'public'"
        )
    ).scalar()
    print("public tables:", n)
