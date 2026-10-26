-- ============================================================
-- BOOSTER TCG - SUPABASE DATABASE SCHEMA
-- ============================================================

-- 1. Tabla de Perfiles de Usuario (Para modo sin contraseña con Nickname)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id TEXT UNIQUE NOT NULL,
    nickname TEXT NOT NULL,
    avatar_url TEXT DEFAULT 'default_avatar.png',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    last_login TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Habilitar RLS (Seguridad a nivel de fila)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access on profiles"
    ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Allow insert profile"
    ON public.profiles FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow update own profile"
    ON public.profiles FOR UPDATE USING (true);

-- 2. Tabla de Timers de Sobres Diarios (1-2 sobres al día por juego)
CREATE TABLE IF NOT EXISTS public.daily_pack_timers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    game_type TEXT NOT NULL, -- 'pokemon', 'magic', 'riftbound', 'onepiece'
    last_opened_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    packs_opened_today INT DEFAULT 1,
    CONSTRAINT unique_user_game UNIQUE (user_id, game_type)
);

ALTER TABLE public.daily_pack_timers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access on daily_pack_timers"
    ON public.daily_pack_timers FOR ALL USING (true);

-- 3. Tabla de Colección de Cartas del Usuario (Álbum en la Nube)
CREATE TABLE IF NOT EXISTS public.user_collection (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    card_id TEXT NOT NULL,          -- Identificador único de la carta (ej: 'scryfall_123', 'tcgdex_swsh1_001')
    game_type TEXT NOT NULL,        -- 'pokemon', 'magic', 'riftbound', 'onepiece'
    set_code TEXT NOT NULL,         -- Código de la expansión (ej: '151', 'BLB', 'OP01', 'OR')
    card_name TEXT NOT NULL,
    rarity TEXT NOT NULL,
    image_url TEXT NOT NULL,
    count INT DEFAULT 1,            -- Cuántas copias tiene el usuario
    is_favorite BOOLEAN DEFAULT false,
    first_obtained_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_user_card UNIQUE (user_id, card_id)
);

ALTER TABLE public.user_collection ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow full access on user_collection"
    ON public.user_collection FOR ALL USING (true);

-- 4. Índice para búsquedas rápidas en el álbum
CREATE INDEX IF NOT EXISTS idx_user_collection_search 
    ON public.user_collection (user_id, game_type, set_code);
