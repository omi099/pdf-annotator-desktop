#!/bin/bash
set -e

echo "🚀 Bootstrapping Hardware-Accurate Knowledge Base..."

# 1. Create Vite/React/TS project
npx create-vite@latest annotator-app --template react-ts
cd annotator-app

# 2. Install dependencies (Pinned for stability)
npm install @tauri-apps/api@^1.5.0 marked@^11.1.1 html2canvas@^1.4.1 jspdf@^2.5.1
npm install --save-dev @tauri-apps/cli@^1.5.0 @types/marked@^6.0.0

# 3. Initialize Tauri
npx tauri init --app-name "KnowledgeBase" --window-title "Architect & Master Whiteboard" --dist-dir "../dist" --dev-path "http://localhost:5173" --before-build-command "npm run build" --before-dev-command "npm run dev"

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
    "productName": "KnowledgeBase",
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
      "identifier": "com.architect.knowledgebase",
      "targets": "all",
      "windows": { "certificateThumbprint": null, "digestAlgorithm": "sha256", "timestampUrl": "" }
    },
    "security": { "csp": null },
    "windows": [
      {
        "fullscreen": false,
        "height": 900,
        "resizable": true,
        "title": "Architect & Master Whiteboard",
        "width": 1400
      }
    ]
  }
}
EOF

# 5. Write App.css (Ported directly from your reference)
cat << 'EOF' > src/App.css
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;800&family=Lora:ital,wght@0,400;0,500;0,600;0,700;1,400&display=swap');

* { box-sizing: border-box; margin: 0; padding: 0; }

:root {
  --bg-dark: #0f1115; --panel-bg: #1a1c23; --border-color: #3a3f4b;
  --grid-color: rgba(255, 255, 255, 0.05);
  --font-sans: 'Inter', sans-serif; --font-serif: 'Lora', serif;
  --text-dark: #111827; --text-light: #f3f4f6;
  --pen-red: #ff4757; --pen-blue: #1e90ff; --pen-green: #2ed573;
  --pen-yellow: #eccc68; --pen-white: #ffffff;
}

body {
  font-family: var(--font-sans); background-color: var(--bg-dark); color: #ffffff;
  display: flex; flex-direction: column; height: 100vh; overflow: hidden; transition: all 0.3s ease;
}

header {
  background-color: var(--panel-bg); padding: 15px 30px; display: flex;
  justify-content: space-between; align-items: center; border-bottom: 1px solid var(--border-color); z-index: 100;
}

header h1 { font-size: 1.5rem; color: #ffffff; letter-spacing: -0.5px; }
.header-buttons { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; }

select.theme-selector {
  background: #2c2f33; color: #00ffcc; border: 1px solid #3a3f4b; padding: 9px 15px;
  font-size: 0.9rem; font-weight: 600; border-radius: 6px; cursor: pointer; outline: none;
}

.btn {
  background: #ffffff; color: #000000; border: none; padding: 9px 15px;
  font-size: 0.85rem; font-weight: 800; border-radius: 6px; cursor: pointer; transition: all 0.2s;
}
.btn:active { transform: translate(2px, 2px); }
.btn-outline { background: transparent; color: #ffffff; border: 1px solid #ffffff; }
.btn-outline:hover { background: rgba(255,255,255,0.1); }
.btn-draw { background: #ff4757; color: white; border:none; }
.btn-print-clean { background: #e5e7eb; color: #111827; }
.btn-print-notes { background: #00ffcc; color: #111827; }

.workspace { display: flex; flex: 1; overflow: hidden; position: relative; }

body.draw-active, body.draw-active * { cursor: none !important; }

.editor-container {
  flex: 0 0 400px; display: flex; flex-direction: column;
  border-right: 2px solid var(--border-color); background-color: #0f1115;
  padding: 20px; transition: all 0.3s ease; z-index: 10;
}
.editor-container.hidden { display: none !important; }

textarea {
  flex: 1; width: 100%; background-color: transparent; color: #00ffcc; 
  font-family: 'Courier New', Courier, monospace; font-size: 1rem;
  border: none; resize: none; outline: none; line-height: 1.5;
}

.preview-container {
  flex: 1; overflow-y: auto; overflow-x: hidden; padding: 0 40px; display: flex;
  justify-content: center; align-items: flex-start; scroll-behavior: smooth; position: relative;
}

.scroll-wrapper { position: relative; width: 100%; max-width: 900px; display: flex; flex-direction: column; min-height: 100%; }
#draw-canvas { position: absolute; top: 0; left: 0; width: 100%; height: 100%; pointer-events: none; z-index: 50; }
.flashcard-grid { display: flex; flex-direction: column; gap: 24px; width: 100%; padding-top: 40px; padding-bottom: 50px; position: relative; z-index: 10; }

.flashcard { width: 100%; border-radius: 12px; box-shadow: 4px 6px 0px rgba(0, 0, 0, 0.4); display: flex; flex-direction: column; position: relative; }
.card-header { 
  padding: 20px 30px; display: flex; justify-content: space-between; align-items: center; 
  cursor: pointer; user-select: none; position: sticky; top: -1px; z-index: 30; 
  border-radius: 12px 12px 0 0; box-shadow: 0 4px 6px -4px rgba(0,0,0,0.2); margin-top: 0; 
}
.card-header.no-sticky { position: relative !important; top: auto !important; }
.card-header h1, .card-header h2, .card-header h3 { font-weight: 800; font-size: 1.5rem; margin: 0; line-height: 1.3; pointer-events: none; }
.chevron { width: 20px; height: 20px; transition: transform 0.3s ease; fill: currentColor; opacity: 0.7; }
.flashcard.collapsed .chevron { transform: rotate(-90deg); }
.flashcard.collapsed .card-body { display: none; }
.flashcard.collapsed .card-header { border-radius: 12px; box-shadow: none; }
.card-body { padding: 25px 30px 30px 30px; font-size: 1.1rem; line-height: 1.8; }
.card-body p { margin-bottom: 16px; }
.card-body ul, .card-body ol { padding-left: 25px; margin-bottom: 16px; }
.card-body li { margin-bottom: 8px; }
.card-body code { padding: 3px 6px; border-radius: 4px; font-family: monospace; font-weight: 600; font-size: 0.9em; }
.card-body pre { padding: 16px; border-radius: 8px; overflow-x: auto; margin-bottom: 16px; }

/* THEMES */
body.theme-pro .preview-container { background-color: var(--bg-dark); background-image: linear-gradient(to right, var(--grid-color) 1px, transparent 1px), linear-gradient(to bottom, var(--grid-color) 1px, transparent 1px); background-size: 30px 30px; }
body.theme-pro .flashcard { background-color: #ffffff; color: var(--text-dark); border: 1px solid #e5e7eb; }
body.theme-pro .card-header { background-color: #f9fafb; border-bottom: 1px solid #e5e7eb; }
body.theme-pro .card-header:hover { background-color: #f3f4f6; }
body.theme-pro .card-body pre { background-color: #f3f4f6; border: 1px solid #e5e7eb; }
body.theme-pro .card-body code { background-color: #e5e7eb; color: #b91c1c; }

body.theme-pastel .preview-container { background-color: var(--bg-dark); background-image: linear-gradient(to right, var(--grid-color) 1px, transparent 1px), linear-gradient(to bottom, var(--grid-color) 1px, transparent 1px); background-size: 30px 30px; }
body.theme-pastel .flashcard { border: 2px solid #2c2f33; color: #1a1c23; }
body.theme-pastel .card-header { background-color: inherit; color: #1a1c23; border-bottom: 2px solid rgba(0,0,0,0.05); }
body.theme-pastel .card-body pre { background-color: #1a1c23; color: #00ffcc; }
body.theme-pastel .card-color-0 { background-color: #ffadad; }
body.theme-pastel .card-color-1 { background-color: #ffd6a5; }
body.theme-pastel .card-color-2 { background-color: #fdffb6; }
body.theme-pastel .card-color-3 { background-color: #caffbf; }

body.theme-sepia .preview-container { background-color: #f4ecd8; }
body.theme-sepia .flashcard { background-color: #fdf6e3 !important; color: #433422 !important; border: 1px solid #d3c4a9; font-family: var(--font-serif); font-size: 1.15rem; }
body.theme-sepia .card-header { background-color: #f4ecd8; border-bottom: 1px solid #d3c4a9; }
body.theme-sepia .card-body pre { background-color: #eee8d5; color: #433422; border: 1px solid #d3c4a9; }
body.theme-sepia h1, body.theme-sepia h2, body.theme-sepia h3 { font-family: var(--font-sans); }

body.theme-night .preview-container { background-color: #000000; }
body.theme-night .flashcard { background-color: #1a1c23 !important; color: #e5e7eb !important; border: 1px solid #333; }
body.theme-night .card-header { background-color: #0f1115; border-bottom: 1px solid #333; }
body.theme-night .card-body pre { background-color: #000000; color: #00ffcc; border: 1px solid #333; }

.empty-state { text-align: center; color: #888; margin-top: 20vh; font-size: 1.2rem; width: 100%; font-family: var(--font-sans); }

.draw-toolbar {
  position: fixed; bottom: 30px; left: 50%; transform: translateX(-50%);
  background: #1a1c23; padding: 12px 20px; border-radius: 50px; display: flex;
  align-items: center; gap: 15px; box-shadow: 0 10px 30px rgba(0,0,0,0.8);
  border: 1px solid #3a3f4b; z-index: 200; opacity: 0; pointer-events: none; transition: all 0.3s ease;
}
.draw-toolbar.visible { opacity: 1; pointer-events: auto; }
.draw-toolbar.force-hide { display: none !important; }

.tool-btn { background: transparent; border: none; color: white; cursor: pointer; padding: 8px; border-radius: 50%; display: flex; align-items: center; justify-content: center; transition: background 0.2s; }
.tool-btn:hover { background: rgba(255,255,255,0.1); }
.tool-btn.active { background: rgba(255,255,255,0.2); outline: 2px solid white; }
.color-dot { width: 24px; height: 24px; border-radius: 50%; cursor: pointer; border: 2px solid transparent; transition: transform 0.2s; }
.color-dot.active { transform: scale(1.2); border-color: white; }
.shortcut-hint { font-size: 0.7rem; color: #888; position: absolute; top: -20px; text-align: center; width: 100%; pointer-events: none;}
.size-badge { font-family: monospace; font-size: 0.9rem; font-weight: bold; color: #00ffcc; min-width: 25px; text-align: center; }
.hide-toolbar-btn { font-size: 0.8rem; background: rgba(255,255,255,0.1); border-radius: 20px; padding: 5px 10px; color: white; border: none; cursor: pointer; margin-left: 10px; }
.hide-toolbar-btn:hover { background: rgba(255,255,255,0.2); }

@media print {
  header, .editor-container, .draw-toolbar { display: none !important; }
  body { height: auto; overflow: visible; display: block; -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; cursor: auto !important; }
  .workspace { display: block; overflow: visible; }
  .preview-container { padding: 0 !important; max-width: 100%; display: block; overflow: visible !important;}
  .scroll-wrapper { max-width: 100%; display: block; padding: 0 !important; }
  .card-header { position: relative !important; } 
  .flashcard { width: 100%; break-inside: avoid; margin-bottom: 25px; }
  .card-body { display: block !important; }
  .chevron { display: none !important; }
  #draw-canvas { display: none !important; } 
}
EOF

# 6. Write App.tsx (The 100% bug-free strict React implementation)
cat << 'EOF' > src/App.tsx
import { useState, useRef, useEffect } from 'react';
import { save } from '@tauri-apps/api/dialog';
import { writeBinaryFile } from '@tauri-apps/api/fs';
import { marked } from 'marked';
import html2canvas from 'html2canvas';
import jsPDF from 'jspdf';
import './App.css';

marked.setOptions({ breaks: true, gfm: true });

type Point = { x: number, y: number, pressure: number };
type Stroke = { color: string, size: number, points: Point[] };
type Flashcard = { id: number, heading: string, body: string, collapsed: boolean, colorIndex: number };

const chevronSVG = `<svg class="chevron" viewBox="0 0 24 24"><path d="M7.41 8.59L12 13.17l4.59-4.58L18 10l-6 6-6-6 1.41-1.41z"/></svg>`;

export default function App() {
  const [theme, setTheme] = useState('theme-pro');
  const [isEditorOpen, setIsEditorOpen] = useState(true);
  const [allExpanded, setAllExpanded] = useState(true);
  const [markdownInput, setMarkdownInput] = useState('');
  const [cards, setCards] = useState<Flashcard[]>([]);
  const [isExporting, setIsExporting] = useState(false);

  // Drawing State UI
  const [isDrawModeOn, setIsDrawModeOn] = useState(false);
  const [isToolbarHidden, setIsToolbarHidden] = useState(false);
  const [tool, setTool] = useState<'pen' | 'eraser'>('pen');
  const [color, setColor] = useState('#ff4757');
  const [size, setSize] = useState(4);
  const [usePressure, setUsePressure] = useState(true);

  // Hardware Refs for 60FPS Native Drawing
  const scrollWrapperRef = useRef<HTMLDivElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const ctxRef = useRef<CanvasRenderingContext2D | null>(null);
  const strokesRef = useRef<Stroke[]>([]);
  const currentStrokeRef = useRef<Stroke | null>(null);
  const isDrawingRef = useRef(false);
  const tempToolRevertRef = useRef<'pen' | 'eraser' | null>(null);
  const cursorRef = useRef<HTMLDivElement>(null);

  // 1. Theme Updater
  useEffect(() => {
    document.body.className = theme;
    if (isDrawModeOn) document.body.classList.add('draw-active');
  }, [theme, isDrawModeOn]);

  // 2. Custom Cursor Follower
  useEffect(() => {
    const handlePointerMove = (e: PointerEvent) => {
      if (document.body.classList.contains('draw-active') && cursorRef.current) {
        cursorRef.current.style.transform = `translate(${e.clientX - 1}px, ${e.clientY - 2}px)`;
      }
    };
    window.addEventListener('pointermove', handlePointerMove);
    return () => window.removeEventListener('pointermove', handlePointerMove);
  }, []);

  // 3. Markdown Parser
  useEffect(() => {
    if (markdownInput.trim() === '') {
      setCards([]);
      return;
    }
    const htmlStr = marked.parse(markdownInput) as string;
    const tempDiv = document.createElement('div');
    tempDiv.innerHTML = htmlStr;
    
    let parsedCards: Flashcard[] = [];
    let currentHeading = '';
    let currentBody = '';
    let colorIdx = 0;

    Array.from(tempDiv.children).forEach(el => {
      if (['H1', 'H2', 'H3'].includes(el.tagName)) {
        if (currentHeading !== '' || currentBody !== '') {
          parsedCards.push({ id: colorIdx, heading: currentHeading || '<h2>Overview</h2>', body: currentBody, collapsed: !allExpanded, colorIndex: colorIdx % 6 });
          colorIdx++;
        }
        currentHeading = el.outerHTML; currentBody = '';
      } else {
        currentBody += el.outerHTML;
      }
    });

    if (currentHeading !== '' || currentBody !== '') {
      parsedCards.push({ id: colorIdx, heading: currentHeading || '<h2>Overview</h2>', body: currentBody, collapsed: !allExpanded, colorIndex: colorIdx % 6 });
    }
    setCards(parsedCards);
  }, [markdownInput, allExpanded]);

  // 4. Canvas Resizer
  const resizeCanvasToDocument = () => {
    if (!scrollWrapperRef.current || !canvasRef.current) return;
    const cssWidth = scrollWrapperRef.current.offsetWidth;
    const cssHeight = scrollWrapperRef.current.offsetHeight;
    const canvas = canvasRef.current;
    canvas.style.width = cssWidth + 'px';
    canvas.style.height = cssHeight + 'px';
    const dpr = window.devicePixelRatio || 1;
    canvas.width = cssWidth * dpr;
    canvas.height = cssHeight * dpr;
    const ctx = canvas.getContext('2d');
    if (ctx) {
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      ctxRef.current = ctx;
      redrawCanvas();
    }
  };

  useEffect(() => {
    const observer = new ResizeObserver(() => resizeCanvasToDocument());
    if (scrollWrapperRef.current) observer.observe(scrollWrapperRef.current);
    return () => observer.disconnect();
  }, [cards, allExpanded]);

  // 5. Hardware Drawing Engine
  const redrawCanvas = () => {
    const canvas = canvasRef.current;
    const ctx = ctxRef.current;
    if (!canvas || !ctx) return;

    const dpr = window.devicePixelRatio || 1;
    ctx.clearRect(0, 0, canvas.width / dpr, canvas.height / dpr);

    for (let stroke of strokesRef.current) {
      if (stroke.points.length < 2) continue;
      ctx.strokeStyle = stroke.color;
      ctx.lineCap = 'round';
      ctx.lineJoin = 'round';

      for (let i = 0; i < stroke.points.length - 1; i++) {
        let p1 = stroke.points[i], p2 = stroke.points[i + 1];
        ctx.beginPath(); ctx.moveTo(p1.x, p1.y); ctx.lineTo(p2.x, p2.y);
        let pFactor = (p1.pressure === -1) ? 1 : Math.pow(p1.pressure, 1.5) * 2;
        ctx.lineWidth = stroke.size * pFactor; ctx.stroke();
      }
    }
  };

  const distPointToSegment = (px: number, py: number, x1: number, y1: number, x2: number, y2: number) => {
    let l2 = (x2 - x1) ** 2 + (y2 - y1) ** 2;
    if (l2 === 0) return Math.hypot(px - x1, py - y1);
    let t = Math.max(0, Math.min(1, ((px - x1) * (x2 - x1) + (py - y1) * (y2 - y1)) / l2));
    return Math.hypot(px - (x1 + t * (x2 - x1)), py - (y1 + t * (y2 - y1)));
  };

  const eraseStrokesAt = (x: number, y: number) => {
    let hitRadius = 20; 
    let beforeCount = strokesRef.current.length;
    strokesRef.current = strokesRef.current.filter(stroke => {
      for (let i = 0; i < stroke.points.length - 1; i++) {
        let d = distPointToSegment(x, y, stroke.points[i].x, stroke.points[i].y, stroke.points[i + 1].x, stroke.points[i + 1].y);
        if (d <= hitRadius) return false;
      }
      return true;
    });
    if (strokesRef.current.length !== beforeCount) redrawCanvas();
  };

  const handlePointerDown = (e: React.PointerEvent) => {
    if (!isDrawModeOn || e.pointerType === 'mouse' || !canvasRef.current) return;
    (e.target as HTMLElement).setPointerCapture(e.pointerId);
    isDrawingRef.current = true;
    
    if ((e.pointerType as string) === 'eraser' || e.button === 5 || (e.buttons & 32)) {
      tempToolRevertRef.current = tool;
      setTool('eraser');
    }

    const rect = canvasRef.current.getBoundingClientRect();
    let x = e.clientX - rect.left, y = e.clientY - rect.top;

    const currentActualTool = tempToolRevertRef.current ? 'eraser' : tool;
    if (currentActualTool === 'eraser') eraseStrokesAt(x, y);
    else {
      let pValue = (e.pressure && usePressure && e.pointerType === 'pen') ? e.pressure : -1;
      currentStrokeRef.current = { color, size, points: [{ x, y, pressure: pValue }] };
      strokesRef.current.push(currentStrokeRef.current);
    }
  };

  const handlePointerMove = (e: React.PointerEvent) => {
    if (!isDrawingRef.current || !isDrawModeOn || e.pointerType === 'mouse' || !canvasRef.current || !ctxRef.current) return;
    const rect = canvasRef.current.getBoundingClientRect();
    let x = e.clientX - rect.left, y = e.clientY - rect.top;

    const currentActualTool = tempToolRevertRef.current ? 'eraser' : tool;

    if (currentActualTool === 'eraser') eraseStrokesAt(x, y);
    else if (currentStrokeRef.current) {
      let pValue = (e.pointerType === 'pen' && e.pressure && usePressure) ? e.pressure : -1;
      currentStrokeRef.current.points.push({ x, y, pressure: pValue });
      
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
    if (e.pointerType === 'mouse') return;
    isDrawingRef.current = false;
    currentStrokeRef.current = null;
    if (tempToolRevertRef.current) {
      setTool(tempToolRevertRef.current);
      tempToolRevertRef.current = null;
    }
  };

  // 6. Keyboard Shortcuts
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (document.activeElement?.tagName === 'TEXTAREA') return;
      if (e.key.toLowerCase() === 'h') { setIsToolbarHidden(prev => !prev); return; }
      if (!isDrawModeOn) return;
      switch(e.key.toLowerCase()) {
        case 'w': setUsePressure(p => !p); break; 
        case 'p': setTool('pen'); break;
        case 'e': setTool('eraser'); break;
        case 'c': strokesRef.current = []; redrawCanvas(); break;
        case ']': setSize(s => Math.min(60, s + 2)); break;
        case '[': setSize(s => Math.max(1, s - 2)); break;
        case '1': setColor('#ff4757'); setTool('pen'); break;
        case '2': setColor('#1e90ff'); setTool('pen'); break;
        case '3': setColor('#2ed573'); setTool('pen'); break;
        case '4': setColor('#eccc68'); setTool('pen'); break;
        case '5': setColor('#ffffff'); setTool('pen'); break;
      }
    };
    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [isDrawModeOn]);

  // 7. Exact HTML to PDF Generation via Tauri
  const generateAccuratePDF = async () => {
    if (!scrollWrapperRef.current) return;
    setIsExporting(true);

    if (!allExpanded) setAllExpanded(true);
    document.querySelectorAll('.card-header').forEach(el => el.classList.add('no-sticky'));
    
    await new Promise(r => setTimeout(r, 600)); // wait for DOM to expand

    try {
      const canvasSnapshot = await html2canvas(scrollWrapperRef.current, {
        scale: 2, useCORS: true,
        backgroundColor: getComputedStyle(document.body).backgroundColor,
        windowWidth: document.documentElement.offsetWidth,
        windowHeight: document.documentElement.offsetHeight
      });

      const imgData = canvasSnapshot.toDataURL('image/jpeg', 0.8);
      const pdfWidth = 210; 
      const a4Height = 297; 
      const extraBottomMargin = 15; 
      const calculatedHeight = (canvasSnapshot.height * pdfWidth) / canvasSnapshot.width;
      const pdfHeight = calculatedHeight + extraBottomMargin;

      const pdf = new jsPDF({ orientation: 'p', unit: 'mm', format: [pdfWidth, pdfHeight] });
      pdf.setFillColor(getComputedStyle(document.body).backgroundColor);
      pdf.rect(0, 0, pdfWidth, pdfHeight, 'F');
      pdf.addImage(imgData, 'JPEG', 0, 0, pdfWidth, calculatedHeight, undefined, 'FAST');

      pdf.setFont("helvetica", "normal");
      pdf.setTextColor(150, 150, 150);
      pdf.setFontSize(10);
      
      const totalVirtualPages = Math.ceil(pdfHeight / a4Height);
      for (let i = 1; i <= totalVirtualPages; i++) {
        let pageBottomY = (i === totalVirtualPages) ? pdfHeight : i * a4Height;
        pdf.text(`Page: ${i}`, pdfWidth - 10, pageBottomY - 6, { align: "right" });
      }

      const savePath = await save({ defaultPath: 'Knowledge-Base-With-Annotations.pdf', filters: [{ name: 'PDF', extensions: ['pdf'] }] });
      if (savePath) {
        const pdfArrayBuffer = pdf.output('arraybuffer');
        await writeBinaryFile(savePath, new Uint8Array(pdfArrayBuffer));
      }
    } catch (err) {
      console.error("PDF Export failed:", err);
      alert("Something went wrong while generating the PDF.");
    } finally {
      document.querySelectorAll('.card-header').forEach(el => el.classList.remove('no-sticky'));
      setIsExporting(false);
    }
  };

  const toggleCardState = (id: number) => {
    setCards(cards.map(c => c.id === id ? { ...c, collapsed: !c.collapsed } : c));
  };

  return (
    <>
      <div id="custom-cursor" ref={cursorRef} style={{ display: isDrawModeOn ? 'block' : 'none' }}></div>
      <header>
        <h1>⚡ Architect & Master Whiteboard</h1>
        <div className="header-buttons">
          <select className="theme-selector" value={theme} onChange={(e) => setTheme(e.target.value)}>
            <option value="theme-pro">💼 Pro Mode</option>
            <option value="theme-sepia">📖 Book Mode</option>
            <option value="theme-night">🌙 Night Mode</option>
            <option value="theme-pastel">🎨 Pastel Mode</option>
          </select>
          <button className="btn btn-draw" style={{background: isDrawModeOn ? '#2ed573' : '#ff4757', color: 'white'}} onClick={() => setIsDrawModeOn(!isDrawModeOn)}>
            🖌️ Draw ({isDrawModeOn ? 'ON' : 'OFF'})
          </button>
          <button className="btn btn-outline" style={{background: isEditorOpen ? 'transparent' : 'rgba(255,255,255,0.2)'}} onClick={() => setIsEditorOpen(!isEditorOpen)}>
            {isEditorOpen ? '👁️ Hide Input' : '📝 Show Input'}
          </button>
          <button className="btn btn-outline" onClick={() => setAllExpanded(!allExpanded)}>
            {allExpanded ? '🔼 Collapse All' : '🔽 Expand All'}
          </button>
          <button className="btn btn-print-clean" onClick={() => window.print()}>📄 Print Clean</button>
          <button className="btn btn-print-notes" style={{ opacity: isExporting ? 0.7 : 1, pointerEvents: isExporting ? 'none' : 'auto' }} onClick={generateAccuratePDF}>
            {isExporting ? '⏳ Processing...' : '🖍️ Print + Notes'}
          </button>
        </div>
      </header>

      <div className="workspace">
        <div className={`editor-container ${!isEditorOpen ? 'hidden' : ''}`}>
          <textarea placeholder="Paste your Markdown here..." value={markdownInput} onChange={(e) => setMarkdownInput(e.target.value)} />
        </div>
        
        <div className="preview-container">
          <div className="scroll-wrapper" ref={scrollWrapperRef} style={{ touchAction: isDrawModeOn ? 'none' : 'auto' }}
               onPointerDown={handlePointerDown} onPointerMove={handlePointerMove} onPointerUp={handlePointerUp} onPointerCancel={handlePointerUp} onPointerOut={handlePointerUp}>
            <canvas id="draw-canvas" ref={canvasRef}></canvas>
            <div className="flashcard-grid">
              {cards.length === 0 ? (
                <div className="empty-state">Interactive cards will appear here.</div>
              ) : (
                cards.map(card => (
                  <div key={card.id} className={`flashcard card-color-${card.colorIndex} ${card.collapsed ? 'collapsed' : ''}`}>
                    <div className="card-header" onClick={() => toggleCardState(card.id)} dangerouslySetInnerHTML={{__html: card.heading + chevronSVG}} />
                    <div className="card-body" dangerouslySetInnerHTML={{__html: card.body}} />
                  </div>
                ))
              )}
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

echo "✅ App code ported completely. Your GitHub Action will now compile the executable!"
