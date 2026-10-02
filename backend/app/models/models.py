from datetime import date, datetime
from decimal import Decimal

from geoalchemy2 import Geography
from sqlalchemy import Date, DateTime, ForeignKey, Integer, Numeric, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Product(Base):
    __tablename__ = "products"

    id: Mapped[int] = mapped_column(primary_key=True)
    canonical_name: Mapped[str] = mapped_column(Text, unique=True)
    category: Mapped[str | None] = mapped_column(Text)

    synonyms: Mapped[list["ProductSynonym"]] = relationship(back_populates="product")
    lots: Mapped[list["Lot"]] = relationship(back_populates="product")


class ProductSynonym(Base):
    __tablename__ = "product_synonyms"

    id: Mapped[int] = mapped_column(primary_key=True)
    product_id: Mapped[int] = mapped_column(ForeignKey("products.id"))
    term: Mapped[str] = mapped_column(Text)
    language: Mapped[str] = mapped_column(Text)

    product: Mapped["Product"] = relationship(back_populates="synonyms")


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    role: Mapped[str] = mapped_column(Text)
    name: Mapped[str] = mapped_column(Text)
    phone: Mapped[str | None] = mapped_column(Text)
    location = mapped_column(
        Geography("POINT", srid=4326, spatial_index=False), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())


class Producer(Base):
    __tablename__ = "producers"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"))
    name: Mapped[str] = mapped_column(Text)
    phone: Mapped[str | None] = mapped_column(Text)
    region: Mapped[str | None] = mapped_column(Text)

    lots: Mapped[list["Lot"]] = relationship(back_populates="producer")


class Lot(Base):
    __tablename__ = "lots"

    id: Mapped[int] = mapped_column(primary_key=True)
    public_id: Mapped[str] = mapped_column(Text, unique=True)
    product_id: Mapped[int] = mapped_column(ForeignKey("products.id"))
    producer_id: Mapped[int | None] = mapped_column(ForeignKey("producers.id"))
    quantity: Mapped[Decimal] = mapped_column(Numeric)
    unit: Mapped[str] = mapped_column(Text)
    price: Mapped[Decimal] = mapped_column(Numeric, default=Decimal("0"))
    harvest_date: Mapped[date | None] = mapped_column(Date)
    status: Mapped[str] = mapped_column(Text, default="AVAILABLE")
    location = mapped_column(
        Geography("POINT", srid=4326, spatial_index=False), nullable=False
    )

    product: Mapped["Product"] = relationship(back_populates="lots")
    producer: Mapped["Producer | None"] = relationship(back_populates="lots")
    events: Mapped[list["LotEvent"]] = relationship(back_populates="lot")


class LotEvent(Base):
    __tablename__ = "lot_events"

    id: Mapped[int] = mapped_column(primary_key=True)
    lot_id: Mapped[int] = mapped_column(ForeignKey("lots.id"))
    event_type: Mapped[str] = mapped_column(Text)
    event_time: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    previous_hash: Mapped[str | None] = mapped_column(Text)
    event_hash: Mapped[str | None] = mapped_column(Text)

    lot: Mapped["Lot"] = relationship(back_populates="events")


class Request(Base):
    __tablename__ = "requests"

    id: Mapped[int] = mapped_column(primary_key=True)
    buyer_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    product_id: Mapped[int] = mapped_column(ForeignKey("products.id"))
    quantity: Mapped[Decimal] = mapped_column(Numeric)
    unit: Mapped[str] = mapped_column(Text)
    location = mapped_column(
        Geography("POINT", srid=4326, spatial_index=False), nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    buyer: Mapped["User"] = relationship()
    product: Mapped["Product"] = relationship()


class VoiceTurn(Base):
    __tablename__ = "voice_turns"

    id: Mapped[int] = mapped_column(primary_key=True)
    transcript: Mapped[str | None] = mapped_column(Text)
    intent: Mapped[str | None] = mapped_column(Text)
    confidence: Mapped[Decimal | None] = mapped_column(Numeric)
    latency_ms: Mapped[int | None] = mapped_column(Integer)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
