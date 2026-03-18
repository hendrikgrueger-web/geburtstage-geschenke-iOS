#!/usr/bin/env python3
"""
Marketing-Screenshot-Generator für Geburtstage & Geschenke (iOS App)
Generiert professionelle App Store Screenshots mit Gradient-Hintergrund und Marketing-Text.

Output: Screenshots/marketing/{lang}_{nr:02d}_{feature}.png
Größe: 1320x2868px (Apple frameless, identisch mit Raw-Screenshots)
"""

import os
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

# ─── Pfade ────────────────────────────────────────────────────────────────────

BASE_DIR = Path(__file__).parent.parent
SCREENSHOTS_DIR = BASE_DIR / "Screenshots"
OUTPUT_DIR = SCREENSHOTS_DIR / "marketing"

# ─── Design-Konstanten ────────────────────────────────────────────────────────

WIDTH, HEIGHT = 1320, 2868

# Gradient: warm orange → lila
GRADIENT_TOP    = (255, 107, 53)   # #FF6B35
GRADIENT_BOTTOM = (123, 47,  190)  # #7B2FBE

# Textfarben
TEXT_COLOR      = (255, 255, 255)          # weiß
TEXT_SHADOW     = (0, 0, 0, 80)            # leichter Schatten

# Screenshot-Layout
SCREENSHOT_WIDTH_RATIO = 0.85              # 85% der Breite
CORNER_RADIUS = 40
SHADOW_BLUR   = 18
SHADOW_OFFSET = (0, 12)
SHADOW_COLOR  = (0, 0, 0, 100)

# Text-Bereich oben (~20% der Höhe = 574px)
TEXT_TOP_MARGIN   = 130   # Abstand Headline vom oberen Rand
HEADLINE_SIZE     = 80
SUBHEADLINE_SIZE  = 42
LINE_GAP          = 30    # Abstand zwischen Headline und Sub-Headline

# Screenshot vertikal: startet nach Text-Bereich, leicht nach unten versetzt
SCREENSHOT_TOP_OFFSET_RATIO = 0.22   # Screenshot beginnt bei 22% der Höhe

# ─── Fonts ────────────────────────────────────────────────────────────────────

FONT_BOLD_PATHS = [
    "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    "/System/Library/Fonts/Supplemental/HelveticaNeue.ttc",
    "/System/Library/Fonts/Helvetica.ttc",
    "/System/Library/Fonts/SFNS.ttf",
]

FONT_REGULAR_PATHS = [
    "/System/Library/Fonts/SFNS.ttf",
    "/System/Library/Fonts/SFNSRounded.ttf",
    "/System/Library/Fonts/Supplemental/HelveticaNeue.ttc",
    "/System/Library/Fonts/Helvetica.ttc",
]


def load_font(paths: list[str], size: int) -> ImageFont.FreeTypeFont:
    for path in paths:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                continue
    print(f"  ⚠️  Kein Font gefunden ({size}px), nutze Default-Font")
    return ImageFont.load_default()


# ─── Marketing-Texte ──────────────────────────────────────────────────────────

# Format pro Eintrag: (reihenfolge, raw_bild_suffix, feature_name, headline, sub_headline)
SCREENSHOTS: dict[str, list[tuple]] = {
    "de": [
        (1, "de_light_01_timeline",    "timeline",      "Nie wieder vergessen",     "Alle Geburtstage auf einen Blick"),
        (2, "de_light_02_person_detail","person_detail", "Persönlich abgestimmt",    "Hobbies, Interessen & Geschenkideen"),
        (3, "de_dark_03_ai_chat",       "ai_chat",       "Dein KI-Assistent",        "Frag nach Geschenkideen — per Text oder Sprache"),
        (4, "de_dark_01_timeline",      "dark_timeline", "Tag & Nacht",              "Automatischer Dark Mode"),
        (5, "de_dark_02_person_detail", "organized",     "Perfekt organisiert",      "Geschenke planen, kaufen, verschenken"),
        (6, "de_light_03_ai_chat",      "smart",         "Smarte Vorschläge",        "Personalisiert nach Alter, Hobbies & Beziehung"),
    ],
    "en": [
        (1, "en_light_01_timeline",    "timeline",      "Never forget again",       "All birthdays at a glance"),
        (2, "en_light_02_person_detail","person_detail", "Personally tailored",      "Hobbies, interests & gift ideas"),
        (3, "en_dark_03_ai_chat",       "ai_chat",       "Your AI assistant",        "Ask for gift ideas — by text or voice"),
        (4, "en_dark_01_timeline",      "dark_timeline", "Day & Night",              "Automatic dark mode"),
        (5, "en_dark_02_person_detail", "organized",     "Perfectly organized",      "Plan, buy, and give gifts"),
        (6, "en_light_03_ai_chat",      "smart",         "Smart suggestions",        "Personalized by age, hobbies & relationship"),
    ],
    "fr": [
        (1, "fr_light_01_timeline",    "timeline",      "Ne jamais oublier",        "Tous les anniversaires en un coup d'œil"),
        (2, "fr_light_02_person_detail","person_detail", "Sur mesure",               "Hobbies, intérêts & idées cadeaux"),
        (3, "fr_dark_03_ai_chat",       "ai_chat",       "Ton assistant IA",         "Demande des idées cadeaux — par texte ou voix"),
        (4, "fr_dark_01_timeline",      "dark_timeline", "Jour & Nuit",              "Mode sombre automatique"),
        (5, "fr_dark_02_person_detail", "organized",     "Parfaitement organisé",    "Planifier, acheter, offrir"),
        (6, "fr_light_03_ai_chat",      "smart",         "Suggestions intelligentes","Personnalisées selon l'âge, les hobbies & la relation"),
    ],
    "es": [
        (1, "es_light_01_timeline",    "timeline",      "Nunca más olvidar",        "Todos los cumpleaños de un vistazo"),
        (2, "es_light_02_person_detail","person_detail", "Personalizado",            "Hobbies, intereses e ideas de regalos"),
        (3, "es_dark_03_ai_chat",       "ai_chat",       "Tu asistente IA",          "Pide ideas de regalos — por texto o voz"),
        (4, "es_dark_01_timeline",      "dark_timeline", "Día y Noche",              "Modo oscuro automático"),
        (5, "es_dark_02_person_detail", "organized",     "Perfectamente organizado", "Planifica, compra y regala"),
        (6, "es_light_03_ai_chat",      "smart",         "Sugerencias inteligentes", "Personalizadas por edad, hobbies y relación"),
    ],
}

# ─── Hilfsfunktionen ──────────────────────────────────────────────────────────

def make_gradient(width: int, height: int) -> Image.Image:
    """Erstellt einen vertikalen Gradient von GRADIENT_TOP nach GRADIENT_BOTTOM."""
    img = Image.new("RGBA", (width, height))
    draw = ImageDraw.Draw(img)
    for y in range(height):
        ratio = y / (height - 1)
        r = int(GRADIENT_TOP[0] + (GRADIENT_BOTTOM[0] - GRADIENT_TOP[0]) * ratio)
        g = int(GRADIENT_TOP[1] + (GRADIENT_BOTTOM[1] - GRADIENT_TOP[1]) * ratio)
        b = int(GRADIENT_TOP[2] + (GRADIENT_BOTTOM[2] - GRADIENT_TOP[2]) * ratio)
        draw.line([(0, y), (width, y)], fill=(r, g, b, 255))
    return img


def add_corner_radius(img: Image.Image, radius: int) -> Image.Image:
    """Rundet die Ecken eines Bildes ab (RGBA-kompatibel)."""
    img = img.convert("RGBA")
    mask = Image.new("L", img.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), img.size], radius=radius, fill=255)
    img.putalpha(mask)
    return img


def make_screenshot_shadow(w: int, h: int, radius: int, blur: int, color: tuple) -> Image.Image:
    """Erstellt einen Schatten-Layer für den Screenshot."""
    shadow = Image.new("RGBA", (w + blur * 4, h + blur * 4), (0, 0, 0, 0))
    draw = ImageDraw.Draw(shadow)
    draw.rounded_rectangle(
        [(blur * 2, blur * 2), (w + blur * 2, h + blur * 2)],
        radius=radius,
        fill=color,
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur))
    return shadow


def draw_text_centered(
    draw: ImageDraw.Draw,
    text: str,
    font: ImageFont.FreeTypeFont,
    y: int,
    canvas_width: int,
    color: tuple,
    max_width: int | None = None,
) -> int:
    """
    Zeichnet Text zentriert auf canvas_width.
    Unterstützt automatischen Zeilenumbruch wenn max_width gesetzt.
    Gibt die neue Y-Position (unterhalb des Textes) zurück.
    """
    if max_width and _text_width(draw, text, font) > max_width:
        lines = _wrap_text(draw, text, font, max_width)
    else:
        lines = [text]

    line_height = font.size + 8
    for line in lines:
        w = _text_width(draw, line, font)
        x = (canvas_width - w) // 2
        # Leichter Schatten
        draw.text((x + 2, y + 2), line, font=font, fill=(0, 0, 0, 60))
        draw.text((x, y), line, font=font, fill=color)
        y += line_height

    return y


def _text_width(draw: ImageDraw.Draw, text: str, font: ImageFont.FreeTypeFont) -> int:
    bbox = draw.textbbox((0, 0), text, font=font)
    return bbox[2] - bbox[0]


def _wrap_text(draw: ImageDraw.Draw, text: str, font: ImageFont.FreeTypeFont, max_width: int) -> list[str]:
    """Bricht Text in mehrere Zeilen um."""
    words = text.split()
    lines = []
    current = ""
    for word in words:
        test = (current + " " + word).strip()
        if _text_width(draw, test, font) <= max_width:
            current = test
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines if lines else [text]


# ─── Screenshot-Generierung ───────────────────────────────────────────────────

def generate_screenshot(
    raw_path: Path,
    output_path: Path,
    headline: str,
    sub_headline: str,
    font_bold: ImageFont.FreeTypeFont,
    font_regular: ImageFont.FreeTypeFont,
) -> None:
    # 1. Gradient-Hintergrund
    canvas = make_gradient(WIDTH, HEIGHT)
    draw = ImageDraw.Draw(canvas)

    # 2. Marketing-Text oben
    max_text_width = int(WIDTH * 0.88)
    y = TEXT_TOP_MARGIN

    # Headline
    y = draw_text_centered(draw, headline, font_bold, y, WIDTH, TEXT_COLOR, max_text_width)
    y += LINE_GAP

    # Sub-Headline
    draw_text_centered(draw, sub_headline, font_regular, y, WIDTH, (255, 255, 255, 220), max_text_width)

    # 3. Raw-Screenshot laden + skalieren
    raw_img = Image.open(raw_path).convert("RGBA")
    target_w = int(WIDTH * SCREENSHOT_WIDTH_RATIO)
    scale = target_w / raw_img.width
    target_h = int(raw_img.height * scale)
    raw_img = raw_img.resize((target_w, target_h), Image.LANCZOS)

    # 4. Abgerundete Ecken
    raw_img = add_corner_radius(raw_img, CORNER_RADIUS)

    # 5. Position: horizontal zentriert, vertikal ab ~22% der Höhe
    screenshot_top = int(HEIGHT * SCREENSHOT_TOP_OFFSET_RATIO)
    # Screenshot vertikal zentrieren im verbleibenden Raum (optional: etwas nach oben rücken)
    remaining_height = HEIGHT - screenshot_top
    paste_x = (WIDTH - target_w) // 2
    paste_y = screenshot_top + (remaining_height - target_h) // 2
    # Sorge dafür, dass der Screenshot nicht unten abgeschnitten wird
    if paste_y + target_h > HEIGHT - 40:
        paste_y = HEIGHT - target_h - 40

    # 6. Schatten unter Screenshot
    shadow = make_screenshot_shadow(target_w, target_h, CORNER_RADIUS, SHADOW_BLUR, SHADOW_COLOR)
    shadow_x = paste_x - SHADOW_BLUR * 2 + SHADOW_OFFSET[0]
    shadow_y = paste_y - SHADOW_BLUR * 2 + SHADOW_OFFSET[1]
    canvas.paste(shadow, (shadow_x, shadow_y), shadow)

    # 7. Screenshot einfügen
    canvas.paste(raw_img, (paste_x, paste_y), raw_img)

    # 8. Speichern
    output_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(output_path, "PNG", optimize=True)


# ─── Main ─────────────────────────────────────────────────────────────────────

def main() -> None:
    print("🚀 Marketing-Screenshot-Generator")
    print(f"   Input:  {SCREENSHOTS_DIR}")
    print(f"   Output: {OUTPUT_DIR}")
    print()

    font_bold    = load_font(FONT_BOLD_PATHS, HEADLINE_SIZE)
    font_regular = load_font(FONT_REGULAR_PATHS, SUBHEADLINE_SIZE)

    total = 0
    errors = 0

    for lang, entries in SCREENSHOTS.items():
        print(f"📸 Sprache: {lang.upper()}")
        for nr, raw_suffix, feature_name, headline, sub_headline in entries:
            raw_path = SCREENSHOTS_DIR / f"{raw_suffix}.png"
            output_filename = f"{lang}_{nr:02d}_{feature_name}.png"
            output_path = OUTPUT_DIR / output_filename

            if not raw_path.exists():
                print(f"   ⚠️  Nicht gefunden: {raw_path.name} — übersprungen")
                errors += 1
                continue

            try:
                generate_screenshot(
                    raw_path=raw_path,
                    output_path=output_path,
                    headline=headline,
                    sub_headline=sub_headline,
                    font_bold=font_bold,
                    font_regular=font_regular,
                )
                print(f"   ✅ {output_filename}")
                total += 1
            except Exception as e:
                print(f"   ❌ {output_filename}: {e}")
                errors += 1

        print()

    print(f"✅ Fertig: {total} Screenshots generiert")
    if errors:
        print(f"⚠️  {errors} Fehler")
    else:
        print(f"   Gespeichert in: {OUTPUT_DIR}")

    return 0 if errors == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
