#!/usr/bin/env bash
# html_to_pdf.sh — 把 HTML 簡報轉成 PDF
#
# 用法:
#   ./scripts/html_to_pdf.sh <input.html> <output.pdf>
#
# 為什麼要先寫到 Temp 再搬:
#   OneDrive 同步資料夾常常拒絕 Chrome headless 直接寫入 (存取被拒 0x5)
#   先輸出到 %TEMP% 再 mv 過去最穩。

set -eo pipefail
USER="${USER:-${USERNAME:-user}}"

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <input.html> <output.pdf>" >&2
  exit 1
fi

INPUT_HTML="$1"
OUTPUT_PDF="$2"

CHROME="/c/Program Files/Google/Chrome/Application/chrome.exe"
if [[ ! -x "$CHROME" ]]; then
  CHROME="/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
fi
if [[ ! -x "$CHROME" ]]; then
  echo "找不到 Chrome 或 Edge，請確認瀏覽器已安裝" >&2
  exit 2
fi

# Resolve absolute paths
INPUT_ABS="$(cd "$(dirname "$INPUT_HTML")" && pwd)/$(basename "$INPUT_HTML")"
OUTPUT_DIR="$(cd "$(dirname "$OUTPUT_PDF")" && pwd)"
OUTPUT_NAME="$(basename "$OUTPUT_PDF")"
OUTPUT_ABS="$OUTPUT_DIR/$OUTPUT_NAME"

# Build file:// URL with proper encoding for spaces and ampersand
INPUT_WIN="$(echo "$INPUT_ABS" | sed 's|^/c/|C:/|; s|^/d/|D:/|')"
INPUT_URL="file:///$(echo "$INPUT_WIN" | sed 's| |%20|g; s|&|%26|g')"

# Output via Temp to dodge OneDrive permission errors
TEMP_PDF="$(mktemp -u --suffix=.pdf 2>/dev/null || echo "/c/Users/$USER/AppData/Local/Temp/htmltopdf_$$.pdf")"
TEMP_PDF_WIN="$(echo "$TEMP_PDF" | sed 's|^/c/|C:/|; s|^/tmp/|C:/Users/'"$USER"'/AppData/Local/Temp/|')"

echo "→ Rendering: $INPUT_URL"
echo "→ Temp out:  $TEMP_PDF_WIN"

"$CHROME" \
  --headless \
  --disable-gpu \
  --no-pdf-header-footer \
  --no-margins \
  --print-to-pdf="$TEMP_PDF_WIN" \
  "$INPUT_URL" 2>&1 | grep -v "DEPRECATED_ENDPOINT" || true

if [[ ! -f "$TEMP_PDF" ]]; then
  echo "PDF 產生失敗" >&2
  exit 3
fi

mv -f "$TEMP_PDF" "$OUTPUT_ABS"
echo "✓ Saved: $OUTPUT_ABS ($(wc -c < "$OUTPUT_ABS") bytes)"
