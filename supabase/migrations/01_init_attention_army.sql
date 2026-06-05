-- Migration: 01_init_attention_army.sql
-- Creates enums, tables and triggers for Attention Army

-- Enums
DO $$ BEGIN
  CREATE TYPE lead_status AS ENUM ('pending', 'contextualizing', 'failed', 'ready_for_review', 'deployed', 'skipped');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE payload_status AS ENUM ('draft', 'approved', 'rejected');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- attention_leads table
CREATE TABLE IF NOT EXISTS attention_leads (
  id BIGSERIAL PRIMARY KEY,
  platform TEXT NOT NULL,
  external_id TEXT NOT NULL,
  author TEXT,
  raw_content TEXT,
  thread_url TEXT,
  status lead_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Unique index on external_id
CREATE UNIQUE INDEX IF NOT EXISTS attention_leads_external_id_idx ON attention_leads (external_id);

-- agent_payloads table
CREATE TABLE IF NOT EXISTS agent_payloads (
  id BIGSERIAL PRIMARY KEY,
  lead_id BIGINT NOT NULL UNIQUE REFERENCES attention_leads(id) ON DELETE CASCADE,
  generated_response TEXT,
  status payload_status NOT NULL DEFAULT 'draft',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Function to update updated_at on update
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for attention_leads
DROP TRIGGER IF EXISTS trg_set_updated_at ON attention_leads;
CREATE TRIGGER trg_set_updated_at
  BEFORE UPDATE ON attention_leads
  FOR EACH ROW EXECUTE PROCEDURE set_updated_at();
