import sys
import fitz  # PyMuPDF
from PyQt5.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, 
                             QHBoxLayout, QPushButton, QScrollArea, QFileDialog, 
                             QMessageBox)
from PyQt5.QtGui import QImage, QPixmap, QPainter, QPen, QColor, QTabletEvent
from PyQt5.QtCore import Qt, QByteArray, QBuffer, QIODevice, QEvent

class PdfPageWidget(QWidget):
    def __init__(self, page_num, fitz_page, parent=None):
        super().__init__(parent)
        self.page_num = page_num
        self.fitz_page = fitz_page
        
        # 2x scaling for high DPI monitors so text stays perfectly crisp
        zoom_matrix = fitz.Matrix(2.0, 2.0)
        pix = self.fitz_page.get_pixmap(matrix=zoom_matrix)
        fmt = QImage.Format_RGBA8888 if pix.alpha else QImage.Format_RGB888
        
        self.original_pdf_image = QImage(pix.samples, pix.width, pix.height, pix.stride, fmt)
        self.current_pdf_image = self.original_pdf_image.copy()
        
        self.setFixedSize(pix.width, pix.height)
        
        # Transparent layer for hardware-accelerated drawing
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

    # --- NATIVE HARDWARE SUPPORT ---
    def tabletEvent(self, event):
        is_eraser = (event.pointerType() == QTabletEvent.Eraser)
        self.handle_drawing(event.pos(), event.pressure(), is_eraser, event.type())
        event.accept()

    def mousePressEvent(self, event):
        if event.button() == Qt.LeftButton:
            self.handle_drawing(event.pos(), 1.0, False, QEvent.TabletPress)

    def mouseMoveEvent(self, event):
        if event.buttons() & Qt.LeftButton:
            self.handle_drawing(event.pos(), 1.0, False, QEvent.TabletMove)

    def mouseReleaseEvent(self, event):
        if event.button() == Qt.LeftButton:
            self.handle_drawing(event.pos(), 0.0, False, QEvent.TabletRelease)

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
                # Pressure curve mapping
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
        self.setWindowTitle("Hardware Accurate PDF Annotator")
        self.setGeometry(100, 100, 1200, 800)
        self.setStyleSheet("background-color: #0f1115; color: white;")
        
        self.pdf_doc = None
        self.pdf_path = None
        self.pages = []

        self.init_ui()

    def init_ui(self):
        main_widget = QWidget()
        self.setCentralWidget(main_widget)
        layout = QVBoxLayout(main_widget)
        
        # --- TOOLBAR ---
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

        # --- SCROLL AREA ---
        self.scroll_area = QScrollArea()
        self.scroll_area.setWidgetResizable(True)
        self.scroll_area.setStyleSheet("border: none; background-color: #0f1115;")
        
        self.scroll_content = QWidget()
        self.scroll_layout = QVBoxLayout(self.scroll_content)
        self.scroll_layout.setAlignment(Qt.AlignHCenter)
        self.scroll_layout.setSpacing(20) # Add a nice gap between PDF pages
        
        self.scroll_area.setWidget(self.scroll_content)
        layout.addWidget(self.scroll_area)
        
        self.statusBar().showMessage("Ready. Click 'Open PDF' to start.")
        self.statusBar().setStyleSheet("color: #888; padding: 5px;")

    def btn_style(self, bg="#1a1c23", color="white"):
        return f"background-color: {bg}; color: {color}; padding: 8px 15px; border-radius: 5px; font-weight: bold; border: 1px solid #3a3f4b;"

    def set_tool(self, tool):
        QApplication.instance().current_tool = tool
        self.statusBar().showMessage(f"Tool selected: {tool.capitalize()}")

    def set_color(self, color):
        QApplication.instance().current_color = color
        self.set_tool('pen')
        self.statusBar().showMessage(f"Color selected: {color}")

    def clear_all(self):
        for page in self.pages:
            page.clear_drawings()
        self.statusBar().showMessage("All drawings cleared.")

    def toggle_dark_mode(self):
        for page in self.pages:
            page.toggle_dark_mode()

    def open_pdf(self):
        path, _ = QFileDialog.getOpenFileName(self, "Open PDF", "", "PDF Files (*.pdf)")
        if path:
            self.pdf_path = path
            self.load_pdf()

    def load_pdf(self):
        try:
            # Clear existing pages from the UI
            for i in reversed(range(self.scroll_layout.count())): 
                widget_to_remove = self.scroll_layout.itemAt(i).widget()
                if widget_to_remove:
                    widget_to_remove.setParent(None)
            self.pages.clear()

            self.pdf_doc = fitz.open(self.pdf_path)
            for i in range(len(self.pdf_doc)):
                page_widget = PdfPageWidget(i, self.pdf_doc.load_page(i))
                self.scroll_layout.addWidget(page_widget)
                self.pages.append(page_widget)
            
            self.statusBar().showMessage(f"Successfully loaded {len(self.pages)} pages.")
        except Exception as e:
            QMessageBox.critical(self, "Error Loading PDF", f"Something went wrong:\n{str(e)}")

    def export_pdf(self):
        if not self.pdf_doc:
            QMessageBox.warning(self, "No PDF", "Please open a PDF before exporting.")
            return
            
        save_path, _ = QFileDialog.getSaveFileName(self, "Save Annotated PDF", "", "PDF Files (*.pdf)")
        if not save_path: 
            return

        self.statusBar().showMessage("Exporting PDF... Please wait.")
        QApplication.processEvents() # Force UI to show the message

        try:
            for i, page_widget in enumerate(self.pages):
                fitz_page = self.pdf_doc.load_page(i)
                
                # Convert the transparent Qt drawing layer into a raw PNG byte stream
                byte_array = QByteArray()
                buffer = QBuffer(byte_array)
                buffer.open(QIODevice.WriteOnly)
                page_widget.drawing_layer.save(buffer, "PNG")
                
                # Stamp the drawing over the exact native dimensions of the original PDF
                rect = fitz_page.rect
                fitz_page.insert_image(rect, stream=byte_array.data())

            self.pdf_doc.save(save_path)
            self.statusBar().showMessage("PDF saved successfully!")
            QMessageBox.information(self, "Success", "PDF Exported Successfully!")
        except Exception as e:
            QMessageBox.critical(self, "Error Saving", f"Failed to save PDF:\n{str(e)}")
            self.statusBar().showMessage("Export failed.")

if __name__ == '__main__':
    # Force high-resolution rendering
    QApplication.setAttribute(Qt.AA_EnableHighDpiScaling, True)
    QApplication.setAttribute(Qt.AA_UseHighDpiPixmaps, True)
    
    app = QApplication(sys.argv)
    
    # Store tools globally so the sub-widgets can read them instantly
    app.current_tool = 'pen'
    app.current_color = '#ff4757'
    app.tool_sizes = {'pen': 4, 'eraser': 30}
    
    window = NativePdfAnnotator()
    window.show()
    sys.exit(app.exec_())
