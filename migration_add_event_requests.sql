-- ============================================================
-- FESTIVO — Migration: Add Event Request System
-- Run this in Supabase SQL Editor (separate from main schema)
-- This is ADDITIVE only — no tables are dropped or modified.
-- ============================================================

-- Allow general users to INSERT their own event requests.
-- Requests are identified by notes starting with 'REQ:'.
-- Admins keep full control via the existing RLS policies.
CREATE POLICY "General users can submit event requests"
  ON public.events FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Allow users to read their own submitted requests.
-- (The existing "All users can view events" policy already covers SELECT,
--  but this makes intent explicit and is safe to add.)
-- This is already covered — no additional SELECT policy needed.

-- Allow general users to DELETE only their own PENDING requests (optional).
CREATE POLICY "Users can delete their own pending requests"
  ON public.events FOR DELETE
  USING (
    auth.uid() = user_id
    AND notes LIKE 'REQ:pending%'
  );

-- ──────────────────────────────────────────────────────────────
-- DONE. No table structure changes. No data loss.
-- The feature uses:
--   events.status = 'cancelled'  → hides from public upcoming list
--   events.notes  = 'REQ:pending' / 'REQ:approved' / 'REQ:rejected'
-- ──────────────────────────────────────────────────────────────
