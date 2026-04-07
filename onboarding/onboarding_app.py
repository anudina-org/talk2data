import streamlit as st
import sqlalchemy as sa
from sqlalchemy import inspect
import chromadb
import ollama
import json

MODEL_NAME = "qwen3:8b"

st.set_page_config(page_title="Team Onboarder", layout="wide")
db_url = "postgresql://postgres:postgres@localhost:5432/talk_2data_employee_rdb"
# --- DATABASE & CHROMA SETUP ---
# with st.sidebar:
#     db_url = st.text_input("Postgres URL", placeholder="postgresql://postgres:postgres@localhost:5432/talk_2data_employee_rdb")
#     if not db_url: st.stop()

engine = sa.create_engine(db_url)
chroma_client = chromadb.HttpClient(host='localhost', port=8000)

# AI Auto-Suggestion (One-time trigger)
if "suggested_meta" not in st.session_state:
    tables = inspect(engine).get_table_names()
    res = ollama.generate(
        model=MODEL_NAME, 
        prompt=f"Table list: {tables}. Suggest a 1-word 'ns' and 1-sentence 'ctx'. JSON format.",
        format="json"
    )
    st.session_state.suggested_meta = json.loads(res['response'])

# --- UI: CONFIGURATION ---
st.title("🚀 Intelligence Onboarding")

user_ns = st.text_input("Namespace ID", value=st.session_state.suggested_meta['ns']).lower().strip()
domain_ctx = st.text_area("Domain Description", value=st.session_state.suggested_meta['ctx'])

# Collision Check
inspector = inspect(engine)
if f"v_{user_ns}_gold" in inspector.get_view_names():
    st.warning(f"⚠️ '{user_ns}' already exists. Finalizing will overwrite it.")

# Selection
available_tables = inspector.get_table_names()
selected_tables = st.multiselect("Tables:", available_tables)

if selected_tables:
    cols = [f"{t}.{c['name']}" for t in selected_tables for c in inspector.get_columns(t)]
    selected_cols = st.multiselect("Columns:", cols)

    if selected_cols and st.button("✅ Build & Index"):
        view_name = f"v_{user_ns}_gold"
        # Create View
        sql_prompt = f"""
        [TASK] Create a PostgreSQL VIEW named '{view_name}'.
        [TABLES] {selected_tables}
        [COLUMNS] {selected_cols}
        
        [CRITICAL RULE FOR ALL DOMAINS] 
        PostgreSQL does not allow duplicate column names in a VIEW. 
        If multiple tables share the same column name, you MUST alias them 
        using the following pattern: [table_name]_[column_name].
        
        Example: If table 'A' and table 'B' both have a column 'ID', 
        you must write: A.ID AS A_ID, B.ID AS B_ID.
        
        [OUTPUT] Return ONLY the 'CREATE OR REPLACE VIEW' SQL. No markdown.
        """
        sql = ollama.generate(model=MODEL_NAME, prompt=sql_prompt)['response'].strip().replace('```sql', '').replace('```', '')
        
        with engine.connect() as conn:
            conn.execute(sa.text(f"DROP VIEW IF EXISTS {view_name} CASCADE;"))
            conn.execute(sa.text(sql))
            conn.commit()

        # Save to ChromaDB (This is what the Chat App will read)
        col = chroma_client.get_or_create_collection(name=user_ns)
        col.upsert(
            ids=["config"],
            documents=[domain_ctx],
            metadatas=[{
                "view_name": view_name, 
                "columns": ",".join(selected_cols), 
                "domain": domain_ctx
            }]
        )
        st.success(f"System '{user_ns}' is now live!")