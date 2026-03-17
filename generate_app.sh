#!/bin/bash
set -e

echo "🚀 Bootstrapping Final Hardware-Accurate PDF Annotator..."

# 1. Create Vite/React/TS project
npx create-vite@latest annotator-app --template react-ts
cd annotator-app

# 2. Install dependencies
npm install @tauri-apps/api@^1.5.0 pdfjs-dist@^3.11.174 pdf-lib@^1.17.1
npm install --save-dev @tauri-apps/cli@^1.5.0

# 3. Initialize Tauri
npx tauri init --app-name "TeachingAnnotator" --window-title "Teaching PDF Annotator" --dist-dir "../dist" --dev-path "http://localhost:5173" --before-build-command "npm run build" --before-dev-command "npm run dev"

# 4. Configure tauri.conf.json (With Icon and Security Permissions)
cat << 'EOF' > src-tauri/tauri.conf.json
{
  "build": {
    "beforeBuildCommand": "npm run build",
    "beforeDevCommand": "npm run dev",
    "devPath": "http://localhost:5173",
    "distDir": "../dist"
  },
  "package": {
    "productName": "TeachingAnnotator",
    "version": "1.0.0"
  },
  "tauri": {
    "allowlist": {
      "all": false,
      "dialog": { "all": true, "save": true, "open": true },
      "fs": { "all": true, "scope": ["**"] },
      "path": { "all": true }
    },
    "bundle": {
      "active": true,
      "category": "Education",
      "identifier": "com.teaching.annotator",
      "icon": ["icons/32x32.png", "icons/128x128.png", "icons/128x128@2x.png", "icons/icon.icns", "icons/icon.ico"],
      "targets": "all"
    },
    "windows": [{ "fullscreen": false, "height": 900, "resizable": true, "title": "Teaching PDF Annotator", "width": 1400 }]
  }
}
EOF

# 5. Write App.css (Strict Cursor Control)
cat << 'EOF' > src/App.css
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;800&display=swap');

:root {
  --bg-dark: #0f1115; --panel-bg: #1a1c23; --border-color: #3a3f4b;
  --grid-color: rgba(255, 255, 255, 0.05);
}

* { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Inter', sans-serif; user-select: none; }
body { background-color: var(--bg-dark); color: #ffffff; overflow: hidden; height: 100vh; display: flex; flex-direction: column; }

/* 🖱️ HIDE DEFAULT CURSOR STICKY RULE */
body.draw-active, body.draw-active * { cursor: none !important; }

header { background-color: var(--panel-bg); padding: 15px 30px; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--border-color); z-index: 100; }
.btn { background: #ffffff; color: #000000; border: none; padding: 9px 15px; font-size: 0.85rem; font-weight: 800; border-radius: 6px; cursor: pointer; transition: all 0.2s; }
.btn:active { transform: translate(2px, 2px); }
.btn-outline { background: transparent; color: #ffffff; border: 1px solid var(--border-color); cursor: default; }

.workspace { display: flex; flex: 1; overflow: hidden; position: relative; background-image: linear-gradient(to right, var(--grid-color) 1px, transparent 1px), linear-gradient(to bottom, var(--grid-color) 1px, transparent 1px); background-size: 40px 40px; }
.preview-container { flex: 1; overflow: auto; display: flex; justify-content: center; align-items: flex-start; }
.scroll-wrapper { position: relative; display: flex; flex-direction: column; align-items: center; padding: 40px; touch-action: none; }

.pdf-page { box-shadow: 0 10px 30px rgba(0,0,0,0.5); border-radius: 4px; display: block; background: white; margin-bottom: 30px; }
.pdf-page.inverted { filter: invert(0.9) hue-rotate(180deg); }

#draw-canvas { position: absolute; top: 0; left: 0; z-index: 50; pointer-events: none; }

#custom-cursor {
  position: fixed; top: 0; left: 0; width: 24px; height: 24px;
  pointer-events: none; z-index: 999999; display: none;
  background: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path fill="%23ffffff" stroke="%23000000" stroke-width="1.5" d="M5.5 3.5L18.5 13.5L12.5 14.5L16.5 20.5L13.5 22.5L9.5 16.5L4.5 20.5V3.5Z"/></svg>') no-repeat;
  transform: translate(-100px, -100px);
}

.draw-toolbar { position: fixed; bottom: 30px; left: 50%; transform: translateX(-50%); background: var(--panel-bg); padding: 12px 20px; border-radius: 50px; display: flex; align-items: center; gap: 15px; box-shadow: 0 10px 30px rgba(0,0,0,0.8); border: 1px solid var(--border-color); z-index: 200; }
.tool-btn { background: transparent; border: none; color: white; cursor: pointer; padding: 8px; border-radius: 50%; display: flex; align-items: center; justify-content: center; }
.tool-btn.active { background: rgba(255,255,255,0.2); outline: 2px solid white; }
.color-dot { width: 24px; height: 24px; border-radius: 50%; cursor: pointer; border: 2px solid transparent; }
.color-dot.active { border-color: white; transform: scale(1.1); }
EOF

# 6. Write App.tsx (Logic Overhaul)
cat << 'EOF' > src/App.tsx
import { useState, useRef, useEffect, useCallback } from 'react';
import { open, save } from '@tauri-apps/api/dialog';
import { readBinaryFile, writeBinaryFile } from '@tauri-apps/api/fs';
import * as pdfjsLib from 'pdfjs-dist';
import { PDFDocument } from 'pdf-lib';
import './App.css';

pdfjsLib.GlobalWorkerOptions.workerSrc = `https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js`;

type Point = { x: number, y: number, pressure: number };
type Stroke = { color: string, size: number, points: Point[] };
type PageData = { url: string; baseWidth: number; baseHeight: number; startY: number };

export default function App() {
  const [pdfBytes, setPdfBytes] = useState<Uint8Array | null>(null);
  const [pages, setPages] = useState<PageData[]>([]);
  const [zoom, setZoom] = useState(1.0);
  const [isDrawModeOn, setIsDrawModeOn] = useState(true);
  const [isPdfInverted, setIsPdfInverted] = useState(true);
  
  const [tool, setTool] = useState<'pen' | 'eraser'>('pen');
  const [color, setColor] = useState('#ff4757');
  const [size, setSize] = useState(4);

  const canvasRef = useRef<HTMLCanvasElement>(null);
  const ctxRef = useRef<CanvasRenderingContext2D | null>(null);
  const scrollWrapperRef = useRef<HTMLDivElement>(null);
  const cursorRef = useRef<HTMLDivElement>(null);
  const strokesRef = useRef<Stroke[]>([]);
  const isDrawingRef = useRef(false);

  // 🖱️ CUSTOM CURSOR ALIGNMENT
  useEffect(() => {
    const moveCursor = (e: PointerEvent) => {
      if (cursorRef.current && isDrawModeOn) {
        cursorRef.current.style.display = 'block';
        cursorRef.current.style.left = `${e.clientX}px`;
        cursorRef.current.style.top = `${e.clientY}px`;
      }
    };
    window.addEventListener('pointermove', moveCursor);
    return () => window.removeEventListener('pointermove', moveCursor);
  }, [isDrawModeOn]);

  const redraw = useCallback(() => {
    const canvas = canvasRef.current;
    if (!canvas || !ctxRef.current) return;
    const ctx = ctxRef.current;
    const dpr = window.devicePixelRatio || 1;
    
    ctx.save();
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.restore();

    strokesRef.current.forEach(stroke => {
      if (stroke.points.length < 2) return;
      ctx.strokeStyle = stroke.color;
      ctx.lineCap = 'round';
      ctx.lineJoin = 'round';
      
      for (let i = 0; i < stroke.points.length - 1; i++) {
        const p1 = stroke.points[i];
        const p2 = stroke.points[i+1];
        ctx.beginPath();
        ctx.moveTo(p1.x, p1.y);
        ctx.lineTo(p2.x, p2.y);
        const pFactor = p1.pressure === -1 ? 1 : Math.pow(p1.pressure, 1.5) * 2;
        ctx.lineWidth = stroke.size * pFactor;
        ctx.stroke();
      }
    });
  }, []);

  const resize = useCallback(() => {
    if (!canvasRef.current || pages.length === 0) return;
    const canvas = canvasRef.current;
    const totalHeight = pages.reduce((sum, p) => sum + p.baseHeight + 30, 0);
    const maxWidth = Math.max(...pages.map(p => p.baseWidth));

    const dpr = window.devicePixelRatio || 1;
    canvas.width = maxWidth * zoom * dpr;
    canvas.height = totalHeight * zoom * dpr;
    canvas.style.width = `${maxWidth * zoom}px`;
    canvas.style.height = `${totalHeight * zoom}px`;

    const ctx = canvas.getContext('2d')!;
    ctx.setTransform(dpr * zoom, 0, 0, dpr * zoom, 0, 0);
    ctxRef.current = ctx;
    redraw();
  }, [pages, zoom, redraw]);

  useEffect(() => { resize(); }, [resize]);
  useEffect(() => { document.body.className = isDrawModeOn ? 'draw-active' : ''; }, [isDrawModeOn]);

  const loadPDF = async () => {
    const path = await open({ filters: [{ name: 'PDF', extensions: ['pdf'] }] });
    if (!path || Array.isArray(path)) return;
    const bytes = await readBinaryFile(path);
    setPdfBytes(bytes);
    
    const pdf = await pdfjsLib.getDocument({ data: bytes }).promise;
    const loadedPages: PageData[] = [];
    let currentY = 0;

    for (let i = 1; i <= pdf.numPages; i++) {
      const page = await pdf.getPage(i);
      const viewport = page.getViewport({ scale: 2.0 });
      const canvas = document.createElement('canvas');
      canvas.width = viewport.width;
      canvas.height = viewport.height;
      await page.render({ canvasContext: canvas.getContext('2d')!, viewport }).promise;
      
      loadedPages.push({ 
        url: canvas.toDataURL('image/jpeg', 0.8), 
        baseWidth: viewport.width / 2, 
        baseHeight: viewport.height / 2, 
        startY: currentY 
      });
      currentY += (viewport.height / 2) + 30;
    }
    setPages(loadedPages);
  };

  const handleDown = (e: React.PointerEvent) => {
    if (!isDrawModeOn || e.pointerType === 'mouse') return;
    isDrawingRef.current = true;
    const rect = canvasRef.current!.getBoundingClientRect();
    const x = (e.clientX - rect.left) / zoom;
    const y = (e.clientY - rect.top) / zoom;

    if (tool === 'eraser' || (e.pointerType as any) === 'eraser') {
      // Stroke Eraser Logic
      strokesRef.current = strokesRef.current.filter(s => {
        return !s.points.some(p => Math.hypot(p.x - x, p.y - y) < 20 / zoom);
      });
      redraw();
    } else {
      strokesRef.current.push({
        color, size, points: [{ x, y, pressure: e.pressure || -1 }]
      });
    }
  };

  const handleMove = (e: React.PointerEvent) => {
    if (!isDrawingRef.current) return;
    const rect = canvasRef.current!.getBoundingClientRect();
    const x = (e.clientX - rect.left) / zoom;
    const y = (e.clientY - rect.top) / zoom;
    
    const current = strokesRef.current[strokesRef.current.length - 1];
    if (tool === 'pen' && current) {
      current.points.push({ x, y, pressure: e.pressure || -1 });
      redraw();
    }
  };

  const exportPDF = async () => {
    if (!pdfBytes) return;
    const path = await save({ defaultPath: 'Annotated.pdf', filters: [{ name: 'PDF', extensions: ['pdf'] }] });
    if (!path) return;

    const pdfDoc = await PDFDocument.load(pdfBytes);
    const pdfPages = pdfDoc.getPages();

    for (let i = 0; i < pages.length; i++) {
      const pData = pages[i];
      const exportCanvas = document.createElement('canvas');
      exportCanvas.width = pData.baseWidth * 2;
      exportCanvas.height = pData.baseHeight * 2;
      const eCtx = exportCanvas.getContext('2d')!;
      eCtx.scale(2, 2);
      eCtx.translate(0, -pData.startY);

      strokesRef.current.forEach(s => {
        eCtx.strokeStyle = s.color;
        eCtx.lineCap = 'round'; eCtx.lineJoin = 'round';
        for (let j = 0; j < s.points.length - 1; j++) {
          const p1 = s.points[j]; const p2 = s.points[j+1];
          eCtx.beginPath(); eCtx.moveTo(p1.x, p1.y); eCtx.lineTo(p2.x, p2.y);
          eCtx.lineWidth = s.size * (p1.pressure === -1 ? 1 : Math.pow(p1.pressure, 1.5) * 2);
          eCtx.stroke();
        }
      });

      const png = await pdfDoc.embedPng(await (await fetch(exportCanvas.toDataURL())).arrayBuffer());
      const { width, height } = pdfPages[i].getSize();
      pdfPages[i].drawImage(png, { x: 0, y: 0, width, height });
    }

    const savedBytes = await pdfDoc.save();
    await writeBinaryFile(path, savedBytes);
    alert("Saved Successfully!");
  };

  return (
    <>
      <div id="custom-cursor" ref={cursorRef}></div>
      <header>
        <h2>📝 Teaching Annotator</h2>
        <div style={{display:'flex', gap:'10px'}}>
           <button className="btn btn-outline">Zoom: {Math.round(zoom*100)}%</button>
           <button className="btn" onClick={() => setZoom(z => z + 0.1)}>+</button>
           <button className="btn" onClick={() => setZoom(z => Math.max(0.1, z - 0.1))}>-</button>
        </div>
        <div className="header-buttons">
          <button className="btn btn-outline" onClick={() => setIsPdfInverted(!isPdfInverted)}>Invert Colors</button>
          <button className="btn btn-outline" onClick={() => setIsDrawModeOn(!isDrawModeOn)}>
            {isDrawModeOn ? "🖌️ Drawing Active" : "✋ Navigation Mode"}
          </button>
          <button className="btn btn-outline" onClick={loadPDF}>📂 Open</button>
          <button className="btn" style={{background:'#00ffcc'}} onClick={exportPDF}>💾 Save PDF</button>
        </div>
      </header>

      <div className="workspace">
        <div className="preview-container">
          <div className="scroll-wrapper" ref={scrollWrapperRef}
               onPointerDown={handleDown} onPointerMove={handleMove} onPointerUp={() => isDrawingRef.current = false}>
            <canvas id="draw-canvas" ref={canvasRef} />
            <div className="pdf-container">
              {pages.map((p, i) => (
                <img key={i} className={`pdf-page ${isPdfInverted ? 'inverted' : ''}`} src={p.url} 
                     style={{ width: p.baseWidth * zoom, height: p.baseHeight * zoom }} />
              ))}
            </div>
          </div>
        </div>
      </div>

      <div className={`draw-toolbar ${isDrawModeOn ? '' : 'force-hide'}`}>
        <button className={`tool-btn ${tool === 'pen' ? 'active' : ''}`} onClick={() => setTool('pen')}>🖊️</button>
        <button className={`tool-btn ${tool === 'eraser' ? 'active' : ''}`} onClick={() => setTool('eraser')}>🧽</button>
        <div style={{width: 1, height: 20, background: '#3a3f4b'}} />
        {['#ff4757', '#1e90ff', '#2ed573', '#ffffff'].map(c => (
          <div key={c} className={`color-dot ${color === c ? 'active' : ''}`} style={{background: c}} onClick={() => setColor(c)} />
        ))}
        <div className="size-badge">{size}</div>
        <button className="tool-btn" onClick={() => setSize(s => Math.min(50, s+2))}>+</button>
        <button className="tool-btn" onClick={() => setSize(s => Math.max(1, s-2))}>-</button>
      </div>
    </>
  );
}
EOF
