import streamlit as st
import sqlalchemy as sa
from sqlalchemy import inspect
import chromadb
import ollama
import pandas as pd
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)

# --- CONFIGURATION ---
MODEL_NAME = "qwen3:8b"
CHROMA_HOST = "localhost"
CHROMA_PORT = 8000

st.set_page_config(page_title="AI Data Analyst", layout="wide", page_icon="💬")
st.title("💬 Chat with your Company Data")

# --- 1. CONNECTION SETUP ---
with st.sidebar:
    st.header("🔗 Connection")
    db_url = st.text_input("Postgres URL", value="postgresql://postgres:password@localhost:5432/company_db")
    
    try:
        engine = sa.create_engine(db_url)
        # Verify connection
        with engine.connect() as conn:
            conn.execute(sa.text("SELECT 1"))
        st.success("Connected to Postgres")

        # Show available tables and views for debugging
        inspector = inspect(engine)
        tables = inspector.get_table_names()
        views = inspector.get_view_names()
        logger.info("views: %s", views)
        logger.info("Available tables: %s", tables)
        logger.info("Available views: %s", views)
        with st.expander("Available Tables & Views"):
            st.write("**Tables:**", tables)
            st.write("**Views:**", views)
            if not views:
                st.error("View 'v_NAMESPACE_GOLD' not found! Please onboard the application using the onboarding app.")
    except:
        st.error("Connection Failed. Check URL.")
        st.stop()

# Initialize ChromaDB
try:
    chroma_client = chromadb.HttpClient(host=CHROMA_HOST, port=CHROMA_PORT)
    collection = chroma_client.get_collection(name="db_metadata")
except:
    st.warning("Metadata not found. Please run the Onboarding App first.")
    st.stop()

# --- 2. THE TRANSLATION ENGINE ---
def build_schema_context(engine):
    """Returns a dict of {table_or_view_name: [column_names]} for all tables and views."""
    inspector = inspect(engine)
    schema = {}
    for name in inspector.get_table_names() + inspector.get_view_names():
        schema[name] = [c['name'] for c in inspector.get_columns(name)]
    return schema

def get_sql_from_ai(user_query, engine):
    logger.info("User Natural Query is :\n%s", user_query)

    schema = build_schema_context(engine)
    logger.info("Schema context: %s", schema)

    schema_lines = "\n".join(
        f"  - {name}: {cols}" for name, cols in schema.items()
    )

    # Precise Prompting
    prompt = f"""
    [SYSTEM] You are a PostgreSQL Expert.
    [CONTEXT] The database has the following tables and views with their columns:
{schema_lines}

    [RULES]
    1. Use ONLY the tables/views and columns listed above.
    2. Choose the most relevant table or view based on the user's question.
    3. Use ILIKE for text searches to be case-insensitive.
    4. Return the raw SQL code that is generated without fail. and explanation why you chose that table or view.just the SQL and a brief rationale.

    [USER QUESTION] {user_query}
    """
    
    logger.info("=== SQL GENERATION REQUEST ===")
    logger.info("User query: %s", user_query)
    logger.info("Prompt sent to LLM:\n%s", prompt)

    response = ollama.generate(model=MODEL_NAME, prompt=prompt)
    cleaned = response['response'].strip().replace('```sql', '').replace('```', '')
    # Split SQL from the rationale the LLM appends after the final semicolon
    last_semicolon = cleaned.rfind(';')
    if last_semicolon != -1:
        raw_sql = cleaned[:last_semicolon + 1]
        rationale = cleaned[last_semicolon + 1:].strip()
    else:
        raw_sql = cleaned
        rationale = ""

    logger.info("=== SQL GENERATION RESPONSE ===")
    logger.info("Raw LLM response:\n%s", response['response'])
    logger.info("Generated SQL:\n%s", raw_sql)
    logger.info("Rationale:\n%s", rationale)

    return raw_sql, rationale

# --- 3. CHAT UI ---
if "messages" not in st.session_state:
    st.session_state.messages = []

for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        st.markdown(message["content"])

if user_input := st.chat_input("Ask about employees, salaries, or projects..."):
    st.session_state.messages.append({"role": "user", "content": user_input})
    with st.chat_message("user"):
        st.markdown(user_input)

    with st.chat_message("assistant"):
        with st.spinner("Generating SQL and analyzing..."):
            generated_sql = None
            try:
                # A. Generate SQL
                generated_sql, rationale = get_sql_from_ai(user_input, engine)

                with st.expander("Query Details"):
                    st.code(generated_sql, language="sql")
                    if rationale:
                        st.caption(f"**Why this query:** {rationale}")

                # B. Execute on Postgres
                logger.info("Executing SQL on Postgres:\n%s", generated_sql)
                df = pd.read_sql(generated_sql, engine)
                logger.info("Query returned %d rows", len(df))
                
                if df.empty:
                    full_response = "I found the right data table, but there were no records matching that specific request."
                else:
                    # C. Summarize Results
                    summary_prompt = f"""
                    The user asked: {user_input}
                    The database returned this data:
                    {df.head(10).to_string()}
                    
                    Provide a concise, friendly summary of these results.
                    """
                    logger.info("=== SUMMARY REQUEST ===")
                    logger.info("Summary prompt sent to LLM:\n%s", summary_prompt)

                    summary_res = ollama.generate(model=MODEL_NAME, prompt=summary_prompt)
                    full_response = summary_res['response']

                    logger.info("=== SUMMARY RESPONSE ===")
                    logger.info("LLM summary:\n%s", full_response)
                
                st.markdown(full_response)
                if not df.empty:
                    st.dataframe(df)
                
                st.session_state.messages.append({"role": "assistant", "content": full_response})

            except Exception as e:
                logger.error("Pipeline error: %s", e, exc_info=True)
                st.error(f"SQL Translation Error: {e}")
                if generated_sql:
                    st.info("I tried to run this query:")
                    st.code(generated_sql)