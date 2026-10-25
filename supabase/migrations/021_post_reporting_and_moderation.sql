-- ==============================================================================
-- FAUNOVA MIGRATION 021: SISTEM PELAPORAN POSTINGAN & MODERASI KOMUNITAS
-- Sesuai acuan: docs/plan_faunova_revisi_5_final.md (Baris 53, 333) & Scope Tingkat 3
-- Aturan Keras AGENTS.md:
-- 1. RLS aktif di tabel public.post_reports
-- 2. Fungsi SECURITY DEFINER wajib menetapkan search_path dan memeriksa auth.uid()
-- 3. Idempoten: 1 pelapor hanya bisa melaporkan 1 postingan sebanyak 1 kali
-- 4. Auto-sembunyikan postingan jika mencapai ambang batas laporan (>= 3 laporan)
-- ==============================================================================

-- 1. TABEL POST_REPORTS
CREATE TABLE IF NOT EXISTS public.post_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    reporter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reason TEXT NOT NULL CHECK (reason IN (
        'bukan_hewan',
        'kekerasan_satwa',
        'lokasi_palsu',
        'spam',
        'ujaran_kebencian',
        'lainnya'
    )),
    notes TEXT DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_post_reporter UNIQUE(post_id, reporter_id)
);

CREATE INDEX IF NOT EXISTS idx_post_reports_post ON public.post_reports(post_id);
CREATE INDEX IF NOT EXISTS idx_post_reports_reporter ON public.post_reports(reporter_id);

-- 2. AKTIFKAN RLS
ALTER TABLE public.post_reports ENABLE ROW LEVEL SECURITY;

-- Pelapor hanya dapat menyisipkan laporannya sendiri
CREATE POLICY "Pengguna dapat melaporkan postingan"
    ON public.post_reports FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = reporter_id);

-- Pelapor hanya dapat melihat daftar laporan miliknya
CREATE POLICY "Pengguna dapat melihat laporannya sendiri"
    ON public.post_reports FOR SELECT
    TO authenticated
    USING (auth.uid() = reporter_id);

-- 3. RPC REPORT_POST
-- Menerima laporan postingan, mencatat ke tabel post_reports, dan auto-sembunyikan jika >= 3 laporan
CREATE OR REPLACE FUNCTION public.report_post(
    p_post_id UUID,
    p_reason TEXT,
    p_notes TEXT DEFAULT ''
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_reporter_id UUID;
    v_author_id UUID;
    v_report_count INT;
    v_is_hidden BOOLEAN := false;
BEGIN
    v_reporter_id := auth.uid();
    IF v_reporter_id IS NULL THEN
        RAISE EXCEPTION 'Pengguna harus masuk untuk melaporkan postingan.';
    END IF;

    -- Validasi keberadaan postingan aktif
    SELECT user_id INTO v_author_id
    FROM public.posts
    WHERE id = p_post_id AND deleted_at IS NULL;

    IF v_author_id IS NULL THEN
        RAISE EXCEPTION 'Postingan tidak ditemukan atau sudah dihapus.';
    END IF;

    -- Cegah melaporkan postingan sendiri
    IF v_author_id = v_reporter_id THEN
        RAISE EXCEPTION 'Anda tidak dapat melaporkan postingan milik Anda sendiri.';
    END IF;

    -- Validasi enum reason
    IF p_reason NOT IN ('bukan_hewan', 'kekerasan_satwa', 'lokasi_palsu', 'spam', 'ujaran_kebencian', 'lainnya') THEN
        RAISE EXCEPTION 'Kategori alasan laporan tidak valid.';
    END IF;

    -- Simpan laporan (idempoten dengan ON CONFLICT DO NOTHING)
    INSERT INTO public.post_reports (
        post_id,
        reporter_id,
        reason,
        notes
    ) VALUES (
        p_post_id,
        v_reporter_id,
        p_reason,
        COALESCE(p_notes, '')
    )
    ON CONFLICT (post_id, reporter_id) 
    DO UPDATE SET 
        reason = EXCLUDED.reason,
        notes = EXCLUDED.notes,
        created_at = now();

    -- Hitung total pelapor unik untuk postingan ini
    SELECT COUNT(*)::INT INTO v_report_count
    FROM public.post_reports
    WHERE post_id = p_post_id;

    -- Auto-sembunyikan postingan jika mencapai ambang batas 3 laporan (Plan 333)
    IF v_report_count >= 3 THEN
        UPDATE public.posts
        SET deleted_at = now()
        WHERE id = p_post_id;
        
        v_is_hidden := true;
    END IF;

    RETURN json_build_object(
        'success', true,
        'message', 'Laporan berhasil dikirim dan akan segera ditinjau tim kurasi.',
        'post_id', p_post_id,
        'is_hidden', v_is_hidden,
        'reports_count', v_report_count
    );
END;
$$;

-- Izin pemanggilan RPC untuk pengguna terotentikasi
GRANT EXECUTE ON FUNCTION public.report_post(UUID, TEXT, TEXT) TO authenticated;
