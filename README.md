# Thai OCR Demo (Offline)

เว็บ OCR ภาษาไทยที่ทำงานในเบราว์เซอร์ทั้งหมด เขียนด้วย vanilla JavaScript + ONNX Runtime Web
**ไม่ต้องต่ออินเทอร์เน็ต** เพราะไลบรารีและโมเดลอยู่ในโปรเจกต์ครบ และรูปภาพไม่ถูกส่งออกนอกเครื่อง

**ลองใช้ออนไลน์:** <https://suraphol.github.io/thai-ocr-demo/> (ประมวลผลในเบราว์เซอร์ รูปไม่ถูกอัปโหลด)

## วิธีใช้

ต้องเปิด web server ในเครื่องก่อนใช้ทุกครั้ง (เบราว์เซอร์ไม่ยอมโหลด ES module / `.wasm` จาก `file://`)

```sh
./serve.sh            # ค่าเริ่มต้นพอร์ต 8000, หรือ ./serve.sh 9000
```

แล้วเปิด <http://localhost:8000> จากนั้น

- ลากรูปมาวาง, กด Ctrl/Cmd+V เพื่อวางรูป หรือกดเลือกไฟล์
- กรอบ **สีเขียว** = บรรทัดที่อ่านได้ด้วยความมั่นใจพอ, **สีแดง** = ความมั่นใจต่ำ (ไม่นำมาใช้)
- กด "คัดลอกข้อความ" เพื่อ copy ผลลัพธ์

กด `Ctrl+C` ใน Terminal เพื่อปิด server

> ต้องมี `python3` (macOS / Linux มีให้อยู่แล้ว) หรือจะใช้ static server ตัวอื่นก็ได้ เช่น `npx serve`

## โครงสร้างไฟล์

```
├── index.html              หน้าเว็บ + โค้ด OCR ทั้งหมด
├── serve.sh                เปิด web server ในเครื่อง
├── download_assets.sh      ดาวน์โหลดไลบรารี/โมเดลใหม่ (ใช้เมื่อต้องการอัปเดตเท่านั้น)
├── lib/ort/                ONNX Runtime Web 1.31.1 (WASM backend)
└── models/                 โมเดล OpenThai2.0-OCR-Text
    ├── det.onnx            text detector (DB)
    ├── rec.onnx            text recognizer (CTC)
    └── rec_dict.txt        ชุดตัวอักษรของ recognizer
```

## หลักการทำงาน

1. **Detection**: ย่อรูปให้ด้านยาวไม่เกิน 1280px (ปัดเป็นทวีคูณของ 32) แล้วส่งเข้า `det.onnx` ได้ probability map ออกมา จากนั้นหา connected components แล้วขยายกรอบ (unclip) ตามสูตรของ DB
2. **Recognition**: ครอปทีละกรอบ, ย่อให้สูง 48px, แปลงเป็นภาพขาวดำ แล้วส่งเข้า `rec.onnx` และถอดรหัสแบบ CTC greedy ด้วย `rec_dict.txt`
3. เรียงบรรทัดจากบนลงล่าง ซ้ายไปขวา แล้วตัดบรรทัดที่ความมั่นใจต่ำกว่า `MIN_CONF` ทิ้ง

ค่าที่ปรับได้ (`DET_THRESH`, `BOX_SCORE`, `UNCLIP`, `MIN_CONF` ฯลฯ) อยู่ส่วนบนของ `<script>` ใน `index.html`

## อัปเดตไลบรารี / โมเดล

แก้เวอร์ชันหรือ URL ใน `download_assets.sh` แล้วรัน (ต้องต่ออินเทอร์เน็ต)

```sh
./download_assets.sh
```

## อ้างอิง

| ส่วนประกอบ | แหล่งที่มา | License |
|---|---|---|
| โมเดล OCR (`models/`) | [iapp/OpenThai2.0-OCR-Text](https://huggingface.co/iapp/OpenThai2.0-OCR-Text) โดย iApp Technology | Apache-2.0 |
| ONNX Runtime Web (`lib/ort/`) | [microsoft/onnxruntime](https://github.com/microsoft/onnxruntime) · [onnxruntime-web@1.31.1 บน npm](https://www.npmjs.com/package/onnxruntime-web) | MIT |
| อัลกอริทึม detection | Liao et al., *Real-time Scene Text Detection with Differentiable Binarization* (AAAI 2020), [arXiv:1911.08947](https://arxiv.org/abs/1911.08947) | — |
| การถอดรหัส CTC | Graves et al., *Connectionist Temporal Classification* (ICML 2006) | — |
| แนวทาง pipeline det + rec | [PaddlePaddle/PaddleOCR](https://github.com/PaddlePaddle/PaddleOCR) | Apache-2.0 |

ไฟล์ใน `models/` และ `lib/ort/` เป็นของเจ้าของต้นฉบับ และแจกจ่ายต่อภายใต้ license ข้างต้น
