import os
import subprocess
from google.colab import files

def run_command(command, show_output=True):
    """Runs a shell command and streams the output to the Colab console."""
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    if show_output:
        for line in process.stdout:
            print(line.strip())
    process.wait()
    return process.returncode

print("==================================================")
print(" 🚀 STARTING CLOUD WINDOWS .EXE COMPILER")
print("==================================================")

# ---------------------------------------------------------
# STEP 1: WRITE THE NATIVE ANNOTATOR SOURCE CODE
# ---------------------------------------------------------
print("\n[1/6] Writing Python Source Code (Annotator.py)...")
annotator_code = """import sys
import fitz  # PyMuPDF
from PyQt5.QtWidgets import *
from PyQt5.QtGui import *
from PyQt5.QtCore import *

class PdfPageWidget(QWidget):
    def __init__(self, page_num, fitz_page, parent=None):
        super().__init__(parent)
        self.page_num = page_num
        self.fitz_page = fitz_page
        
        zoom_matrix = fitz.Matrix(2.0, 2.0)
        pix = self.fitz_page.get_pixmap(matrix=zoom_matrix)
        fmt = QImage.Format_RGBA8888 if pix.alpha else QImage.Format_RGB888
        
        self.original_pdf_image = QImage(pix.samples, pix.width, pix.height, pix.stride, fmt)
        self.current_pdf_image = self.original_pdf_image.copy()
        
        self.setFixedSize(pix.width, pix.height)
        
        self.drawing_layer = QPixmap(self.width(), self.height())
        self.drawing_layer.fill(Qt.transparent)
        
        self.is_dark_mode = False
        self.last_point = None
        self.last_pressure = 0.0

    def toggle_dark_mode(self):
        self.is_dark_mode = not self.is_dark_mode
        if self.is_dark_mode:
            self.current_pdf_image.invertPixels()
        else:
            self.current_pdf_image = self.original_pdf_image.copy()
        self.update()

    def clear_drawings(self):
        self.drawing_layer.fill(Qt.transparent)
        self.update()

    def tabletEvent(self, event):
        self.handle_drawing(event.pos(), event.pressure(), event.pointerType() == QTabletEvent.Eraser, event.type())
        event.accept()

    def mousePressEvent(self, event):
        if event.button() == Qt.LeftButton: self.handle_drawing(event.pos(), 1.0, False, QEvent.TabletPress)

    def mouseMoveEvent(self, event):
        if event.buttons() & Qt.LeftButton: self.handle_drawing(event.pos(), 1.0, False, QEvent.TabletMove)

    def mouseReleaseEvent(self, event):
        if event.button() == Qt.LeftButton: self.handle_drawing(event.pos(), 0.0, False, QEvent.TabletRelease)

    def handle_drawing(self, pos, pressure, is_eraser, event_type):
        app = QApplication.instance()
        
        if event_type == QEvent.TabletPress:
            self.last_point = pos
            self.last_pressure = pressure
            return

        if event_type == QEvent.TabletMove and self.last_point:
            painter = QPainter(self.drawing_layer)
            painter.setRenderHint(QPainter.Antialiasing)
            
            if is_eraser or app.current_tool == 'eraser':
                painter.setCompositionMode(QPainter.CompositionMode_Clear)
                width = app.tool_sizes['eraser']
            else:
                painter.setCompositionMode(QPainter.CompositionMode_SourceOver)
                p_factor = (pressure ** 1.5) * 2.0 if pressure > 0 else 1.0
                width = app.tool_sizes['pen'] * p_factor
                painter.setPen(QPen(QColor(app.current_color), width, Qt.SolidLine, Qt.RoundCap, Qt.RoundJoin))

            painter.drawLine(self.last_point, pos)
            painter.end()
            
            self.last_point = pos
            self.last_pressure = pressure
            self.update()

        if event_type == QEvent.TabletRelease:
            self.last_point = None

    def paintEvent(self, event):
        painter = QPainter(self)
        painter.drawImage(0, 0, self.current_pdf_image)
        painter.drawPixmap(0, 0, self.drawing_layer)

class NativePdfAnnotator(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Hardware Accurate Annotator")
        self.setGeometry(100, 100, 1200, 800)
        self.setStyleSheet("background-color: #0f1115; color: white;")
        
        self.current_tool = 'pen'
        self.current_color = '#ff4757'
        self.tool_sizes = {'pen': 4, 'eraser': 30}
        
        self.pdf_doc = None
        self.pdf_path = None
        self.pages = []

        self.init_ui()

    def init_ui(self):
        main_widget = QWidget()
        self.setCentralWidget(main_widget)
        layout = QVBoxLayout(main_widget)
        
        toolbar = QHBoxLayout()
        
        btn_open = QPushButton("📂 Open PDF")
        btn_open.clicked.connect(self.open_pdf)
        btn_open.setStyleSheet(self.btn_style())
        toolbar.addWidget(btn_open)

        self.btn_dark = QPushButton("🌙 Dark Mode")
        self.btn_dark.clicked.connect(self.toggle_dark_mode)
        self.btn_dark.setStyleSheet(self.btn_style())
        toolbar.addWidget(self.btn_dark)

        btn_export = QPushButton("💾 Export PDF")
        btn_export.clicked.connect(self.export_pdf)
        btn_export.setStyleSheet(self.btn_style(bg="#00ffcc", color="black"))
        toolbar.addWidget(btn_export)
        
        toolbar.addStretch()

        btn_pen = QPushButton("🖊️ Pen")
        btn_pen.clicked.connect(lambda: self.set_tool('pen'))
        btn_pen.setStyleSheet(self.btn_style())
        toolbar.addWidget(btn_pen)

        btn_eraser = QPushButton("🧽 Eraser")
        btn_eraser.clicked.connect(lambda: self.set_tool('eraser'))
        btn_eraser.setStyleSheet(self.btn_style())
        toolbar.addWidget(btn_eraser)

        colors = ['#ff4757', '#1e90ff', '#2ed573', '#eccc68', '#ffffff', '#000000']
        for c in colors:
            btn_color = QPushButton()
            btn_color.setFixedSize(25, 25)
            btn_color.setStyleSheet(f"background-color: {c}; border-radius: 12px; border: 2px solid #3a3f4b;")
            btn_color.clicked.connect(lambda checked, col=c: self.set_color(col))
            toolbar.addWidget(btn_color)

        btn_clear = QPushButton("🗑️ Clear")
        btn_clear.clicked.connect(self.clear_all)
        btn_clear.setStyleSheet(self.btn_style())
        toolbar.addWidget(btn_clear)

        layout.addLayout(toolbar)

        self.scroll_area = QScrollArea()
        self.scroll_area.setWidgetResizable(True)
        self.scroll_area.setStyleSheet("border: none; background-color: #0f1115;")
        
        self.scroll_content = QWidget()
        self.scroll_layout = QVBoxLayout(self.scroll_content)
        self.scroll_layout.setAlignment(Qt.AlignHCenter)
        
        self.scroll_area.setWidget(self.scroll_content)
        layout.addWidget(self.scroll_area)

    def btn_style(self, bg="#1a1c23", color="white"):
        return f"background-color: {bg}; color: {color}; padding: 8px 15px; border-radius: 5px; font-weight: bold; border: 1px solid #3a3f4b;"

    def set_tool(self, tool): self.current_tool = tool
    def set_color(self, color): self.current_color = color; self.set_tool('pen')
    def clear_all(self): [page.clear_drawings() for page in self.pages]
    def toggle_dark_mode(self): [page.toggle_dark_mode() for page in self.pages]

    def open_pdf(self):
        path, _ = QFileDialog.getOpenFileName(self, "Open PDF", "", "PDF Files (*.pdf)")
        if path:
            self.pdf_path = path
            self.load_pdf()

    def load_pdf(self):
        for i in reversed(range(self.scroll_layout.count())): 
            self.scroll_layout.itemAt(i).widget().setParent(None)
        self.pages.clear()

        self.pdf_doc = fitz.open(self.pdf_path)
        for i in range(len(self.pdf_doc)):
            page_widget = PdfPageWidget(i, self.pdf_doc.load_page(i))
            self.scroll_layout.addWidget(page_widget)
            self.pages.append(page_widget)

    def export_pdf(self):
        if not self.pdf_doc: return
        save_path, _ = QFileDialog.getSaveFileName(self, "Save Annotated PDF", "", "PDF Files (*.pdf)")
        if not save_path: return

        for i, page_widget in enumerate(self.pages):
            fitz_page = self.pdf_doc.load_page(i)
            byte_array = QByteArray()
            buffer = QBuffer(byte_array)
            buffer.open(QIODevice.WriteOnly)
            page_widget.drawing_layer.save(buffer, "PNG")
            fitz_page.insert_image(fitz_page.rect, stream=byte_array.data())

        self.pdf_doc.save(save_path)
        QMessageBox.information(self, "Success", "PDF Exported Successfully!")

if __name__ == '__main__':
    QApplication.setAttribute(Qt.AA_EnableHighDpiScaling, True)
    QApplication.setAttribute(Qt.AA_UseHighDpiPixmaps, True)
    
    app = QApplication(sys.argv)
    app.current_tool = 'pen'
    app.current_color = '#ff4757'
    app.tool_sizes = {'pen': 4, 'eraser': 30}
    
    window = NativePdfAnnotator()
    window.show()
    sys.exit(app.exec_())
"""

with open("Annotator.py", "w", encoding="utf-8") as f:
    f.write(annotator_code)

# ---------------------------------------------------------
# STEP 2: INSTALL WINE (WINDOWS EMULATOR FOR LINUX)
# ---------------------------------------------------------
print("\n[2/6] Installing Windows Emulator (Wine) on Google Cloud... (Please wait)")
run_command("dpkg --add-architecture i386", show_output=False)
run_command("apt-get update -qq", show_output=False)
run_command("DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends wine64 wine32 > /dev/null 2>&1", show_output=False)

# ---------------------------------------------------------
# STEP 3: DOWNLOAD WINDOWS PYTHON
# ---------------------------------------------------------
print("\n[3/6] Downloading Windows Python 3.10...")
run_command("wget -qnc https://www.python.org/ftp/python/3.10.11/python-3.10.11-amd64.exe", show_output=False)

# ---------------------------------------------------------
# STEP 4: INSTALL WINDOWS PYTHON INSIDE WINE
# ---------------------------------------------------------
print("\n[4/6] Installing Windows Python into the emulator... (This takes about 1-2 minutes)")
WINE_ENV = "export WINEPREFIX=/content/.wine && export WINEDEBUG=-all && "
run_command(WINE_ENV + "wine python-3.10.11-amd64.exe /quiet InstallAllUsers=1 PrependPath=1 Include_test=0", show_output=False)
run_command("wineserver -w", show_output=False)

# ---------------------------------------------------------
# STEP 5: INSTALL LIBRARIES (PyQt5, PyMuPDF, PyInstaller)
# ---------------------------------------------------------
print("\n[5/6] Installing libraries (PyQt5, PyMuPDF) inside Windows Python...")
WINE_PYTHON = '"/content/.wine/drive_c/Program Files/Python310/python.exe"'
run_command(f"{WINE_ENV} wine {WINE_PYTHON} -m pip install --upgrade pip > /dev/null 2>&1", show_output=False)
run_command(f"{WINE_ENV} wine {WINE_PYTHON} -m pip install PyQt5 PyMuPDF pyinstaller > /dev/null 2>&1", show_output=False)
run_command("wineserver -w", show_output=False)

# ---------------------------------------------------------
# STEP 6: COMPILE THE .EXE
# ---------------------------------------------------------
print("\n[6/6] Compiling Annotator.py into a standalone .exe... (Almost done!)")
WINE_PYINSTALLER = '"/content/.wine/drive_c/Program Files/Python310/Scripts/pyinstaller.exe"'
compile_cmd = f"{WINE_ENV} wine {WINE_PYINSTALLER} --noconsole --onefile Annotator.py"
run_command(compile_cmd, show_output=False)
run_command("wineserver -w", show_output=False)

# ---------------------------------------------------------
# FINAL: DOWNLOAD THE EXECUTABLE
# ---------------------------------------------------------
if os.path.exists("dist/Annotator.exe"):
    print("\n✅ SUCCESS! Downloading Annotator.exe to your computer...")
    files.download("dist/Annotator.exe")
else:
    print("\n❌ Compilation failed. Google Colab environment may have interrupted the Wine installation.")
