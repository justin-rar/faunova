// @ts-nocheck
// ==============================================================================
// FAUNOVA EDGE FUNCTION: create-payment
// Menghasilkan Snap Token Midtrans Sandbox untuk langganan Centang Biru (Rp 15.000)
// Server key HANYA diakses di server, tidak pernah sampai ke klien Flutter.
// ==============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.42.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const BLUE_CHECK_PRICE_IDR = 15000;

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serverKey = Deno.env.get("MIDTRANS_SERVER_KEY");

    if (!supabaseUrl || !serverKey) {
      return new Response(
        JSON.stringify({
          error: "CONFIGURATION_ERROR",
          message: "Kunci server Midtrans belum dikonfigurasi.",
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey!);

    // Autentikasi Pengguna
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({
          error: "AUTH_REQUIRED",
          message: "Autentikasi diperlukan.",
        }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const token = authHeader.replace("Bearer ", "");
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(token);

    if (authError || !user) {
      return new Response(
        JSON.stringify({
          error: "INVALID_TOKEN",
          message: "Sesi pengguna tidak valid.",
        }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Buat order_id kanonis unik
    const orderId = `FAUNOVA-CB-${user.id.slice(0, 8)}-${Date.now()}`;

    // Request Snap Token ke Midtrans Sandbox
    const authString = btoa(`${serverKey}:`);
    const snapUrl = "https://app.sandbox.midtrans.com/snap/v1/transactions";

    const snapPayload = {
      transaction_details: {
        order_id: orderId,
        gross_amount: BLUE_CHECK_PRICE_IDR,
      },
      item_details: [
        {
          id: "centang_biru_30_hari",
          price: BLUE_CHECK_PRICE_IDR,
          quantity: 1,
          name: "Langganan Centang Biru (30 Hari)",
          category: "Subscription",
        },
      ],
      customer_details: {
        first_name: user.user_metadata?.display_name || user.email?.split("@")[0] || "Kolektor",
        email: user.email,
      },
    };

    const midtransResp = await fetch(snapUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        Authorization: `Basic ${authString}`,
      },
      body: JSON.stringify(snapPayload),
    });

    if (!midtransResp.ok) {
      const errorText = await midtransResp.text();
      return new Response(
        JSON.stringify({
          error: "PAYMENT_GATEWAY_ERROR",
          message: "Gagal membuat transaksi pembayaran.",
          details: errorText,
        }),
        {
          status: 502,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const midtransData = await midtransResp.json();

    // Catat transaksi pending ke tabel public.transactions
    const adminServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const adminClient = createClient(supabaseUrl, adminServiceKey || supabaseAnonKey!);

    try {
      await adminClient.from("transactions").insert({
        order_id: orderId,
        user_id: user.id,
        amount_idr: BLUE_CHECK_PRICE_IDR,
        currency: "IDR",
        status: "pending",
        snap_token: midtransData.token,
        redirect_url: midtransData.redirect_url,
        entitlement_days: 30,
      });
    } catch (dbErr) {
      console.warn("Failed to record pending transaction to DB:", dbErr);
    }

    return new Response(
      JSON.stringify({
        orderId,
        token: midtransData.token,
        redirectUrl: midtransData.redirect_url,
        amountIdr: BLUE_CHECK_PRICE_IDR,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    return new Response(
      JSON.stringify({ error: "INTERNAL_ERROR", message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
