#!/bin/bash
set -e

echo "🚀 Bootstrapping the Ultimate GoodNotes-Level Annotator..."

# 1. Clean environment
rm -rf TeachingAnnotator
dotnet new wpf -n TeachingAnnotator -f net8.0 --force
cd TeachingAnnotator

# 2. Install Native PDF Writer Libraries
dotnet add package PdfSharp --version 6.1.1
dotnet add package System.Text.Encoding.CodePages --version 8.0.0

# 3. Overwrite .csproj
cat << 'EOF' > TeachingAnnotator.csproj
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net8.0-windows10.0.19041.0</TargetFramework>
    <Nullable>enable</Nullable>
    <UseWPF>true</UseWPF>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="PdfSharp" Version="6.1.1" />
    <PackageReference Include="System.Text.Encoding.CodePages" Version="8.0.0" />
  </ItemGroup>
</Project>
EOF

# 4. Overwrite MainWindow.xaml (Added PreviewMouseWheel for Scroll Physics)
cat << 'EOF' > MainWindow.xaml
<Window x:Class="TeachingAnnotator.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Apex Native Annotator - Ultimate Edition" Height="900" Width="1400"
        Background="#0f1115" WindowStartupLocation="CenterScreen"
        KeyDown="Window_KeyDown">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        
        <Border Grid.Row="0" Background="#1a1c23" BorderBrush="#3a3f4b" BorderThickness="0,0,0,1" Padding="15,10" Panel.ZIndex="100">
            <WrapPanel Orientation="Horizontal">
                <Button Content="📂 Open PDF" Click="OpenPdf_Click" Foreground="White" Background="#3a3f4b" Margin="0,0,10,0" Padding="12,6" FontWeight="Bold" BorderThickness="0"/>
                <Button Content="💾 Export Annotated PDF" Click="ExportAnnotated_Click" Foreground="#00ffcc" Background="#3a3f4b" Margin="0,0,10,0" Padding="12,6" FontWeight="Bold" BorderThickness="0"/>
                
                <Rectangle Width="2" Fill="#3a3f4b" Margin="0,0,15,0"/>
                
                <RadioButton Content="🖊️ Pen (P)" x:Name="PenBtn" IsChecked="True" Checked="Tool_Checked" Foreground="White" Margin="0,0,15,0" VerticalAlignment="Center" FontWeight="Bold"/>
                <RadioButton Content="🖍️ Highlight (H)" x:Name="HighlightBtn" Checked="Tool_Checked" Foreground="White" Margin="0,0,15,0" VerticalAlignment="Center" FontWeight="Bold"/>
                <RadioButton Content="☄️ Laser (L)" x:Name="LaserBtn" Checked="Tool_Checked" Foreground="#ff6b81" Margin="0,0,15,0" VerticalAlignment="Center" FontWeight="Bold"/>
                <RadioButton Content="🧽 Eraser (E)" x:Name="EraserBtn" Checked="Tool_Checked" Foreground="White" Margin="0,0,15,0" VerticalAlignment="Center" FontWeight="Bold"/>
                <RadioButton Content="⬚ Select (S)" x:Name="SelectBtn" Checked="Tool_Checked" Foreground="#7bed9f" Margin="0,0,15,0" VerticalAlignment="Center" FontWeight="Bold" ToolTip="Draw a lasso around ink to resize or hit Delete."/>
                
                <Rectangle Width="2" Fill="#3a3f4b" Margin="0,0,15,0"/>
                
                <TextBlock Text="Color:" Foreground="White" VerticalAlignment="Center" Margin="0,0,5,0" FontWeight="Bold"/>
                <ComboBox x:Name="ColorPicker" SelectionChanged="Color_Changed" Width="80" Margin="0,0,15,0" SelectedIndex="0">
                    <ComboBoxItem Content="Red"/>
                    <ComboBoxItem Content="Blue"/>
                    <ComboBoxItem Content="Green"/>
                    <ComboBoxItem Content="Black"/>
                    <ComboBoxItem Content="White"/>
                    <ComboBoxItem Content="Yellow"/>
                    <ComboBoxItem Content="Cyan"/>
                    <ComboBoxItem Content="Magenta"/>
                </ComboBox>

                <TextBlock Text="Size:" Foreground="White" VerticalAlignment="Center" Margin="0,0,5,0" FontWeight="Bold"/>
                <Slider x:Name="SizeSlider" Minimum="0.5" Maximum="50" Value="4" Width="80" VerticalAlignment="Center" Margin="0,0,5,0" ValueChanged="Size_Changed" IsMoveToPointEnabled="True"/>
                
                <TextBox x:Name="SizeInput" Text="{Binding Value, ElementName=SizeSlider, UpdateSourceTrigger=PropertyChanged, StringFormat=F1}" 
                         Width="35" TextAlignment="Center" VerticalAlignment="Center" Margin="0,0,15,0" FontWeight="Bold" Background="#3a3f4b" Foreground="#00ffcc" BorderThickness="0"/>

                <CheckBox x:Name="PressureToggle" Content="Pressure" IsChecked="True" Foreground="White" VerticalAlignment="Center" Margin="0,0,15,0" Checked="Pressure_Changed" Unchecked="Pressure_Changed" FontWeight="Bold"/>

                <Rectangle Width="2" Fill="#3a3f4b" Margin="0,0,15,0"/>

                <Button Content="🗑️ Clear All" Click="ClearInk_Click" Foreground="#ff4757" Background="#3a3f4b" Margin="0,0,10,0" Padding="12,6" FontWeight="Bold" BorderThickness="0"/>
                <Button Content="🔍 +" Click="ZoomIn_Click" Foreground="White" Background="#3a3f4b" Margin="0,0,5,0" Padding="10,6" FontWeight="Bold" BorderThickness="0"/>
                <Button Content="🔍 -" Click="ZoomOut_Click" Foreground="White" Background="#3a3f4b" Padding="10,6" FontWeight="Bold" BorderThickness="0"/>
            </WrapPanel>
        </Border>

        <ScrollViewer Grid.Row="1" x:Name="MainScroll" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto" PanningMode="Both" Background="#0f1115" PreviewMouseWheel="MainScroll_PreviewMouseWheel">
            <Grid x:Name="Workspace" HorizontalAlignment="Center" VerticalAlignment="Top" Margin="40">
                <Grid.LayoutTransform>
                    <ScaleTransform x:Name="ZoomTransform" ScaleX="1" ScaleY="1"/>
                </Grid.LayoutTransform>
                
                <ItemsControl x:Name="PdfItemsControl">
                    <ItemsControl.ItemTemplate>
                        <DataTemplate>
                            <Border Background="White" Margin="0,0,0,25" CornerRadius="4" HorizontalAlignment="Left">
                                <Border.Effect>
                                    <DropShadowEffect Color="Black" BlurRadius="15" Opacity="0.5" Direction="270" ShadowDepth="5"/>
                                </Border.Effect>
                                <Image Source="{Binding ImageSource}" Width="{Binding Width}" Height="{Binding Height}" Stretch="Uniform" RenderOptions.BitmapScalingMode="HighQuality"/>
                            </Border>
                        </DataTemplate>
                    </ItemsControl.ItemTemplate>
                </ItemsControl>

                <InkCanvas x:Name="MainInkCanvas" Background="Transparent" UseCustomCursor="True" HorizontalAlignment="Left" VerticalAlignment="Top"
                           MouseMove="MainInkCanvas_MouseMove" MouseLeave="MainInkCanvas_MouseLeave" MouseEnter="MainInkCanvas_MouseEnter"
                           StrokeCollected="MainInkCanvas_StrokeCollected"/>
                
                <Canvas x:Name="CursorCanvas" IsHitTestVisible="False" HorizontalAlignment="Stretch" VerticalAlignment="Stretch">
                    <Ellipse x:Name="CustomDotCursor" Visibility="Hidden" IsHitTestVisible="False">
                        <Ellipse.Effect>
                            <DropShadowEffect x:Name="CursorGlow" BlurRadius="10" ShadowDepth="0" Opacity="0.8" />
                        </Ellipse.Effect>
                    </Ellipse>
                </Canvas>
            </Grid>
        </ScrollViewer>
    </Grid>
</Window>
EOF

# 5. Overwrite MainWindow.xaml.cs (Advanced Scroll & Laser Physics)
cat << 'EOF' > MainWindow.xaml.cs
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.IO;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Ink;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using Microsoft.Win32;
using Windows.Data.Pdf;
using Windows.Storage;
using Windows.Storage.Streams;
using PdfSharp.Pdf;
using PdfSharp.Pdf.IO;
using PdfSharp.Drawing;

namespace TeachingAnnotator
{
    public class PdfPageModel
    {
        public BitmapImage? ImageSource { get; set; }
        public double Width { get; set; }
        public double Height { get; set; }
        public double StartY { get; set; }
    }

    public class LaserStrokeData
    {
        public Stroke Stroke { get; set; }
        public int Life { get; set; } = 255;
        public LaserStrokeData(Stroke s) { Stroke = s; }
    }

    public partial class MainWindow : Window
    {
        public ObservableCollection<PdfPageModel> PdfPages { get; set; } = new ObservableCollection<PdfPageModel>();
        private double _zoom = 1.0;
        private string? _currentPdfPath = null;
        private bool _isUpdatingUI = false;

        private double _penSize = 4.0;
        private Color _penColor = Colors.Red;
        private double _highlightSize = 24.0;
        private Color _highlightColor = Colors.Yellow;
        private double _laserSize = 6.0;
        private Color _laserColor = Colors.Red;

        private List<LaserStrokeData> _laserStrokes = new List<LaserStrokeData>();
        private DispatcherTimer _laserTimer;
        private DateTime _lastLaserActivityTime = DateTime.Now;

        public MainWindow()
        {
            InitializeComponent();
            PdfItemsControl.ItemsSource = PdfPages;
            System.Text.Encoding.RegisterProvider(System.Text.CodePagesEncodingProvider.Instance);

            MainInkCanvas.Cursor = Cursors.None;

            _laserTimer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(33) };
            _laserTimer.Tick += LaserTimer_Tick;
            _laserTimer.Start();

            SyncToolToUI();
        }

        // --- CUSTOM SCROLL PHYSICS ---
        private void MainScroll_PreviewMouseWheel(object sender, MouseWheelEventArgs e)
        {
            e.Handled = true; // Block default aggressive scrolling
            
            if (Keyboard.Modifiers == ModifierKeys.Control)
            {
                // Smooth CTRL+Scroll Zooming
                if (e.Delta > 0) ZoomIn_Click(null, null);
                else ZoomOut_Click(null, null);
            }
            else
            {
                // Smooth dampening factor (0.3 = 30% of normal scroll speed)
                double scrollFactor = 0.3; 
                if (Keyboard.Modifiers == ModifierKeys.Shift)
                {
                    MainScroll.ScrollToHorizontalOffset(MainScroll.HorizontalOffset - (e.Delta * scrollFactor));
                }
                else
                {
                    MainScroll.ScrollToVerticalOffset(MainScroll.VerticalOffset - (e.Delta * scrollFactor));
                }
            }
        }

        private void Window_KeyDown(object sender, KeyEventArgs e)
        {
            if (SizeInput.IsFocused) return;

            if (e.Key == Key.P) PenBtn.IsChecked = true;
            else if (e.Key == Key.H) HighlightBtn.IsChecked = true;
            else if (e.Key == Key.E) EraserBtn.IsChecked = true;
            else if (e.Key == Key.S) SelectBtn.IsChecked = true;
            else if (e.Key == Key.L) LaserBtn.IsChecked = true;
        }

        private void Tool_Checked(object sender, RoutedEventArgs e)
        {
            if (_isUpdatingUI || MainInkCanvas == null) return;
            SyncToolToUI();
        }

        private void SyncToolToUI()
        {
            _isUpdatingUI = true;
            if (PenBtn.IsChecked == true) { SizeSlider.Value = _penSize; SetComboColor(_penColor); } 
            else if (HighlightBtn.IsChecked == true) { SizeSlider.Value = _highlightSize; SetComboColor(_highlightColor); } 
            else if (LaserBtn.IsChecked == true) { SizeSlider.Value = _laserSize; SetComboColor(_laserColor); }
            _isUpdatingUI = false;
            ApplyPenAttributes();
        }

        private void SetComboColor(Color c)
        {
            string search = "Red";
            if (c == Colors.Blue) search = "Blue";
            else if (c == Colors.Green) search = "Green";
            else if (c == Colors.Black) search = "Black";
            else if (c == Colors.White) search = "White";
            else if (c == Colors.Yellow) search = "Yellow";
            else if (c == Colors.Cyan) search = "Cyan";
            else if (c == Colors.Magenta) search = "Magenta";

            foreach (ComboBoxItem item in ColorPicker.Items) {
                if (item.Content.ToString() == search) { ColorPicker.SelectedItem = item; break; }
            }
        }

        private Color GetComboColor()
        {
            var item = ColorPicker.SelectedItem as ComboBoxItem;
            string c = item?.Content.ToString() ?? "Red";
            switch (c) {
                case "Blue": return Colors.Blue;
                case "Green": return Colors.Green;
                case "Black": return Colors.Black;
                case "White": return Colors.White;
                case "Yellow": return Colors.Yellow;
                case "Cyan": return Colors.Cyan;
                case "Magenta": return Colors.Magenta;
                default: return Colors.Red;
            }
        }

        private void Color_Changed(object sender, SelectionChangedEventArgs e)
        {
            if (_isUpdatingUI) return;
            Color c = GetComboColor();
            if (PenBtn.IsChecked == true) _penColor = c;
            else if (HighlightBtn.IsChecked == true) _highlightColor = c;
            else if (LaserBtn.IsChecked == true) _laserColor = c;
            ApplyPenAttributes();
        }

        private void Size_Changed(object sender, RoutedPropertyChangedEventArgs<double> e)
        {
            if (_isUpdatingUI) return;
            double s = SizeSlider.Value;
            if (PenBtn.IsChecked == true) _penSize = s;
            else if (HighlightBtn.IsChecked == true) _highlightSize = s;
            else if (LaserBtn.IsChecked == true) _laserSize = s;
            ApplyPenAttributes();
        }

        private void Pressure_Changed(object sender, RoutedEventArgs e) => ApplyPenAttributes();

        private void ApplyPenAttributes()
        {
            if (MainInkCanvas == null) return;

            bool ignorePressure = PressureToggle.IsChecked == false;
            Color activeColor = GetComboColor();
            double activeSize = SizeSlider.Value;

            if (PenBtn.IsChecked == true)
            {
                MainInkCanvas.EditingMode = InkCanvasEditingMode.Ink;
                MainInkCanvas.Cursor = Cursors.None;
                MainInkCanvas.DefaultDrawingAttributes = new DrawingAttributes { Color = activeColor, Width = activeSize, Height = activeSize, FitToCurve = true, IgnorePressure = ignorePressure };
            }
            else if (HighlightBtn.IsChecked == true)
            {
                MainInkCanvas.EditingMode = InkCanvasEditingMode.Ink;
                MainInkCanvas.Cursor = Cursors.None;
                MainInkCanvas.DefaultDrawingAttributes = new DrawingAttributes { Color = Color.FromArgb(120, activeColor.R, activeColor.G, activeColor.B), Width = activeSize * 4, Height = activeSize * 4, StylusTip = StylusTip.Rectangle, IsHighlighter = true, IgnorePressure = true };
            }
            else if (LaserBtn.IsChecked == true)
            {
                MainInkCanvas.EditingMode = InkCanvasEditingMode.Ink;
                MainInkCanvas.Cursor = Cursors.None;
                MainInkCanvas.DefaultDrawingAttributes = new DrawingAttributes { Color = activeColor, Width = activeSize, Height = activeSize, FitToCurve = true, IgnorePressure = true };
            }
            else if (EraserBtn.IsChecked == true)
            {
                MainInkCanvas.EditingMode = InkCanvasEditingMode.EraseByStroke;
                MainInkCanvas.Cursor = Cursors.None;
            }
            else if (SelectBtn.IsChecked == true)
            {
                MainInkCanvas.EditingMode = InkCanvasEditingMode.Select;
                MainInkCanvas.Cursor = Cursors.Cross;
            }

            UpdateCustomCursorAppearance();
        }

        private void UpdateCustomCursorAppearance()
        {
            if (CustomDotCursor == null) return;

            if (SelectBtn.IsChecked == true) {
                CustomDotCursor.Visibility = Visibility.Hidden;
                return;
            }

            double size = SizeSlider.Value;
            Color c = GetComboColor();

            if (HighlightBtn.IsChecked == true) { size *= 4; c = Color.FromArgb(120, c.R, c.G, c.B); }
            
            if (EraserBtn.IsChecked == true) {
                size = 20; c = Colors.White;
                CustomDotCursor.Stroke = new SolidColorBrush(Colors.Black);
                CustomDotCursor.StrokeThickness = 1;
            } else { CustomDotCursor.StrokeThickness = 0; }

            CustomDotCursor.Width = size; CustomDotCursor.Height = size;
            CustomDotCursor.Fill = new SolidColorBrush(c);
            
            if (LaserBtn.IsChecked == true) {
                CursorGlow.Color = c; CursorGlow.Opacity = 1.0; CursorGlow.BlurRadius = size * 2;
            } else { CursorGlow.Opacity = 0.0; }
        }

        private void MainInkCanvas_MouseMove(object sender, MouseEventArgs e)
        {
            // Reset Laser fade timer if drawing
            if (LaserBtn.IsChecked == true && e.LeftButton == MouseButtonState.Pressed)
            {
                _lastLaserActivityTime = DateTime.Now;
            }

            if (SelectBtn.IsChecked == true) return;
            CustomDotCursor.Visibility = Visibility.Visible;
            Point p = e.GetPosition(CursorCanvas);
            Canvas.SetLeft(CustomDotCursor, p.X - (CustomDotCursor.Width / 2));
            Canvas.SetTop(CustomDotCursor, p.Y - (CustomDotCursor.Height / 2));
        }

        private void MainInkCanvas_MouseLeave(object sender, MouseEventArgs e) => CustomDotCursor.Visibility = Visibility.Hidden;
        private void MainInkCanvas_MouseEnter(object sender, MouseEventArgs e) { if (SelectBtn.IsChecked != true) CustomDotCursor.Visibility = Visibility.Visible; }

        // --- 1.5s DELAY LASER PHYSICS ---
        private void MainInkCanvas_StrokeCollected(object sender, InkCanvasStrokeCollectedEventArgs e)
        {
            if (LaserBtn.IsChecked == true)
            {
                _laserStrokes.Add(new LaserStrokeData(e.Stroke));
                _lastLaserActivityTime = DateTime.Now; // Reset the 1.5s timer
            }
        }

        private void LaserTimer_Tick(object sender, EventArgs e)
        {
            if (_laserStrokes.Count == 0) return;

            // Wait 1.5 seconds after pen stops moving before fading
            if ((DateTime.Now - _lastLaserActivityTime).TotalSeconds > 1.5)
            {
                for (int i = _laserStrokes.Count - 1; i >= 0; i--)
                {
                    var ls = _laserStrokes[i];
                    ls.Life -= 15; // Fast fade once the timer hits

                    if (ls.Life <= 0)
                    {
                        MainInkCanvas.Strokes.Remove(ls.Stroke);
                        _laserStrokes.RemoveAt(i);
                    }
                    else
                    {
                        var c = ls.Stroke.DrawingAttributes.Color;
                        ls.Stroke.DrawingAttributes.Color = Color.FromArgb((byte)ls.Life, c.R, c.G, c.B);
                    }
                }
            }
        }

        private async void OpenPdf_Click(object sender, RoutedEventArgs e)
        {
            OpenFileDialog dlg = new OpenFileDialog { Filter = "PDF Files (*.pdf)|*.pdf" };
            if (dlg.ShowDialog() == true)
            {
                _currentPdfPath = dlg.FileName;
                PdfPages.Clear();
                MainInkCanvas.Strokes.Clear();

                try 
                {
                    StorageFile file = await StorageFile.GetFileFromPathAsync(dlg.FileName);
                    Windows.Data.Pdf.PdfDocument pdfDoc = await Windows.Data.Pdf.PdfDocument.LoadFromFileAsync(file);

                    double currentY = 0;
                    double maxWidth = 0;

                    for (uint i = 0; i < pdfDoc.PageCount; i++)
                    {
                        using (Windows.Data.Pdf.PdfPage page = pdfDoc.GetPage(i))
                        {
                            using (var stream = new InMemoryRandomAccessStream())
                            {
                                var options = new Windows.Data.Pdf.PdfPageRenderOptions
                                {
                                    DestinationWidth = (uint)(page.Size.Width * 3.0),
                                    DestinationHeight = (uint)(page.Size.Height * 3.0)
                                };
                                await page.RenderToStreamAsync(stream, options);

                                var reader = new DataReader(stream.GetInputStreamAt(0));
                                await reader.LoadAsync((uint)stream.Size);
                                byte[] buffer = new byte[stream.Size];
                                reader.ReadBytes(buffer);

                                using (var ms = new MemoryStream(buffer))
                                {
                                    var bitmap = new BitmapImage();
                                    bitmap.BeginInit();
                                    bitmap.CacheOption = BitmapCacheOption.OnLoad;
                                    bitmap.StreamSource = ms;
                                    bitmap.EndInit();

                                    PdfPages.Add(new PdfPageModel { ImageSource = bitmap, Width = page.Size.Width, Height = page.Size.Height, StartY = currentY });
                                    currentY += page.Size.Height + 25; 
                                    maxWidth = Math.Max(maxWidth, page.Size.Width);
                                }
                            }
                        }
                    }

                    Workspace.Width = maxWidth; Workspace.Height = currentY;
                    MainInkCanvas.Width = maxWidth; MainInkCanvas.Height = currentY;
                    CursorCanvas.Width = maxWidth; CursorCanvas.Height = currentY;
                    MainScroll.ScrollToTop();
                } 
                catch (Exception ex) { MessageBox.Show("Failed to load PDF: " + ex.Message); }
            }
        }

        private void ExportAnnotated_Click(object sender, RoutedEventArgs e)
        {
            if (string.IsNullOrEmpty(_currentPdfPath)) { MessageBox.Show("Open a PDF first."); return; }

            SaveFileDialog dlg = new SaveFileDialog { Filter = "PDF (*.pdf)|*.pdf", FileName = "Annotated_Document.pdf" };
            if (dlg.ShowDialog() == true)
            {
                try
                {
                    PdfSharp.Pdf.PdfDocument document = PdfReader.Open(_currentPdfPath, PdfDocumentOpenMode.Modify);

                    for (int i = 0; i < document.Pages.Count; i++)
                    {
                        if (i >= PdfPages.Count) break;
                        
                        PdfSharp.Pdf.PdfPage pdfPage = document.Pages[i];
                        XGraphics gfx = XGraphics.FromPdfPage(pdfPage);
                        PdfPageModel uiPage = PdfPages[i];

                        double scaleX = pdfPage.Width.Point / uiPage.Width;
                        double scaleY = pdfPage.Height.Point / uiPage.Height;

                        foreach (Stroke stroke in MainInkCanvas.Strokes)
                        {
                            if (_laserStrokes.Any(ls => ls.Stroke == stroke)) continue;

                            Rect bounds = stroke.GetBounds();
                            if (bounds.Bottom >= uiPage.StartY && bounds.Top <= (uiPage.StartY + uiPage.Height))
                            {
                                XColor color = XColor.FromArgb(stroke.DrawingAttributes.Color.A, stroke.DrawingAttributes.Color.R, stroke.DrawingAttributes.Color.G, stroke.DrawingAttributes.Color.B);
                                double baseThickness = stroke.DrawingAttributes.Width * scaleX;

                                StylusPointCollection points = stroke.StylusPoints;
                                if (points.Count > 1)
                                {
                                    for (int j = 0; j < points.Count - 1; j++)
                                    {
                                        var p1 = points[j]; var p2 = points[j + 1];
                                        double x1 = p1.X * scaleX; double y1 = (p1.Y - uiPage.StartY) * scaleY;
                                        double x2 = p2.X * scaleX; double y2 = (p2.Y - uiPage.StartY) * scaleY;
                                        double pFactor = stroke.DrawingAttributes.IgnorePressure ? 1.0 : p1.PressureFactor * 2.0;
                                        
                                        XPen segmentPen = new XPen(color, baseThickness * pFactor) { LineCap = XLineCap.Round };
                                        gfx.DrawLine(segmentPen, x1, y1, x2, y2);
                                    }
                                }
                            }
                        }
                    }
                    document.Save(dlg.FileName);
                    MessageBox.Show("Vector PDF Exported Successfully!");
                }
                catch (Exception ex) { MessageBox.Show("Export failed: " + ex.Message); }
            }
        }

        private void ClearInk_Click(object sender, RoutedEventArgs e) => MainInkCanvas.Strokes.Clear();
        private void ZoomIn_Click(object sender, RoutedEventArgs e) { _zoom += 0.25; ZoomTransform.ScaleX = _zoom; ZoomTransform.ScaleY = _zoom; }
        private void ZoomOut_Click(object sender, RoutedEventArgs e) { _zoom = Math.Max(0.25, _zoom - 0.25); ZoomTransform.ScaleX = _zoom; ZoomTransform.ScaleY = _zoom; }
    }
}
EOF

echo "✅ Ultimate GoodNotes Architecture Generated Flawlessly!"
