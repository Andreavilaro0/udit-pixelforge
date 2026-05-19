#!/usr/bin/env python3
"""Convert MEMORIA.md → MEMORIA.html, ready to Print → Save as PDF."""
import re
import sys
from pathlib import Path

try:
    import markdown
except ImportError:
    sys.exit("Instala python3-markdown: sudo apt install python3-markdown")

HERE = Path(__file__).parent
SRC = HERE / "MEMORIA.md"
DST = HERE / "MEMORIA.html"

raw = SRC.read_text(encoding="utf-8")

# Strip YAML frontmatter
if raw.startswith("---"):
    end = raw.find("\n---", 3)
    if end != -1:
        raw = raw[end + 4 :].lstrip()

# Strip \newpage literals (LaTeX-only) and convert to <div class="page-break">
raw = re.sub(r"\\newpage", '<div class="page-break"></div>', raw)

md = markdown.Markdown(
    extensions=[
        "extra",
        "toc",
        "fenced_code",
        "tables",
        "sane_lists",
        "codehilite",
        "attr_list",
    ],
    extension_configs={
        "toc": {"title": "Índice", "toc_depth": "1-3", "permalink": False},
        "codehilite": {"noclasses": True, "pygments_style": "tango"},
    },
)

body = md.convert(raw)
toc = md.toc

TEMPLATE = r"""<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<title>UDIT PixelForge — Memoria Técnica</title>
<style>
 :root{
   --bg:#ffffff;
   --ink:#17202a;
   --muted:#5c6b7a;
   --brand:#1b2a41;
   --accent:#4cc9f0;
   --amber:#f4a261;
   --green:#2a9d8f;
   --rule:#dfe4ea;
 }
 *{box-sizing:border-box}
 html,body{margin:0;padding:0;background:#f1f5f9;color:var(--ink);
  font-family:"Inter","Helvetica Neue",Arial,sans-serif;font-size:11pt;line-height:1.55}
 .page{max-width:210mm;margin:2rem auto;background:var(--bg);
  padding:22mm 20mm;box-shadow:0 10px 40px rgba(0,0,0,.08);border-radius:4px}
 @media print{
   html,body{background:#fff}
   .page{margin:0;box-shadow:none;border-radius:0;max-width:none;padding:18mm 16mm}
   .no-print{display:none!important}
   .page-break{page-break-after:always;break-after:page;height:0}
   h1,h2,h3{page-break-after:avoid;break-after:avoid}
   table,pre,blockquote,figure{page-break-inside:avoid;break-inside:avoid}
   @page{size:A4;margin:0}
 }
 .no-print{position:fixed;top:16px;left:16px;z-index:99}
 .no-print button{background:var(--brand);color:#fff;border:0;padding:12px 20px;
  border-radius:8px;font-weight:700;font-size:14px;cursor:pointer;box-shadow:0 4px 14px rgba(0,0,0,.2)}
 .no-print button:hover{background:#243957}
 .no-print .hint{display:block;margin-top:6px;background:#fff;color:#5c6b7a;padding:6px 10px;
  border-radius:6px;font-size:12px;max-width:260px;box-shadow:0 2px 10px rgba(0,0,0,.08)}

 .masthead{border-left:6px solid var(--accent);padding:6px 14px;margin-bottom:24px}
 .masthead .eyebrow{font-size:10pt;color:var(--muted);letter-spacing:.08em;text-transform:uppercase}
 .masthead h1{margin:4px 0 2px;font-size:26pt;font-weight:800;color:var(--brand);letter-spacing:-.01em}
 .masthead .sub{color:var(--muted);font-size:12pt}

 h1,h2,h3,h4{color:var(--brand);font-weight:800;letter-spacing:-.01em}
 h1{font-size:20pt;margin:24px 0 8px;border-bottom:3px solid var(--brand);padding-bottom:4px}
 h2{font-size:15pt;margin:22px 0 8px;border-bottom:1px solid var(--rule);padding-bottom:3px}
 h3{font-size:12.5pt;margin:16px 0 4px}
 h4{font-size:11pt;margin:12px 0 4px}
 p{margin:6px 0 10px;text-align:justify;hyphens:auto}
 ul,ol{margin:4px 0 10px 22px;padding:0}
 li{margin:3px 0}
 hr{border:0;border-top:1px solid var(--rule);margin:18px 0}

 code{background:#f3f6fa;color:#b91c1c;padding:1px 6px;border-radius:4px;
  font-family:"DejaVu Sans Mono","Menlo",monospace;font-size:.92em}
 pre{background:#0f172a;color:#e2e8f0;padding:14px 16px;border-radius:8px;
  overflow-x:auto;font-size:9.5pt;line-height:1.45}
 pre code{background:transparent;color:inherit;padding:0;border-radius:0}

 table{border-collapse:collapse;width:100%;margin:10px 0 14px;font-size:10pt}
 th,td{border:1px solid var(--rule);padding:6px 9px;text-align:left;vertical-align:top}
 th{background:#eef2f7;color:var(--brand);font-weight:700}
 tr:nth-child(even) td{background:#fafbfc}

 blockquote{border-left:4px solid var(--amber);background:#fff8ec;margin:10px 0;
  padding:8px 14px;color:#6b4c1e;border-radius:4px}

 .toc{background:#f7f9fc;border:1px solid var(--rule);border-radius:6px;padding:10px 18px;margin:12px 0 20px}
 .toc .toctitle{font-weight:800;color:var(--brand);font-size:13pt;margin:4px 0 6px}
 .toc ul{list-style:none;margin-left:12px}
 .toc li{margin:2px 0;font-size:10.5pt}
 .toc a{color:var(--ink);text-decoration:none}
 .toc a:hover{color:var(--accent)}

 .tag{display:inline-block;background:var(--green);color:#fff;padding:1px 8px;border-radius:10px;font-size:9pt}
 .page-break{page-break-after:always;break-after:page;height:0}
 footer{margin-top:30px;border-top:1px solid var(--rule);padding-top:10px;color:var(--muted);font-size:9pt;text-align:center}
</style>
</head>
<body>

<div class="no-print">
  <button onclick="window.print()">🖨️ Guardar como PDF</button>
  <span class="hint">Ctrl+P → Destino «Guardar como PDF» · A4 · activa «Gráficos de fondo»</span>
</div>

<div class="page">
  <div class="masthead">
    <div class="eyebrow">UDIT · Sistemas Operativos Avanzados · Proyecto Final</div>
    <h1>UDIT PixelForge</h1>
    <div class="sub">Memoria Técnica · Distribución Linux personalizada basada en Debian 13 ARM64</div>
  </div>

  __TOC__

  __BODY__

  <footer>Andrea &amp; Iván · UDIT 2026 · ISO v19 · SHA-256 57bbc10b…c77d4</footer>
</div>
</body>
</html>
"""

html = TEMPLATE.replace("__TOC__", toc or "").replace("__BODY__", body)
DST.write_text(html, encoding="utf-8")
print(f"OK → {DST}")
print(f"   {DST.stat().st_size/1024:.1f} KB")
