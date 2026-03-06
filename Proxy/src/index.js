/**
 * Cloudflare Worker — OpenRouter API-Key Proxy für AI Präsente
 *
 * Leitet Anfragen von der iOS-App an OpenRouter weiter ohne den API-Key
 * in der App zu exponieren. Der Key liegt als Cloudflare Secret.
 *
 * Deployment:
 *   cd Proxy && npm install
 *   wrangler secret put OPENROUTER_API_KEY
 *   wrangler secret put APP_SECRET
 *   wrangler deploy
 */

export default {
  async fetch(request, env) {

    // CORS preflight
    if (request.method === "OPTIONS") {
      return new Response(null, {
        headers: corsHeaders(),
        status: 204,
      });
    }

    // Nur POST erlaubt
    if (request.method !== "POST") {
      return jsonError("Method Not Allowed", 405);
    }

    // App-Secret Authentifizierung
    const appSecret = env.APP_SECRET;
    if (appSecret) {
      const auth = request.headers.get("X-App-Secret") ?? "";
      if (auth !== appSecret) {
        return jsonError("Unauthorized", 401);
      }
    }

    try {
      const body = await request.json();

      const upstream = await fetch("https://openrouter.ai/api/v1/chat/completions", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${env.OPENROUTER_API_KEY}`,
          "Content-Type": "application/json",
          "HTTP-Referer": "https://github.com/harryhirsch1878/ai-presents-app-ios",
          "X-Title": "AI Praesente",
        },
        body: JSON.stringify(body),
      });

      const data = await upstream.json();
      return new Response(JSON.stringify(data), {
        status: upstream.status,
        headers: {
          "Content-Type": "application/json",
          ...corsHeaders(),
        },
      });
    } catch (err) {
      return jsonError(String(err), 500);
    }
  },
};

function corsHeaders() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, X-App-Secret",
  };
}

function jsonError(message, status) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders() },
  });
}
