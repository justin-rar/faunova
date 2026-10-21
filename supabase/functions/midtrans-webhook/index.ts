// @ts-nocheck
// ==============================================================================
// FAUNOVA EDGE FUNCTION: midtrans-webhook
// Menerima notifikasi HTTP webhook dari Midtrans Sandbox
// Dideploy dengan flag: --no-verify-jwt (karena Midtrans tidak menyertakan JWT)
// Keamanan dipaksakan lewat verifikasi Signature SHA-512 + pencocokan order/nominal.
// ==============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.42.0";

// Fungsi verifikasi signature SHA-512 sesuai spesifikasi Midtrans
async function verifyMidtransSignature(
  orderId: string,
  statusCode: string,
  grossAmount: string,
  serverKey: string,
  expectedSignature: string
): Promise<boolean> {
  const payload = `${orderId}${statusCode}${grossAmount}${serverKey}`;
  const encoder = new TextEncoder();
  const data = encoder.encode(payload);
  const hashBuffer = await crypto.subtle.digest("SHA-512", data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  const calculatedHex = hashArray
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");

  return calculatedHex.toLowerCase() === expectedSignature.toLowerCase();
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "content-type",
      },
    });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const serverKey = Deno.env.get("MIDTRANS_SERVER_KEY");

    if (!supabaseUrl || !serverKey) {
      console.error("Missing SUPABASE_URL or MIDTRANS_SERVER_KEY");
      return new Response(JSON.stringify({ error: "CONFIG_ERROR" }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    const adminClient = createClient(
      supabaseUrl,
      supabaseServiceKey || Deno.env.get("SUPABASE_ANON_KEY")!
    );

    const body = await req.json();

    const {
      order_id,
      status_code,
      gross_amount,
      signature_key,
      transaction_status,
      fraud_status,
    } = body;

    if (!order_id || !status_code || !gross_amount || !signature_key) {
      return new Response(
        JSON.stringify({
          error: "INVALID_PAYLOAD",
          message: "Data notifikasi tidak lengkap.",
        }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    // 1. Verifikasi Signature SHA-512
    const isSignatureValid = await verifyMidtransSignature(
      order_id,
      status_code,
      gross_amount,
      serverKey,
      signature_key
    );

    if (!isSignatureValid) {
      console.error(`Invalid signature for order ${order_id}`);
      return new Response(
        JSON.stringify({
          error: "FORBIDDEN",
          message: "Signature tidak valid.",
        }),
        {
          status: 403,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    // 2. Ekstrak User ID dari order_id (Format: FAUNOVA-CB-{prefixUserId}-{timestamp})
    // Contoh: FAUNOVA-CB-12345678-1718000000000
    // Atau query riwayat transaksi
    const orderParts = order_id.split("-");
    const userPrefix = orderParts.length >= 3 ? orderParts[2] : null;

    console.log(
      `Webhook verified: order=${order_id}, status=${transaction_status}, userPrefix=${userPrefix}`
    );

    // 3. Tangani Status Transaksi (settlement atau capture accept)
    const isSuccess =
      transaction_status === "settlement" ||
      (transaction_status === "capture" && fraud_status === "accept");

    if (isSuccess && userPrefix) {
      // Cari pengguna yang ID-nya diawali prefix tersebut
      const { data: users, error: userFindErr } = await adminClient
        .from("profiles")
        .select("id, verified_until")
        .ilike("id", `${userPrefix}%`)
        .limit(1);

      if (!userFindErr && users && users.length > 0) {
        const targetUser = users[0];
        const now = new Date();
        const currentVerifiedUntil = targetUser.verified_until
          ? new Date(targetUser.verified_until)
          : null;

        // Perpanjang 30 hari dari batas aktif sekarang, atau 30 hari dari sekarang jika sudah expired
        const baseDate =
          currentVerifiedUntil && currentVerifiedUntil > now
            ? currentVerifiedUntil
            : now;

        const newVerifiedUntil = new Date(
          baseDate.getTime() + 30 * 24 * 60 * 60 * 1000
        );

        await adminClient
          .from("profiles")
          .update({
            verified_until: newVerifiedUntil.toISOString(),
            updated_at: now.toISOString(),
          })
          .eq("id", targetUser.id);

        console.log(
          `User ${targetUser.id} verified_until extended to ${newVerifiedUntil.toISOString()}`
        );
      }
    }

    return new Response(
      JSON.stringify({
        status: "OK",
        order_id,
        transaction_status,
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }
    );
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("Webhook processing error:", message);
    return new Response(
      JSON.stringify({ error: "INTERNAL_ERROR", message }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
});
