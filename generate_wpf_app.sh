#!/bin/bash
set -e

echo "🚀 Bootstrapping the Native WPF Annotator (Platinum Master Edition)..."

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
    <TieredCompilation>true</TieredCompilation>
    <Optimize>true</Optimize>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="PdfSharp" Version="6.1.1" />
    <PackageReference Include="System.Text.Encoding.CodePages" Version="8.0.0" />
  </ItemGroup>
</Project>
EOF

# 4. Overwrite MainWindow.xaml (FIXED: Properly encoded XML characters for the UI label)
cat << 'EOF' > MainWindow.xaml
<Window x:Class="TeachingAnnotator.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Apex Native Annotator - Platinum Edition" 
        WindowState="Maximized" 
        Background="#0f1115" WindowStartupLocation="CenterScreen"
        KeyDown="Window_KeyDown">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        
        <Border x:Name="MainToolbar" Grid.Row="0" Background="#1a1c23" BorderBrush="#3a3f4b" BorderThickness="0,0,0,1" Padding="15,10" Panel.ZIndex="100">
            <WrapPanel Orientation="Horizontal">
                <Button Content="📂 Open PDF" Click="OpenPdf_Click" Foreground="White" Background="#3a3f4b" Margin="0,0,10,0" Padding="12,6" FontWeight="Bold" BorderThickness="0"/>
                <Button Content="💾 Export Vector PDF" Click="ExportAnnotated_Click" Foreground="#00ffcc" Background="#3a3f4b" Margin="0,0,10,0" Padding="12,6" FontWeight="Bold" BorderThickness="0"/>
                
                <Rectangle Width="2" Fill="#3a3f4b" Margin="0,0,15,0"/>
                
                <RadioButton Content="🖊️ Pen (P)" x:Name="PenBtn" IsChecked="True" Checked="Tool_Checked" Foreground="White" Margin="0,0,15,0" VerticalAlignment="Center" FontWeight="Bold"/>
                <RadioButton Content="🖍️ Highlight (M)" x:Name="HighlightBtn" Checked="Tool_Checked" Foreground="White" Margin="0,0,15,0" VerticalAlignment="Center" FontWeight="Bold"/>
                <RadioButton Content="☄️ Laser (L)" x:Name="LaserBtn" Checked="Tool_Checked" Foreground="#ff6b81" Margin="0,0,15,0" VerticalAlignment="Center" FontWeight="Bold"/>
                <RadioButton Content="🧽 Eraser (E)" x:Name="EraserBtn" Checked="Tool_Checked" Foreground="White" Margin="0,0,15,0" VerticalAlignment="Center" FontWeight="Bold"/>
                <RadioButton Content="⬚ Select (S)" x:Name="SelectBtn" Checked="Tool_Checked" Foreground="#7bed9f" Margin="0,0,15,0" VerticalAlignment="Center" FontWeight="Bold" ToolTip="Draw a lasso around ink to resize or hit Delete."/>
                
                <Rectangle Width="2" Fill="#3a3f4b" Margin="0,0,15,0"/>
                
                <TextBlock Text="Color (1-8):" Foreground="White" VerticalAlignment="Center" Margin="0,0,5,0" FontWeight="Bold"/>
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

                <TextBlock Text="Size (&lt; &gt;):" Foreground="White" VerticalAlignment="Center" Margin="0,0,5,0" FontWeight="Bold"/>
                <Slider x:Name="SizeSlider" Minimum="0.5" Maximum="50" Value="4" Width="80" VerticalAlignment="Center" Margin="0,0,5,0" ValueChanged="Size_Changed" IsMoveToPointEnabled="True"/>
                
                <TextBox x:Name="SizeInput" Text="{Binding Value, ElementName=SizeSlider, UpdateSourceTrigger=PropertyChanged, StringFormat=F1}" 
                         Width="35" TextAlignment="Center" VerticalAlignment="Center" Margin="0,0,15,0" FontWeight="Bold" Background="#3a3f4b" Foreground="#00ffcc" BorderThickness="0"/>

                <CheckBox x:Name="PressureToggle" Content="Pressure" IsChecked="True" Foreground="White" VerticalAlignment="Center" Margin="0,0,15,0" Checked="Pressure_Changed" Unchecked="Pressure_Changed" FontWeight="Bold"/>

                <Rectangle Width="2" Fill="#3a3f4b" Margin="0,0,15,0"/>

                <Button Content="🗑️ Clear All" Click="ClearInk_Click" Foreground="#ff4757" Background="#3a3f4b" Margin="0,0,10,0" Padding="12,6" FontWeight="Bold" BorderThickness="0"/>
                <TextBlock Text="[F] Full | [H] Hide | [Ctrl+Z] Undo" Foreground="#00ffcc" VerticalAlignment="Center" Margin="10,0,0,0" FontWeight="Bold"/>
            </WrapPanel>
        </Border>

        <ScrollViewer Grid.Row="1" x:Name="MainScroll" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto" PanningMode="Both" Background="#0f1115" PreviewMouseWheel="MainScroll_PreviewMouseWheel">
            
            <Grid x:Name="Workspace" HorizontalAlignment="Center" VerticalAlignment="Top" Margin="40">
                <Grid.Background>
                    <DrawingBrush TileMode="Tile" Viewport="0,0,40,40" ViewportUnits="Absolute">
                        <DrawingBrush.Drawing>
                            <GeometryDrawing Geometry="M0,0 L0,40 M0,0 L40,0">
                                <GeometryDrawing.Pen>
                                    <Pen Brush="#2A2E39" Thickness="1"/>
                                </GeometryDrawing.Pen>
                            </GeometryDrawing>
                        </DrawingBrush.Drawing>
                    </DrawingBrush>
                </Grid.Background>

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

                <InkCanvas x:Name="MainInkCanvas" Background="Transparent" UseCustomCursor="True" Cursor="Arrow" HorizontalAlignment="Left" VerticalAlignment="Top" Focusable="True"
                           PreviewMouseLeftButtonDown="MainInkCanvas_PreviewMouseLeftButtonDown"
                           MouseMove="MainInkCanvas_MouseMove" MouseLeave="MainInkCanvas_MouseLeave" MouseEnter="MainInkCanvas_MouseEnter"
                           StrokeCollected="MainInkCanvas_StrokeCollected">
                    <InkCanvas.Resources>
                        <SolidColorBrush x:Key="{x:Static SystemColors.HighlightBrushKey}" Color="#2ecc71"/>
                    </InkCanvas.Resources>
                </InkCanvas>
                
                <Canvas x:Name="CursorCanvas" IsHitTestVisible="False" HorizontalAlignment="Stretch" VerticalAlignment="Stretch" Panel.ZIndex="999">
                    <Ellipse x:Name="CustomDotCursor" Visibility="Hidden" IsHitTestVisible="False">
                        <Ellipse.Effect>
                            <DropShadowEffect x:Name="CursorGlow" BlurRadius="4" ShadowDepth="1" Opacity="0.6" />
                        </Ellipse.Effect>
                    </Ellipse>
                </Canvas>
            </Grid>
        </ScrollViewer>
    </Grid>
</Window>
EOF

# 5. Overwrite MainWindow.xaml.cs 
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

        // Custom Undo/Redo Engine
        private Stack<StrokeCollection> _undoStack = new Stack<StrokeCollection>();
        private Stack<StrokeCollection> _redoStack = new Stack<StrokeCollection>();

        public MainWindow()
        {
            InitializeComponent();
            PdfItemsControl.ItemsSource = PdfPages;
            System.Text.Encoding.RegisterProvider(System.Text.CodePagesEncodingProvider.Instance);

            MainInkCanvas.Cursor = Cursors.Arrow;

            // Initialize Whiteboard Dimensions (4K Default Teaching Space)
            Workspace.Width = 3840; Workspace.Height = 2160;
            MainInkCanvas.Width = 3840; MainInkCanvas.Height = 2160;
            CursorCanvas.Width = 3840; CursorCanvas.Height = 2160;

            _laserTimer = new DispatcherTimer(DispatcherPriority.Render) { Interval = TimeSpan.FromMilliseconds(33) };
            _laserTimer.Tick += LaserTimer_Tick;
            _laserTimer.Start();

            SyncToolToUI();
        }

        // --- UNDO / REDO LOGIC ---
        private void SaveUndoState()
        {
            if (_isUpdatingUI) return;
            _undoStack.Push(MainInkCanvas.Strokes.Clone());
            _redoStack.Clear();
        }

        private void PerformUndo()
        {
            if (_undoStack.Count > 0)
            {
                _isUpdatingUI = true;
                _redoStack.Push(MainInkCanvas.Strokes.Clone());
                MainInkCanvas.Strokes = _undoStack.Pop();
                _laserStrokes.Clear(); // Clear orphans
                _isUpdatingUI = false;
            }
        }

        private void PerformRedo()
        {
            if (_redoStack.Count > 0)
            {
                _isUpdatingUI = true;
                _undoStack.Push(MainInkCanvas.Strokes.Clone());
                MainInkCanvas.Strokes = _redoStack.Pop();
                _laserStrokes.Clear();
                _isUpdatingUI = false;
            }
        }

        // Snapshot stroke state RIGHT BEFORE the user touches the canvas to draw or erase
        private void MainInkCanvas_PreviewMouseLeftButtonDown(object sender, MouseButtonEventArgs e)
        {
            if (MainInkCanvas.EditingMode != InkCanvasEditingMode.None && MainInkCanvas.EditingMode != InkCanvasEditingMode.Select)
            {
                SaveUndoState();
            }
        }

        private void MainScroll_PreviewMouseWheel(object sender, MouseWheelEventArgs e)
        {
            e.Handled = true; 
            if (Keyboard.Modifiers == ModifierKeys.Control) {
                if (e.Delta > 0) PerformZoomIn();
                else PerformZoomOut();
            } else {
                double scrollFactor = 0.3; 
                if (Keyboard.Modifiers == ModifierKeys.Shift) MainScroll.ScrollToHorizontalOffset(MainScroll.HorizontalOffset - (e.Delta * scrollFactor));
                else MainScroll.ScrollToVerticalOffset(MainScroll.VerticalOffset - (e.Delta * scrollFactor));
            }
        }

        private void Window_KeyDown(object sender, KeyEventArgs e)
        {
            // Ctrl Shortcuts
            if (Keyboard.Modifiers == ModifierKeys.Control)
            {
                if (e.Key == Key.Z) { PerformUndo(); return; }
                if (e.Key == Key.Y) { PerformRedo(); return; }
            }

            // Custom Delete Hook
            if (e.Key == Key.Delete)
            {
                var selectedStrokes = MainInkCanvas.GetSelectedStrokes();
                if (selectedStrokes.Count > 0)
                {
                    SaveUndoState();
                    MainInkCanvas.Strokes.Remove(selectedStrokes);
                    return;
                }
            }

            if (SizeInput.IsFocused) return;

            // Numbers 1-8 for Colors
            if (e.Key >= Key.D1 && e.Key <= Key.D8)
            {
                int index = e.Key - Key.D1;
                if (index < ColorPicker.Items.Count) ColorPicker.SelectedIndex = index;
            }
            if (e.Key >= Key.NumPad1 && e.Key <= Key.NumPad8)
            {
                int index = e.Key - Key.NumPad1;
                if (index < ColorPicker.Items.Count) ColorPicker.SelectedIndex = index;
            }

            // < and > for Pen Size
            if (e.Key == Key.OemComma) SizeSlider.Value = Math.Max(SizeSlider.Minimum, SizeSlider.Value - 1.0);
            if (e.Key == Key.OemPeriod) SizeSlider.Value = Math.Min(SizeSlider.Maximum, SizeSlider.Value + 1.0);

            // Toggles
            if (e.Key == Key.F)
            {
                if (this.WindowStyle == WindowStyle.None) { this.WindowStyle = WindowStyle.SingleBorderWindow; this.WindowState = WindowState.Normal; this.Topmost = false; }
                else { this.WindowStyle = WindowStyle.None; this.WindowState = WindowState.Maximized; this.Topmost = true; }
            }
            if (e.Key == Key.H) MainToolbar.Visibility = MainToolbar.Visibility == Visibility.Visible ? Visibility.Collapsed : Visibility.Visible;
            if (e.Key == Key.P) PenBtn.IsChecked = true;
            else if (e.Key == Key.M) HighlightBtn.IsChecked = true; 
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
                if (item.Content?.ToString() == search) { ColorPicker.SelectedItem = item; break; }
            }
        }

        private Color GetComboColor()
        {
            var item = ColorPicker.SelectedItem as ComboBoxItem;
            string c = item?.Content?.ToString() ?? "Red";
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
                MainInkCanvas.Cursor = Cursors.Arrow;
                MainInkCanvas.DefaultDrawingAttributes = new DrawingAttributes { Color = activeColor, Width = activeSize, Height = activeSize, FitToCurve = true, IgnorePressure = ignorePressure };
            }
            else if (HighlightBtn.IsChecked == true)
            {
                MainInkCanvas.EditingMode = InkCanvasEditingMode.Ink;
                MainInkCanvas.Cursor = Cursors.Arrow;
                MainInkCanvas.DefaultDrawingAttributes = new DrawingAttributes { Color = Color.FromArgb(120, activeColor.R, activeColor.G, activeColor.B), Width = activeSize * 4, Height = activeSize * 4, StylusTip = StylusTip.Rectangle, IsHighlighter = true, IgnorePressure = true };
            }
            else if (LaserBtn.IsChecked == true)
            {
                MainInkCanvas.EditingMode = InkCanvasEditingMode.Ink;
                MainInkCanvas.Cursor = Cursors.Arrow;
                // Make the laser highly vibrant internally so the ink glows
                MainInkCanvas.DefaultDrawingAttributes = new DrawingAttributes { Color = Color.FromArgb(200, activeColor.R, activeColor.G, activeColor.B), Width = activeSize, Height = activeSize, FitToCurve = true, IgnorePressure = true };
            }
            else if (EraserBtn.IsChecked == true)
            {
                MainInkCanvas.EditingMode = InkCanvasEditingMode.EraseByStroke;
                MainInkCanvas.Cursor = Cursors.Arrow;
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
                size = 20; 
                c = Colors.White;
                CustomDotCursor.Stroke = new SolidColorBrush(Colors.Black);
                CustomDotCursor.Fill = new SolidColorBrush(Color.FromArgb(100, 255, 255, 255));
            } else { 
                CustomDotCursor.Stroke = new SolidColorBrush(c);
                CustomDotCursor.Fill = new SolidColorBrush(Color.FromArgb(150, c.R, c.G, c.B)); 
            }

            CustomDotCursor.Width = size; 
            CustomDotCursor.Height = size;

            if (LaserBtn.IsChecked == true) {
                CursorGlow.Color = c; CursorGlow.Opacity = 1.0; CursorGlow.BlurRadius = 15; CursorGlow.ShadowDepth = 0;
            } else { 
                CursorGlow.Color = Colors.Black; CursorGlow.Opacity = 0.5; CursorGlow.BlurRadius = 4; CursorGlow.ShadowDepth = 1;
            }
        }

        private void MainInkCanvas_MouseMove(object sender, MouseEventArgs e)
        {
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

        private void MainInkCanvas_StrokeCollected(object sender, InkCanvasStrokeCollectedEventArgs e)
        {
            if (LaserBtn.IsChecked == true)
            {
                _laserStrokes.Add(new LaserStrokeData(e.Stroke));
                _lastLaserActivityTime = DateTime.Now; 
            }
        }

        private void LaserTimer_Tick(object? sender, EventArgs e)
        {
            if (_laserStrokes.Count == 0) return;

            if ((DateTime.Now - _lastLaserActivityTime).TotalSeconds > 1.5)
            {
                for (int i = _laserStrokes.Count - 1; i >= 0; i--)
                {
                    var ls = _laserStrokes[i];
                    ls.Life -= 15; 

                    if (ls.Life <= 0)
                    {
                        // Remove gracefully without triggering the undo stack
                        _isUpdatingUI = true;
                        MainInkCanvas.Strokes.Remove(ls.Stroke);
                        _isUpdatingUI = false;
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
                _undoStack.Clear();
                _redoStack.Clear();

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

                    // Remove Whiteboard Background
                    Workspace.Background = new SolidColorBrush(Colors.Transparent);
                    
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
            // STANDALONE WHITEBOARD EXPORT LOGIC
            if (string.IsNullOrEmpty(_currentPdfPath)) 
            { 
                SaveFileDialog wbdlg = new SaveFileDialog { Filter = "PDF (*.pdf)|*.pdf", FileName = "Whiteboard_Export.pdf" };
                if (wbdlg.ShowDialog() == true)
                {
                    try
                    {
                        PdfSharp.Pdf.PdfDocument wbDoc = new PdfSharp.Pdf.PdfDocument();
                        PdfSharp.Pdf.PdfPage wbPage = wbDoc.AddPage();
                        
                        // Standard 1080p Landscape Output
                        wbPage.Width = XUnit.FromPoint(1920);
                        wbPage.Height = XUnit.FromPoint(1080);
                        XGraphics gfx = XGraphics.FromPdfPage(wbPage);

                        // Draw Dark Background
                        gfx.DrawRectangle(new XSolidBrush(XColor.FromArgb(255, 15, 17, 21)), 0, 0, wbPage.Width.Point, wbPage.Height.Point);
                        
                        // Draw Minimal Grid
                        XPen gridPen = new XPen(XColor.FromArgb(255, 42, 46, 57), 1);
                        for (double x = 0; x < wbPage.Width.Point; x += 40) gfx.DrawLine(gridPen, x, 0, x, wbPage.Height.Point);
                        for (double y = 0; y < wbPage.Height.Point; y += 40) gfx.DrawLine(gridPen, 0, y, wbPage.Width.Point, y);

                        // Math scaling to fit strokes on 1080p page
                        double scaleX = wbPage.Width.Point / Workspace.Width;
                        double scaleY = wbPage.Height.Point / Workspace.Height;

                        foreach (Stroke stroke in MainInkCanvas.Strokes)
                        {
                            if (_laserStrokes.Any(ls => ls.Stroke == stroke)) continue;

                            XColor color = XColor.FromArgb(stroke.DrawingAttributes.Color.A, stroke.DrawingAttributes.Color.R, stroke.DrawingAttributes.Color.G, stroke.DrawingAttributes.Color.B);
                            double baseThickness = stroke.DrawingAttributes.Width * scaleX;
                            StylusPointCollection points = stroke.StylusPoints;

                            if (points.Count > 1)
                            {
                                if (stroke.DrawingAttributes.IsHighlighter || stroke.DrawingAttributes.IgnorePressure)
                                {
                                    XGraphicsPath path = new XGraphicsPath();
                                    XPoint[] xPoints = new XPoint[points.Count];
                                    for (int j = 0; j < points.Count; j++) { xPoints[j] = new XPoint(points[j].X * scaleX, points[j].Y * scaleY); }
                                    path.AddLines(xPoints);
                                    
                                    XLineCap cap = stroke.DrawingAttributes.IsHighlighter ? XLineCap.Square : XLineCap.Round;
                                    XPen pathPen = new XPen(color, baseThickness) { LineCap = cap, LineJoin = XLineJoin.Round };
                                    gfx.DrawPath(pathPen, path);
                                }
                                else
                                {
                                    for (int j = 0; j < points.Count - 1; j++)
                                    {
                                        var p1 = points[j]; var p2 = points[j + 1];
                                        double x1 = p1.X * scaleX; double y1 = p1.Y * scaleY;
                                        double x2 = p2.X * scaleX; double y2 = p2.Y * scaleY;
                                        double pFactor = p1.PressureFactor * 2.0;
                                        
                                        XPen segmentPen = new XPen(color, baseThickness * pFactor) { LineCap = XLineCap.Round };
                                        gfx.DrawLine(segmentPen, x1, y1, x2, y2);
                                    }
                                }
                            }
                        }

                        wbDoc.Save(wbdlg.FileName);
                        MessageBox.Show("Whiteboard Vector Exported Successfully!");
                    }
                    catch (Exception ex) { MessageBox.Show("Export failed: " + ex.Message); }
                }
                return; 
            }

            // PDF EXPORT LOGIC
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
                                    if (stroke.DrawingAttributes.IsHighlighter || stroke.DrawingAttributes.IgnorePressure)
                                    {
                                        XGraphicsPath path = new XGraphicsPath();
                                        XPoint[] xPoints = new XPoint[points.Count];
                                        for (int j = 0; j < points.Count; j++) { xPoints[j] = new XPoint(points[j].X * scaleX, (points[j].Y - uiPage.StartY) * scaleY); }
                                        path.AddLines(xPoints);
                                        
                                        XLineCap cap = stroke.DrawingAttributes.IsHighlighter ? XLineCap.Square : XLineCap.Round;
                                        XPen pathPen = new XPen(color, baseThickness) { LineCap = cap, LineJoin = XLineJoin.Round };
                                        gfx.DrawPath(pathPen, path);
                                    }
                                    else
                                    {
                                        for (int j = 0; j < points.Count - 1; j++)
                                        {
                                            var p1 = points[j]; var p2 = points[j + 1];
                                            double x1 = p1.X * scaleX; double y1 = (p1.Y - uiPage.StartY) * scaleY;
                                            double x2 = p2.X * scaleX; double y2 = (p2.Y - uiPage.StartY) * scaleY;
                                            double pFactor = p1.PressureFactor * 2.0;
                                            
                                            XPen segmentPen = new XPen(color, baseThickness * pFactor) { LineCap = XLineCap.Round };
                                            gfx.DrawLine(segmentPen, x1, y1, x2, y2);
                                        }
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

        private void ClearInk_Click(object sender, RoutedEventArgs e)
        {
            SaveUndoState();
            MainInkCanvas.Strokes.Clear();
        }

        private void PerformZoomIn() { _zoom += 0.25; ZoomTransform.ScaleX = _zoom; ZoomTransform.ScaleY = _zoom; }
        private void PerformZoomOut() { _zoom = Math.Max(0.25, _zoom - 0.25); ZoomTransform.ScaleX = _zoom; ZoomTransform.ScaleY = _zoom; }

        private void ZoomIn_Click(object sender, RoutedEventArgs e) => PerformZoomIn();
        private void ZoomOut_Click(object sender, RoutedEventArgs e) => PerformZoomOut();
    }
}
EOF

echo "✅ App Polished to Absolute Perfection!"
