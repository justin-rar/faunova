-- ==============================================================================
-- FAUNOVA MIGRATION 011: Tabel Transaksi & Pemrosesan Pembayaran Midtrans Sandbox
-- Sesuai Plan 5.4, Plan 304, Plan 444, Plan 550 & AGENTS.md (Aturan Keras 2, 3, 6)
-- ==============================================================================

-- 1. Buat Tabel transactions
CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id TEXT UNIQUE NOT NULL,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    amount_idr BIGINT NOT NULL CHECK (amount_idr > 0),
    currency TEXT NOT NULL DEFAULT 'IDR' CHECK (currency = 'IDR'),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'settlement', 'capture', 'deny', 'expire', 'cancel')),
    provider_transaction_id TEXT NULL,
    provider_status TEXT NULL,
    processed_at TIMESTAMPTZ NULL,
    entitlement_days INT NOT NULL DEFAULT 30 CHECK (entitlement_days > 0),
    snap_token TEXT NULL,
    redirect_url TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- Indeks performa query riwayat dan webhook
CREATE INDEX IF NOT EXISTS idx_transactions_user_created ON public.transactions(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_order_id ON public.transactions(order_id);

-- Aktifkan RLS
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

-- Policy RLS: Pengguna hanya boleh membaca transaksi miliknya sendiri
CREATE POLICY "Users can view own transactions"
    ON public.transactions
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

-- Tidak ada policy INSERT/UPDATE untuk role authenticated langsung (Aturan Keras 2 & 6)
-- Pembaruan transaksi dan verified_until HANYA melalui Edge Function service_role atau RPC SECURITY DEFINER.

-- ==============================================================================
-- 2. RPC process_midtrans_settlement (SECURITY DEFINER, Idempotent)
-- ==============================================================================
-- Fungsi ini dipanggil dari Edge Function midtrans-webhook yang telah memvalidasi
-- SHA-512 signature key Midtrans Sandbox dan keaslian request.
CREATE OR REPLACE FUNCTION public.process_midtrans_settlement(
    p_order_id TEXT,
    p_provider_tx_id TEXT,
    p_provider_status TEXT,
    p_gross_amount BIGINT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_tx RECORD;
    v_target_user_id UUID;
    v_entitlement_days INT;
    v_current_verified TIMESTAMPTZ;
    v_new_verified TIMESTAMPTZ;
    v_now TIMESTAMPTZ := timezone('utc', now());
BEGIN
    -- 1. Kunci baris transaksi dengan FOR UPDATE untuk mencegah race condition webhook ganda
    SELECT * INTO v_tx
    FROM public.transactions
    WHERE order_id = p_order_id
    FOR UPDATE;

    -- Jika transaksi tidak ditemukan di tabel lokal
    IF NOT FOUND THEN
        -- Coba ekstrak user_id jika order_id memiliki format standar FAUNOVA-CB-{userIdPrefix}-{ts}
        -- dan catat transaksi baru
        RETURN jsonb_build_object(
            'success', false,
            'error', 'ORDER_NOT_FOUND',
            'message', 'Order ID tidak terdaftar di sistem Faunova.'
        );
    END IF;

    -- 2. Validasi nominal tagihan
    IF v_tx.amount_idr != p_gross_amount THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'AMOUNT_MISMATCH',
            'message', 'Nominal transaksi tidak cocok dengan tagihan order.'
        );
    END IF;

    -- 3. Idempotensi (Aturan Keras 6): Jika sudah berstatus 'settlement', jangan tambah masa aktif lagi!
    IF v_tx.status = 'settlement' THEN
        RETURN jsonb_build_object(
            'success', true,
            'already_processed', true,
            'order_id', p_order_id,
            'message', 'Transaksi sudah pernah diproses sebelumnya (idempotent).'
        );
    END IF;

    v_target_user_id := v_tx.user_id;
    v_entitlement_days := COALESCE(v_tx.entitlement_days, 30);

    -- 4. Perbarui status transaksi menjadi 'settlement'
    UPDATE public.transactions
    SET status = 'settlement',
        provider_transaction_id = p_provider_tx_id,
        provider_status = p_provider_status,
        processed_at = v_now,
        updated_at = v_now
    WHERE id = v_tx.id;

    -- 5. Perpanjang verified_until di tabel profiles
    SELECT verified_until INTO v_current_verified
    FROM public.profiles
    WHERE id = v_target_user_id;

    IF v_current_verified IS NOT NULL AND v_current_verified > v_now THEN
        -- Jika masih aktif, tambahkan 30 hari dari masa aktif yang ada
        v_new_verified := v_current_verified + (v_entitlement_days || ' days')::INTERVAL;
    ELSE
        -- Jika belum aktif atau sudah kadaluwarsa, mulai dari sekarang + 30 hari
        v_new_verified := v_now + (v_entitlement_days || ' days')::INTERVAL;
    END IF;

    UPDATE public.profiles
    SET verified_until = v_new_verified,
        updated_at = v_now
    WHERE id = v_target_user_id;

    RETURN jsonb_build_object(
        'success', true,
        'already_processed', false,
        'order_id', p_order_id,
        'user_id', v_target_user_id,
        'verified_until', v_new_verified,
        'entitlement_days', v_entitlement_days
    );
END;
$$;

-- ==============================================================================
-- 3. RPC get_my_transactions (SECURITY DEFINER)
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.get_my_transactions()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_caller_id UUID := auth.uid();
    v_list JSONB;
BEGIN
    IF v_caller_id IS NULL THEN
        RAISE EXCEPTION 'Autentikasi diperlukan untuk melihat riwayat transaksi.';
    END IF;

    SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY t.created_at DESC), '[]'::jsonb)
    INTO v_list
    FROM (
        SELECT
            order_id,
            amount_idr,
            currency,
            status,
            created_at,
            processed_at,
            entitlement_days
        FROM public.transactions
        WHERE user_id = v_caller_id
    ) t;

    RETURN v_list;
END;
$$;
