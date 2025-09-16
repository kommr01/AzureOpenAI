import pyodbc
import pandas as pd
from dotenv import load_dotenv
from app.core.rag_service import RagService
import os
import re

load_dotenv()
rag = RagService()
def db_connect():
    if os.getenv("DB_CONNECTION_STRING"):
        db_server = re.search(r"Data Source=([^;]+)", os.getenv("DB_CONNECTION_STRING")).group(1)
        database = re.search(r"Initial Catalog=([^;]+)", os.getenv("DB_CONNECTION_STRING")).group(1)
        db_user_id = re.search(r"User ID=([^;]+)", os.getenv("DB_CONNECTION_STRING")).group(1)
        db_password = re.search(r"Password=([^;]+)", os.getenv("DB_CONNECTION_STRING")).group(1)
        CONNECTION_STRING = (
            'DRIVER={ODBC Driver 17 for SQL Server};'
            f'SERVER={db_server};'
            f'DATABASE={database};'
            f'UID={db_user_id};'
            f'PWD={db_password};'
            )
        return pyodbc.connect(CONNECTION_STRING)

def run_query(sql):
    with db_connect() as conn:
        try:
            df = pd.read_sql(sql, conn)
        except Exception as e:
            updated_sql_query  = rag.validate_sql_statement(e, sql)
            try:
                df = pd.read_sql(updated_sql_query, conn)
            except Exception as e:
                return e
            return df
    return df

