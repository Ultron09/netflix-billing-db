#!/usr/bin/env python3
"""
ULTRON // Netflix Billing Database Explorer
Provides an interactive terminal dashboard to inspect tables and execute queries.
"""

import sqlite3
import sys
import os

DB_PATH = "/home/ultron/Projects/netflix_billing_db/netflix_billing.db"

def print_table(cursor, title="Query Result"):
    rows = cursor.fetchall()
    if not rows:
        print(f"\n[!] {title}: No rows returned.")
        return

    headers = [desc[0] for desc in cursor.description]
    # Format rows to strings
    str_rows = [[str(v) if v is not None else "NULL" for v in row] for row in rows]
    
    # Calculate column widths
    col_widths = [len(h) for h in headers]
    for row in str_rows:
        for i, val in enumerate(row):
            col_widths[i] = max(col_widths[i], len(val))

    separator = "+-" + "-+-".join("-" * w for w in col_widths) + "-+"
    header_line = "| " + " | ".join(h.ljust(w) for h, w in zip(headers, col_widths)) + " |"

    print(f"\n=== {title} ({len(rows)} rows) ===")
    print(separator)
    print(header_line)
    print(separator)
    for row in str_rows:
        print("| " + " | ".join(val.ljust(w) for val, w in zip(row, col_widths)) + " |")
    print(separator)

def show_summary(conn):
    cur = conn.cursor()
    tables = [
        "USERS", "SUBSCRIPTION_PLANS", "TAX_RATES", "SUBSCRIPTIONS",
        "PAYMENT_METHODS", "INVOICES", "PAYMENTS", "REVENUE_LEDGER"
    ]
    print("\n⚡ ULTRON // NETFLIX DATABASE METRICS MATRIX")
    print("-" * 50)
    for tbl in tables:
        cur.execute(f"SELECT COUNT(*) FROM {tbl};")
        cnt = cur.fetchone()[0]
        print(f"  • {tbl.ljust(22)} : {cnt} records")
    print("-" * 50)

def main():
    if not os.path.exists(DB_PATH):
        print(f"Error: Database not found at {DB_PATH}")
        sys.exit(1)

    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    if len(sys.argv) > 1:
        cmd = sys.argv[1].lower()
        if cmd == "summary":
            show_summary(conn)
        elif cmd in ["users", "plans", "subscriptions", "payments", "invoices", "taxes", "methods", "ledger"]:
            mapping = {
                "users": "USERS",
                "plans": "SUBSCRIPTION_PLANS",
                "subscriptions": "SUBSCRIPTIONS",
                "payments": "PAYMENTS",
                "invoices": "INVOICES",
                "taxes": "TAX_RATES",
                "methods": "PAYMENT_METHODS",
                "ledger": "REVENUE_LEDGER"
            }
            tbl = mapping[cmd]
            cur.execute(f"SELECT * FROM {tbl};")
            print_table(cur, f"TABLE: {tbl}")
        elif cmd == "query" and len(sys.argv) > 2:
            query_str = " ".join(sys.argv[2:])
            try:
                cur.execute(query_str)
                print_table(cur, "Custom SQL Execution")
            except Exception as e:
                print(f"[ERROR] {e}")
        else:
            print("Usage:")
            print("  ./explore.py summary")
            print("  ./explore.py [users|plans|subscriptions|invoices|payments|methods|taxes|ledger]")
            print("  ./explore.py query \"SELECT * FROM USERS;\"")
    else:
        show_summary(conn)
        print("\n[Tip] Run with table names or 'query' parameter for deeper inspection.")

    conn.close()

if __name__ == "__main__":
    main()
