"""
RetailCo ERP Extractor  –  Checkpoint 2
Pulls all 9 entities from the ERP REST API into lake.raw.*
Handles: pagination, incremental watermarks, 429 rate limit,
         500/timeout retries, idempotent upsert.
"""

import os, time, logging
import requests, psycopg2, psycopg2.extras
from typing import Generator

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

API_KEY  = os.environ["ERP_API_KEY"]
BASE_URL = os.environ.get("ERP_BASE_URL", "https://hngstage8da-55c7f5f769c8.herokuapp.com")
LAKE_DB  = os.environ["LAKE_DB_URL"]

HEADERS = {"X-API-Key": API_KEY, "Accept": "application/json"}

ENTITIES = {
    "customers":           "customer_id",
    "products":            "product_id",
    "stores":              "store_id",
    "employees":           "employee_id",
    "orders":              "order_id",
    "order_items":         "order_item_id",
    "payments":            "payment_id",
    "inventory_movements": "movement_id",
    "payment_methods":     "payment_method_id",
}

MAX_RETRIES  = 5
BASE_BACKOFF = 2
PAGE_LIMIT   = 100


# ─── HTTP ────────────────────────────────────────────────────────────────────

def _get(url: str, params: dict = None) -> dict:
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            r = requests.get(url, headers=HEADERS, params=params, timeout=30)
        except requests.exceptions.Timeout:
            if attempt == MAX_RETRIES:
                raise
            time.sleep(BASE_BACKOFF ** attempt)
            continue

        if r.status_code == 200:
            return r.json()
        if r.status_code == 429:
            wait = int(r.headers.get("Retry-After", BASE_BACKOFF ** attempt))
            log.warning("Rate limited – sleeping %ss", wait)
            time.sleep(wait)
            continue
        if r.status_code in (500, 502, 503, 504):
            if attempt == MAX_RETRIES:
                r.raise_for_status()
            time.sleep(BASE_BACKOFF ** attempt)
            continue
        r.raise_for_status()


def paginate(entity: str, updated_after: str = None) -> Generator[dict, None, None]:
    url, cursor, total = f"{BASE_URL}/api/v1/{entity}", None, 0
    while True:
        params = {"limit": PAGE_LIMIT}
        if cursor:
            params["cursor"] = cursor
        if updated_after:
            params["updated_after"] = updated_after
        data = _get(url, params)
        rows = data.get("data", data.get("items", []))
        for row in rows:
            yield row
            total += 1
        if not data.get("has_more", False):
            break
        cursor = data.get("next_cursor") or data.get("cursor")
        if not cursor:
            break
    log.info("Fetched %d rows from %s", total, entity)


# ─── DB ──────────────────────────────────────────────────────────────────────

def get_db():
    return psycopg2.connect(LAKE_DB)


def get_watermark(conn, entity):
    with conn.cursor() as cur:
        cur.execute("SELECT last_updated_at FROM raw._watermarks WHERE entity = %s", (entity,))
        row = cur.fetchone()
        return row[0].isoformat() if row and row[0] else None


def set_watermark(conn, entity, ts):
    with conn.cursor() as cur:
        cur.execute("""
            INSERT INTO raw._watermarks (entity, last_updated_at, last_run_at)
            VALUES (%s, %s, NOW())
            ON CONFLICT (entity) DO UPDATE
                SET last_updated_at = EXCLUDED.last_updated_at,
                    last_run_at = NOW()
        """, (entity, ts))
    conn.commit()


def ensure_table(conn, entity, sample_row):
    pk   = ENTITIES[entity]
    cols = ", ".join(f'"{k}" TEXT' for k in sample_row.keys())
    with conn.cursor() as cur:
        cur.execute(f"""
            CREATE TABLE IF NOT EXISTS raw.{entity} (
                {cols},
                _extracted_at TIMESTAMPTZ DEFAULT NOW(),
                PRIMARY KEY ("{pk}")
            )
        """)
        for col in sample_row.keys():
            cur.execute(f"""
                DO $$ BEGIN
                    ALTER TABLE raw.{entity} ADD COLUMN IF NOT EXISTS "{col}" TEXT;
                EXCEPTION WHEN duplicate_column THEN NULL;
                END $$;
            """)
    conn.commit()


def upsert_rows(conn, entity, rows):
    if not rows:
        return
    pk   = ENTITIES[entity]
    cols = list(rows[0].keys())
    col_list = ", ".join(f'"{c}"' for c in cols)
    placeholders = ", ".join(["%s"] * len(cols))
    update_set = ", ".join(f'"{c}" = EXCLUDED."{c}"' for c in cols if c != pk)
    sql = f"""
        INSERT INTO raw.{entity} ({col_list}, _extracted_at)
        VALUES ({placeholders}, NOW())
        ON CONFLICT ("{pk}") DO UPDATE SET {update_set}, _extracted_at = NOW()
    """
    values = [[str(r.get(c)) if r.get(c) is not None else None for c in cols] for r in rows]
    with conn.cursor() as cur:
        psycopg2.extras.execute_batch(cur, sql, values, page_size=500)
    conn.commit()


# ─── Main ────────────────────────────────────────────────────────────────────

def extract_entity(entity: str, full_refresh: bool = False):
    conn = get_db()
    watermark = None if full_refresh else get_watermark(conn, entity)
    log.info("%s extract for %s", "Full" if not watermark else "Incremental", entity)

    buffer, max_ts, ready = [], watermark, False
    for row in paginate(entity, updated_after=watermark):
        if not ready:
            ensure_table(conn, entity, row)
            ready = True
        buffer.append(row)
        ts = row.get("updated_at")
        if ts and (max_ts is None or ts > max_ts):
            max_ts = ts
        if len(buffer) >= 500:
            upsert_rows(conn, entity, buffer)
            buffer = []

    if buffer:
        upsert_rows(conn, entity, buffer)
    if max_ts:
        set_watermark(conn, entity, max_ts)
    conn.close()
    log.info("Done: %s", entity)


def run_all(full_refresh: bool = False):
    for entity in ENTITIES:
        try:
            extract_entity(entity, full_refresh)
        except Exception as e:
            log.error("Failed %s: %s", entity, e)
            raise


if __name__ == "__main__":
    run_all()
