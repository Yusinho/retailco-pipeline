-- Lake database initialisation
-- Creates the raw schema and watermark table

CREATE SCHEMA IF NOT EXISTS raw;

-- Watermark table tracks last successful extract per entity
CREATE TABLE IF NOT EXISTS raw._watermarks (
    entity      VARCHAR(100) PRIMARY KEY,
    last_updated_at TIMESTAMPTZ,
    last_run_at     TIMESTAMPTZ DEFAULT NOW()
);

-- Raw entity tables (created by extractor on first run)
-- Defined here for documentation purposes only;
-- the Python extractor uses CREATE TABLE IF NOT EXISTS with UPSERT logic.
