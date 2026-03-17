#!/bin/bash
set -e

echo "🚀 Bootstrapping Teaching PDF Annotator..."

# 1. Create Vite/React/TS project (avoiding create-tauri-app interactive prompts)
npx create-vite@latest annotator-app --template react-ts
cd annotator-app

# 2. Install dependencies
npm install @tauri-apps/api@^1.5.0 pdfjs-dist@^3.11.174 pdf-lib@^1.17.5 lucide-react
npm install --save-dev @tauri-apps/cli@^1.5.0

# 3. Initialize Tauri
npx tauri init --app-name "TeachingAnnotator" --window-title "Teaching PDF Annotator" --dist-dir "../dist" --dev-path "http://localhost:5173" --before-build-command "npm run build" --before-dev-command "npm run dev"

# 4. Configure tauri.conf.json to allow Dialog and FS APIs
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
      "dialog": { "all": true },
      "fs": { "all": true, "scope": ["**"] },
      "path": { "all": true }
    },
    "bundle": {
      "active": true,
      "category": "Education",
      "copyright": "",
      "deb": { "depends": [] },
      "externalBin": [],
      "icon": [
        "icons/32x32.png",
        "icons/128x128.png",
        "icons/128x128@2x.png",
        "icons/icon.icns",
        "icons/icon.ico"
      ],
      "identifier": "com.teaching.annotator",
      "longDescription": "",
      "macOS": { "entitlements": null, "exceptionDomain": "", "frameworks": [], "providerShortName": null, "signingIdentity": null },
      "resources": [],
      "shortDescription": "",
      "targets": "all",
      "windows": { "certificateThumbprint": null, "digestAlgorithm": "sha256", "timestampUrl": "" }
    },
    "security": { "csp": null },
    "updater": { "active": false },
    "windows": [
      {
        "fullscreen": false,
        "height": 800,
        "resizable": true,
        "title": "Teaching PDF Annotator",
        "width": 1200
      }
    ]
  }
}
EOF

# 5. Write App.css (Dark Mode + Grid)
cat << 'EOF' > src/App.css
:root {
  --bg-dark: #0f1115;
  --panel-bg: #1a1c23;
  --border-color: #3a3f4b;
  --grid-color: rgba(255, 255, 255, 0.05);
}

* { box-sizing: border-box; margin: 0; padding: 0; user-select: none; }

body {
  background-color: var(--bg-dark);
  color: #ffffff;
  font-family: 'Inter', system-ui, sans-serif;
  overflow: hidden;
}

.header {
  background-color: var(--panel-bg);
  padding: 15px 30px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid var(--border-color);
  z-index: 100;
}

.btn {
  background: #ffffff; color: #000000; border: none; padding: 9px 15px;
  font-size: 0.85rem; font-weight: 800; border-radius: 6px; cursor: pointer;
  transition: all 0.2s; margin-left: 10px;
}
.btn:hover { opacity: 0.9; }
.btn-outline { background: transparent; color: #ffffff; border: 1px solid var(--border-color); }

.workspace {
  display: flex; flex: 1; height: calc(100vh - 60px); overflow: auto;
  position: relative;
  background-image: linear-gradient(to right, var(--grid-color) 1px, transparent 1px),
                    linear-gradient(to bottom, var(--grid-color) 1px, transparent 1px);
  background-size: 40px 40px; justify-content: center;
}

.pdf-wrapper { position: relative; margin: 40px; display: flex; flex-direction: column; gap: 20px; }

canvas.pdf-page {
  box-shadow: 0 10px 30px rgba(0,0,0,0.5); border-radius: 4px;
  background: white; filter: invert(0.9) hue-rotate(180deg);
}

canvas#draw-layer {
  position: absolute; top: 0; left: 0;
  pointer-events: auto; touch-action: none;
  z-index: 50; cursor: crosshair;
}

.toolbar {
  position: fixed; bottom: 30px; left: 50%; transform: translateX(-50%);
  background: var(--panel-bg); padding: 12px 20px; border-radius: 50px;
  display: flex; align-items: center; gap: 15px; border: 1px solid var(--border-color);
  box-shadow: 0 10px 30px rgba(0,0,0,0.8); z-index: 200;
}

.tool-btn {
  background: transparent; border: none; color: white; cursor: pointer; padding: 8px;
  border-radius: 50%; display: flex; align-items: center; justify-content: center;
}
.tool-btn.active { background: rgba(255,255,255,0.2); outline: 2px solid white; }
.color-dot { width: 24px; height: 24px; border-radius: 50%; cursor: pointer; border: 2px solid transparent; }
.color-dot.active { transform: scale(1.2); border-color: white; }
EOF

# 6. Write App.tsx (Core Logic)
cat << 'EOF' > src/App.tsx
import { useState, useRef, useEffect } from 'react';
import { open, save } from '@tauri-apps/api/dialog';
import { readBinaryFile, writeBinaryFile } from '@tauri-apps/api/fs';
import * as pdfjsLib from 'pdfjs-dist';
import { PDFDocument } from 'pdf-lib';
import './App.css';

pdfjsLib.GlobalWorkerOptions.workerSrc = `https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js`;

export default function App() {
  const [pdfBytes, setPdfBytes] = useState<Uint8Array | null>(null);
  const [pages, setPages] = useState<{ canvas: HTMLCanvasElement; width: number; height: number }[]>([]);
  const drawLayerRef = useRef<HTMLCanvasElement>(null);
  const wrapperRef = useRef<HTMLDivElement>(null);

  // Drawing State
  const [tool, setTool] = useState<'pen' | 'eraser'>('pen');
  const [color, setColor] = useState('#ff4757');
  const [size, setSize] = useState(4);
  const isDrawing = useRef(false);
  const ctxRef = useRef<CanvasRenderingContext2D | null>(null);

  useEffect(() => {
    if (drawLayerRef.current) {
      const ctx = drawLayerRef.current.getContext('2d');
      if (ctx) {
        ctx.lineCap = 'round';
        ctx.lineJoin = 'round';
        ctxRef.current = ctx;
      }
    }
  }, [pages]);

  const loadPDF = async () => {
    try {
      const selectedPath = await open({ filters: [{ name: 'PDF', extensions: ['pdf'] }] });
      if (!selectedPath || Array.isArray(selectedPath)) return;
      
      const bytes = await readBinaryFile(selectedPath);
      setPdfBytes(bytes);
      
      const loadingTask = pdfjsLib.getDocument({ data: bytes });
      const pdf = await loadingTask.promise;
      
      const renderedPages = [];
      let totalHeight = 0;
      let maxWidth = 0;

      for (let i = 1; i <= pdf.numPages; i++) {
        const page = await pdf.getPage(i);
        const viewport = page.getViewport({ scale: 2.0 }); // High DPI
        
        const canvas = document.createElement('canvas');
        const ctx = canvas.getContext('2d')!;
        canvas.width = viewport.width;
        canvas.height = viewport.height;
        
        await page.render({ canvasContext: ctx, viewport }).promise;
        renderedPages.push({ canvas, width: viewport.width, height: viewport.height });
        
        totalHeight += viewport.height + 20; // 20px gap
        maxWidth = Math.max(maxWidth, viewport.width);
      }
      
      setPages(renderedPages);

      // Setup giant transparent canvas covering all pages
      if (drawLayerRef.current) {
        drawLayerRef.current.width = maxWidth;
        drawLayerRef.current.height = totalHeight - 20;
      }
    } catch (err) {
      console.error("Failed to load PDF", err);
    }
  };

  const handlePointerDown = (e: React.PointerEvent) => {
    if (!ctxRef.current || !drawLayerRef.current) return;
    isDrawing.current = true;
    
    // Hardware Eraser Map
    if (e.pointerType === 'eraser' || e.button === 5) {
      ctxRef.current.globalCompositeOperation = 'destination-out';
      ctxRef.current.lineWidth = size * 5;
    } else {
      ctxRef.current.globalCompositeOperation = tool === 'eraser' ? 'destination-out' : 'source-over';
      ctxRef.current.strokeStyle = color;
      ctxRef.current.lineWidth = size;
    }

    const rect = drawLayerRef.current.getBoundingClientRect();
    ctxRef.current.beginPath();
    ctxRef.current.moveTo(e.clientX - rect.left, e.clientY - rect.top);
  };

  const handlePointerMove = (e: React.PointerEvent) => {
    if (!isDrawing.current || !ctxRef.current || !drawLayerRef.current) return;
    
    // Pressure sensitivity scaling
    const pressureMultiplier = e.pointerType === 'pen' && e.pressure > 0 ? e.pressure * 2 : 1;
    ctxRef.current.lineWidth = size * pressureMultiplier;

    const rect = drawLayerRef.current.getBoundingClientRect();
    ctxRef.current.lineTo(e.clientX - rect.left, e.clientY - rect.top);
    ctxRef.current.stroke();
  };

  const handlePointerUp = () => {
    isDrawing.current = false;
    if (ctxRef.current) ctxRef.current.closePath();
  };

  const exportPDF = async (withAnnotations: boolean) => {
    if (!pdfBytes) return;
    try {
      const savePath = await save({ defaultPath: 'Exported.pdf', filters: [{ name: 'PDF', extensions: ['pdf'] }] });
      if (!savePath) return;

      if (!withAnnotations) {
        await writeBinaryFile(savePath, pdfBytes);
        return;
      }

      // Merge Annotations natively
      const pdfDoc = await PDFDocument.load(pdfBytes);
      const pdfPages = pdfDoc.getPages();
      
      let currentYOffset = 0;

      for (let i = 0; i < pages.length; i++) {
        const pageData = pages[i];
        
        // Slice the master canvas for this specific page
        const sliceCanvas = document.createElement('canvas');
        sliceCanvas.width = pageData.width;
        sliceCanvas.height = pageData.height;
        const sCtx = sliceCanvas.getContext('2d')!;
        
        sCtx.drawImage(
          drawLayerRef.current!,
          0, currentYOffset, pageData.width, pageData.height,
          0, 0, pageData.width, pageData.height
        );
        
        const pngImageBytes = await new Promise<Uint8Array>((resolve) => {
          sliceCanvas.toBlob(async (blob) => {
            const buf = await blob!.arrayBuffer();
            resolve(new Uint8Array(buf));
          }, 'image/png');
        });

        // Embed png natively into pdf-lib
        const embeddedPng = await pdfDoc.embedPng(pngImageBytes);
        const pdfPage = pdfPages[i];
        const { width, height } = pdfPage.getSize();
        
        pdfPage.drawImage(embeddedPng, {
          x: 0, y: 0,
          width: width, height: height,
        });

        currentYOffset += pageData.height + 20; // Move to next slice
      }

      const finalPdfBytes = await pdfDoc.save();
      await writeBinaryFile(savePath, finalPdfBytes);

    } catch (err) {
      console.error("Export failed:", err);
    }
  };

  return (
    <>
      <header className="header">
        <h2>📝 Teaching PDF Annotator</h2>
        <div>
          <button className="btn btn-outline" onClick={loadPDF}>📂 Load PDF</button>
          <button className="btn" onClick={() => exportPDF(false)}>💾 Export Original</button>
          <button className="btn" style={{background: '#00ffcc'}} onClick={() => exportPDF(true)}>🔥 Export Annotated</button>
        </div>
      </header>

      <div className="workspace">
        <div className="pdf-wrapper" ref={wrapperRef}>
           {pages.map((p, i) => (
              <img 
                key={i} 
                src={p.canvas.toDataURL()} 
                style={{ width: p.width, height: p.height, filter: 'invert(0.9) hue-rotate(180deg)', borderRadius: 4, boxShadow: '0 10px 30px rgba(0,0,0,0.5)' }} 
                alt={`Page ${i+1}`} 
              />
           ))}
           
           {pages.length > 0 && (
             <canvas
               id="draw-layer"
               ref={drawLayerRef}
               onPointerDown={handlePointerDown}
               onPointerMove={handlePointerMove}
               onPointerUp={handlePointerUp}
               onPointerCancel={handlePointerUp}
               onPointerOut={handlePointerUp}
             />
           )}
        </div>
      </div>

      <div className="toolbar">
        <button className={`tool-btn ${tool === 'pen' ? 'active' : ''}`} onClick={() => setTool('pen')}>✏️</button>
        <button className={`tool-btn ${tool === 'eraser' ? 'active' : ''}`} onClick={() => setTool('eraser')}>🧽</button>
        <div style={{width: 1, height: 20, background: '#3a3f4b'}} />
        <div className={`color-dot ${color === '#ff4757' ? 'active' : ''}`} style={{background: '#ff4757'}} onClick={() => {setColor('#ff4757'); setTool('pen');}} />
        <div className={`color-dot ${color === '#1e90ff' ? 'active' : ''}`} style={{background: '#1e90ff'}} onClick={() => {setColor('#1e90ff'); setTool('pen');}} />
        <div className={`color-dot ${color === '#2ed573' ? 'active' : ''}`} style={{background: '#2ed573'}} onClick={() => {setColor('#2ed573'); setTool('pen');}} />
        <div className={`color-dot ${color === '#ffffff' ? 'active' : ''}`} style={{background: '#ffffff'}} onClick={() => {setColor('#ffffff'); setTool('pen');}} />
        <div style={{width: 1, height: 20, background: '#3a3f4b'}} />
        <button className="tool-btn" onClick={() => setSize(s => Math.max(1, s - 2))}>➖</button>
        <span style={{fontFamily: 'monospace'}}>{size}</span>
        <button className="tool-btn" onClick={() => setSize(s => Math.min(50, s + 2))}>➕</button>
      </div>
    </>
  );
}
EOF

# Build routine check (Optional, comment out if strictly running in CI)
echo "✅ Generation complete. Run 'cd annotator-app && npm install && npm run tauri dev' to test locally."
