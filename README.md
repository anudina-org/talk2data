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

---

# Chat Bot

> Ask questions about your data in plain English — no SQL required.

---

## What Is This?

The Talk2Data Chat Bot is the query interface for teams whose data has been onboarded. Once a team's database is registered via the Onboarding App, anyone on that team can open this app and ask natural language questions directly against their live data.

---

## Who Is This For?

- **Business users and analysts** who want answers from data without writing SQL
- **Team leads** who need quick ad-hoc lookups across their team's database
- Anyone who has completed the onboarding step and wants to start querying

---

## What Does It Do?

### Connects to Your Database
Enter your Postgres connection URL in the sidebar. The app verifies the connection and lists all available tables and views so you know exactly what data is queryable.

### Translates Plain English to SQL
Type any question in the chat input — the app uses a local LLM (`qwen3:8b` via Ollama) to generate the correct SQL query automatically. The model inspects your full database schema at query time, so it always picks the right table or view.

### Shows Its Work
Every response includes a **Query Details** expander with:
- The exact SQL that was executed (syntax-highlighted)
- The LLM's rationale for choosing that particular table or view

### Returns Results + a Summary
Query results are displayed as an interactive data table. The LLM also generates a concise, friendly summary of the results so you don't have to interpret raw rows.

### Logs Everything
All LLM prompts, generated SQL, rationales, row counts, and errors are logged to the terminal with timestamps — useful for debugging or auditing queries.

---

## Prerequisites

| Requirement | Details |
|-------------|---------|
| Onboarding complete | Run the Onboarding App first so your database has at least one registered view |
| Ollama running locally | The chat bot calls `http://localhost:11434` with model `qwen3:8b` |
| ChromaDB running | Metadata index must be available at `localhost:8000` |
| Postgres accessible | The connection URL must be reachable from where the app runs |

---

## How to Use

```bash
streamlit run app/chat_bot.py
```

1. Enter your Postgres connection URL in the sidebar
2. Verify the sidebar shows your expected tables and views
3. Type a question in the chat input, e.g.:
   - *"List all employees"*
   - *"Show me salaries above 80000"*
   - *"Which department has the most headcount?"*
4. The app returns a summary and a data table — expand **Query Details** to see the SQL and rationale

---

## Configuration

Edit the constants at the top of `app/chat_bot.py`:

| Variable | Default | Description |
|----------|---------|-------------|
| `MODEL_NAME` | `qwen3:8b` | Ollama model used for SQL generation and summarization |
| `CHROMA_HOST` | `localhost` | ChromaDB host |
| `CHROMA_PORT` | `8000` | ChromaDB port |


Sample Run: 
![alt text](image.png)

![alt text](image-1.png)
![alt text](image-2.png)