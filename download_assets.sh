#!/bin/sh
# ดาวน์โหลดไลบรารีและโมเดลมาเก็บในเครื่อง (รันครั้งเดียวตอนมีอินเทอร์เน็ต)
set -e
cd "$(dirname "$0")"

ORT_BASE="https://cdn.jsdelivr.net/npm/onnxruntime-web@1.31.1/dist"
MODEL_BASE="https://huggingface.co/iapp/OpenThai2.0-OCR-Text/resolve/main"

mkdir -p lib/ort models

for f in ort.wasm.min.mjs ort-wasm-simd-threaded.mjs ort-wasm-simd-threaded.wasm; do
  echo "lib/ort/$f"
  curl -fL --progress-bar "$ORT_BASE/$f" -o "lib/ort/$f"
done

for f in det.onnx rec.onnx rec_dict.txt; do
  echo "models/$f"
  curl -fL --progress-bar "$MODEL_BASE/$f" -o "models/$f"
done

echo "เสร็จแล้ว — รัน ./serve.sh แล้วเปิด http://localhost:8000"
