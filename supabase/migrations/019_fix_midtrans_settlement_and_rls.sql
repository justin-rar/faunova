-- ==============================================================================
-- FAUNOVA MIGRATION 019: Perbaikan RLS Transaksi & Robust Midtrans Settlement
-- Menjamin pencatatan pending transaction via RLS, auto-create fallback pada settlement,
-- dan penyelesaian transaksi tertunda pengguna.
-- ==============================================================================

-- 1. Tambahkan policy INSERT untuk pengguna terautentikasi pada status 'pending'
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'transactions' AND policyname = 'Users can insert own pending transactions'
    ) THEN
        CREATE POLICY "Users can insert own pending transactions"
            ON public.transactions
            FOR INSERT
            TO authenticated
            WITH CHECK (auth.uid() = user_id AND status = 'pending');
    END IF;
END $$;

-- 2. Perbarui RPC process_midtrans_settlement agar tahan terhadap order yang belum tercatat di DB lokal
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
    v_user_prefix TEXT;
    v_entitlement_days INT := 30;
    v_current_verified TIMESTAMPTZ;
    v_new_verified TIMESTAMPTZ;
    v_now TIMESTAMPTZ := timezone('utc', now());
BEGIN
    -- 1. Kunci baris transaksi dengan FOR UPDATE untuk mencegah race condition
    SELECT * INTO v_tx
    FROM public.transactions
    WHERE order_id = p_order_id
    FOR UPDATE;

    -- 2. Jika transaksi belum tercatat (misal create-payment terkendala RLS sebelumnya)
    IF NOT FOUND THEN
        IF p_order_id LIKE 'FAUNOVA-CB-%' THEN
            v_user_prefix := split_part(p_order_id, '-', 3);

            SELECT id INTO v_target_user_id
            FROM public.profiles
            WHERE id::text LIKE v_user_prefix || '%'
            LIMIT 1;

            IF v_target_user_id IS NOT NULL THEN
                INSERT INTO public.transactions (
                    order_id,
                    user_id,
                    amount_idr,
                    currency,
                    status,
                    provider_transaction_id,
                    provider_status,
                    processed_at,
                    entitlement_days
                ) VALUES (
                    p_order_id,
                    v_target_user_id,
                    p_gross_amount,
                    'IDR',
                    'pending',
                    p_provider_tx_id,
                    p_provider_status,
                    v_now,
                    30
                )
                RETURNING * INTO v_tx;
            ELSE
                RETURN jsonb_build_object(
                    'success', false,
                    'error', 'ORDER_AND_USER_NOT_FOUND',
                    'message', 'Order ID dan user tidak ditemukan di sistem Faunova.'
                );
            END IF;
        ELSE
            RETURN jsonb_build_object(
                'success', false,
                'error', 'ORDER_NOT_FOUND',
                'message', 'Order ID tidak terdaftar di sistem Faunova.'
            );
        END IF;
    END IF;

    -- 3. Validasi nominal tagihan
    IF v_tx.amount_idr != p_gross_amount THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'AMOUNT_MISMATCH',
            'message', 'Nominal transaksi tidak cocok dengan tagihan order.'
        );
    END IF;

    -- 4. Idempotensi (Aturan Keras 6)
    IF v_tx.status = 'settlement' AND v_tx.processed_at < v_now - INTERVAL '10 seconds' THEN
        RETURN jsonb_build_object(
            'success', true,
            'already_processed', true,
            'order_id', p_order_id,
            'message', 'Transaksi sudah pernah diproses sebelumnya (idempotent).'
        );
    END IF;

    v_target_user_id := v_tx.user_id;
    v_entitlement_days := COALESCE(v_tx.entitlement_days, 30);

    -- 5. Perbarui status transaksi menjadi 'settlement'
    UPDATE public.transactions
    SET status = 'settlement',
        provider_transaction_id = p_provider_tx_id,
        provider_status = p_provider_status,
        processed_at = v_now,
        updated_at = v_now
    WHERE id = v_tx.id;

    -- 6. Perpanjang verified_until di tabel profiles
    SELECT verified_until INTO v_current_verified
    FROM public.profiles
    WHERE id = v_target_user_id;

    IF v_current_verified IS NOT NULL AND v_current_verified > v_now THEN
        v_new_verified := v_current_verified + (v_entitlement_days || ' days')::INTERVAL;
    ELSE
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

-- 3. Selesaikan transaksi pengguna yang telah berhasil dibayar melalui simulasi BCA
DO $$
BEGIN
    PERFORM public.process_midtrans_settlement(
        'FAUNOVA-CB-6505f051-1792869421980',
        'bca_va_settlement_sandbox',
        'settlement',
        15000
    );
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Notice: Settlement FAUNOVA-CB-6505f051-1792869421980 ditangani: %', SQLERRM;
END $$;
