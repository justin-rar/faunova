-- ==============================================================================
-- FAUNOVA MIGRATION 028: RPC Notifikasi Sosial & Deduplikasi Like
-- Sesuai Dokumen Desain Plan 5.9, Scope Tingkat 3 & AGENTS.md
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.dispatch_social_notification_rpc(
    p_recipient_id UUID,
    p_type TEXT,
    p_title TEXT,
    p_body TEXT,
    p_post_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_actor_id UUID;
    v_existing_id UUID;
    v_notif_id UUID;
BEGIN
    v_actor_id := auth.uid();
    IF v_actor_id IS NULL THEN
        RAISE EXCEPTION 'Akses ditolak: autentikasi diperlukan.'
            USING ERRCODE = '42501';
    END IF;

    -- Aturan keras: Aksi ke diri sendiri tidak membuat notifikasi
    IF v_actor_id = p_recipient_id THEN
        RETURN jsonb_build_object('success', false, 'reason', 'self_action_ignored');
    END IF;

    -- Validasi tipe notifikasi
    IF p_type NOT IN ('follow', 'like', 'system') THEN
        RAISE EXCEPTION 'Tipe notifikasi tidak valid: %', p_type
            USING ERRCODE = '22023';
    END IF;

    -- DEDUPLIKASI: Jika like untuk postingan yang sama dari pelaku yang sama sudah ada,
    -- perbarui waktu created_at dan set is_read = false agar tidak spamming baris baru.
    IF p_type = 'like' AND p_post_id IS NOT NULL THEN
        SELECT id INTO v_existing_id
        FROM public.notifications
        WHERE recipient_id = p_recipient_id
          AND actor_id = v_actor_id
          AND type = 'like'
          AND post_id = p_post_id
        ORDER BY created_at DESC
        LIMIT 1;

        IF v_existing_id IS NOT NULL THEN
            UPDATE public.notifications
            SET created_at = now(),
                is_read = false,
                title = p_title,
                body = p_body
            WHERE id = v_existing_id;

            RETURN jsonb_build_object(
                'success', true,
                'id', v_existing_id,
                'deduplicated', true
            );
        END IF;
    END IF;

    -- DEDUPLIKASI: Jika follow dari pelaku yang sama sudah ada, perbarui waktu created_at
    IF p_type = 'follow' THEN
        SELECT id INTO v_existing_id
        FROM public.notifications
        WHERE recipient_id = p_recipient_id
          AND actor_id = v_actor_id
          AND type = 'follow'
        ORDER BY created_at DESC
        LIMIT 1;

        IF v_existing_id IS NOT NULL THEN
            UPDATE public.notifications
            SET created_at = now(),
                is_read = false,
                title = p_title,
                body = p_body
            WHERE id = v_existing_id;

            RETURN jsonb_build_object(
                'success', true,
                'id', v_existing_id,
                'deduplicated', true
            );
        END IF;
    END IF;

    -- Sisipkan notifikasi baru jika belum ada
    INSERT INTO public.notifications (
        recipient_id,
        actor_id,
        type,
        post_id,
        title,
        body,
        created_at
    ) VALUES (
        p_recipient_id,
        v_actor_id,
        p_type,
        p_post_id,
        p_title,
        p_body,
        now()
    )
    RETURNING id INTO v_notif_id;

    RETURN jsonb_build_object(
        'success', true,
        'id', v_notif_id,
        'deduplicated', false
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.dispatch_social_notification_rpc(UUID, TEXT, TEXT, TEXT, UUID) TO authenticated;
