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

const ALLOWED_MODELS = ["google/gemini-3.1-flash-lite-preview"];
const MAX_PAYLOAD_BYTES = 50_000;
const MAX_MESSAGES = 50;
const MAX_CONTENT_LENGTH = 10_000;
const VALID_ROLES = ["system", "user", "assistant"];

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

    // Payload-Size-Limit
    const contentLength = parseInt(request.headers.get("Content-Length") || "0");
    if (contentLength > MAX_PAYLOAD_BYTES) {
      return jsonError("Payload too large", 413);
    }

    try {
      const body = await request.json();

      // Model-Whitelisting
      if (!body.model || !ALLOWED_MODELS.includes(body.model)) {
        return jsonError("Model not allowed", 400);
      }

      // Messages-Validierung
      if (!Array.isArray(body.messages) || body.messages.length === 0 || body.messages.length > MAX_MESSAGES) {
        return jsonError("Invalid messages", 400);
      }

      const sanitized = {
        model: body.model,
        messages: body.messages.map(m => ({
          role: VALID_ROLES.includes(m.role) ? m.role : "user",
          content: String(m.content || "").slice(0, MAX_CONTENT_LENGTH),
        })),
      };

      const upstream = await fetch("https://openrouter.ai/api/v1/chat/completions", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${env.OPENROUTER_API_KEY}`,
          "Content-Type": "application/json",
          "HTTP-Referer": "https://github.com/hendrikgrueger-web/geburtstage-geschenke-iOS",
          "X-Title": "AI Praesente",
        },
        body: JSON.stringify(sanitized),
      });

      const data = await upstream.json();
      return new Response(JSON.stringify(data), {
        status: upstream.status,
        headers: { "Content-Type": "application/json" },
      });
    } catch (err) {
      return jsonError(String(err), 500);
    }
  },
};

function corsHeaders() {
  return {
    "Access-Control-Allow-Origin": "null",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, X-App-Secret",
  };
}

function jsonError(message, status) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
