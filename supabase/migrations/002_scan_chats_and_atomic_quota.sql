-- ==============================================================================
-- FAUNOVA - MIGRATION 002: TABEL SCAN_CHATS & FUNGSI ATOMIK KUOTA (Sesi S6)
-- Acuan: AGENTS.md, docs/plan_faunova_revisi_5_final.md Bagian 5.2, 14, 15
-- ==============================================================================

-- 1. TABEL SCAN_CHATS (Riwayat Percakapan AI per Scan)
CREATE TABLE IF NOT EXISTS public.scan_chats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    scan_id UUID NOT NULL REFERENCES public.scans(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
    content TEXT NOT NULL,
    request_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indeks performa riwayat chat
CREATE INDEX IF NOT EXISTS idx_scan_chats_scan_created ON public.scan_chats(scan_id, created_at ASC);
CREATE INDEX IF NOT EXISTS idx_scan_chats_user ON public.scan_chats(user_id);

-- RLS untuk scan_chats
ALTER TABLE public.scan_chats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ScanChats: Pemilik dapat membaca riwayat percakapan sendiri"
    ON public.scan_chats FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "ScanChats: Pemilik dapat menambah pesan percakapan sendiri"
    ON public.scan_chats FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- ==============================================================================
-- 2. FUNGSI ATOMIK: Reservasi Kuota Chat per Scan (Anti Race-Condition)
-- Mencegah dua request paralel menembus batas kuota (5 reguler / 10 Centang Biru)
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.reserve_chat_quota(
    p_scan_id UUID,
    p_user_id UUID,
    p_limit INT
)
RETURNS TABLE(allowed BOOLEAN, current_chat_count INT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_new_count INT;
BEGIN
    -- Update bersyarat dengan kunci baris atomik
    UPDATE public.scans
    SET chat_count = chat_count + 1
    WHERE id = p_scan_id
      AND user_id = p_user_id
      AND is_animal = true
      AND chat_count < p_limit
    RETURNING chat_count INTO v_new_count;

    IF FOUND THEN
        RETURN QUERY SELECT true, v_new_count;
    ELSE
        -- Jika gagal karena kuota habis atau bukan satwa
        SELECT chat_count INTO v_new_count 
        FROM public.scans 
        WHERE id = p_scan_id AND user_id = p_user_id;
        
        RETURN QUERY SELECT false, COALESCE(v_new_count, p_limit);
    END IF;
END;
$$;

-- ==============================================================================
-- 3. FUNGSI ATOMIK: Reservasi Kuota Scan Harian (20 scan/hari WIB)
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.reserve_scan_quota(
    p_user_id UUID,
    p_date_wib DATE,
    p_max_scans INT DEFAULT 20
)
RETURNS TABLE(allowed BOOLEAN, current_used_count INT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_used INT;
BEGIN
    -- Pastikan baris kuota hari ini ada
    INSERT INTO public.daily_scan_usage (user_id, date_wib, used_count, updated_at)
    VALUES (p_user_id, p_date_wib, 0, now())
    ON CONFLICT (user_id, date_wib) DO NOTHING;

    -- Update atomik jika belum melewati batas
    UPDATE public.daily_scan_usage
    SET used_count = used_count + 1, updated_at = now()
    WHERE user_id = p_user_id
      AND date_wib = p_date_wib
      AND used_count < p_max_scans
    RETURNING daily_scan_usage.used_count INTO v_used;

    IF FOUND THEN
        RETURN QUERY SELECT true, v_used;
    ELSE
        SELECT daily_scan_usage.used_count INTO v_used 
        FROM public.daily_scan_usage 
        WHERE user_id = p_user_id AND date_wib = p_date_wib;

        RETURN QUERY SELECT false, COALESCE(v_used, p_max_scans);
    END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.reserve_chat_quota(UUID, UUID, INT) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.reserve_scan_quota(UUID, DATE, INT) TO authenticated, service_role;
