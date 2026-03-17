#!/usr/bin/env bash
set -euo pipefail

echo "============================================="
echo " Teaching PDF Annotator - Full Build Script"
echo "============================================="

# -----------------------------------------------
# 1. CREATE package.json
# -----------------------------------------------
cat > package.json << 'PACKAGEJSONEOF'
{
  "name": "teaching-pdf-annotator",
  "private": true,
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "tauri": "tauri"
  },
  "dependencies": {
    "@tauri-apps/api": "^1.5.6",
    "pdf-lib": "^1.17.1",
    "pdfjs-dist": "^3.11.174",
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "devDependencies": {
    "@tauri-apps/cli": "^1.5.14",
    "@types/react": "^18.2.79",
    "@types/react-dom": "^18.2.25",
    "@vitejs/plugin-react": "^4.2.1",
    "typescript": "^5.4.5",
    "vite": "^5.2.11"
  }
}
PACKAGEJSONEOF

echo "[1/15] package.json created."

# -----------------------------------------------
# 2. CREATE tsconfig.json
# -----------------------------------------------
cat > tsconfig.json << 'TSCONFIGEOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": false,
    "noUnusedParameters": false,
    "noFallthroughCasesInSwitch": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
TSCONFIGEOF

echo "[2/15] tsconfig.json created."

# -----------------------------------------------
# 3. CREATE tsconfig.node.json
# -----------------------------------------------
cat > tsconfig.node.json << 'TSCONFIGNODEEOF'
{
  "compilerOptions": {
    "composite": true,
    "skipLibCheck": true,
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowSyntheticDefaultImports": true
  },
  "include": ["vite.config.ts"]
}
TSCONFIGNODEEOF

echo "[3/15] tsconfig.node.json created."

# -----------------------------------------------
# 4. CREATE vite.config.ts
# -----------------------------------------------
cat > vite.config.ts << 'VITECONFIGEOF'
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig(async () => ({
  plugins: [react()],
  clearScreen: false,
  server: {
    port: 1420,
    strictPort: true,
  },
  envPrefix: ["VITE_", "TAURI_"],
  build: {
    target: ["es2021", "chrome100", "safari13"],
    minify: !process.env.TAURI_DEBUG ? "esbuild" : false,
    sourcemap: !!process.env.TAURI_DEBUG,
  },
}));
VITECONFIGEOF

echo "[4/15] vite.config.ts created."

# -----------------------------------------------
# 5. CREATE index.html
# -----------------------------------------------
cat > index.html << 'INDEXHTMLEOF'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Teaching PDF Annotator</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
INDEXHTMLEOF

echo "[5/15] index.html created."

# -----------------------------------------------
# 6. CREATE src directory and main.tsx
# -----------------------------------------------
mkdir -p src

cat > src/main.tsx << 'MAINTSXEOF'
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import "./App.css";

ReactDOM.createRoot(document.getElementById("root") as HTMLElement).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
MAINTSXEOF

echo "[6/15] src/main.tsx created."

# -----------------------------------------------
# 7. CREATE src/vite-env.d.ts
# -----------------------------------------------
cat > src/vite-env.d.ts << 'VITEENVEOF'
/// <reference types="vite/client" />
VITEENVEOF

echo "[7/15] src/vite-env.d.ts created."

# -----------------------------------------------
# 8. CREATE src/App.css
# -----------------------------------------------
cat > src/App.css << 'APPCSSEOF'
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

html, body, #root {
  width: 100%;
  height: 100%;
  overflow: hidden;
  background-color: #0f1115;
  font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
  color: #e0e0e0;
  user-select: none;
}

.app-container {
  display: flex;
  flex-direction: column;
  width: 100%;
  height: 100%;
}

.top-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 16px;
  background: #13151a;
  border-bottom: 1px solid #2a2d35;
  min-height: 48px;
  z-index: 100;
}

.top-bar-left {
  display: flex;
  align-items: center;
  gap: 8px;
}

.top-bar-right {
  display: flex;
  align-items: center;
  gap: 8px;
}

.top-bar h1 {
  font-size: 14px;
  font-weight: 600;
  color: #c0c4cc;
  letter-spacing: 0.5px;
}

.btn {
  padding: 7px 16px;
  border: none;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.15s ease;
  white-space: nowrap;
}

.btn-primary {
  background: #3b82f6;
  color: #fff;
}
.btn-primary:hover {
  background: #2563eb;
}

.btn-success {
  background: #22c55e;
  color: #fff;
}
.btn-success:hover {
  background: #16a34a;
}

.btn-secondary {
  background: #374151;
  color: #d1d5db;
}
.btn-secondary:hover {
  background: #4b5563;
}

.btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.canvas-viewport {
  flex: 1;
  overflow: auto;
  display: flex;
  justify-content: center;
  align-items: flex-start;
  padding: 24px;
  background-color: #0f1115;
  background-image:
    linear-gradient(rgba(255,255,255,0.02) 1px, transparent 1px),
    linear-gradient(90deg, rgba(255,255,255,0.02) 1px, transparent 1px);
  background-size: 24px 24px;
}

.canvas-wrapper {
  position: relative;
  box-shadow: 0 8px 32px rgba(0,0,0,0.6);
  border-radius: 4px;
  overflow: hidden;
}

.pdf-canvas {
  display: block;
}

.draw-canvas {
  position: absolute;
  top: 0;
  left: 0;
  cursor: crosshair;
  touch-action: none;
}

.placeholder-text {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 16px;
  color: #555;
  font-size: 18px;
  margin-top: 200px;
}

.placeholder-text svg {
  opacity: 0.3;
}

.floating-toolbar {
  position: fixed;
  bottom: 20px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 20px;
  background: #1e2028;
  border: 1px solid #2e3040;
  border-radius: 14px;
  box-shadow: 0 8px 30px rgba(0,0,0,0.5);
  z-index: 200;
}

.toolbar-divider {
  width: 1px;
  height: 28px;
  background: #2e3040;
}

.tool-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 38px;
  height: 38px;
  border: none;
  border-radius: 8px;
  background: transparent;
  color: #9ca3af;
  cursor: pointer;
  transition: all 0.15s ease;
}

.tool-btn:hover {
  background: #2a2d38;
  color: #e0e0e0;
}

.tool-btn.active {
  background: #3b82f6;
  color: #fff;
}

.color-swatch {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  border: 2px solid #444;
  cursor: pointer;
  transition: transform 0.1s ease;
}

.color-swatch:hover {
  transform: scale(1.15);
}

.color-swatch.active {
  border-color: #fff;
  transform: scale(1.15);
}

.size-slider-group {
  display: flex;
  align-items: center;
  gap: 6px;
}

.size-slider-group label {
  font-size: 11px;
  color: #777;
  min-width: 28px;
}

.size-slider {
  -webkit-appearance: none;
  appearance: none;
  width: 80px;
  height: 4px;
  border-radius: 2px;
  background: #333;
  outline: none;
}

.size-slider::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 14px;
  height: 14px;
  border-radius: 50%;
  background: #3b82f6;
  cursor: pointer;
}

.status-bar {
  position: fixed;
  bottom: 80px;
  left: 50%;
  transform: translateX(-50%);
  padding: 8px 20px;
  background: #3b82f6;
  color: #fff;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 600;
  z-index: 300;
  box-shadow: 0 4px 20px rgba(59,130,246,0.4);
  animation: fadeInUp 0.2s ease;
}

@keyframes fadeInUp {
  from { opacity: 0; transform: translateX(-50%) translateY(10px); }
  to { opacity: 1; transform: translateX(-50%) translateY(0); }
}

.page-nav {
  display: flex;
  align-items: center;
  gap: 6px;
}

.page-nav span {
  font-size: 12px;
  color: #888;
  min-width: 60px;
  text-align: center;
}

.page-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 30px;
  height: 30px;
  border: none;
  border-radius: 6px;
  background: #2a2d38;
  color: #ccc;
  cursor: pointer;
  font-size: 14px;
  font-weight: bold;
}

.page-btn:hover {
  background: #3b82f6;
  color: #fff;
}

.page-btn:disabled {
  opacity: 0.3;
  cursor: not-allowed;
}
APPCSSEOF

echo "[8/15] src/App.css created."

# -----------------------------------------------
# 9. CREATE src/App.tsx (THE BIG ONE)
# -----------------------------------------------
cat > src/App.tsx << 'APPTSXEOF'
import { useState, useRef, useEffect, useCallback } from "react";
import { open, save } from "@tauri-apps/api/dialog";
import { readBinaryFile, writeBinaryFile } from "@tauri-apps/api/fs";
import { PDFDocument } from "pdf-lib";

// We must use the legacy build of pdfjs-dist for Vite compatibility
import * as pdfjsLib from "pdfjs-dist";

// Point to the worker shipped with pdfjs-dist
pdfjsLib.GlobalWorkerOptions.workerSrc = new URL(
  "pdfjs-dist/build/pdf.worker.mjs",
  import.meta.url
).toString();

type Tool = "pen" | "eraser";

interface DrawPoint {
  x: number;
  y: number;
  pressure: number;
}

interface Stroke {
  points: DrawPoint[];
  color: string;
  size: number;
  tool: Tool;
}

// Per-page annotation storage
type PageAnnotations = Map<number, Stroke[]>;

const COLORS = ["#ff3b3b", "#3b82f6", "#22c55e", "#f59e0b", "#a855f7", "#ffffff", "#000000"];

function App() {
  // PDF state
  const [pdfBytes, setPdfBytes] = useState<Uint8Array | null>(null);
  const [pdfDoc, setPdfDoc] = useState<pdfjsLib.PDFDocumentProxy | null>(null);
  const [totalPages, setTotalPages] = useState(0);
  const [currentPage, setCurrentPage] = useState(1);
  const [pageRendering, setPageRendering] = useState(false);

  // Tool state
  const [activeTool, setActiveTool] = useState<Tool>("pen");
  const [penColor, setPenColor] = useState("#ff3b3b");
  const [penSize, setPenSize] = useState(3);

  // Drawing state
  const [isDrawing, setIsDrawing] = useState(false);
  const currentStrokeRef = useRef<Stroke | null>(null);
  const annotationsRef = useRef<PageAnnotations>(new Map());

  // Status
  const [statusMsg, setStatusMsg] = useState<string | null>(null);

  // Canvas refs
  const pdfCanvasRef = useRef<HTMLCanvasElement | null>(null);
  const drawCanvasRef = useRef<HTMLCanvasElement | null>(null);
  const wrapperRef = useRef<HTMLDivElement | null>(null);

  // Track CSS dimensions for the canvases
  const [canvasDims, setCanvasDims] = useState({ width: 0, height: 0 });

  // DPR for high-DPI rendering
  const dpr = typeof window !== "undefined" ? window.devicePixelRatio || 1 : 1;

  // ----- Status helper -----
  const showStatus = useCallback((msg: string, durationMs = 2500) => {
    setStatusMsg(msg);
    setTimeout(() => setStatusMsg(null), durationMs);
  }, []);

  // ----- Load PDF -----
  const handleLoadPdf = useCallback(async () => {
    try {
      const selected = await open({
        multiple: false,
        filters: [{ name: "PDF", extensions: ["pdf"] }],
      });
      if (!selected || Array.isArray(selected)) return;

      showStatus("Loading PDF...");
      const bytes = await readBinaryFile(selected);
      const uint8 = new Uint8Array(bytes);
      setPdfBytes(uint8);

      const loadingTask = pdfjsLib.getDocument({ data: uint8.slice() });
      const doc = await loadingTask.promise;
      setPdfDoc(doc);
      setTotalPages(doc.numPages);
      setCurrentPage(1);
      annotationsRef.current = new Map();
      showStatus(`Loaded ${doc.numPages} page(s)`);
    } catch (err) {
      console.error(err);
      showStatus("Failed to load PDF");
    }
  }, [showStatus]);

  // ----- Render a specific page -----
  const renderPage = useCallback(
    async (pageNum: number) => {
      if (!pdfDoc || !pdfCanvasRef.current || !drawCanvasRef.current) return;
      if (pageRendering) return;

      setPageRendering(true);

      try {
        const page = await pdfDoc.getPage(pageNum);
        const viewport = page.getViewport({ scale: 1.5 });

        const cssWidth = viewport.width;
        const cssHeight = viewport.height;

        // PDF canvas
        const pdfCanvas = pdfCanvasRef.current;
        pdfCanvas.width = cssWidth * dpr;
        pdfCanvas.height = cssHeight * dpr;
        pdfCanvas.style.width = `${cssWidth}px`;
        pdfCanvas.style.height = `${cssHeight}px`;

        const pdfCtx = pdfCanvas.getContext("2d");
        if (!pdfCtx) return;
        pdfCtx.setTransform(dpr, 0, 0, dpr, 0, 0);

        await page.render({ canvasContext: pdfCtx, viewport }).promise;

        // Drawing canvas
        const drawCanvas = drawCanvasRef.current;
        drawCanvas.width = cssWidth * dpr;
        drawCanvas.height = cssHeight * dpr;
        drawCanvas.style.width = `${cssWidth}px`;
        drawCanvas.style.height = `${cssHeight}px`;

        setCanvasDims({ width: cssWidth, height: cssHeight });

        // Redraw existing annotations for this page
        redrawAnnotations(pageNum);
      } catch (err) {
        console.error("Render error:", err);
      }

      setPageRendering(false);
    },
    [pdfDoc, dpr, pageRendering]
  );

  // Render when page or pdfDoc changes
  useEffect(() => {
    if (pdfDoc && currentPage >= 1 && currentPage <= totalPages) {
      renderPage(currentPage);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [pdfDoc, currentPage, totalPages]);

  // ----- Redraw stored strokes on the drawing canvas -----
  const redrawAnnotations = useCallback(
    (pageNum: number) => {
      const drawCanvas = drawCanvasRef.current;
      if (!drawCanvas) return;
      const ctx = drawCanvas.getContext("2d");
      if (!ctx) return;

      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      ctx.clearRect(0, 0, drawCanvas.width, drawCanvas.height);

      const strokes = annotationsRef.current.get(pageNum);
      if (!strokes) return;

      for (const stroke of strokes) {
        drawStroke(ctx, stroke);
      }
    },
    [dpr]
  );

  // ----- Draw a single stroke -----
  const drawStroke = (ctx: CanvasRenderingContext2D, stroke: Stroke) => {
    if (stroke.points.length < 2) return;

    ctx.lineCap = "round";
    ctx.lineJoin = "round";

    if (stroke.tool === "eraser") {
      ctx.globalCompositeOperation = "destination-out";
    } else {
      ctx.globalCompositeOperation = "source-over";
    }

    ctx.strokeStyle = stroke.tool === "eraser" ? "rgba(0,0,0,1)" : stroke.color;

    for (let i = 1; i < stroke.points.length; i++) {
      const prev = stroke.points[i - 1];
      const curr = stroke.points[i];
      const pressure = Math.max(curr.pressure, 0.1);
      ctx.lineWidth = stroke.size * pressure * (stroke.tool === "eraser" ? 3 : 1);

      ctx.beginPath();
      ctx.moveTo(prev.x, prev.y);
      ctx.lineTo(curr.x, curr.y);
      ctx.stroke();
    }

    ctx.globalCompositeOperation = "source-over";
  };

  // ----- Pointer event helpers -----
  const getCanvasPoint = (e: React.PointerEvent<HTMLCanvasElement>): DrawPoint => {
    const canvas = drawCanvasRef.current!;
    const rect = canvas.getBoundingClientRect();
    return {
      x: e.clientX - rect.left,
      y: e.clientY - rect.top,
      pressure: e.pressure || 0.5,
    };
  };

  const handlePointerDown = (e: React.PointerEvent<HTMLCanvasElement>) => {
    if (!pdfDoc) return;
    e.preventDefault();
    (e.target as HTMLCanvasElement).setPointerCapture(e.pointerId);

    // Detect physical eraser button on stylus
    const tool: Tool =
      e.buttons === 32 || (e.pointerType === "pen" && e.button === 5)
        ? "eraser"
        : activeTool;

    const point = getCanvasPoint(e);
    currentStrokeRef.current = {
      points: [point],
      color: penColor,
      size: penSize,
      tool,
    };
    setIsDrawing(true);
  };

  const handlePointerMove = (e: React.PointerEvent<HTMLCanvasElement>) => {
    if (!isDrawing || !currentStrokeRef.current) return;
    e.preventDefault();

    const point = getCanvasPoint(e);
    currentStrokeRef.current.points.push(point);

    // Live draw
    const drawCanvas = drawCanvasRef.current;
    if (!drawCanvas) return;
    const ctx = drawCanvas.getContext("2d");
    if (!ctx) return;

    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);

    const stroke = currentStrokeRef.current;
    const len = stroke.points.length;
    if (len < 2) return;

    const prev = stroke.points[len - 2];
    const curr = stroke.points[len - 1];

    ctx.lineCap = "round";
    ctx.lineJoin = "round";

    if (stroke.tool === "eraser") {
      ctx.globalCompositeOperation = "destination-out";
      ctx.strokeStyle = "rgba(0,0,0,1)";
    } else {
      ctx.globalCompositeOperation = "source-over";
      ctx.strokeStyle = stroke.color;
    }

    const pressure = Math.max(curr.pressure, 0.1);
    ctx.lineWidth = stroke.size * pressure * (stroke.tool === "eraser" ? 3 : 1);

    ctx.beginPath();
    ctx.moveTo(prev.x, prev.y);
    ctx.lineTo(curr.x, curr.y);
    ctx.stroke();

    ctx.globalCompositeOperation = "source-over";
  };

  const handlePointerUp = (e: React.PointerEvent<HTMLCanvasElement>) => {
    if (!isDrawing || !currentStrokeRef.current) {
      setIsDrawing(false);
      return;
    }
    e.preventDefault();

    // Store the stroke for this page
    const pageStrokes = annotationsRef.current.get(currentPage) || [];
    pageStrokes.push(currentStrokeRef.current);
    annotationsRef.current.set(currentPage, pageStrokes);

    currentStrokeRef.current = null;
    setIsDrawing(false);
  };

  // ----- Export WITHOUT annotations -----
  const handleExportClean = useCallback(async () => {
    if (!pdfBytes) return;
    try {
      const filePath = await save({
        filters: [{ name: "PDF", extensions: ["pdf"] }],
        defaultPath: "document_clean.pdf",
      });
      if (!filePath) return;
      showStatus("Exporting clean PDF...");
      await writeBinaryFile(filePath, pdfBytes);
      showStatus("Clean PDF saved!");
    } catch (err) {
      console.error(err);
      showStatus("Export failed");
    }
  }, [pdfBytes, showStatus]);

  // ----- Export WITH annotations -----
  const handleExportAnnotated = useCallback(async () => {
    if (!pdfBytes || !pdfDoc) return;
    try {
      const filePath = await save({
        filters: [{ name: "PDF", extensions: ["pdf"] }],
        defaultPath: "document_annotated.pdf",
      });
      if (!filePath) return;

      showStatus("Exporting annotated PDF...");

      const pdfLibDoc = await PDFDocument.load(pdfBytes);
      const pages = pdfLibDoc.getPages();

      // For each page that has annotations, render them onto a temporary canvas
      // and embed as a PNG overlay
      for (let pageIdx = 0; pageIdx < pages.length; pageIdx++) {
        const pageNum = pageIdx + 1;
        const strokes = annotationsRef.current.get(pageNum);
        if (!strokes || strokes.length === 0) continue;

        const page = pages[pageIdx];
        const { width: pdfW, height: pdfH } = page.getSize();

        // We need to get the viewport to know the render scale
        const pdfJsPage = await pdfDoc.getPage(pageNum);
        const viewport = pdfJsPage.getViewport({ scale: 1.5 });

        // Create an offscreen canvas at the viewport size
        const offscreen = document.createElement("canvas");
        const offDpr = 1; // Use 1x for PDF embedding
        offscreen.width = viewport.width;
        offscreen.height = viewport.height;
        const offCtx = offscreen.getContext("2d");
        if (!offCtx) continue;

        // Draw all strokes
        for (const stroke of strokes) {
          if (stroke.tool === "eraser") continue; // eraser strokes erase; we only embed visible marks
          drawStroke(offCtx, stroke);
        }

        // If there were eraser strokes, we need to do a full composite render
        const hasEraser = strokes.some((s) => s.tool === "eraser");
        if (hasEraser) {
          // Re-render properly with eraser compositing
          offCtx.clearRect(0, 0, offscreen.width, offscreen.height);
          for (const stroke of strokes) {
            drawStroke(offCtx, stroke);
          }
        }

        // Export to PNG
        const dataUrl = offscreen.toDataURL("image/png");
        const base64 = dataUrl.split(",")[1];
        const pngBytes = Uint8Array.from(atob(base64), (c) => c.charCodeAt(0));
        const pngImage = await pdfLibDoc.embedPng(pngBytes);

        // Draw image on the PDF page, scaled to fill
        page.drawImage(pngImage, {
          x: 0,
          y: 0,
          width: pdfW,
          height: pdfH,
        });
      }

      const annotatedBytes = await pdfLibDoc.save();
      await writeBinaryFile(filePath, annotatedBytes);
      showStatus("Annotated PDF saved!");
    } catch (err) {
      console.error(err);
      showStatus("Export failed");
    }
  }, [pdfBytes, pdfDoc, showStatus]);

  // ----- Page navigation -----
  const goToPrevPage = () => {
    if (currentPage > 1) setCurrentPage((p) => p - 1);
  };
  const goToNextPage = () => {
    if (currentPage < totalPages) setCurrentPage((p) => p + 1);
  };

  // ----- Clear current page annotations -----
  const clearCurrentPage = () => {
    annotationsRef.current.set(currentPage, []);
    redrawAnnotations(currentPage);
    showStatus("Page cleared");
  };

  return (
    <div className="app-container">
      {/* Top Bar */}
      <div className="top-bar">
        <div className="top-bar-left">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#3b82f6" strokeWidth="2">
            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
            <polyline points="14 2 14 8 20 8" />
          </svg>
          <h1>Teaching PDF Annotator</h1>
        </div>
        <div className="top-bar-right">
          <button className="btn btn-primary" onClick={handleLoadPdf}>
            📂 Load PDF
          </button>
          <button className="btn btn-secondary" onClick={handleExportClean} disabled={!pdfBytes}>
            💾 Export Clean
          </button>
          <button className="btn btn-success" onClick={handleExportAnnotated} disabled={!pdfBytes}>
            ✏️ Export Annotated
          </button>
          <button className="btn btn-secondary" onClick={clearCurrentPage} disabled={!pdfDoc}>
            🗑️ Clear Page
          </button>
        </div>
      </div>

      {/* Canvas viewport */}
      <div className="canvas-viewport">
        {!pdfDoc ? (
          <div className="placeholder-text">
            <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="#555" strokeWidth="1">
              <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
              <polyline points="14 2 14 8 20 8" />
              <line x1="16" y1="13" x2="8" y2="13" />
              <line x1="16" y1="17" x2="8" y2="17" />
              <polyline points="10 9 9 9 8 9" />
            </svg>
            <span>Click "Load PDF" to open a document</span>
          </div>
        ) : (
          <div className="canvas-wrapper" ref={wrapperRef}>
            <canvas ref={pdfCanvasRef} className="pdf-canvas" />
            <canvas
              ref={drawCanvasRef}
              className="draw-canvas"
              onPointerDown={handlePointerDown}
              onPointerMove={handlePointerMove}
              onPointerUp={handlePointerUp}
              onPointerLeave={handlePointerUp}
              onContextMenu={(e) => e.preventDefault()}
            />
          </div>
        )}
      </div>

      {/* Floating toolbar */}
      {pdfDoc && (
        <div className="floating-toolbar">
          {/* Pen */}
          <button
            className={`tool-btn ${activeTool === "pen" ? "active" : ""}`}
            onClick={() => setActiveTool("pen")}
            title="Pen"
          >
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M12 19l7-7 3 3-7 7-3-3z" />
              <path d="M18 13l-1.5-7.5L2 2l3.5 14.5L13 18l5-5z" />
              <path d="M2 2l7.586 7.586" />
              <circle cx="11" cy="11" r="2" />
            </svg>
          </button>

          {/* Eraser */}
          <button
            className={`tool-btn ${activeTool === "eraser" ? "active" : ""}`}
            onClick={() => setActiveTool("eraser")}
            title="Eraser"
          >
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M20 20H7L3 16l9-9 8 8-4 4" />
              <path d="M6.5 13.5l5-5" />
            </svg>
          </button>

          <div className="toolbar-divider" />

          {/* Colors */}
          {COLORS.map((c) => (
            <div
              key={c}
              className={`color-swatch ${penColor === c ? "active" : ""}`}
              style={{ backgroundColor: c }}
              onClick={() => {
                setPenColor(c);
                setActiveTool("pen");
              }}
            />
          ))}

          <div className="toolbar-divider" />

          {/* Size slider */}
          <div className="size-slider-group">
            <label>{penSize}px</label>
            <input
              type="range"
              className="size-slider"
              min={1}
              max={20}
              value={penSize}
              onChange={(e) => setPenSize(Number(e.target.value))}
            />
          </div>

          <div className="toolbar-divider" />

          {/* Page navigation */}
          <div className="page-nav">
            <button className="page-btn" onClick={goToPrevPage} disabled={currentPage <= 1}>
              ‹
            </button>
            <span>
              {currentPage} / {totalPages}
            </span>
            <button className="page-btn" onClick={goToNextPage} disabled={currentPage >= totalPages}>
              ›
            </button>
          </div>
        </div>
      )}

      {/* Status message */}
      {statusMsg && <div className="status-bar">{statusMsg}</div>}
    </div>
  );
}

export default App;
APPTSXEOF

echo "[9/15] src/App.tsx created."

# -----------------------------------------------
# 10. CREATE src-tauri DIRECTORY STRUCTURE
# -----------------------------------------------
mkdir -p src-tauri/src
mkdir -p src-tauri/icons

echo "[10/15] src-tauri directories created."

# -----------------------------------------------
# 11. CREATE src-tauri/Cargo.toml
# -----------------------------------------------
cat > src-tauri/Cargo.toml << 'CARGOTOMLEOF'
[package]
name = "teaching-pdf-annotator"
version = "1.0.0"
description = "Teaching PDF Annotator"
authors = ["developer"]
license = "MIT"
repository = ""
edition = "2021"

[build-dependencies]
tauri-build = { version = "1", features = [] }

[dependencies]
tauri = { version = "1", features = ["dialog-all", "fs-all", "shell-open"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"

[features]
default = ["custom-protocol"]
custom-protocol = ["tauri/custom-protocol"]
CARGOTOMLEOF

echo "[11/15] src-tauri/Cargo.toml created."

# -----------------------------------------------
# 12. CREATE src-tauri/tauri.conf.json
# -----------------------------------------------
cat > src-tauri/tauri.conf.json << 'TAURICONFEOF'
{
  "build": {
    "beforeBuildCommand": "npm run build",
    "beforeDevCommand": "npm run dev",
    "devPath": "http://localhost:1420",
    "distDir": "../dist"
  },
  "package": {
    "productName": "Teaching PDF Annotator",
    "version": "1.0.0"
  },
  "tauri": {
    "allowlist": {
      "all": false,
      "dialog": {
        "all": true,
        "ask": true,
        "confirm": true,
        "message": true,
        "open": true,
        "save": true
      },
      "fs": {
        "all": true,
        "readFile": true,
        "writeFile": true,
        "readDir": true,
        "copyFile": true,
        "createDir": true,
        "removeDir": true,
        "removeFile": true,
        "renameFile": true,
        "exists": true,
        "scope": ["**"]
      },
      "shell": {
        "open": true
      }
    },
    "bundle": {
      "active": true,
      "targets": "all",
      "identifier": "com.teaching.pdf.annotator",
      "icon": [
        "icons/32x32.png",
        "icons/128x128.png",
        "icons/128x128@2x.png",
        "icons/icon.icns",
        "icons/icon.ico"
      ]
    },
    "security": {
      "csp": null
    },
    "windows": [
      {
        "fullscreen": false,
        "resizable": true,
        "title": "Teaching PDF Annotator",
        "width": 1280,
        "height": 800,
        "minWidth": 800,
        "minHeight": 600
      }
    ]
  }
}
TAURICONFEOF

echo "[12/15] src-tauri/tauri.conf.json created."

# -----------------------------------------------
# 13. CREATE src-tauri/src/main.rs
# -----------------------------------------------
cat > src-tauri/src/main.rs << 'MAINRSEOF'
// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

fn main() {
    tauri::Builder::default()
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
MAINRSEOF

echo "[13/15] src-tauri/src/main.rs created."

# -----------------------------------------------
# 14. CREATE src-tauri/build.rs
# -----------------------------------------------
cat > src-tauri/build.rs << 'BUILDRSEOF'
fn main() {
    tauri_build::build()
}
BUILDRSEOF

echo "[14/15] src-tauri/build.rs created."

# -----------------------------------------------
# 15. GENERATE PLACEHOLDER ICONS
# -----------------------------------------------
# We need to generate valid PNG icons for Tauri to build.
# We'll create minimal valid PNGs using printf + base64 decode.

# Minimal 32x32 blue square PNG (base64 encoded)
generate_icon() {
    local size=$1
    local output=$2

    # Use Node.js to generate a simple PNG icon
    node -e "
const { createCanvas } = (() => {
  try { return require('canvas'); } catch(e) { return null; }
})() || {};

// If node-canvas is not available, generate a minimal valid PNG manually
const fs = require('fs');

// Minimal 1x1 transparent PNG, we'll use it as placeholder
// For actual icons, the build still works with these minimal PNGs
const pngSignature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);

function crc32(buf) {
  let crc = 0xFFFFFFFF;
  const table = new Int32Array(256);
  for (let i = 0; i < 256; i++) {
    let c = i;
    for (let j = 0; j < 8; j++) {
      c = (c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
    }
    table[i] = c;
  }
  for (let i = 0; i < buf.length; i++) {
    crc = table[(crc ^ buf[i]) & 0xFF] ^ (crc >>> 8);
  }
  return (crc ^ 0xFFFFFFFF) >>> 0;
}

function createChunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length, 0);
  const typeAndData = Buffer.concat([Buffer.from(type), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(typeAndData), 0);
  return Buffer.concat([len, typeAndData, crc]);
}

const width = ${size};
const height = ${size};

// IHDR
const ihdr = Buffer.alloc(13);
ihdr.writeUInt32BE(width, 0);
ihdr.writeUInt32BE(height, 4);
ihdr[8] = 8; // bit depth
ihdr[9] = 2; // color type (RGB)
ihdr[10] = 0; // compression
ihdr[11] = 0; // filter
ihdr[12] = 0; // interlace

// IDAT - raw image data: each row is filter_byte + RGB pixels
const rowSize = 1 + width * 3;
const rawData = Buffer.alloc(rowSize * height);
for (let y = 0; y < height; y++) {
  rawData[y * rowSize] = 0; // filter: none
  for (let x = 0; x < width; x++) {
    const offset = y * rowSize + 1 + x * 3;
    rawData[offset] = 59;   // R (blue theme)
    rawData[offset+1] = 130; // G
    rawData[offset+2] = 246; // B
  }
}

const zlib = require('zlib');
const compressed = zlib.deflateSync(rawData);

const png = Buffer.concat([
  pngSignature,
  createChunk('IHDR', ihdr),
  createChunk('IDAT', compressed),
  createChunk('IEND', Buffer.alloc(0))
]);

fs.writeFileSync('${output}', png);
console.log('Generated ${output} (${size}x${size})');
" 2>/dev/null || echo "Icon generation via node for ${output} - using fallback"
}

generate_icon 32 "src-tauri/icons/32x32.png"
generate_icon 128 "src-tauri/icons/128x128.png"
generate_icon 256 "src-tauri/icons/128x128@2x.png"

# Copy 256 as icon.png for ICO generation
cp "src-tauri/icons/128x128@2x.png" "src-tauri/icons/icon.png" 2>/dev/null || true

# Generate a minimal .ico file (just wrapping the 32x32 PNG)
node -e "
const fs = require('fs');
const png32 = fs.readFileSync('src-tauri/icons/32x32.png');

// ICO file format: header + directory entry + PNG data
const header = Buffer.alloc(6);
header.writeUInt16LE(0, 0);     // reserved
header.writeUInt16LE(1, 2);     // type: icon
header.writeUInt16LE(1, 4);     // count: 1

const entry = Buffer.alloc(16);
entry[0] = 32;                  // width
entry[1] = 32;                  // height
entry[2] = 0;                   // color palette
entry[3] = 0;                   // reserved
entry.writeUInt16LE(1, 4);      // color planes
entry.writeUInt16LE(32, 6);     // bits per pixel
entry.writeUInt32LE(png32.length, 8);  // size of PNG data
entry.writeUInt32LE(22, 12);    // offset (6 + 16)

const ico = Buffer.concat([header, entry, png32]);
fs.writeFileSync('src-tauri/icons/icon.ico', ico);
console.log('Generated icon.ico');
" 2>/dev/null || echo "ICO generation fallback"

# Generate a minimal .icns file (macOS - just a copy of PNG as placeholder, won't be used on Windows)
cp "src-tauri/icons/128x128.png" "src-tauri/icons/icon.icns" 2>/dev/null || true

echo "[15/15] Icons generated."

# -----------------------------------------------
# 16. INSTALL DEPENDENCIES
# -----------------------------------------------
echo ""
echo "============================================="
echo " Installing npm dependencies..."
echo "============================================="
npm install

# -----------------------------------------------
# 17. BUILD THE TAURI APP
# -----------------------------------------------
echo ""
echo "============================================="
echo " Building Tauri application..."
echo "============================================="
npm run tauri build

echo ""
echo "============================================="
echo " BUILD COMPLETE!"
echo "============================================="
echo ""
echo "Output files should be in:"
echo "  src-tauri/target/release/bundle/nsis/*.exe"
echo "  src-tauri/target/release/bundle/msi/*.msi"
echo ""

# List the output files
echo "Looking for built artifacts..."
find src-tauri/target/release/bundle -name "*.exe" -o -name "*.msi" 2>/dev/null || echo "No bundle artifacts found (check build logs above)"

echo ""
echo "Done!"
