// @ts-nocheck
// ==============================================================================
// FAUNOVA EDGE FUNCTION: ai-gateway
// Mengelola integrasi Gemini API, validasi foto, kuota scan (20/hari WIB),
// dan kuota chat AI (5 standard / 10 verified)
// ==============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.42.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface ScanRequestBody {
  mode: "scan";
  requestId: string;
  imageBase64: string;
  mimeType: string;
  latitude?: number | null;
  longitude?: number | null;
  heading?: number | null;
  isMock?: boolean | null;
}

interface ChatRequestBody {
  mode: "chat";
  scanId: string;
  message: string;
}

type RequestBody = ScanRequestBody | ChatRequestBody;

// Format tanggal WIB (UTC+7)
function getWibDateString(): string {
  const nowUtc = new Date();
  const wibTime = new Date(nowUtc.getTime() + 7 * 60 * 60 * 1000);
  return wibTime.toISOString().split("T")[0];
}

// Hitung SHA-256 dari string base64 / binary bytes
async function calculateSha256(base64Data: string): Promise<string> {
  const binaryString = atob(base64Data);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  const hashBuffer = await crypto.subtle.digest("SHA-256", bytes);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");
}

serve(async (req: Request) => {
  // 1. CORS Preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const geminiApiKey = Deno.env.get("GEMINI_API_KEY");

    if (!supabaseUrl || !geminiApiKey) {
      return new Response(
        JSON.stringify({
          error: "CONFIGURATION_ERROR",
          message: "Server environment variables are incomplete.",
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Client dengan hak admin untuk reservasi kuota dan tabel scans
    const adminClient = createClient(
      supabaseUrl,
      supabaseServiceKey || supabaseAnonKey!
    );

    // 2. Autentikasi Pengguna via JWT
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({
          error: "AUTH_REQUIRED",
          message: "Autentikasi diperlukan untuk mengakses layanan ini.",
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
    } = await adminClient.auth.getUser(token);

    if (authError || !user) {
      return new Response(
        JSON.stringify({
          error: "INVALID_TOKEN",
          message: "Sesi Anda tidak valid atau telah berakhir.",
        }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const body: RequestBody = await req.json();

    // =========================================================================
    // MODE SCAN: Identifikasi Hewan dari Foto
    // =========================================================================
    if (body.mode === "scan") {
      const {
        requestId,
        imageBase64,
        mimeType,
        latitude,
        longitude,
        heading,
        isMock,
      } = body;

      if (!imageBase64 || !mimeType) {
        return new Response(
          JSON.stringify({
            error: "VALIDATION_ERROR",
            message: "Foto dan format MIME wajib disertakan.",
          }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      // Validasi MIME
      const allowedMimes = ["image/jpeg", "image/png", "image/webp"];
      if (!allowedMimes.includes(mimeType.toLowerCase())) {
        return new Response(
          JSON.stringify({
            error: "INVALID_MIME",
            message: "Format foto harus JPG, PNG, atau WebP.",
          }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      // Idempotensi: periksa apakah request_id sudah pernah diproses untuk user ini
      if (requestId) {
        const { data: existingScan } = await adminClient
          .from("scans")
          .select("id, status, is_animal, result, photo_sha256")
          .eq("user_id", user.id)
          .eq("request_id", requestId)
          .maybeSingle();

        if (existingScan) {
          return new Response(
            JSON.stringify({
              scanId: existingScan.id,
              status: existingScan.status,
              isAnimal: existingScan.is_animal,
              result: existingScan.result,
              photoSha256: existingScan.photo_sha256,
              idempotent: true,
            }),
            {
              status: 200,
              headers: { ...corsHeaders, "Content-Type": "application/json" },
            }
          );
        }
      }

      // Kuota Atomik Harian: 20 scan / hari WIB (Anti Race-Condition)
      const dateWib = getWibDateString();
      let scanAllowed = false;
      let currentCount = 0;
      let usedRpcReservation = false;

      const { data: scanRpcData, error: scanRpcErr } = await adminClient.rpc(
        "reserve_scan_quota",
        {
          p_user_id: user.id,
          p_date_wib: dateWib,
          p_max_scans: 20,
        }
      );

      if (!scanRpcErr && scanRpcData && scanRpcData.length > 0) {
        scanAllowed = scanRpcData[0].allowed === true;
        currentCount = scanRpcData[0].current_used_count;
        usedRpcReservation = true;
      } else {
        // Fallback jika migration RPC belum aktif
        const { data: usage } = await adminClient
          .from("daily_scan_usage")
          .select("used_count")
          .eq("user_id", user.id)
          .eq("date_wib", dateWib)
          .maybeSingle();

        currentCount = usage?.used_count ?? 0;
        scanAllowed = currentCount < 20;
      }

      if (!scanAllowed) {
        return new Response(
          JSON.stringify({
            error: "QUOTA_EXCEEDED",
            message:
              "Batas kuota 20 scan harian Anda telah tercapai. Kuota direset besok pk 00:00 WIB.",
          }),
          {
            status: 429,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      // Hitung SHA-256 byte foto
      const photoSha256 = await calculateSha256(imageBase64);

      // Panggil Gemini Vision API (gemini-3.8-flash)
      const prompt =
        "Kamu adalah pakar zoologi dan taksonomi fauna Indonesia untuk aplikasi Faunova. " +
        "Analisis gambar satwa berikut secara cermat. Tentukan apakah gambar ini menampilkan satwa/hewan nyata atau bukan. " +
        "Kembalikan jawaban HANYA berupa JSON valid sesuai skema:\n" +
        "{\n" +
        '  "isAnimal": true/false,\n' +
        '  "name": "Nama umum satwa dalam bahasa Indonesia (atau null jika bukan hewan)",\n' +
        '  "categoryOrSpecies": "Nama ilmiah / taksonomi genus & spesies (atau null jika bukan hewan)",\n' +
        '  "description": "Deskripsi singkat ciri fisik, habitat, dan status konservasi dalam 2-3 kalimat (atau null jika bukan hewan)",\n' +
        '  "additionalFact": "Fakta unik satwa ini dalam 1-2 kalimat (atau pesan peringatan jika bukan hewan: Foto ini tidak memuat satwa)")\n' +
        "}";

      const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent?key=${geminiApiKey}`;
      const geminiPayload = {
        contents: [
          {
            parts: [
              { text: prompt },
              {
                inline_data: {
                  mime_type: mimeType,
                  data: imageBase64,
                },
              },
            ],
          },
        ],
        generationConfig: {
          response_mime_type: "application/json",
          temperature: 0.2,
        },
      };

      const geminiResp = await fetch(geminiUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(geminiPayload),
      });

      if (!geminiResp.ok) {
        const errorText = await geminiResp.text();
        return new Response(
          JSON.stringify({
            error: "PROVIDER_ERROR",
            message: "Layanan identifikasi AI sedang mengalami gangguan.",
            details: errorText,
          }),
          {
            status: 502,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      const geminiData = await geminiResp.json();
      const rawJsonText =
        geminiData.candidates?.[0]?.content?.parts?.[0]?.text;
      const parsedResult = JSON.parse(rawJsonText);

      // Jika tidak menggunakan RPC reservation, update counter sekarang
      if (!usedRpcReservation) {
        await adminClient.from("daily_scan_usage").upsert(
          {
            user_id: user.id,
            date_wib: dateWib,
            used_count: currentCount + 1,
            updated_at: new Date().toISOString(),
          },
          { onConflict: "user_id,date_wib" }
        );
      }

      // Simpan ke tabel public.scans
      const locationCheck =
        isMock === true
          ? "reported_mock"
          : isMock === false
          ? "reported_not_mock"
          : "unknown";

      const scanStatus = parsedResult.isAnimal
        ? "completed"
        : "rejected_not_animal";

      const { data: newScan, error: insertError } = await adminClient
        .from("scans")
        .insert({
          user_id: user.id,
          request_id: requestId || crypto.randomUUID(),
          status: scanStatus,
          is_animal: parsedResult.isAnimal,
          result: parsedResult,
          photo_sha256: photoSha256,
          latitude: latitude ?? null,
          longitude: longitude ?? null,
          camera_heading: heading ?? null,
          location_check: locationCheck,
          received_at: new Date().toISOString(),
        })
        .select("id")
        .single();

      if (insertError) {
        return new Response(
          JSON.stringify({
            error: "DATABASE_ERROR",
            message: "Gagal menyimpan riwayat scan.",
          }),
          {
            status: 500,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      return new Response(
        JSON.stringify({
          scanId: newScan.id,
          status: scanStatus,
          isAnimal: parsedResult.isAnimal,
          result: parsedResult,
          photoSha256: photoSha256,
          quotaUsed: currentCount + 1,
          quotaMax: 20,
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // =========================================================================
    // MODE CHAT: Tanya Jawab Seputar Satwa Hasil Scan (Sesi S6)
    // =========================================================================
    if (body.mode === "chat") {
      const { scanId, message } = body;

      if (!scanId || !message || typeof message !== "string") {
        return new Response(
          JSON.stringify({
            error: "VALIDATION_ERROR",
            message: "scanId dan pertanyaan wajib diisi.",
          }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      const trimmedMessage = message.trim();
      if (trimmedMessage.length === 0) {
        return new Response(
          JSON.stringify({
            error: "VALIDATION_ERROR",
            message: "Pertanyaan tidak boleh kosong.",
          }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      if (trimmedMessage.length > 500) {
        return new Response(
          JSON.stringify({
            error: "VALIDATION_ERROR",
            message: "Pertanyaan maksimal 500 karakter.",
          }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      // Ambil data scan dan pastikan milik pengguna
      const { data: scan, error: scanErr } = await adminClient
        .from("scans")
        .select("id, user_id, is_animal, result, chat_count, status")
        .eq("id", scanId)
        .eq("user_id", user.id)
        .maybeSingle();

      if (scanErr || !scan) {
        return new Response(
          JSON.stringify({
            error: "NOT_FOUND_OR_FORBIDDEN",
            message: "Data scan tidak ditemukan atau bukan milik Anda.",
          }),
          {
            status: 404,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      // Aturan keras: Objek bukan hewan ditolak untuk diajak chat
      if (!scan.is_animal) {
        return new Response(
          JSON.stringify({
            error: "NOT_ANIMAL",
            message: "Fitur tanya jawab hanya tersedia untuk observasi satwa.",
          }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      // Periksa status Centang Biru pengguna untuk batas kuota chat (10 vs 5)
      const { data: profile } = await adminClient
        .from("profiles")
        .select("verified_until")
        .eq("id", user.id)
        .single();

      const isVerified =
        profile?.verified_until &&
        new Date(profile.verified_until) > new Date();

      const chatLimit = isVerified ? 10 : 5;

      // -----------------------------------------------------------------------
      // KUOTA ATOMIK: Eksekusi RPC reserve_chat_quota atau Conditional UPDATE
      // Mencegah race condition dua request paralel menembus batas kuota
      // -----------------------------------------------------------------------
      let isAllowed = false;
      let newChatCount = scan.chat_count;

      const { data: rpcData, error: rpcErr } = await adminClient.rpc(
        "reserve_chat_quota",
        {
          p_scan_id: scan.id,
          p_user_id: user.id,
          p_limit: chatLimit,
        }
      );

      if (!rpcErr && rpcData && rpcData.length > 0) {
        isAllowed = rpcData[0].allowed === true;
        newChatCount = rpcData[0].current_chat_count;
      } else {
        // Fallback: conditional UPDATE langsung di Postgres scans
        const { data: updatedScan, error: updateErr } = await adminClient
          .from("scans")
          .update({ chat_count: scan.chat_count + 1 })
          .eq("id", scan.id)
          .eq("user_id", user.id)
          .eq("is_animal", true)
          .lt("chat_count", chatLimit)
          .select("chat_count")
          .maybeSingle();

        if (updatedScan && !updateErr) {
          isAllowed = true;
          newChatCount = updatedScan.chat_count;
        } else {
          isAllowed = false;
          newChatCount = scan.chat_count;
        }
      }

      if (!isAllowed) {
        return new Response(
          JSON.stringify({
            error: "QUOTA_EXCEEDED",
            message: `Batas ${chatLimit} pertanyaan untuk scan ini telah tercapai.${
              !isVerified ? " Berlangganan Centang Biru untuk kuota hingga 10 pertanyaan." : ""
            }`,
            chatCount: newChatCount,
            chatLimit: chatLimit,
          }),
          {
            status: 429,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      // Ambil riwayat percakapan sebelumnya dari scan_chats
      const { data: chatHistory } = await adminClient
        .from("scan_chats")
        .select("role, content")
        .eq("scan_id", scan.id)
        .order("created_at", { ascending: true })
        .limit(10);

      const animalInfo = scan.result;

      // Bentuk riwayat konteks percakapan multi-turn untuk Gemini
      const geminiContents: Array<{
        role: "user" | "model";
        parts: Array<{ text: string }>;
      }> = [
        {
          role: "user",
          parts: [
            {
              text:
                "Sistem Faunova: Kamu adalah pemandu konservasi satwa dan naturalis lapangan Faunova yang ramah, santun, dan berbasis sains. " +
                `Pengguna sedang berdiskusi mengenai hasil observasi satwa berikut:\n` +
                `- Nama Umum: ${animalInfo?.name || "Satwa Lapangan"}\n` +
                `- Nama Ilmiah / Taksonomi: ${animalInfo?.categoryOrSpecies || "-"}\n` +
                `- Ciri Morfologi & Habitat: ${animalInfo?.description || "-"}\n` +
                `- Catatan Lapangan / Fakta: ${animalInfo?.additionalFact || "-"}\n\n` +
                "Tugasmu: Jawab pertanyaan seputar satwa tersebut secara informatif, lugas, dan ringkas (1-2 paragraf pendek dalam bahasa Indonesia). Jangan berhalusinasi.",
            },
          ],
        },
        {
          role: "model",
          parts: [
            {
              text: `Halo Penjelajah Faunova! Saya siap membantu menjawab pertanyaan Anda mengenai satwa ${animalInfo?.name || "ini"}. Silakan tanyakan apa saja yang ingin Anda ketahui!`,
            },
          ],
        },
      ];

      // Masukkan riwayat pesan sebelumnya
      if (chatHistory && chatHistory.length > 0) {
        for (const historyItem of chatHistory) {
          geminiContents.push({
            role: historyItem.role === "assistant" ? "model" : "user",
            parts: [{ text: historyItem.content }],
          });
        }
      }

      // Masukkan pertanyaan baru pengguna
      geminiContents.push({
        role: "user",
        parts: [{ text: trimmedMessage }],
      });

      const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent?key=${geminiApiKey}`;
      const geminiResp = await fetch(geminiUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: geminiContents,
          generationConfig: {
            temperature: 0.6,
            maxOutputTokens: 350,
          },
        }),
      });

      if (!geminiResp.ok) {
        return new Response(
          JSON.stringify({
            error: "PROVIDER_ERROR",
            message: "Layanan asisten AI sedang sibuk. Silakan coba sesaat lagi.",
          }),
          {
            status: 502,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      const geminiData = await geminiResp.json();
      const rawReply =
        geminiData.candidates?.[0]?.content?.parts?.[0]?.text ||
        "Maaf, asisten tidak dapat memberikan penjelasan saat ini.";
      const reply = rawReply.trim();

      // Simpan riwayat chat ke tabel scan_chats (user message dan assistant reply)
      try {
        await adminClient.from("scan_chats").insert([
          {
            scan_id: scan.id,
            user_id: user.id,
            role: "user",
            content: trimmedMessage,
          },
          {
            scan_id: scan.id,
            user_id: user.id,
            role: "assistant",
            content: reply,
          },
        ]);
      } catch (insertErr) {
        // Log jika tabel belum dibuat, jangan gagalkan balasan chat ke pengguna
        console.warn("Penyimpanan scan_chats gagal:", insertErr);
      }

      return new Response(
        JSON.stringify({
          reply: reply,
          chatCount: newChatCount,
          chatLimit: chatLimit,
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    return new Response(
      JSON.stringify({ error: "INVALID_MODE", message: "Mode tidak dikenali." }),
      {
        status: 400,
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
