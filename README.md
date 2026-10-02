# 🎙️ VoiceTrace — Voice-First Traceable Marketplace

**AI-powered voice marketplace with LLM-based structured extraction, semantic search, and product traceability.**

VoiceTrace is a **voice-first digital marketplace** designed to connect producers directly with buyers through natural-language interaction.

Producers can create product listings using **Tunisian Derja, Arabic, French, or structured forms**, while buyers can search for products using voice or text. The platform combines **Speech-to-Text, LLM-based intent and entity extraction, geospatial search, vector similarity, and QR-based traceability** into a single system.

The architecture is designed around one core principle:

> **AI understands the user. Deterministic backend services control the data.**

---

## 🧠 Core AI Architecture

VoiceTrace separates AI interpretation from transactional operations.

```text
User Voice
    ↓
Speech-to-Text
    ↓
Derja / Arabic / French Normalization
    ↓
LLM Structured NLU
    ↓
Pydantic Validation
    ↓
Dialogue State Machine
    ↓
User Confirmation
    ↓
Backend Tool
    ↓
PostgreSQL
```

The LLM **never receives unrestricted database access**.

Instead, it produces structured information such as:

```json
{
  "intent": "CREATE_LISTING",
  "slots": {
    "product": "olive_oil",
    "quantity": 40,
    "unit": "liter",
    "price": 12
  },
  "missing_slots": [
    "harvest_date",
    "location"
  ]
}
```

The backend validates the output before any database operation is executed.

---

## 🚀 Key Features

### 🎙️ Voice-First Product Creation

Producers can publish products through natural-language voice input.

The voice pipeline performs:

* 🎤 Audio capture
* 🔊 Speech-to-Text
* 🧹 Dialect and text normalization
* 🧠 Intent detection
* 📦 Entity / slot extraction
* 🔄 Dialogue management
* ✅ Pydantic validation
* 🔐 Confirmation before persistence
* 🔊 Text-to-Speech response

---

### 🧠 LLM-Powered Structured NLU

The LLM converts natural language into typed application data.

Supported intents include:

```text
CREATE_LISTING
SEARCH_PRODUCT
CHECK_STOCK
CHECK_SALES
UNKNOWN
```

Extracted information can include:

```text
Product
Quantity
Unit
Price
Harvest date
Location
Attributes
```

Structured outputs are validated using **Pydantic** before reaching business logic.

---

### 🔎 Semantic Product Search

Buyers can search using either voice or text.

```text
Voice / Text Query
       ↓
      STT
       ↓
Normalization
       ↓
Structured Search Intent
       ↓
PostGIS Geographic Filtering
       ↓
Product / Availability Filtering
       ↓
Semantic Matching
       ↓
Distance + Relevance + Freshness
       ↓
Top Results
```

The system combines:

* **PostGIS** for geographic filtering
* **pgvector** for vector similarity
* Product attributes
* Availability
* Geographic distance
* Listing freshness

---

## 📚 Agricultural RAG

VoiceTrace includes an architecture for **Retrieval-Augmented Generation** over expert-reviewed agricultural knowledge.

```text
Producer Question
       ↓
Embedding
       ↓
pgvector Similarity Search
       ↓
Expert-Reviewed Knowledge
       ↓
Relevant Passages
       ↓
LLM
       ↓
Grounded Answer
```

Only **reviewed knowledge** is used for agricultural guidance.

The system stores:

* Knowledge content
* Reviewer
* Review date
* Embedding
* Internal source identifier

If retrieval confidence is insufficient, the system can respond that no reliable information was found rather than generating unsupported advice.

---

## 🌍 Tunisian Derja Normalization

A major component of the system is handling variation in Tunisian speech and writing.

Examples:

```text
"أربعين لتر"
"40 لتر"
"40 litres"

        ↓

quantity = 40
unit = "liter"
```

```text
"دينار"
"dt"
"TND"

        ↓

currency = "TND"
```

```text
"زيت زيتون"
"zit zitoun"
"huile olive"

        ↓

product = "olive_oil"
```

This normalization layer sits between **speech recognition and structured LLM extraction**.

---

## 🔐 Traceability System

Each product quantity is represented as a **traceable lot** with a unique public identifier.

```text
LOT #8F3A92
     │
     ├── Harvest
     │
     ├── Processing
     │
     ├── Packaging
     │
     ├── Marketplace Listing
     │
     └── Sold
```

Each lot can be accessed through a **QR passport**.

The QR code contains only a short public URL:

```text
/p/8F3A92
```

rather than storing the complete product information inside the QR code.

### Hash-Chained Events

The traceability history can use a lightweight hash-chain mechanism:

```text
Event 1
   ↓
Event Hash
   ↓
Event 2 + Previous Hash
   ↓
Event Hash
   ↓
Event 3 + Previous Hash
```

This provides a **tamper-evident event history** without requiring blockchain infrastructure.

---

## 🏗️ System Architecture

```text
                    ┌──────────────────────┐
                    │      Users           │
                    │ Producer / Buyer     │
                    └──────────┬───────────┘
                               │
                       Voice / Text / Form
                               │
                               ▼
                    ┌──────────────────────┐
                    │     React PWA         │
                    │ Voice · Forms · Search│
                    └──────────┬───────────┘
                               │ HTTPS / REST
                               ▼
                    ┌──────────────────────┐
                    │      FastAPI         │
                    │ Auth · Marketplace   │
                    │ Search · Voice · AI  │
                    └──────────┬───────────┘
                               │
            ┌──────────────────┼──────────────────┐
            ▼                  ▼                  ▼
     ┌────────────┐    ┌──────────────┐   ┌──────────────┐
     │Voice       │    │AI Assistant  │   │Marketplace   │
     │Pipeline    │    │              │   │Services      │
     │STT / NLU   │    │Tools / RAG   │   │Listings      │
     │TTS         │    │Guardrails    │   │Search / Lots │
     └─────┬──────┘    └──────┬───────┘   └──────┬───────┘
           │                   │                  │
           └───────────────────┼──────────────────┘
                               ▼
                    ┌──────────────────────┐
                    │     PostgreSQL       │
                    │ PostGIS + pgvector   │
                    └──────────┬───────────┘
                               │
                    ┌──────────┴───────────┐
                    ▼                      ▼
              QR Passport           Object Storage
                                   Photos / Audio
```

---

## 🛠️ Technology Stack

### 🤖 AI / LLM

`LLMs` `RAG` `Embeddings` `Structured NLU` `Prompt Engineering`

### 🎙️ Voice AI

`Speech-to-Text` `Text-to-Speech` `FFmpeg` `Audio Processing`

### 🔎 Retrieval

`pgvector` `Vector Search` `Semantic Search` `HNSW`

### ⚙️ Backend

`Python` `FastAPI` `Pydantic` `SQLAlchemy` `Alembic`

### 🗄️ Database

`PostgreSQL` `PostGIS` `pgvector`

### 💻 Frontend

`React` `Vite` `PWA` `Tailwind CSS` `i18next`

### 🗺️ Geographic Services

`PostGIS` `Leaflet` `OpenStreetMap`

### 🔐 Security

`JWT` `Role-Based Authorization` `Input Validation` `Rate Limiting`

### 🚀 DevOps

`Docker` `GitHub Actions` `Pytest` `Ruff`

---

## 🧩 Project Structure

```text
VoiceTrace/
│
├── frontend/
│   └── src/
│       ├── components/
│       │   ├── VoiceButton/
│       │   ├── ProductCard/
│       │   ├── LotCard/
│       │   ├── QRCode/
│       │   └── AudioPlayer/
│       │
│       ├── pages/
│       │   ├── Home/
│       │   ├── Producer/
│       │   ├── Buyer/
│       │   ├── CreateListing/
│       │   ├── Search/
│       │   ├── Assistant/
│       │   └── Passport/
│       │
│       ├── services/
│       ├── hooks/
│       └── i18n/
│
├── backend/
│   └── app/
│       ├── api/
│       │   ├── auth.py
│       │   ├── listings.py
│       │   ├── lots.py
│       │   ├── search.py
│       │   ├── requests.py
│       │   ├── voice.py
│       │   └── assistant.py
│       │
│       ├── models/
│       ├── schemas/
│       ├── services/
│       │
│       ├── ai/
│       │   ├── stt/
│       │   ├── tts/
│       │   ├── llm/
│       │   ├── normalizer/
│       │   └── embeddings/
│       │
│       └── tools/
│           ├── marketplace_tools.py
│           ├── producer_tools.py
│           └── knowledge_tools.py
│
└── README.md
```

---

## 🔌 AI Provider Architecture

AI providers are isolated behind adapter interfaces.

```text
                AI Provider Layer
                       │
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
    STTAdapter     LLMAdapter     TTSAdapter
        │              │              │
   ┌────┴────┐    ┌────┴────┐         │
   │         │    │         │         │
Whisper   Other  Gemini    Other   Provider
```

This allows providers to be benchmarked and replaced without changing the core application architecture.

---

## 🔒 AI Safety & Backend Guardrails

VoiceTrace follows an **AI-assisted, backend-controlled** architecture.

### The LLM cannot:

* Execute arbitrary SQL
* Access database credentials
* Decide user identity
* Directly modify persistent data
* Bypass authorization rules

### Instead:

```text
LLM
 ↓
Structured Output
 ↓
Pydantic Validation
 ↓
Dialogue Confirmation
 ↓
Whitelisted Backend Tool
 ↓
Business Logic
 ↓
Database
```

Authenticated identity is obtained from the user's **JWT**, not from an LLM-generated parameter.

---

## 📊 Database Model

Core entities include:

```text
Users
  │
  ├── Producers
  │
  └── Buyers

Products
  │
  ├── Product Synonyms
  │
  └── Listings
          │
          └── Lots
                │
                └── Lot Events

Buyers
  │
  └── Requests

Knowledge
  │
  └── Embeddings

Voice Users
  │
  └── Voice Turns
```

PostgreSQL acts as the unified data layer with:

* **PostGIS** → geographic queries
* **pgvector** → semantic/vector retrieval
* Relational tables → marketplace and traceability data

---

## 📡 API

Example endpoints:

| Method | Endpoint              | Purpose                      |
| ------ | --------------------- | ---------------------------- |
| `POST` | `/auth/login`         | Authenticate user            |
| `POST` | `/auth/register`      | Register user                |
| `POST` | `/listings`           | Create listing               |
| `GET`  | `/listings`           | Browse marketplace           |
| `GET`  | `/listings/{id}`      | Get listing                  |
| `GET`  | `/lots/{id}`          | Get lot                      |
| `GET`  | `/lots/{id}/passport` | Public traceability passport |
| `GET`  | `/lots/{id}/events`   | Traceability history         |
| `GET`  | `/search`             | Search products              |
| `POST` | `/requests`           | Create buyer request         |
| `POST` | `/voice/turn`         | Process voice interaction    |
| `POST` | `/assistant/ask`      | Query AI assistant           |

---

## 🧪 Derja AI Evaluation

The system is designed to evaluate voice providers using a dedicated benchmark containing realistic Tunisian Derja utterances.

Evaluation metrics include:

* **WER / CER**
* Product entity accuracy
* Quantity accuracy
* Unit accuracy
* Price accuracy
* Date extraction accuracy
* Intent classification accuracy
* Latency
* Failure rate

This makes provider selection **measurement-driven rather than assumption-driven**.

---

## 🎯 Engineering Principles

* **Voice-first, not voice-only**
* **AI-assisted, backend-controlled**
* **Typed structured outputs**
* **Deterministic business logic**
* **Provider-independent AI**
* **Traceability by design**
* **Mobile-first architecture**
* **Low-cost infrastructure**
* **Security at every execution boundary**
* **RAG grounded in reviewed knowledge**

---

## 🔮 Future Improvements

* Advanced multilingual RAG
* Improved Derja speech recognition
* Larger voice evaluation datasets
* Personalized semantic product recommendations
* Advanced marketplace analytics
* Automated traceability verification
* AI-powered demand forecasting
* Expanded producer knowledge assistant
* Offline-first capabilities

---

## 👩‍💻 Project Focus

VoiceTrace combines several areas of modern software engineering:

**Generative AI · RAG · LLM Applications · NLP · Speech AI · Vector Search · Geospatial Data · Backend Engineering · Data Modeling · Traceability · PWA Development**

The goal is not simply to add an LLM to a marketplace, but to design an **AI system where language understanding, retrieval, validation, business logic, and transactional data remain clearly separated**.

---

⭐ **Built with Python, FastAPI, React, PostgreSQL, PostGIS, pgvector and LLM-powered AI.**
