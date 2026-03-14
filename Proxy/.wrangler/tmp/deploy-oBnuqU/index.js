var __defProp = Object.defineProperty;
var __name = (target, value) => __defProp(target, "name", { value, configurable: true });

// src/index.js
var ALLOWED_MODELS = ["x-ai/grok-4.1-fast", "openai/gpt-4.1-mini", "openai/gpt-4.1-nano", "google/gemini-3.1-flash-lite-preview"];
var MAX_PAYLOAD_BYTES = 5e4;
var MAX_MESSAGES = 50;
var MAX_CONTENT_LENGTH = 1e4;
var VALID_ROLES = ["system", "user", "assistant"];
var RATE_LIMIT_MAX = 60;
var RATE_LIMIT_WINDOW = 6e4;
var rateLimitMap = /* @__PURE__ */ new Map();
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
__name(checkRateLimit, "checkRateLimit");
var index_default = {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204
      });
    }
    if (request.method !== "POST") {
      return jsonError("Method Not Allowed", 405);
    }
    const clientIP = request.headers.get("CF-Connecting-IP") || "unknown";
    if (!checkRateLimit(clientIP)) {
      return new Response(JSON.stringify({ error: "Rate limit exceeded. Please try again later." }), {
        status: 429,
        headers: { "Content-Type": "application/json" }
      });
    }
    const appSecret = env.APP_SECRET;
    if (appSecret) {
      const auth = request.headers.get("X-App-Secret") ?? "";
      if (auth !== appSecret) {
        return jsonError("Unauthorized", 401);
      }
    }
    const contentLength = parseInt(request.headers.get("Content-Length") || "0");
    if (contentLength > MAX_PAYLOAD_BYTES) {
      return jsonError("Payload too large", 413);
    }
    try {
      const body = await request.json();
      if (!body.model || !ALLOWED_MODELS.includes(body.model)) {
        return jsonError("Model not allowed", 400);
      }
      if (!Array.isArray(body.messages) || body.messages.length === 0 || body.messages.length > MAX_MESSAGES) {
        return jsonError("Invalid messages", 400);
      }
      const sanitized = {
        model: body.model,
        messages: body.messages.map((m) => ({
          role: VALID_ROLES.includes(m.role) ? m.role : "user",
          content: String(m.content || "").slice(0, MAX_CONTENT_LENGTH)
        }))
      };
      const upstream = await fetch("https://openrouter.ai/api/v1/chat/completions", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${env.OPENROUTER_API_KEY}`,
          "Content-Type": "application/json",
          "HTTP-Referer": "https://github.com/hendrikgrueger-web/geburtstage-geschenke-iOS",
          "X-Title": "AI Praesente"
        },
        body: JSON.stringify(sanitized)
      });
      const data = await upstream.json();
      return new Response(JSON.stringify(data), {
        status: upstream.status,
        headers: { "Content-Type": "application/json" }
      });
    } catch (err) {
      return jsonError(String(err), 500);
    }
  }
};
function jsonError(message, status) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { "Content-Type": "application/json" }
  });
}
__name(jsonError, "jsonError");
export {
  index_default as default
};
//# sourceMappingURL=index.js.map
