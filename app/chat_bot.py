import streamlit as st
import sqlalchemy as sa
from sqlalchemy import inspect
import chromadb
import ollama
import pandas as pd

# --- CONFIGURATION ---
MODEL_NAME = "qwen3:8b"
CHROMA_HOST = "localhost"
CHROMA_PORT = 8000
VIEW_NAME = "v_ai_flattened_report"

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
def get_sql_from_ai(user_query, engine):
    # Get ground-truth columns from Postgres
    inspector = inspect(engine)
    columns = [c['name'] for c in inspector.get_columns(VIEW_NAME)]
    
    # Precise Prompting
    prompt = f"""
    [SYSTEM] You are a PostgreSQL Expert. 
    [CONTEXT] You are querying a view named '{VIEW_NAME}'.
    [AVAILABLE COLUMNS] {columns}
    
    [RULES]
    1. Use ONLY the columns listed above. 
    2. If the user asks for 'name', use 'employee_name'. 
    3. If the user asks for 'department', use 'dept_name'.
    4. Use ILIKE for text searches to be case-insensitive.
    5. Return ONLY the raw SQL code. No markdown.
    
    [USER QUESTION] {user_query}
    """
    
    response = ollama.generate(model=MODEL_NAME, prompt=prompt)
    return response['response'].strip().replace('```sql', '').replace('```', '')

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
            try:
                # A. Generate SQL
                generated_sql = get_sql_from_ai(user_input, engine)
                
                # B. Execute on Postgres
                df = pd.read_sql(generated_sql, engine)
                
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
                    summary_res = ollama.generate(model=MODEL_NAME, prompt=summary_prompt)
                    full_response = summary_res['response']
                
                st.markdown(full_response)
                if not df.empty:
                    st.dataframe(df)
                
                st.session_state.messages.append({"role": "assistant", "content": full_response})

            except Exception as e:
                st.error(f"SQL Translation Error: {e}")
                st.info("I tried to run this query:")
                st.code(generated_sql)