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
└── models/                 โมเดล OpenThai2.1-OCR-Text v2.1.4
    ├── det.onnx            text detector (DB)
    ├── rec.onnx            text recognizer (CTC)
    ├── rec2.onnx           recognizer ตัวที่ 2 สำหรับฟอนต์ไม่มีหัว (Kanit, Prompt, Sukhumvit Set)
    ├── rec_dict.txt        ชุดตัวอักษรของ recognizer
    ├── config.json         เกณฑ์กรองบรรทัดและการตั้งค่า runtime จาก iApp
    └── NOTICE              ข้อความ attribution ของโมเดล (Apache-2.0)
```

## หลักการทำงาน

1. **Detection**: ย่อรูปให้ด้านยาวไม่เกิน 1280px (ปัดเป็นทวีคูณของ 32) แล้วส่งเข้า `det.onnx` ได้ probability map ออกมา จากนั้นหา connected components แล้วขยายกรอบ (unclip) ตามสูตรของ DB
2. **Recognition**: ครอปทีละกรอบ, ย่อให้สูง 48px, แปลงเป็นภาพเทาแล้วลบพื้นหลังทีละคอลัมน์ (`flatten`) ทำให้อ่านตัวสีอ่อนบนพื้นเข้มหรือพื้นไล่สีได้ จากนั้นส่งเข้า `rec.onnx` และถอดรหัสแบบ CTC greedy ด้วย `rec_dict.txt`
3. **rec2**: ถ้าผลอ่านมีอักษรละตินปนอยู่ในคำไทย (เช่น "lละพลNSะทU" ซึ่งเป็นอาการของฟอนต์ไม่มีหัว) จะอ่านบรรทัดนั้นซ้ำด้วย `rec2.onnx` และเก็บผลที่มีละตินปนน้อยกว่า
4. **จัดรูปข้อความ**: ทำข้อความไทยให้อยู่ในรูปมาตรฐาน (ลำดับสระ/วรรณยุกต์, `ํ` + `า` → `ำ`, `เเ` → `แ`) และแก้ comma ที่ใช้แทนจุดทศนิยมในจำนวนเงิน (`280,00` → `280.00`)
5. **กรองบรรทัด**: ทิ้งบรรทัดที่ความมั่นใจต่ำ, สั้นเกินไป หรือสะกดผิดหลักภาษาไทยเกินเกณฑ์ (มักเป็นตราประทับหรือลายเซ็น) แต่เก็บตัวเลขหรือตัวอักษรอังกฤษตัวเดียวในช่องตารางไว้ ถ้ากล่องสูงพอ เกณฑ์ทั้งหมดอ่านจาก `models/config.json`

ขั้นที่ 2–5 เขียนเป็น JavaScript ตาม runtime Python (`runtime/line_engine.py`, `runtime/thai_norm.py`) ของ v2.1.4 แต่ยังไม่มีบางส่วนของ runtime ตัวเต็ม เช่น การเก็บวรรณยุกต์ลอยของหนังสือเก่า, การอ่านหลายคอลัมน์ และการหมุนหน้าอัตโนมัติ

ค่าของ detector (`DET_THRESH`, `BOX_SCORE`, `UNCLIP` ฯลฯ) อยู่ส่วนบนของ `<script>` ใน `index.html` ส่วนเกณฑ์กรองบรรทัดแก้ได้ที่ `models/config.json` (เปิด console จะเห็นบรรทัดที่ถูกทิ้งพร้อมเหตุผล)

## อัปเดตไลบรารี / โมเดล

แก้เวอร์ชันหรือ URL ใน `download_assets.sh` แล้วรัน (ต้องต่ออินเทอร์เน็ต)

```sh
./download_assets.sh
```

## อ้างอิง

| ส่วนประกอบ | แหล่งที่มา | License |
|---|---|---|
| โมเดล OCR และ runtime ต้นฉบับ (`models/`) | [iapp/OpenThai2.1-OCR-Text-20261118](https://huggingface.co/iapp/OpenThai2.1-OCR-Text-20261118) v2.1.4 โดย iApp Technology (เดิมชื่อ OpenThai2.0-OCR-Text) | Apache-2.0 |
| detector / recognizer ต้นทาง | PP-OCRv6_tiny_det, PP-OCRv6_tiny_rec โดย [PaddlePaddle](https://huggingface.co/PaddlePaddle) (ดู `models/NOTICE`) | Apache-2.0 |
| ONNX Runtime Web (`lib/ort/`) | [microsoft/onnxruntime](https://github.com/microsoft/onnxruntime) · [onnxruntime-web@1.31.1 บน npm](https://www.npmjs.com/package/onnxruntime-web) | MIT |
| อัลกอริทึม detection | Liao et al., *Real-time Scene Text Detection with Differentiable Binarization* (AAAI 2020), [arXiv:1911.08947](https://arxiv.org/abs/1911.08947) | — |
| การถอดรหัส CTC | Graves et al., *Connectionist Temporal Classification* (ICML 2006) | — |
| แนวทาง pipeline det + rec | [PaddlePaddle/PaddleOCR](https://github.com/PaddlePaddle/PaddleOCR) | Apache-2.0 |

ไฟล์ใน `models/` และ `lib/ort/` เป็นของเจ้าของต้นฉบับ และแจกจ่ายต่อภายใต้ license ข้างต้น
