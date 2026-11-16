#!/bin/sh
# เปิด web server ในเครื่อง (ES module / fetch / wasm ใช้กับ file:// ไม่ได้)
cd "$(dirname "$0")"
PORT="${1:-8000}"
echo "เปิด http://localhost:$PORT"
exec python3 -m http.server "$PORT" --bind 127.0.0.1
