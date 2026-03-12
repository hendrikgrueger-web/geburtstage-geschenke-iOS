#!/bin/bash
set -euo pipefail

# === Config ===
SIM_UDID="64FFF207-1F6A-48CD-B9FA-25F806FBAA7F"  # iPhone 17 Pro Max
APP_BUNDLE="com.hendrikgrueger.birthdays-presents-ai"
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData/ai-presents-app-ios-efbawrhrvdhxckfbcsczidtzxrdt"
APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/aiPresentsApp.app"
SCREENSHOT_DIR="$(cd "$(dirname "$0")/.." && pwd)/Screenshots"
PLIST_PATH="$HOME/Library/Developer/CoreSimulator/Devices/$SIM_UDID/data/Library/Preferences/.GlobalPreferences.plist"

# Languages: code → locale pairs
declare -A LANG_CODES=(
    [de]="de"
    [en]="en"
    [fr]="fr"
    [es]="es"
)
declare -A REGION_CODES=(
    [de]="DE"
    [en]="US"
    [fr]="FR"
    [es]="ES"
)

wait_for_app() {
    local max_wait=15
    local count=0
    while [ $count -lt $max_wait ]; do
        if xcrun simctl spawn "$SIM_UDID" launchctl list 2>/dev/null | grep -q "$APP_BUNDLE" 2>/dev/null; then
            return 0
        fi
        sleep 1
        count=$((count + 1))
    done
    echo "  ⚠️  App nicht gestartet nach ${max_wait}s"
    return 1
}

take_screenshot() {
    local name="$1"
    local lang="$2"
    local mode="$3"
    local file="$SCREENSHOT_DIR/${lang}_${mode}_${name}.png"
    sleep 3  # UI settle time
    xcrun simctl io "$SIM_UDID" screenshot "$file" 2>/dev/null
    echo "  📸 $file"
}

set_language() {
    local lang="$1"
    local region="$2"
    echo "  🌍 Sprache → $lang-$region"
    xcrun simctl shutdown "$SIM_UDID" 2>/dev/null || true
    sleep 2
    plutil -replace AppleLanguages -json "[\"$lang-$region\",\"$lang\"]" "$PLIST_PATH" 2>/dev/null || \
        plutil -replace AppleLanguages -json "[\"$lang-$region\",\"$lang\"]" "$PLIST_PATH"
    plutil -replace AppleLocale -json "\"${lang}_${region}\"" "$PLIST_PATH"
    xcrun simctl boot "$SIM_UDID"
    sleep 5  # Boot settle
}

set_status_bar() {
    xcrun simctl status_bar "$SIM_UDID" override \
        --time "9:41" \
        --batteryState charged \
        --batteryLevel 100 \
        --cellularMode active \
        --cellularBars 4 \
        --wifiBars 3 \
        --operatorName "" 2>/dev/null || true
}

set_appearance() {
    local mode="$1"
    xcrun simctl ui "$SIM_UDID" appearance "$mode" 2>/dev/null || true
    sleep 1
}

terminate_app() {
    xcrun simctl terminate "$SIM_UDID" "$APP_BUNDLE" 2>/dev/null || true
    sleep 1
}

launch_app() {
    local args="$@"
    xcrun simctl launch "$SIM_UDID" "$APP_BUNDLE" $args 2>/dev/null
    wait_for_app
}

get_person_uuid() {
    # Query SQLite for a person with gift ideas (best for PersonDetail screenshot)
    local db_container=$(xcrun simctl get_app_container "$SIM_UDID" "$APP_BUNDLE" groups 2>/dev/null | head -1 || echo "")
    if [ -z "$db_container" ]; then
        db_container=$(find "$HOME/Library/Developer/CoreSimulator/Devices/$SIM_UDID/data/Containers/Shared/AppGroup" -name "default.store" -path "*ai-presents*" 2>/dev/null | head -1 | xargs dirname || echo "")
    fi
    
    # Try finding the SwiftData store
    local store=""
    for search_path in \
        "$HOME/Library/Developer/CoreSimulator/Devices/$SIM_UDID/data/Containers/Shared/AppGroup/*/Library/Application Support/default.store" \
        "$HOME/Library/Developer/CoreSimulator/Devices/$SIM_UDID/data/Containers/Data/Application/*/Library/Application Support/default.store" \
        "$HOME/Library/Developer/CoreSimulator/Devices/$SIM_UDID/data/Containers/Data/Application/*/Library/Application Support/ai-presents-app.store"; do
        store=$(ls $search_path 2>/dev/null | head -1 || echo "")
        if [ -n "$store" ]; then break; fi
    done
    
    if [ -z "$store" ]; then
        echo ""
        return
    fi
    
    # Get first person UUID that has hobbies (more interesting for screenshot)
    local uuid=$(sqlite3 "$store" "SELECT ZHEXID FROM ZPERSONREF WHERE ZCONTACTIDENTIFIER LIKE 'demo-erika%' LIMIT 1;" 2>/dev/null || echo "")
    if [ -z "$uuid" ]; then
        uuid=$(sqlite3 "$store" "SELECT hex(ZID) FROM ZPERSONREF LIMIT 1;" 2>/dev/null || echo "")
    fi
    echo "$uuid"
}

# === Main ===
echo "🚀 Screenshot-Pipeline starten"
echo "   Simulator: iPhone 17 Pro Max ($SIM_UDID)"
echo "   Output: $SCREENSHOT_DIR"
echo ""

# Sicherstellen dass App gebaut ist
if [ ! -d "$APP_PATH" ]; then
    echo "❌ App nicht gebaut. Bitte erst: xcodebuild build"
    exit 1
fi

# Install app (nur einmal nötig, bleibt über Reboots bestehen)
xcrun simctl boot "$SIM_UDID" 2>/dev/null || true
sleep 3
xcrun simctl install "$SIM_UDID" "$APP_PATH"
echo "✅ App installiert"

# Erster Launch mit Sample Data um DB zu befüllen
launch_app --reset-sample-data
sleep 3
terminate_app

# UUID für PersonDetail ermitteln
echo ""
echo "🔍 Person-UUID für PersonDetail suchen..."
PERSON_UUID=$(get_person_uuid)
if [ -z "$PERSON_UUID" ]; then
    echo "⚠️  Keine Person-UUID gefunden — PersonDetail-Screenshots werden übersprungen"
fi
echo "   UUID: $PERSON_UUID"

# === Für jede Sprache ===
for lang in de en fr es; do
    region="${REGION_CODES[$lang]}"
    echo ""
    echo "═══════════════════════════════════════"
    echo "🌍 $lang-$region — Screenshots starten"
    echo "═══════════════════════════════════════"
    
    # Sprache setzen (inkl. Reboot)
    set_language "$lang" "$region"
    set_status_bar
    
    # App installieren (nach Reboot nötig)
    xcrun simctl install "$SIM_UDID" "$APP_PATH"
    
    for mode in light dark; do
        echo ""
        echo "  🎨 Modus: $mode"
        set_appearance "$mode"
        
        # 1. Timeline Screenshot
        echo "  📱 1/4 Timeline..."
        terminate_app
        launch_app --reset-sample-data
        take_screenshot "01_timeline" "$lang" "$mode"
        
        # 2. PersonDetail Screenshot
        if [ -n "$PERSON_UUID" ]; then
            echo "  📱 2/4 PersonDetail..."
            terminate_app
            launch_app --reset-sample-data --show-person "$PERSON_UUID"
            sleep 1  # Extra wait for navigation
            take_screenshot "02_person_detail" "$lang" "$mode"
        fi
        
        # 3. AI Chat Screenshot
        echo "  📱 3/4 AI Chat..."
        terminate_app
        launch_app --reset-sample-data --show-chat
        sleep 1  # Extra wait for sheet
        take_screenshot "03_ai_chat" "$lang" "$mode"
        
        # 4. Timeline (scrolled/alternate) — zusätzlicher Screenshot
        echo "  📱 4/4 Timeline alt..."
        terminate_app
        launch_app --reset-sample-data
        take_screenshot "04_timeline_alt" "$lang" "$mode"
        
        terminate_app
    done
done

# Cleanup
xcrun simctl status_bar "$SIM_UDID" clear 2>/dev/null || true
xcrun simctl shutdown "$SIM_UDID" 2>/dev/null || true

echo ""
echo "═══════════════════════════════════════"
echo "✅ Alle Screenshots fertig!"
echo "   Verzeichnis: $SCREENSHOT_DIR"
ls -la "$SCREENSHOT_DIR"/*.png 2>/dev/null | wc -l | xargs -I{} echo "   Dateien: {}"
echo "═══════════════════════════════════════"
