#!/bin/bash
set -e

echo "🚀 Bootstrapping Zoomable Hardware-Accurate PDF Annotator..."

# 1. Create Vite/React/TS project
npx create-vite@latest annotator-app --template react-ts
cd annotator-app

# 2. Install dependencies (Pinned versions)
npm install @tauri-apps/api@^1.5.0 pdfjs-dist@^3.11.174 pdf-lib@^1.17.1
npm install --save-dev @tauri-apps/cli@^1.5.0

# 3. Initialize Tauri
npx tauri init --app-name "TeachingAnnotator" --window-title "Teaching PDF Annotator" --dist-dir "../dist" --dev-path "http://localhost:5173" --before-build-command "npm run build" --before-dev-command "npm run dev"

# 4. Configure tauri.conf.json
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
      "identifier": "com.teaching.annotator",
      "targets": "all",
      "windows": { "certificateThumbprint": null, "digestAlgorithm": "sha256", "timestampUrl": "" }
    },
    "security": { "csp": null },
    "windows": [
      {
        "fullscreen": false,
        "height": 900,
        "resizable": true,
        "title": "Teaching PDF Annotator",
        "width": 1400
      }
    ]
  }
}
EOF

# 5. Write App.css
cat << 'EOF' > src/App.css
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;800&display=swap');

:root {
  --bg-dark: #0f1115; --panel-bg: #1a1c23; --border-color: #3a3f4b;
  --grid-color: rgba(255, 255, 255, 0.05);
}

* { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Inter', sans-serif; user-select: none; }
body { background-color: var(--bg-dark); color: #ffffff; overflow: hidden; height: 100vh; display: flex; flex-direction: column; }
header { background-color: var(--panel-bg); padding: 15px 30px; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--border-color); z-index: 100; }

.header-buttons { display: flex; gap: 10px; align-items: center; }
.btn { background: #ffffff; color: #000000; border: none; padding: 9px 15px; font-size: 0.85rem; font-weight: 800; border-radius: 6px; cursor: pointer; transition: all 0.2s; }
.btn:active { transform: translate(2px, 2px); }
.btn-outline { background: transparent; color: #ffffff; border: 1px solid var(--border-color); }
.btn-outline:hover { background: rgba(255,255,255,0.1); }
.btn:disabled { opacity: 0.5; cursor: not-allowed; }

.zoom-controls { display: flex; align-items: center; background: #2c2f33; border-radius: 6px; overflow: hidden; border: 1px solid var(--border-color); }
.zoom-controls button { background: transparent; color: white; border: none; padding: 8px 12px; cursor: pointer; font-weight: bold; }
.zoom-controls button:hover { background: rgba(255,255,255,0.1); }
.zoom-controls span { padding: 0 10px; font-family: monospace; font-size: 0.9rem; min-width: 60px; text-align: center; }

.workspace { display: flex; flex: 1; overflow: hidden; position: relative; background-image: linear-gradient(to right, var(--grid-color) 1px, transparent 1px), linear-gradient(to bottom, var(--grid-color) 1px, transparent 1px); background-size: 40px 40px; background-position: center top; }
.preview-container { flex: 1; overflow: auto; display: flex; justify-content: center; align-items: flex-start; scroll-behavior: smooth; }
.scroll-wrapper { position: relative; display: flex; flex-direction: column; align-items: center; padding: 40px; touch-action: none; transform-origin: top center; transition: width 0.1s, height 0.1s; }

.pdf-container { display: flex; flex-direction: column; gap: 30px; position: relative; z-index: 10; }
.pdf-page { box-shadow: 0 10px 30px rgba(0,0,0,0.5); border-radius: 4px; display: block; background: white; transition: filter 0.3s ease; }
.pdf-page.inverted { filter: invert(0.9) hue-rotate(180deg); }

#draw-canvas { position: absolute; top: 0; left: 0; z-index: 50; pointer-events: none; }

.draw-toolbar { position: fixed; bottom: 30px; left: 50%; transform: translateX(-50%); background: var(--panel-bg); padding: 12px 20px; border-radius: 50px; display: flex; align-items: center; gap: 15px; box-shadow: 0 10px 30px rgba(0,0,0,0.8); border: 1px solid var(--border-color); z-index: 200; opacity: 0; pointer-events: none; transition: all 0.3s ease; }
.draw-toolbar.visible { opacity: 1; pointer-events: auto; }
.draw-toolbar.force-hide { display: none !important; }
.tool-btn { background: transparent; border: none; color: white; cursor: pointer; padding: 8px; border-radius: 50%; display: flex; align-items: center; justify-content: center; }
.tool-btn.active { background: rgba(255,255,255,0.2); outline: 2px solid white; }
.color-dot { width: 24px; height: 24px; border-radius: 50%; cursor: pointer; border: 2px solid transparent; }
.color-dot.active { transform: scale(1.2); border-color: white; }
.size-badge { font-family: monospace; font-size: 0.9rem; font-weight: bold; color: #00ffcc; min-width: 25px; text-align: center; }
.hide-toolbar-btn { font-size: 0.8rem; background: rgba(255,255,255,0.1); border-radius: 20px; padding: 5px 10px; color: white; border: none; cursor: pointer; margin-left: 10px; }
EOF

# 6. Write App.tsx (Unused variables removed!)
cat << 'EOF' > src/App.tsx
import { useState, useRef, useEffect } from 'react';
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
  const [isPdfInverted, setIsPdfInverted] = useState(true);
  const [isDrawModeOn, setIsDrawModeOn] = useState(false);
  const [isToolbarHidden, setIsToolbarHidden] = useState(false);
  const [zoom, setZoom] = useState(1.0);
  
  const [tool, setTool] = useState<'pen' | 'eraser'>('pen');
  const [color, setColor] = useState('#ff4757');
  const [size, setSize] = useState(4);
  const [usePressure, setUsePressure] = useState(true);

  const wrapperRef = useRef<HTMLDivElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const ctxRef = useRef<CanvasRenderingContext2D | null>(null);

  // Math State
  const zoomRef = useRef(1.0);
  const strokesRef = useRef<Stroke[]>([]);
  const currentStrokeRef = useRef<Stroke | null>(null);
  const isDrawingRef = useRef(false);
  const tempToolRevertRef = useRef<'pen' | 'eraser' | null>(null);
  const cursorRef = useRef<HTMLDivElement>(null);

  useEffect(() => { zoomRef.current = zoom; resizeCanvasToDocument(); }, [zoom, pages]);

  useEffect(() => {
    const handlePointerMove = (e: PointerEvent) => {
      if (isDrawModeOn && cursorRef.current && (e.pointerType as string) !== 'mouse') {
        cursorRef.current.style.transform = `translate(${e.clientX - 1}px, ${e.clientY - 2}px)`;
      }
    };
    window.addEventListener('pointermove', handlePointerMove);
    return () => window.removeEventListener('pointermove', handlePointerMove);
  }, [isDrawModeOn]);

  const resizeCanvasToDocument = () => {
    if (!wrapperRef.current || !canvasRef.current || pages.length === 0) return;
    
    // Calculate total base dimensions
    let totalBaseHeight = 0;
    let maxBaseWidth = 0;
    pages.forEach(p => {
      totalBaseHeight += p.baseHeight + 30; // 30px gap
      maxBaseWidth = Math.max(maxBaseWidth, p.baseWidth);
    });

    const currentZoom = zoomRef.current;
    const cssWidth = maxBaseWidth * currentZoom;
    const cssHeight = totalBaseHeight * currentZoom;

    const canvas = canvasRef.current;
    canvas.style.width = cssWidth + 'px';
    canvas.style.height = cssHeight + 'px';
    
    const dpr = window.devicePixelRatio || 1;
    canvas.width = cssWidth * dpr;
    canvas.height = cssHeight * dpr;
    
    const ctx = canvas.getContext('2d');
    if (ctx) {
      // Scale context so 1 drawing unit = 1 base PDF pixel
      ctx.setTransform(dpr * currentZoom, 0, 0, dpr * currentZoom, 0, 0);
      ctxRef.current = ctx;
      redrawCanvas();
    }
  };

  const redrawCanvas = () => {
    const canvas = canvasRef.current;
    const ctx = ctxRef.current;
    if (!canvas || !ctx) return;
    
    ctx.save();
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.restore();

    for (let stroke of strokesRef.current) {
      if (stroke.points.length < 2) continue;
      ctx.strokeStyle = stroke.color;
      ctx.lineCap = 'round'; ctx.lineJoin = 'round';

      for (let i = 0; i < stroke.points.length - 1; i++) {
        let p1 = stroke.points[i], p2 = stroke.points[i + 1];
        ctx.beginPath();
        ctx.moveTo(p1.x, p1.y);
        ctx.lineTo(p2.x, p2.y);
        let pFactor = (p1.pressure === -1) ? 1 : Math.pow(p1.pressure, 1.5) * 2;
        ctx.lineWidth = stroke.size * pFactor;
        ctx.stroke();
      }
    }
  };

  const distPointToSegment = (px: number, py: number, x1: number, y1: number, x2: number, y2: number) => {
    let l2 = (x2 - x1) ** 2 + (y2 - y1) ** 2;
    if (l2 === 0) return Math.hypot(px - x1, py - y1);
    let t = Math.max(0, Math.min(1, ((px - x1) * (x2 - x1) + (py - y1) * (y2 - y1)) / l2));
    return Math.hypot(px - (x1 + t * (x2 - x1)), py - (y1 + t * (y2 - y1)));
  };

  const eraseStrokesAt = (baseX: number, baseY: number) => {
    let hitRadius = 20 / zoomRef.current; // Scale eraser size inversely to zoom
    let beforeCount = strokesRef.current.length;
    strokesRef.current = strokesRef.current.filter(stroke => {
      for (let i = 0; i < stroke.points.length - 1; i++) {
        let d = distPointToSegment(baseX, baseY, stroke.points[i].x, stroke.points[i].y, stroke.points[i + 1].x, stroke.points[i + 1].y);
        if (d <= hitRadius) return false;
      }
      return true;
    });
    if (strokesRef.current.length !== beforeCount) redrawCanvas();
  };

  const getBaseCoords = (e: React.PointerEvent) => {
    const rect = canvasRef.current!.getBoundingClientRect();
    const cssX = e.clientX - rect.left;
    const cssY = e.clientY - rect.top;
    return { x: cssX / zoomRef.current, y: cssY / zoomRef.current };
  };

  const handlePointerDown = (e: React.PointerEvent) => {
    if (!isDrawModeOn || (e.pointerType as string) === 'mouse' || !canvasRef.current) return;
    (e.target as HTMLElement).setPointerCapture(e.pointerId);
    isDrawingRef.current = true;
    
    if ((e.pointerType as string) === 'eraser' || e.button === 5 || (e.buttons & 32)) {
      tempToolRevertRef.current = tool;
      setTool('eraser');
    }

    const coords = getBaseCoords(e);
    const currentActualTool = tempToolRevertRef.current ? 'eraser' : tool;

    if (currentActualTool === 'eraser') eraseStrokesAt(coords.x, coords.y);
    else {
      let pValue = (e.pressure && usePressure && (e.pointerType as string) === 'pen') ? e.pressure : -1;
      currentStrokeRef.current = { color, size, points: [{ x: coords.x, y: coords.y, pressure: pValue }] };
      strokesRef.current.push(currentStrokeRef.current);
    }
  };

  const handlePointerMove = (e: React.PointerEvent) => {
    if (!isDrawingRef.current || !isDrawModeOn || (e.pointerType as string) === 'mouse' || !canvasRef.current || !ctxRef.current) return;
    
    const coords = getBaseCoords(e);
    const currentActualTool = tempToolRevertRef.current ? 'eraser' : tool;

    if (currentActualTool === 'eraser') eraseStrokesAt(coords.x, coords.y);
    else if (currentStrokeRef.current) {
      let pValue = ((e.pointerType as string) === 'pen' && e.pressure && usePressure) ? e.pressure : -1;
      currentStrokeRef.current.points.push({ x: coords.x, y: coords.y, pressure: pValue });
      
      let pts = currentStrokeRef.current.points;
      let p1 = pts[pts.length - 2], p2 = pts[pts.length - 1];
      
      let ctx = ctxRef.current;
      ctx.beginPath(); ctx.moveTo(p1.x, p1.y); ctx.lineTo(p2.x, p2.y);
      ctx.lineCap = 'round'; ctx.lineJoin = 'round';
      let pFactor = (p1.pressure === -1) ? 1 : Math.pow(p1.pressure, 1.5) * 2;
      ctx.lineWidth = currentStrokeRef.current.size * pFactor;
      ctx.strokeStyle = currentStrokeRef.current.color; ctx.stroke();
    }
  };

  const handlePointerUp = (e: React.PointerEvent) => {
    if ((e.pointerType as string) === 'mouse') return;
    isDrawingRef.current = false; currentStrokeRef.current = null;
    if (tempToolRevertRef.current) { setTool(tempToolRevertRef.current); tempToolRevertRef.current = null; }
  };

  const loadPDF = async () => {
    try {
      const selectedPath = await open({ filters: [{ name: 'PDF', extensions: ['pdf'] }] });
      if (!selectedPath || Array.isArray(selectedPath)) return;
      
      const bytes = await readBinaryFile(selectedPath);
      setPdfBytes(bytes);
      strokesRef.current = []; 
      
      const pdf = await pdfjsLib.getDocument({ data: bytes }).promise;
      const renderedPages: PageData[] = [];
      let currentY = 0;

      // Render at 2.0 scale internally so zooming in looks crisp
      for (let i = 1; i <= pdf.numPages; i++) {
        const page = await pdf.getPage(i);
        const viewport = page.getViewport({ scale: 2.0 });
        const canvas = document.createElement('canvas');
        canvas.width = viewport.width; canvas.height = viewport.height;
        await page.render({ canvasContext: canvas.getContext('2d')!, viewport }).promise;
        
        // Base width is scale 1.0 equivalent
        const baseWidth = viewport.width / 2.0;
        const baseHeight = viewport.height / 2.0;
        
        renderedPages.push({ url: canvas.toDataURL('image/jpeg', 0.8), baseWidth, baseHeight, startY: currentY });
        currentY += baseHeight + 30; // 30px gap
      }
      setPages(renderedPages);
      setZoom(1.0);
    } catch (err) { console.error("Failed to load PDF", err); }
  };

  const exportPDF = async (withAnnotations: boolean) => {
    if (!pdfBytes) return;
    try {
      const savePath = await save({ defaultPath: 'Exported.pdf', filters: [{ name: 'PDF', extensions: ['pdf'] }] });
      if (!savePath) return;

      if (!withAnnotations) {
        await writeBinaryFile(savePath, pdfBytes); return;
      }

      const pdfDoc = await PDFDocument.load(pdfBytes);
      const pdfPages = pdfDoc.getPages();
      const exportScale = 2.0; // Export sharp ink regardless of UI zoom

      for (let i = 0; i < pages.length; i++) {
        const page = pages[i];
        
        // Dynamically create a canvas JUST for this page's annotations
        const exportCanvas = document.createElement('canvas');
        exportCanvas.width = page.baseWidth * exportScale;
        exportCanvas.height = page.baseHeight * exportScale;
        const eCtx = exportCanvas.getContext('2d')!;
        
        eCtx.scale(exportScale, exportScale);
        eCtx.translate(0, -page.startY); // Shift coordinate system up to match this page

        // Draw all strokes (those outside the page bounding box get clipped natively by canvas)
        for (let stroke of strokesRef.current) {
          if (stroke.points.length < 2) continue;
          eCtx.strokeStyle = stroke.color;
          eCtx.lineCap = 'round'; eCtx.lineJoin = 'round';
          for (let j = 0; j < stroke.points.length - 1; j++) {
            let p1 = stroke.points[j], p2 = stroke.points[j + 1];
            eCtx.beginPath(); eCtx.moveTo(p1.x, p1.y); eCtx.lineTo(p2.x, p2.y);
            let pFactor = (p1.pressure === -1) ? 1 : Math.pow(p1.pressure, 1.5) * 2;
            eCtx.lineWidth = stroke.size * pFactor; eCtx.stroke();
          }
        }

        const pngImageBytes = await new Promise<Uint8Array>((resolve) => {
          exportCanvas.toBlob(async (blob) => {
            const buf = await blob!.arrayBuffer();
            resolve(new Uint8Array(buf));
          }, 'image/png');
        });

        const embeddedPng = await pdfDoc.embedPng(pngImageBytes);
        const pdfPage = pdfPages[i];
        const { width, height } = pdfPage.getSize();
        pdfPage.drawImage(embeddedPng, { x: 0, y: 0, width, height });
      }

      const finalPdfBytes = await pdfDoc.save();
      await writeBinaryFile(savePath, finalPdfBytes);
      alert("Export Successful!");
    } catch (err) { console.error("Export failed:", err); alert("Export failed."); }
  };

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key.toLowerCase() === 'h') { setIsToolbarHidden(prev => !prev); return; }
      if (!isDrawModeOn) return;
      switch(e.key.toLowerCase()) {
        case 'w': setUsePressure(p => !p); break; 
        case 'p': setTool('pen'); break;
        case 'e': setTool('eraser'); break;
        case 'c': strokesRef.current = []; redrawCanvas(); break;
        case ']': setSize(s => Math.min(60, s + 2)); break;
        case '[': setSize(s => Math.max(1, s - 2)); break;
      }
    };
    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [isDrawModeOn]);

  return (
    <>
      <div id="custom-cursor" ref={cursorRef} style={{ display: isDrawModeOn ? 'block' : 'none', position: 'fixed', top: 0, left: 0, width: 24, height: 24, pointerEvents: 'none', zIndex: 999999, background: `url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path fill="%23ffffff" stroke="%23000000" stroke-width="1.5" d="M5.5 3.5L18.5 13.5L12.5 14.5L16.5 20.5L13.5 22.5L9.5 16.5L4.5 20.5V3.5Z"/></svg>') no-repeat`, transformOrigin: 'top left' }}></div>
      <header>
        <h2>📝 Teaching Annotator</h2>
        
        <div className="zoom-controls">
          <button disabled={zoom <= 0.5} onClick={() => setZoom(z => Math.max(0.5, z - 0.25))}>-</button>
          <span>{Math.round(zoom * 100)}%</span>
          <button disabled={zoom >= 3.0} onClick={() => setZoom(z => Math.min(3.0, z + 0.25))}>+</button>
        </div>

        <div className="header-buttons">
          <button className="btn btn-outline" onClick={() => setIsPdfInverted(!isPdfInverted)}>
            {isPdfInverted ? '☀️ Lighten PDF' : '🌙 Darken PDF'}
          </button>
          <button className="btn" style={{background: isDrawModeOn ? '#2ed573' : '#ff4757', color: 'white'}} onClick={() => setIsDrawModeOn(!isDrawModeOn)}>
            🖌️ Draw ({isDrawModeOn ? 'ON' : 'OFF'})
          </button>
          <button className="btn btn-outline" onClick={loadPDF}>📂 Open PDF</button>
          {pages.length > 0 && (
            <>
              <button className="btn" onClick={() => exportPDF(false)}>💾 Original</button>
              <button className="btn" style={{background: '#00ffcc'}} onClick={() => exportPDF(true)}>🔥 Annotated</button>
            </>
          )}
        </div>
      </header>

      <div className="workspace">
        <div className="preview-container">
          <div className="scroll-wrapper" ref={wrapperRef} style={{ touchAction: isDrawModeOn ? 'none' : 'auto' }}
               onPointerDown={handlePointerDown} onPointerMove={handlePointerMove} onPointerUp={handlePointerUp} onPointerCancel={handlePointerUp} onPointerOut={handlePointerUp}>
            
            <canvas id="draw-canvas" ref={canvasRef} />
            
            <div className="pdf-container">
               {pages.length === 0 && <div style={{textAlign: 'center', color: '#888', marginTop: '30vh'}}>Upload a PDF to start annotating...</div>}
               {pages.map((p, i) => (
                  <img key={i} className={`pdf-page ${isPdfInverted ? 'inverted' : ''}`} src={p.url} style={{ width: p.baseWidth * zoom, height: p.baseHeight * zoom }} alt={`Page ${i+1}`} />
               ))}
            </div>

          </div>
        </div>

        {isDrawModeOn && (
          <div className={`draw-toolbar ${isToolbarHidden ? 'force-hide' : 'visible'}`}>
            <button className={`tool-btn ${tool === 'pen' ? 'active' : ''}`} onClick={() => setTool('pen')}>🖊️</button>
            <button className={`tool-btn ${usePressure ? 'active' : ''}`} onClick={() => setUsePressure(!usePressure)}>〰️</button>
            <button className={`tool-btn ${tool === 'eraser' ? 'active' : ''}`} onClick={() => setTool('eraser')}>🧽</button>
            <div style={{width: 1, height: 20, background: '#3a3f4b'}} />
            <div className={`color-dot ${color === '#ff4757' ? 'active' : ''}`} style={{background: '#ff4757'}} onClick={() => {setColor('#ff4757'); setTool('pen');}} />
            <div className={`color-dot ${color === '#1e90ff' ? 'active' : ''}`} style={{background: '#1e90ff'}} onClick={() => {setColor('#1e90ff'); setTool('pen');}} />
            <div className={`color-dot ${color === '#2ed573' ? 'active' : ''}`} style={{background: '#2ed573'}} onClick={() => {setColor('#2ed573'); setTool('pen');}} />
            <div className={`color-dot ${color === '#eccc68' ? 'active' : ''}`} style={{background: '#eccc68'}} onClick={() => {setColor('#eccc68'); setTool('pen');}} />
            <div className={`color-dot ${color === '#ffffff' ? 'active' : ''}`} style={{background: '#ffffff'}} onClick={() => {setColor('#ffffff'); setTool('pen');}} />
            <div style={{width: 1, height: 20, background: '#3a3f4b'}} />
            <button className="tool-btn" onClick={() => setSize(s => Math.max(1, s - 2))}>➖</button>
            <span className="size-badge">{size}</span>
            <button className="tool-btn" onClick={() => setSize(s => Math.min(60, s + 2))}>➕</button>
            <button className="tool-btn" onClick={() => { strokesRef.current = []; redrawCanvas(); }}>🗑️</button>
            <button className="hide-toolbar-btn" onClick={() => setIsToolbarHidden(true)}>👁️ Hide [H]</button>
          </div>
        )}
      </div>
    </>
  );
}
EOF

echo "✅ Zoomable PDF Annotator App generated successfully!"
