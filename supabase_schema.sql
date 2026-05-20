-- ============================================================
-- FESTIVO — Supabase Database Schema (Role-Based)
-- Run this in your Supabase SQL Editor
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─── USER ROLES ───────────────────────────────────────────────
CREATE TYPE user_role AS ENUM ('admin', 'general');

-- ─── PROFILES ────────────────────────────────────────────────
CREATE TABLE public.profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name   TEXT NOT NULL,
  phone       TEXT,
  avatar_url  TEXT,
  bio         TEXT,
  role        user_role NOT NULL DEFAULT 'general',
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view profiles"
  ON public.profiles FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
  ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Admins can update any profile"
  ON public.profiles FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ─── HELPER: check if current user is admin ──────────────────
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ─── TRIGGER: auto-create profile; first user becomes admin ──
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_role user_role;
BEGIN
  IF (SELECT COUNT(*) FROM public.profiles) = 0 THEN
    v_role := 'admin';
  ELSE
    v_role := 'general';
  END IF;
  INSERT INTO public.profiles (id, full_name, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
    v_role
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ─── EVENTS ──────────────────────────────────────────────────
CREATE TYPE event_status AS ENUM ('upcoming', 'ongoing', 'completed', 'cancelled');
CREATE TYPE event_category AS ENUM ('wedding', 'birthday', 'corporate', 'concert', 'festival', 'sports', 'other');

CREATE TABLE public.events (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id        UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title          TEXT NOT NULL,
  description    TEXT,
  category       event_category NOT NULL DEFAULT 'other',
  event_date     DATE NOT NULL,
  event_time     TIME NOT NULL,
  location       TEXT,
  max_guests     INTEGER DEFAULT 0,
  current_guests INTEGER DEFAULT 0,
  cover_image    TEXT,
  status         event_status DEFAULT 'upcoming',
  notes          TEXT,
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  updated_at     TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All users can view events"
  ON public.events FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Admins can create events"
  ON public.events FOR INSERT WITH CHECK (public.is_admin());

CREATE POLICY "Admins can update events"
  ON public.events FOR UPDATE USING (public.is_admin());

CREATE POLICY "Admins can delete events"
  ON public.events FOR DELETE USING (public.is_admin());

-- ─── FOOD ITEMS ───────────────────────────────────────────────
CREATE TYPE food_category AS ENUM ('appetizer', 'main_course', 'dessert', 'beverage', 'snack', 'other');

CREATE TABLE public.food_items (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  event_id        UUID REFERENCES public.events(id) ON DELETE SET NULL,
  name            TEXT NOT NULL,
  description     TEXT,
  category        food_category NOT NULL DEFAULT 'other',
  price           NUMERIC(10,2) DEFAULT 0.00,
  quantity        INTEGER DEFAULT 1,
  quantity_served INTEGER DEFAULT 0,
  image_url       TEXT,
  is_vegetarian   BOOLEAN DEFAULT FALSE,
  is_available    BOOLEAN DEFAULT TRUE,
  notes           TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.food_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All users can view food items"
  ON public.food_items FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Admins can create food items"
  ON public.food_items FOR INSERT WITH CHECK (public.is_admin());

CREATE POLICY "Admins can update food items"
  ON public.food_items FOR UPDATE USING (public.is_admin());

CREATE POLICY "Admins can delete food items"
  ON public.food_items FOR DELETE USING (public.is_admin());

-- ─── UPDATED_AT TRIGGERS ─────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at_profiles
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_updated_at_events
  BEFORE UPDATE ON public.events
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_updated_at_food_items
  BEFORE UPDATE ON public.food_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ─── REALTIME ────────────────────────────────────────────────
-- General users get live updates when admins change events/food.
ALTER PUBLICATION supabase_realtime ADD TABLE public.events;
ALTER PUBLICATION supabase_realtime ADD TABLE public.food_items;

-- ─── USER LIST VIEW (admin use) ──────────────────────────────
CREATE VIEW public.user_list AS
  SELECT p.id, p.full_name, p.phone, p.role, p.created_at, u.email
  FROM public.profiles p
  JOIN auth.users u ON u.id = p.id;

GRANT SELECT ON public.user_list TO authenticated;

-- ─── MIGRATION (if upgrading existing DB) ────────────────────
-- ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS role user_role NOT NULL DEFAULT 'general';
-- ALTER TABLE public.events ADD COLUMN IF NOT EXISTS current_guests INTEGER DEFAULT 0;
-- ALTER TABLE public.events ADD COLUMN IF NOT EXISTS notes TEXT;
-- ALTER TABLE public.food_items ADD COLUMN IF NOT EXISTS quantity_served INTEGER DEFAULT 0;
-- ALTER TABLE public.food_items ADD COLUMN IF NOT EXISTS notes TEXT;
-- ALTER TABLE public.food_items ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
-- Then set your first admin:
-- UPDATE public.profiles SET role = 'admin' WHERE id = '<your-uuid>';

-- ─── EVENT REQUEST SYSTEM (Additive Migration) ───────────────
-- Run this section if you already have the schema above deployed.
-- If running from scratch, everything below is already included.

-- Allow general users to insert their own event requests.
CREATE POLICY IF NOT EXISTS "General users can submit event requests"
  ON public.events FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Allow general users to delete only their own pending requests.
CREATE POLICY IF NOT EXISTS "Users can delete their own pending requests"
  ON public.events FOR DELETE
  USING (
    auth.uid() = user_id
    AND notes LIKE 'REQ:pending%'
  );

-- How the request system works (no schema changes needed):
--   status = 'cancelled' + notes = 'REQ:pending'  → awaiting admin review
--   status = 'upcoming'  + notes = 'REQ:approved' → approved, visible to all
--   status = 'cancelled' + notes = 'REQ:rejected' → rejected by admin
