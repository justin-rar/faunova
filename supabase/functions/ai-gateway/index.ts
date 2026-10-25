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

interface ResetQuotaRequestBody {
  mode: "reset_quota";
  username?: string;
  userId?: string;
}

type RequestBody = ScanRequestBody | ChatRequestBody | ResetQuotaRequestBody;

// Format tanggal WIB (UTC+7)
function getWibDateString(): string {
  const nowUtc = new Date();
  const wibTime = new Date(nowUtc.getTime() + 7 * 60 * 60 * 1000);
  return wibTime.toISOString().split("T")[0];
}

// Validasi Guardrail Ketat Topik Chat: Menolak tegas pertanyaan di luar fauna (programming, rumus, politik, resep, dll)
function checkOffTopicGuardrail(message: string, animalName?: string): string | null {
  const lower = message.toLowerCase().trim();
  const animal = animalName || "satwa ini";
  const standardRejection = `Maaf, sebagai pemandu konservasi satwa Faunova, saya hanya dapat membantu menjawab pertanyaan seputar satwa, habitat, ekologi, dan perilakunya. Silakan ajukan pertanyaan yang berkaitan dengan ${animal} ya!`;

  // 1. Jailbreak, Prompt Injection, dan Roleplay Bypass
  const jailbreakPatterns = [
    /\b(abaikan (semua )?(aturan|instruksi|perintah)|ignore (all )?(instructions|rules)|lupakan (semua )?(aturan|batasan)|roleplay|pretend you are|kamu sekarang adalah|kamu adalah asisten|bypass|override)\b/i,
  ];

  for (const pattern of jailbreakPatterns) {
    if (pattern.test(lower)) {
      return standardRejection;
    }
  }

  // 2. Keyword & Pola Pertanyaan Pemrograman / Software / Coding
  const programmingPatterns = [
    /\b(program|programming|programmer|coding|koding|koder|developer|software|perangkat lunak|aplikasi mobile|web|website)\b/i,
    /\b(source code|kode program|syntax|sintaks|algoritma|algorithm|pseudocode|script|skrip|script bash|terminal|command line)\b/i,
    /\b(python|javascript|typescript|dart|flutter|java|c\+\+|c\#|golang|rust|html|css|php|sql|nosql|react|vue|node\.?js|bash|git|github)\b/i,
    /\b(function|fungsi|class|kelas|variabel|variable|loop|perulangan|array|debugging|debug|compiler|framework|library|api|endpoint|database)\b/i,
    /\b(print\(|console\.log|void main|import |def |public static void|select \* from)\b/i,
  ];

  for (const pattern of programmingPatterns) {
    if (pattern.test(lower)) {
      return standardRejection;
    }
  }

  // 3. Matematika, Fisika, dan Sains Non-Biologi
  const nonBioSciencePatterns = [
    /\b(matematika|kalkulus|integral|turunan|aljabar|persamaan kuadrat|trigonometri|matriks|bilangan prima|luas segitiga|lingkaran|sudut)\b/i,
    /\b(fisika|kimia|hukum newton|gravitasi|relativitas|einstein|kecepatan cahaya|termodinamika|stoikiometri|reaksi kimia non-biologi)\b/i,
    /(hitung|berapakah|hitunglah)\s+.*([0-9\+\-\*\/\^\(\)\=\.\,]{3,})/i,
  ];

  for (const pattern of nonBioSciencePatterns) {
    if (pattern.test(lower)) {
      return standardRejection;
    }
  }

  // 4. Finansial, Investasi & Politik
  const financeAndPoliticsPatterns = [
    /\b(presiden|menteri|gubernur|bupati|walikota|perdana menteri|dpr|mpr|pemilu|pilpres|pilkada|partai politik|politik|pejabat)\b/i,
    /\b(crypto|kripto|bitcoin|ethereum|saham|investasi|trading|forex|pinjol|pinjaman online|rupiah|dollar|rekening bank)\b/i,
  ];

  for (const pattern of financeAndPoliticsPatterns) {
    if (pattern.test(lower)) {
      return standardRejection;
    }
  }

  // 5. Resep Masakan & Puisi/Lagu/Kuliner Non-Fauna
  const recipesAndGeneralPatterns = [
    /\b(resep|bumbu|cara memasak|cara membuat nasi|membuat kue|bakar rica|ikan bakar|gorengan|soto|rendang|sambal|makanan enak)\b/i,
    /\b(puisi cinta|surat cinta|chord gitar|kunci gitar|lirik lagu)\b/i,
  ];

  for (const pattern of recipesAndGeneralPatterns) {
    if (pattern.test(lower)) {
      return standardRejection;
    }
  }

  return null;
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

// Ekstraksi JSON bersih dari teks output Gemini (menghapus blok markdown ```json ... ```)
function extractCleanJson(rawText: string): any {
  let cleaned = rawText.trim();
  if (cleaned.startsWith("```json")) {
    cleaned = cleaned.replace(/^```json\s*/i, "").replace(/\s*```$/, "");
  } else if (cleaned.startsWith("```")) {
    cleaned = cleaned.replace(/^```\s*/, "").replace(/\s*```$/, "");
  }
  const firstBrace = cleaned.indexOf("{");
  const lastBrace = cleaned.lastIndexOf("}");
  if (firstBrace !== -1 && lastBrace !== -1 && lastBrace > firstBrace) {
    cleaned = cleaned.substring(firstBrace, lastBrace + 1);
  }
  return JSON.parse(cleaned);
}

// Konversi base64 string ke array angka byte (diperlukan untuk endpoint REST Cloudflare Workers AI)
function base64ToByteArray(base64: string): number[] {
  const binaryString = atob(base64);
  const bytes = new Array<number>(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes;
}

// Panggil Cloudflare Workers AI Vision (Llama 3.2 11B Vision Instruct & MiniMax M3.1 Flash)
async function callCloudflareVision(
  accountId: string,
  apiToken: string,
  prompt: string,
  mimeType: string,
  imageBase64: string,
  timeoutMs = 25000
): Promise<{ ok: boolean; data?: any; error?: string }> {
  // 1. Coba native Cloudflare Llama 3.2 11B Vision (Gratis, cepat di edge, token & account aktif)
  try {
    const bytes = base64ToByteArray(imageBase64);
    const runUrl = `https://api.cloudflare.com/client/v4/accounts/${accountId}/ai/run/@cf/meta/llama-3.2-11b-vision-instruct`;
    const resp = await fetch(runUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiToken}`,
      },
      body: JSON.stringify({
        prompt: prompt,
        image: bytes,
        max_tokens: 1024,
      }),
      signal: AbortSignal.timeout(timeoutMs),
    });

    if (resp.ok) {
      const json = await resp.json();
      const raw = json.result?.response;
      if (raw) {
        if (typeof raw === "object") {
          return { ok: true, data: raw };
        }
        try {
          return { ok: true, data: extractCleanJson(String(raw)) };
        } catch (parseErr) {
          console.warn("Gagal parse raw JSON string:", parseErr, raw);
        }
      }
    } else {
      const errText = await resp.text();
      console.warn("Cloudflare Llama Vision non-ok:", resp.status, errText);
    }
  } catch (err: any) {
    console.warn("Cloudflare Llama Vision error:", err.message);
  }

  // 2. Coba MiniMax M3.1 Flash via OpenAI chat/completions (jika tersedia kredit/BYOK)
  try {
    const completionsUrl = `https://api.cloudflare.com/client/v4/accounts/${accountId}/ai/v1/chat/completions`;
    const payload = {
      model: "minimax/m3.1-flash",
      messages: [
        {
          role: "user",
          content: [
            {
              type: "image_url",
              image_url: { url: `data:${mimeType};base64,${imageBase64}` },
            },
            { type: "text", text: prompt },
          ],
        },
      ],
      temperature: 0.1,
    };

    const resp = await fetch(completionsUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiToken}`,
      },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(timeoutMs),
    });

    if (resp.ok) {
      const json = await resp.json();
      const rawContent = json.choices?.[0]?.message?.content;
      if (rawContent) {
        return { ok: true, data: extractCleanJson(rawContent) };
      }
    }
  } catch (err: any) {
    console.warn("Cloudflare MiniMax error:", err.message);
  }

  return { ok: false, error: "Cloudflare Vision gagal diproses" };
}

// Panggil Cloudflare Workers AI untuk Chat Multi-turn
async function callCloudflareChat(
  accountId: string,
  apiToken: string,
  messages: Array<{ role: string; content: string }>,
  timeoutMs = 25000
): Promise<{ ok: boolean; reply?: string; error?: string }> {
  try {
    const completionsUrl = `https://api.cloudflare.com/client/v4/accounts/${accountId}/ai/v1/chat/completions`;
    const payload = {
      model: "@cf/meta/llama-3.2-11b-vision-instruct",
      messages: messages,
      temperature: 0.6,
      max_tokens: 600,
    };

    const resp = await fetch(completionsUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiToken}`,
      },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(timeoutMs),
    });

    if (resp.ok) {
      const json = await resp.json();
      const text = json.choices?.[0]?.message?.content?.trim();
      if (text) {
        return { ok: true, reply: text };
      }
    }
  } catch (err: any) {
    console.warn("Cloudflare Chat error:", err.message);
  }

  return { ok: false, error: "Cloudflare Chat gagal" };
}

// Panggil Gemini API (kompatibilitas gemini-3.8-flash, gemini-2.5-flash, gemini-2.0-flash, & gemini-1.5-flash-latest)
async function callGemini(
  geminiApiKey: string,
  payload: any,
  models = ["gemini-2.5-flash", "gemini-2.0-flash", "gemini-1.5-flash-latest"],
  timeoutMs = 25000
): Promise<Response> {
  let lastErrorText = "";
  let lastStatus = 502;

  for (const model of models) {
    try {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${geminiApiKey}`;
      const resp = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
        signal: AbortSignal.timeout(timeoutMs),
      });

      if (resp.ok) {
        return resp;
      }

      lastStatus = resp.status;
      lastErrorText = await resp.text();
      console.warn(`Model ${model} gagal status ${lastStatus}: ${lastErrorText}. Mencoba model fallback.`);
    } catch (err: any) {
      console.warn(`Model ${model} request error: ${err.message}. Mencoba model fallback.`);
      lastErrorText = err.message;
    }
  }

  // Bersihkan format JSON mentah dari pesan kesalahan Google
  let cleanErrorMessage = lastErrorText;
  try {
    const parsed = JSON.parse(lastErrorText);
    if (parsed.error?.message) {
      cleanErrorMessage = parsed.error.message;
    }
  } catch (_) {}

  return new Response(
    JSON.stringify({
      error: "PROVIDER_ERROR",
      message: `Layanan identifikasi AI: ${cleanErrorMessage.substring(0, 160)}`,
      details: lastErrorText,
    }),
    { status: lastStatus >= 400 && lastStatus < 600 ? lastStatus : 502 }
  );
}

// Panggil DeepSeek API untuk Chat Tanya-Jawab (Fallback jika Gemini sibuk/limit)
async function callDeepSeekChat(
  apiKey: string,
  messages: Array<{ role: string; content: string }>,
  timeoutMs = 25000
): Promise<{ ok: boolean; reply?: string; error?: string }> {
  try {
    const completionsUrl = "https://api.deepseek.com/chat/completions";
    const models = ["deepseek-flash", "deepseek-chat"];

    for (const model of models) {
      try {
        const payload = {
          model: model,
          messages: messages,
          temperature: 0.6,
          max_tokens: 1000,
        };

        const resp = await fetch(completionsUrl, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${apiKey}`,
          },
          body: JSON.stringify(payload),
          signal: AbortSignal.timeout(timeoutMs),
        });

        if (resp.ok) {
          const json = await resp.json();
          const text = json.choices?.[0]?.message?.content?.trim();
          if (text) {
            return { ok: true, reply: text };
          }
        } else {
          const errText = await resp.text();
          console.warn(`DeepSeek Chat model ${model} status ${resp.status}:`, errText);
          if (errText.includes("Insufficient Balance")) {
            return { ok: false, error: "Insufficient Balance" };
          }
        }
      } catch (mErr: any) {
        console.warn(`DeepSeek Chat model ${model} request error:`, mErr.message);
      }
    }
  } catch (err: any) {
    console.warn("DeepSeek Chat error:", err.message);
    return { ok: false, error: err.message };
  }

  return { ok: false, error: "DeepSeek Chat tidak menghasilkan respons" };
}

// Panggil DeepSeek API untuk Identifikasi Satwa Vision (DeepSeek-V4.1-Flash multimodal)
async function callDeepSeekVision(
  apiKey: string,
  prompt: string,
  mimeType: string,
  imageBase64: string,
  timeoutMs = 30000
): Promise<{ ok: boolean; data?: any; error?: string }> {
  const completionsUrl = "https://api.deepseek.com/chat/completions";
  const models = ["deepseek-flash", "deepseek-v4-flash-vision-exp", "deepseek-chat"];
  let lastErrText = "";

  for (const model of models) {
    try {
      const payload = {
        model: model,
        messages: [
          {
            role: "user",
            content: [
              {
                type: "image_url",
                image_url: { url: `data:${mimeType};base64,${imageBase64}` },
              },
              { type: "text", text: prompt },
            ],
          },
        ],
        temperature: 0.1,
      };

      const resp = await fetch(completionsUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${apiKey}`,
        },
        body: JSON.stringify(payload),
        signal: AbortSignal.timeout(timeoutMs),
      });

      if (resp.ok) {
        const json = await resp.json();
        const rawContent = json.choices?.[0]?.message?.content;
        if (rawContent) {
          return { ok: true, data: extractCleanJson(rawContent) };
        }
      } else {
        const errText = await resp.text();
        console.warn(`DeepSeek Vision model ${model} non-ok:`, resp.status, errText);
        lastErrText = errText;
        if (errText.includes("Insufficient Balance")) {
          return { ok: false, error: "Insufficient Balance" };
        }
      }
    } catch (err: any) {
      console.warn(`DeepSeek Vision model ${model} error:`, err.message);
      lastErrText = err.message;
    }
  }

  return { ok: false, error: lastErrText || "DeepSeek Vision gagal diproses" };
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
    const cloudflareApiToken = Deno.env.get("CLOUDFLARE_API_TOKEN");
    const cloudflareAccountId = Deno.env.get("CLOUDFLARE_ACCOUNT_ID");
    const deepseekApiKey = Deno.env.get("DEEPSEEK_API_KEY");

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

    const body: RequestBody = await req.json();

    // =========================================================================
    // MODE RESET QUOTA: Reset Kuota Scan Harian (Untuk Testing Akun WowokTT)
    // =========================================================================
    if (body.mode === "reset_quota") {
      const targetUsername = (body.username || "WowokTT").trim();
      console.log(`Mereset kuota scan harian untuk akun '${targetUsername}'...`);

      // Cari di public.profiles
      const { data: profile } = await adminClient
        .from("profiles")
        .select("id, username")
        .ilike("username", targetUsername)
        .maybeSingle();

      let targetUserId = profile?.id;

      if (!targetUserId) {
        try {
          const { data: usersData } = await adminClient.auth.admin.listUsers();
          const found = usersData?.users?.find(
            (u: any) =>
              u.user_metadata?.username?.toLowerCase() === targetUsername.toLowerCase() ||
              u.email?.toLowerCase().includes(targetUsername.toLowerCase())
          );
          if (found) targetUserId = found.id;
        } catch (_) {}
      }

      if (!targetUserId) {
        const { data: allProfiles } = await adminClient
          .from("profiles")
          .select("id, username")
          .limit(10);

        return new Response(
          JSON.stringify({
            error: "USER_NOT_FOUND",
            message: `User '${targetUsername}' tidak ditemukan di sistem.`,
            existingProfiles: allProfiles,
          }),
          {
            status: 404,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      // Hapus data daily_scan_usage lama untuk user ini
      await adminClient
        .from("daily_scan_usage")
        .delete()
        .eq("user_id", targetUserId);

      // Inisialisasi ulang kuota menjadi 0 hari ini
      const dateWib = getWibDateString();
      await adminClient.from("daily_scan_usage").upsert(
        {
          user_id: targetUserId,
          date_wib: dateWib,
          used_count: 0,
          updated_at: new Date().toISOString(),
        },
        { onConflict: "user_id,date_wib" }
      );

      return new Response(
        JSON.stringify({
          success: true,
          message: `Kuota scan harian untuk akun '${targetUsername}' berhasil di-reset menjadi 0 / 20.`,
          userId: targetUserId,
          username: profile?.username || targetUsername,
          dateWib: dateWib,
          usedCount: 0,
          maxQuota: 20,
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // 2. Autentikasi Pengguna via JWT (untuk mode scan & chat)
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

      // Kuota Harian WIB: 20 scan / hari (Pengecekan Kuota di Awal Tanpa Memotong)
      const dateWib = getWibDateString();
      const { data: usage } = await adminClient
        .from("daily_scan_usage")
        .select("used_count")
        .eq("user_id", user.id)
        .eq("date_wib", dateWib)
        .maybeSingle();

      let currentCount = usage?.used_count ?? 0;
      let scanAllowed = currentCount < 20;

      // Pengecekan akun tester developer (WowokTT)
      let isTesterAccount = false;
      try {
        const { data: up } = await adminClient
          .from("profiles")
          .select("username")
          .eq("id", user.id)
          .maybeSingle();

        isTesterAccount =
          up?.username?.toLowerCase() === "wowoktt" ||
          user.user_metadata?.username?.toLowerCase() === "wowoktt" ||
          (user.email && user.email.toLowerCase().includes("wowok"));
      } catch (_) {}

      if (isTesterAccount && !scanAllowed) {
        console.log("Akun tester WowokTT mencapai batas scan, auto-reset kuota ke 0 untuk testing.");
        await adminClient.from("daily_scan_usage").upsert(
          {
            user_id: user.id,
            date_wib: dateWib,
            used_count: 0,
            updated_at: new Date().toISOString(),
          },
          { onConflict: "user_id,date_wib" }
        );
        scanAllowed = true;
        currentCount = 0;
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

      // Prompt identifikasi satwa Faunova (Objektif: Temukan dan identifikasi satwa nyata non-manusia)
      const prompt =
        "Kamu adalah pakar zoologi dan taksonomi fauna Indonesia untuk aplikasi observasi satwa Faunova.\n" +
        "TUGAS UTAMA: Periksa apakah di dalam foto terdapat SATWA/HEWAN NYATA (Kingdom Animalia non-manusia: mamalia, burung, reptil, amfibi, ikan, serangga, laba-laba, moluska, dll) baik di alam bebas maupun peliharaan.\n\n" +
        "PANDUAN KLASIFIKASI OBJEKTIF:\n" +
        "1. JIKA TERDAPAT SATWA DI FOTO (PRIORITAS UTAMA):\n" +
        "   - Satwa sering kali berada di dahan pohon, di antara dedaunan/tanaman, di atas rumput/tanah, di air, di dinding, atau memiliki latar belakang lingkungan alami/buatan. JIKA ADA SATWA DI GAMBAR, FOKUSLAH PADA SATWA TERSEBUT dan WAJIB tetapkan \"isAnimal\": true!\n" +
        "   - Jangan sekali-kali menolak satwa hanya karena latar belakangnya berupa tanaman, pohon, kandang, lantai, atau benda sekitar.\n" +
        "   - Tentukan nama umum satwa dalam bahasa Indonesia, nama ilmiah latin (Genus species), deskripsi ciri morfologi & habitat alami, serta fakta uniknya.\n" +
        "2. JIKA SAMA SEKALI TIDAK ADA SATWA (BUKAN SATWA):\n" +
        "   - Tetapkan \"isAnimal\": false HANYA jika foto BENAR-BENAR TIDAK MEMUAT SATWA SAMA SEKALI, yaitu:\n" +
        "     a. Foto manusia (Homo sapiens, orang, wajah manusia, selfie, tubuh manusia). Faunova khusus untuk fauna non-manusia.\n" +
        "     b. Foto murni tanaman/tumbuhan/bunga/pohon tanpa ada hewan di atasnya.\n" +
        "     c. Benda mati, laptop/elektronik, kendaraan, perabotan, makanan/minuman olahan manusia, mainan/boneka, gambar kartun/logo, atau foto layar.\n" +
        "   - Untuk bukan satwa, isi \"name\": null, \"categoryOrSpecies\": null, \"description\": null, dan \"additionalFact\" jelaskan secara ramah objek apa yang terpotret (misal: 'Foto memuat manusia (Homo sapiens)', 'Foto hanya memuat tanaman/bunga', 'Foto memuat benda mati').\n\n" +
        "Format respon JSON WAJIB:\n" +
        "Jika SATWA NYATA DITEMUKAN:\n" +
        "{\n" +
        '  "isAnimal": true,\n' +
        '  "name": "Nama satwa dalam bahasa Indonesia",\n' +
        '  "categoryOrSpecies": "Nama ilmiah latin (Genus species)",\n' +
        '  "description": "Deskripsi ciri fisik satwa, habitat alami, dan status konservasi",\n' +
        '  "additionalFact": "Fakta unik satwa ini"\n' +
        "}\n" +
        "Jika BUKAN SATWA / Manusia / Tanaman murni / Benda mati:\n" +
        "{\n" +
        '  "isAnimal": false,\n' +
        '  "name": null,\n' +
        '  "categoryOrSpecies": null,\n' +
        '  "description": null,\n' +
        '  "additionalFact": "Foto ini tidak memuat satwa (misal: memuat manusia atau benda mati)"\n' +
        "}";

      let parsedResult: any = null;
      let usedAiProvider = "Google Gemini Flash";

      // 1. PRIORITAS UTAMA: Google Gemini Flash (Multimodal Vision)
      if (geminiApiKey) {
        try {
          console.log("Menganalisis foto satwa dengan Google Gemini Flash...");
          const geminiPayload = {
            contents: [
              {
                parts: [
                  { text: prompt },
                  {
                    inlineData: {
                      mimeType: mimeType,
                      data: imageBase64,
                    },
                  },
                ],
              },
            ],
            generationConfig: {
              responseMimeType: "application/json",
              temperature: 0.1,
              maxOutputTokens: 800,
            },
          };

          const geminiResp = await callGemini(
            geminiApiKey,
            geminiPayload,
            ["gemini-2.5-flash", "gemini-2.0-flash", "gemini-1.5-flash-latest"],
            25000
          );

          if (geminiResp.ok) {
            const geminiData = await geminiResp.json();
            const parts = geminiData.candidates?.[0]?.content?.parts;
            const answerPart =
              parts?.find((p: any) => !p.thought && typeof p.text === "string" && p.text.trim().length > 0) ||
              parts?.[parts.length - 1];
            const rawJsonText =
              answerPart?.text ||
              geminiData.candidates?.[0]?.content?.parts?.[0]?.text ||
              "{}";
            parsedResult = extractCleanJson(rawJsonText);
            usedAiProvider = "Google Gemini Flash";
            console.log("Identifikasi satwa sukses via Google Gemini Flash");
          } else {
            const errorText = await geminiResp.text();
            console.warn("Google Gemini Flash gagal status", geminiResp.status, errorText, "Mencoba fallback...");
          }
        } catch (geminiErr: any) {
          console.warn("Google Gemini Flash exception:", geminiErr?.message || geminiErr, "Mencoba fallback...");
        }
      }

      // 2. CADANGAN 1: Cloudflare Workers AI Vision (jika Gemini terkendala)
      if (!parsedResult && cloudflareApiToken && cloudflareAccountId) {
        try {
          console.log("Mencoba cadangan Cloudflare Workers AI Vision...");
          const cfResult = await callCloudflareVision(
            cloudflareAccountId,
            cloudflareApiToken,
            prompt,
            mimeType,
            imageBase64
          );
          if (cfResult.ok && cfResult.data) {
            parsedResult = cfResult.data;
            usedAiProvider = "Cloudflare Llama 3.2 Vision (Cadangan)";
            console.log("Identifikasi satwa sukses via cadangan Cloudflare Workers AI Vision");
          }
        } catch (cfErr: any) {
          console.warn("Cloudflare Vision error:", cfErr?.message || cfErr);
        }
      }

      // 3. CADANGAN 2: DeepSeek Vision API (jika Gemini dan Cloudflare terkendala)
      if (!parsedResult && deepseekApiKey) {
        try {
          console.log("Mencoba cadangan DeepSeek Vision API...");
          const dsResult = await callDeepSeekVision(
            deepseekApiKey,
            prompt,
            mimeType,
            imageBase64,
            30000
          );
          if (dsResult.ok && dsResult.data) {
            parsedResult = dsResult.data;
            usedAiProvider = "DeepSeek Vision (Cadangan)";
            console.log("Identifikasi satwa sukses via cadangan DeepSeek Vision API");
          } else {
            console.warn("DeepSeek Vision cadangan belum menghasilkan data:", dsResult.error);
          }
        } catch (dsErr: any) {
          console.warn("DeepSeek Vision cadangan error:", dsErr?.message || dsErr);
        }
      }

      if (!parsedResult) {
        console.error("Seluruh provider AI Vision gagal.");
        return new Response(
          JSON.stringify({
            error: "PROVIDER_ERROR",
            message: "Layanan identifikasi AI sedang sibuk atau mengalami kendala jaringan. Silakan coba sesaat lagi.",
          }),
          {
            status: 502,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      // Sanitasi & Validasi ketat hasil isAnimal di sisi server
      let isAnimal = parsedResult?.isAnimal === true;
      const additionalFactStr = String(parsedResult?.additionalFact || "").toLowerCase();
      const nameStr = String(parsedResult?.name || "").toLowerCase();
      const speciesStr = String(parsedResult?.categoryOrSpecies || "").toLowerCase();

      // Periksa manusia (Homo sapiens, orang, selfie)
      const isHuman =
        speciesStr.includes("homo sapiens") ||
        speciesStr.startsWith("homo ") ||
        nameStr === "manusia" ||
        nameStr === "orang" ||
        nameStr === "selfie" ||
        nameStr.includes("wajah manusia");

      // Periksa flora murni pada nama/spesies (bukan pada deskripsi diet/habitat satwa)
      const isPureFloraName =
        (nameStr.startsWith("pohon ") ||
          nameStr.startsWith("tanaman ") ||
          nameStr.startsWith("bunga ") ||
          nameStr === "kopi" ||
          nameStr === "teh" ||
          speciesStr.startsWith("coffea ")) &&
        !nameStr.includes("kupu") &&
        !nameStr.includes("burung") &&
        !nameStr.includes("serangga") &&
        !nameStr.includes("kumbang");

      // Periksa penolakan eksplisit dari AI
      const isExplicitlyRejected =
        additionalFactStr.includes("tidak memuat satwa") ||
        additionalFactStr.includes("bukan satwa") ||
        additionalFactStr.includes("bukan hewan") ||
        !parsedResult?.name ||
        nameStr === "null";

      if (isHuman || isPureFloraName || isExplicitlyRejected) {
        isAnimal = false;
        if (parsedResult) {
          parsedResult.isAnimal = false;
          parsedResult.name = null;
          parsedResult.categoryOrSpecies = null;
          parsedResult.description = null;
          if (isHuman) {
            parsedResult.additionalFact = "Foto memuat manusia (Homo sapiens). Faunova khusus untuk katalog satwa dan fauna non-manusia.";
          } else if (isPureFloraName) {
            parsedResult.additionalFact = "Foto memuat flora/tanaman murni, bukan satwa.";
          } else {
            parsedResult.additionalFact = "Foto ini tidak memuat satwa.";
          }
        }
      }

      // Pemotongan Kuota Harian:
      // Kuota HANYA dipotong jika AI BERHASIL menganalisis foto (baik satwa maupun bukan satwa).
      // Jika AI error / gagal di atas, kuota user tetap utuh tanpa dipotong.
      const newQuotaUsed = currentCount + 1;
      await adminClient.from("daily_scan_usage").upsert(
        {
          user_id: user.id,
          date_wib: dateWib,
          used_count: newQuotaUsed,
          updated_at: new Date().toISOString(),
        },
        { onConflict: "user_id,date_wib" }
      );

      // Simpan ke tabel public.scans
      const locationCheck =
        isMock === true
          ? "reported_mock"
          : isMock === false
          ? "reported_not_mock"
          : "unknown";

      const scanStatus = isAnimal
        ? "completed"
        : "rejected_not_animal";

      const { data: newScan, error: insertError } = await adminClient
        .from("scans")
        .insert({
          user_id: user.id,
          request_id: requestId || crypto.randomUUID(),
          status: scanStatus,
          is_animal: isAnimal,
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

      // Generate 5 soal kuis AI secara otomatis untuk memperluas bank soal (Plan Crowdsourced Quiz)
      if (isAnimal && parsedResult?.name && parsedResult?.categoryOrSpecies) {
        (async () => {
          try {
            const animalName = parsedResult.name;
            const speciesName = parsedResult.categoryOrSpecies;
            const desc = parsedResult.description || "";
            const fact = parsedResult.additionalFact || "";
            const firstGenus = speciesName.trim().split(" ")[0] || "Fauna";

            const generatedQuestions = [
              {
                category: "Fauna",
                question: `Satwa "${animalName}" (${speciesName}) diklasifikasikan ke dalam taksonomi genus...`,
                options: [firstGenus, "Panthera", "Varanus", "Macaca"],
                correct_option: 0,
                explanation: `${animalName} diklasifikasikan ke dalam genus ${firstGenus}.`,
                is_active: true,
              },
              {
                category: "Fauna",
                question: `Berdasarkan pengamatan lapangan, adaptasi utama satwa "${animalName}" (${speciesName}) adalah...`,
                options: [
                  desc || "Beradaptasi secara alami pada ekosistem hutan tropis Indonesia.",
                  "Hidup di kutub es tanpa vegetasi tanaman.",
                  "Hanya mengonsumsi bebatuan vulkanik kering.",
                  "Memiliki sayap berselaput untuk menyelam di palung laut.",
                ],
                correct_option: 0,
                explanation: `${animalName}: ${desc || "Satwa khas ekosistem nusantara."}`,
                is_active: true,
              },
              {
                category: "Konservasi",
                question: `Fakta unik biologi mengenai satwa "${animalName}" di alam liar adalah...`,
                options: [
                  fact || "Memiliki peran penting menjaga keseimbangan rantai makanan habitat aslinya.",
                  "Dapat memancarkan sinar laser saat musim kemarau.",
                  "Tidak memerlukan air minum sepanjang masa hidupnya.",
                  "Dapat terbang melintasi samudra dalam hitungan menit.",
                ],
                correct_option: 0,
                explanation: fact || "Satwa ini memiliki peranan penting dalam keanekaragaman hayati.",
                is_active: true,
              },
              {
                category: "Fauna",
                question: `Di habitat alaminya, satwa "${animalName}" berfungsi penting menjaga kelestarian alam sebagai...`,
                options: [
                  "Bagian dari rantai makanan dan keseimbangan biodiversitas ekosistem",
                  "Hama perusak mutlak yang harus dimusnahkan",
                  "Parasit mematikan bagi semua pohon hutan",
                  "Satwa pengganggu tanpa peranan ekologis",
                ],
                correct_option: 0,
                explanation: `Setiap satwa seperti ${animalName} memiliki peran spesifik menjaga kelangsungan ekosistem alam.`,
                is_active: true,
              },
              {
                category: "Taksonomi",
                question: `Nama ilmiah binomial resmi yang diakui dalam zoologi internasional untuk "${animalName}" adalah...`,
                options: [
                  speciesName,
                  "Canis lupus familiaris",
                  "Felis catus domesticus",
                  "Gallus gallus domesticus",
                ],
                correct_option: 0,
                explanation: `Tata nama ilmiah resmi untuk satwa ${animalName} adalah ${speciesName}.`,
                is_active: true,
              },
            ];

            await adminClient.from("quiz_questions").upsert(
              generatedQuestions,
              { onConflict: "question", ignoreDuplicates: true }
            );
            console.log(`Berhasil menambahkan 5 soal kuis dinamis untuk ${animalName} ke database.`);
          } catch (quizErr) {
            console.warn("Gagal membuat soal kuis dinamis di background:", quizErr);
          }
        })();
      }

      return new Response(
        JSON.stringify({
          scanId: newScan.id,
          status: scanStatus,
          isAnimal: isAnimal,
          result: parsedResult,
          photoSha256: photoSha256,
          quotaUsed: newQuotaUsed,
          quotaMax: 20,
          aiProvider: usedAiProvider,
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
                "ATURAN BATASAN TOPIK (GUARDRAIL KERAS):\n" +
                "1. Fokus Khusus: Kamu HANYA boleh menjawab pertanyaan seputar satwa ini (" +
                (animalInfo?.name || "satwa") +
                "), biologi satwa, ekologi, perilaku, taksonomi, pola makan, siklus hidup, habitat, atau upaya konservasi satwa liar.\n" +
                "2. Penolakan Tegas Topik di Luar Satwa: Jika pengguna menanyakan topik di luar satwa/fauna (seperti pemrograman/coding, matematika/hitungan, rumus, tugas sekolah non-fauna, politik, resep masakan manusia, atau obrolan umum yang tidak berkaitan dengan satwa), kamu WAJIB MENOLAKNYA SECARA SOPAN DAN MENOLAK MEMBERIKAN JAWABAN TOPIK TERSEBUT. Ingatkan pengguna bahwa kamu adalah pemandu satwa Faunova dan arahkan mereka kembali untuk bertanya seputar satwa ini.\n" +
                "Contoh penolakan: 'Maaf, sebagai pemandu konservasi satwa Faunova, saya hanya dapat membantu menjawab pertanyaan seputar satwa, habitat, dan ekologinya. Silakan ajukan pertanyaan yang berkaitan dengan " +
                (animalInfo?.name || "satwa ini") +
                " ya!'\n" +
                "3. Format Respons: Bahasa Indonesia yang lugas, ramah, edukatif, dan ringkas (1-2 paragraf pendek). Jangan pernah berhalusinasi atau melanggar batasan topik ini.",
            },
          ],
        },
        {
          role: "model",
          parts: [
            {
              text: `Halo Penjelajah Faunova! Saya siap membantu menjawab pertanyaan Anda mengenai satwa ${animalInfo?.name || "ini"}. Silakan tanyakan apa saja seputar satwa, habitat, atau perilakunya!`,
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

      let reply: string = "";

      // 0. PRE-GUARDRAIL FILTER: Blokir langsung pertanyaan di luar topik satwa (Programming, Rumus, Politik, Resep, dll)
      const offTopicRejection = checkOffTopicGuardrail(trimmedMessage, animalInfo?.name);
      if (offTopicRejection) {
        console.log(`[Guardrail Aktif] Pertanyaan "${trimmedMessage}" diblokir karena di luar topik satwa.`);
        reply = offTopicRejection;
      }

      // 1. PRIORITAS UTAMA: Google Gemini Flash (Multi-turn Conversation)
      if (!reply && geminiApiKey) {
        try {
          const systemInstructionText =
            "PERAN UTAMA: Kamu adalah Naturalis dan Pemandu Konservasi Satwa Faunova yang ramah, sopan, dan berwawasan ilmiah.\n" +
            `Konteks Satwa yang Sedang Diobservasi:\n` +
            `- Nama Satwa: ${animalInfo?.name || "Satwa Lapangan"}\n` +
            `- Nama Ilmiah / Taksonomi: ${animalInfo?.categoryOrSpecies || "-"}\n` +
            `- Ciri Morfologi & Habitat: ${animalInfo?.description || "-"}\n` +
            `- Catatan Lapangan: ${animalInfo?.additionalFact || "-"}\n\n` +
            "ATURAN MUTLAK GUARDRAIL (SANGAT KETAT / ZERO TOLERANCE):\n" +
            "1. FOKUS HANYA PADA DUNIA SATWA: Kamu HANYA BOLEH menjawab pertanyaan seputar satwa ini (" +
            (animalInfo?.name || "satwa") +
            "), atau dunia satwa liar / biologi satwa (habitat, anatomi, pola makan, taksonomi, perlindungan).\n" +
            "2. LARANGAN KERAS TOPIK LAIN: DILARANG KERAS menjawab topik pemrograman/coding, rumus matematika, fisika/kimia non-biologi, resep masakan, politik, teknologi umum, atau pertanyaan di luar fauna!\n" +
            "3. WAJIB MENOLAK TOPIK DI LUAR SATWA: Jika pengguna menanyakan topik di luar fauna (misalnya tentang coding, pemrograman, matematika, resep, atau obrolan umum), KAMU WAJIB MENOLAKNYA SECARA SOPAN DAN MENOLAK MEMBERIKAN JAWABAN TOPIK TERSEBUT.\n" +
            "Gunakan persis kalimat penolakan ini:\n" +
            "\"Maaf, sebagai pemandu konservasi satwa Faunova, saya hanya dapat membantu menjawab pertanyaan seputar satwa, habitat, dan ekologinya. Silakan ajukan pertanyaan yang berkaitan dengan " +
            (animalInfo?.name || "satwa ini") +
            " ya!\"\n" +
            "4. FORMAT RESPONS: Bahasa Indonesia yang lugas, hangat, edukatif, dan ringkas (1-2 paragraf pendek). JANGAN PERNAH menyertakan potongan kode program sama sekali.";

          const geminiChatPayload = {
            systemInstruction: {
              parts: [{ text: systemInstructionText }],
            },
            contents: geminiContents,
            generationConfig: {
              temperature: 0.2,
              maxOutputTokens: 1000,
            },
          };

          const geminiResp = await callGemini(
            geminiApiKey,
            geminiChatPayload,
            ["gemini-2.5-flash", "gemini-2.0-flash", "gemini-1.5-flash-latest"],
            25000
          );

          if (geminiResp.ok) {
            const geminiData = await geminiResp.json();
            const chatParts = geminiData.candidates?.[0]?.content?.parts;
            const chatAnswerPart =
              chatParts?.find((p: any) => !p.thought && typeof p.text === "string" && p.text.trim().length > 0) ||
              chatParts?.[chatParts.length - 1];
            const rawReply =
              chatAnswerPart?.text ||
              geminiData.candidates?.[0]?.content?.parts?.[0]?.text ||
              "Maaf, asisten tidak dapat memberikan penjelasan saat ini.";
            reply = rawReply.trim();
            console.log("Balasan chat sukses via Google Gemini Flash");
          } else {
            const errorText = await geminiResp.text();
            console.warn("Gemini chat error, mencoba provider cadangan:", geminiResp.status, errorText);
          }
        } catch (geminiChatErr: any) {
          console.warn("Gemini chat exception:", geminiChatErr?.message || geminiChatErr);
        }
      }

      // 2. CADANGAN 1: Cloudflare MiniMax / Llama untuk Chat jika token dan account ID diset
      if (!reply && cloudflareApiToken && cloudflareAccountId) {
        try {
          const cfChatMessages: Array<{ role: string; content: string }> = [
            {
              role: "system",
              content:
                "Sistem Faunova: Kamu adalah pemandu konservasi satwa dan naturalis lapangan Faunova yang ramah, santun, dan berbasis sains. " +
                `Pengguna sedang berdiskusi mengenai hasil observasi satwa berikut:\n` +
                `- Nama Umum: ${animalInfo?.name || "Satwa Lapangan"}\n` +
                `- Nama Ilmiah / Taksonomi: ${animalInfo?.categoryOrSpecies || "-"}\n` +
                `- Ciri Morfologi & Habitat: ${animalInfo?.description || "-"}\n` +
                `- Catatan Lapangan / Fakta: ${animalInfo?.additionalFact || "-"}\n\n` +
                "ATURAN BATASAN TOPIK (GUARDRAIL KERAS):\n" +
                "1. Fokus Khusus: Kamu HANYA boleh menjawab pertanyaan seputar satwa ini (" +
                (animalInfo?.name || "satwa") +
                "), biologi satwa, ekologi, perilaku, taksonomi, pola makan, siklus hidup, habitat, atau upaya konservasi satwa liar.\n" +
                "2. Penolakan Tegas Topik di Luar Satwa: Jika pengguna menanyakan topik di luar satwa/fauna, kamu WAJIB MENOLAKNYA SECARA SOPAN DAN MENOLAK MEMBERIKAN JAWABAN TOPIK TERSEBUT.\n" +
                "3. Format Respons: Bahasa Indonesia yang lugas, ramah, edukatif, dan ringkas (1-2 paragraf pendek).",
            },
          ];

          if (chatHistory && chatHistory.length > 0) {
            for (const h of chatHistory) {
              cfChatMessages.push({
                role: h.role === "assistant" ? "assistant" : "user",
                content: h.content,
              });
            }
          }

          cfChatMessages.push({
            role: "user",
            content: trimmedMessage,
          });

          const cfChatResult = await callCloudflareChat(
            cloudflareAccountId,
            cloudflareApiToken,
            cfChatMessages
          );

          if (cfChatResult.ok && cfChatResult.reply) {
            reply = cfChatResult.reply;
            console.log("Balasan chat sukses via cadangan Cloudflare Workers AI");
          }
        } catch (cfChatErr: any) {
          console.warn("Cloudflare MiniMax Chat error, beralih ke cadangan:", cfChatErr?.message || cfChatErr);
        }
      }

      // 3. CADANGAN 2: DeepSeek Chat (deepseek-flash / deepseek-chat)
      if (!reply && deepseekApiKey) {
        try {
          const dsChatMessages: Array<{ role: string; content: string }> = [
            {
              role: "system",
              content:
                "Sistem Faunova: Kamu adalah pemandu konservasi satwa dan naturalis lapangan Faunova yang ramah, santun, dan berbasis sains. " +
                `Pengguna sedang berdiskusi mengenai hasil observasi satwa berikut:\n` +
                `- Nama Umum: ${animalInfo?.name || "Satwa Lapangan"}\n` +
                `- Nama Ilmiah / Taksonomi: ${animalInfo?.categoryOrSpecies || "-"}\n` +
                `- Ciri Morfologi & Habitat: ${animalInfo?.description || "-"}\n` +
                `- Catatan Lapangan / Fakta: ${animalInfo?.additionalFact || "-"}\n\n` +
                "ATURAN BATASAN TOPIK (GUARDRAIL KERAS):\n" +
                "1. Fokus Khusus: Kamu HANYA boleh menjawab pertanyaan seputar satwa ini (" +
                (animalInfo?.name || "satwa") +
                "), biologi satwa, ekologi, perilaku, taksonomi, pola makan, siklus hidup, habitat, atau upaya konservasi satwa liar.\n" +
                "2. Penolakan Tegas Topik di Luar Satwa: Jika pengguna menanyakan topik di luar satwa/fauna, kamu WAJIB MENOLAKNYA SECARA SOPAN DAN MENOLAK MEMBERIKAN JAWABAN TOPIK TERSEBUT.\n" +
                "3. Format Respons: Bahasa Indonesia yang lugas, ramah, edukatif, dan ringkas (1-2 paragraf pendek).",
            },
          ];

          if (chatHistory && chatHistory.length > 0) {
            for (const h of chatHistory) {
              dsChatMessages.push({
                role: h.role === "assistant" ? "assistant" : "user",
                content: h.content,
              });
            }
          }

          dsChatMessages.push({
            role: "user",
            content: trimmedMessage,
          });

          const dsChatResult = await callDeepSeekChat(
            deepseekApiKey,
            dsChatMessages
          );

          if (dsChatResult.ok && dsChatResult.reply) {
            reply = dsChatResult.reply;
            console.log("Balasan chat sukses via cadangan DeepSeek Chat");
          } else {
            console.warn("DeepSeek Chat cadangan belum menghasilkan balasan:", dsChatResult.error);
          }
        } catch (dsErr: any) {
          console.warn("DeepSeek Chat cadangan error:", dsErr?.message || dsErr);
        }
      }

      // 4. POST-GUARDRAIL SAFETY NET: Jika respons memuat kode program / syntax
      if (
        reply &&
        (reply.includes("```") ||
          /\b(def |class |function |const |let |var |import |console\.log|print\(|public static)\b/.test(reply))
      ) {
        console.log("[Guardrail Post-Filter] Jawaban AI memuat potongan kode/sintaks, diganti dengan penolakan sopan.");
        reply = `Maaf, sebagai pemandu konservasi satwa Faunova, saya hanya dapat membantu menjawab pertanyaan seputar satwa, habitat, dan ekologinya. Silakan ajukan pertanyaan yang berkaitan dengan ${animalInfo?.name || "satwa ini"} ya!`;
      }

      if (!reply) {
        console.error("Seluruh provider chat AI gagal");
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
