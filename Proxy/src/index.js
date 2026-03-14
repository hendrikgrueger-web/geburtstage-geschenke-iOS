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

const ALLOWED_MODELS = ["openai/gpt-4.1-nano", "google/gemini-3.1-flash-lite-preview"];
const MAX_PAYLOAD_BYTES = 50_000;
const MAX_MESSAGES = 50;
const MAX_CONTENT_LENGTH = 10_000;
const VALID_ROLES = ["system", "user", "assistant"];
const RATE_LIMIT_MAX = 60; // Requests pro Minute pro IP
const RATE_LIMIT_WINDOW = 60_000; // 1 Minute in ms

// Einfaches In-Memory Rate Limiting (wird bei Worker-Neustart zurückgesetzt)
const rateLimitMap = new Map();

function checkRateLimit(ip) {
  const now = Date.now();
  const entry = rateLimitMap.get(ip);
  if (!entry || now - entry.windowStart > RATE_LIMIT_WINDOW) {
    rateLimitMap.set(ip, { windowStart: now, count: 1 });
    return true;
  }
  entry.count++;
  return entry.count <= RATE_LIMIT_MAX;
}

export default {
  async fetch(request, env) {

    // CORS preflight (native iOS-App braucht keine CORS-Headers, aber ignorieren wir es nicht)
    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
      });
    }

    // Nur POST erlaubt
    if (request.method !== "POST") {
      return jsonError("Method Not Allowed", 405);
    }

    // Rate Limiting
    const clientIP = request.headers.get("CF-Connecting-IP") || "unknown";
    if (!checkRateLimit(clientIP)) {
      return new Response(JSON.stringify({ error: "Rate limit exceeded. Please try again later." }), {
        status: 429,
        headers: { "Content-Type": "application/json" }
      });
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

function jsonError(message, status) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
