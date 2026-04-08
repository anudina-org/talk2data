# Team Onboarder

> One-click intelligence onboarding for any database team — connects your data, generates a semantic gold view, and registers it so the Talk2Data chat app can query it in natural language.

---

## How It Works

```
Your Database  →  Select Tables & Columns  →  AI Builds a Gold View  →  Indexed in ChromaDB  →  Chat App Ready
```

1. Paste your database connection URL in the sidebar
2. AI inspects your tables and suggests a namespace + domain description
3. You pick the tables and columns to expose
4. Click **Build & Index** — a SQL view is created and registered

---

## Features

### Multi-Database Support
Connect to any database at runtime — no code changes needed.

| Database    | Connection URL Format |
|-------------|----------------------|
| PostgreSQL  | `postgresql://user:pass@host:5432/db` |
| MySQL       | `mysql+pymysql://user:pass@host:3306/db` |
| SQL Server  | `mssql+pyodbc://user:pass@host/db?driver=ODBC+Driver+17+for+SQL+Server` |
| Oracle      | `oracle+cx_oracle://user:pass@host:1521/service` |

---

### AI-Suggested Namespace & Description
On first load, the LLM (`qwen3:8b` via Ollama) inspects the connected database and auto-suggests:
- A **1-word Namespace ID** identifying the team or domain (e.g. `employee`, `sales`, `finance`)
- A **1-sentence Domain Description** for semantic context

Both are editable before you finalize.

---

### Dynamic Table & Column Selection
- Lists all tables in the connected database
- Select multiple tables, then drill into specific columns
- Supports any combination across tables in a single onboarding session

---

### AI-Generated Gold View
The LLM generates a production-ready SQL view that:
- Is named `v_{namespace}_gold`
- Automatically aliases duplicate column names across tables to avoid conflicts
  - e.g. if both `employees` and `departments` have an `id` column → `employees_id`, `departments_id`
- Handles SQL dialect differences automatically:
  - PostgreSQL / MySQL / Oracle → `CREATE OR REPLACE VIEW`
  - SQL Server → `CREATE OR ALTER VIEW`

---

### Namespace Collision Detection
Before building, the app checks if `v_{namespace}_gold` already exists in the database and warns you — preventing accidental overwrites without your confirmation.

---

### ChromaDB Indexing
After the view is created, the app registers the team's metadata into a ChromaDB collection named `{namespace}`:

| Field | Value stored |
|-------|-------------|
| Document | Domain description (used for semantic search) |
| `view_name` | The SQL view the chat app will query |
| `columns` | Comma-separated list of selected columns |
| `domain` | Full domain context description |

This is what the Talk2Data chat app reads to understand which view to query and how to interpret results.

---

## Prerequisites

### Services

| Service   | Command |
|-----------|---------|
| ChromaDB  | `docker pull chromadb/chroma && docker run -p 8000:8000 chromadb/chroma` |
| Ollama    | `ollama pull qwen3:8b` |
| Database  | Your source database must be accessible via network |

### Python Dependencies

```bash
pip install streamlit sqlalchemy chromadb ollama

# Add the driver for your specific database:
pip install psycopg2-binary   # PostgreSQL
pip install pymysql           # MySQL
pip install pyodbc            # SQL Server
pip install cx_Oracle         # Oracle
```

---

## Running the App

```bash
streamlit run onboarding/onboarding_app.py
```

---

## Onboarding a New Team — Step by Step

| Step | Action |
|------|--------|
| 1 | Select your database type from the sidebar dropdown |
| 2 | Paste the connection URL |
| 3 | Review or edit the AI-suggested Namespace ID |
| 4 | Review or edit the Domain Description |
| 5 | Select tables to include |
| 6 | Select specific columns from those tables |
| 7 | Click **Build & Index** |

Each team gets its own namespace — run the app multiple times with different URLs and namespace IDs to onboard multiple teams independently.

---

## Output — What Gets Created

```
PostgreSQL (or target DB)
└── View: v_{namespace}_gold       ← queryable by the chat app

ChromaDB
└── Collection: {namespace}
    └── doc: domain description
        meta: view_name, columns, domain
```
