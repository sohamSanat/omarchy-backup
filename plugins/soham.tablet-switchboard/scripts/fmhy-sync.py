#!/usr/bin/env python3
import sys, os, json, sqlite3

if len(sys.argv) < 3:
    sys.exit(1)

cache_file = sys.argv[1]
db_file = sys.argv[2]

if not os.path.exists(cache_file):
    sys.exit(0)

try:
    with open(cache_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    os.makedirs(os.path.dirname(db_file), exist_ok=True)
    temp_db = db_file + ".tmp"
    if os.path.exists(temp_db):
        os.remove(temp_db)
        
    conn = sqlite3.connect(temp_db)
    c = conn.cursor()
    c.execute("CREATE VIRTUAL TABLE fmhy USING fts5(title, description, category, hostname, url, starred UNINDEXED);")
    records = [
        (
            r.get('title', ''),
            r.get('description', ''),
            r.get('category', ''),
            r.get('hostname', ''),
            r.get('url', ''),
            1 if r.get('starred') else 0
        )
        for r in data.get('resources', [])
    ]
    c.executemany("INSERT INTO fmhy(title, description, category, hostname, url, starred) VALUES (?, ?, ?, ?, ?, ?);", records)
    conn.commit()
    conn.close()
    
    os.replace(temp_db, db_file)
except Exception as e:
    sys.stderr.write(f"Error rebuilding FMHY db: {e}\n")
    sys.exit(1)
