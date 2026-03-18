#!/bin/bash
set -e

echo "🚀 Bootstrapping the Native WPF Annotator (Perfect Yellow Lasso Edition)..."

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

# 4. Overwrite MainWindow.xaml
cat << 'EOF' > MainWindow.xaml
<Window x:Class="TeachingAnnotator.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Apex Native Annotator - Platinum Edition" 
        WindowState="Maximized" 
        Background="#0f1115" WindowStartupLocation="CenterScreen"
        KeyDown="Window_KeyDown">

    <Window.Resources>
        <SolidColorBrush x:Key="{x:Static SystemColors.HighlightBrushKey}" Color="#FFFF00"/>
        <SolidColorBrush x:Key="{x:Static SystemColors.WindowFrameBrushKey}" Color="#FFFF00"/>
        <SolidColorBrush x:Key="{x:Static SystemColors.WindowTextBrushKey}" Color="#FFFF00"/>
        <SolidColorBrush x:Key="{x:Static SystemColors.ControlTextBrushKey}" Color="#FFFF00"/>
        <SolidColorBrush x:Key="{x:Static SystemColors.ActiveBorderBrushKey}" Color="#FFFF00"/>
    </Window.Resources>

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        
        <Border x:Name="MainToolbar" Grid.Row="0" Background="#1a1c23" BorderBrush="#3a3f4b" BorderThickness="0,0,0,1" Padding="15,10" Panel.ZIndex="100">
            <Border.Resources>
                <SolidColorBrush x:Key="{x:Static SystemColors.WindowTextBrushKey}" Color="Black"/>
                <SolidColorBrush x:Key="{x:Static SystemColors.ControlTextBrushKey}" Color="Black"/>
                <SolidColorBrush x:Key="{x:Static SystemColors.HighlightBrushKey}" Color="#0078D7"/>
            </Border.Resources>
            
            <WrapPanel Orientation="Horizontal">
                <Button Content="📂 Open PDF" Click="OpenPdf_Click" Foreground="White" Background="#3a3f4b" Margin="0,0,10,0" Padding="12,6" FontWeight="Bold" BorderThickness="0"/>
                <Button Content="💾 Export Vector PDF" Click="ExportAnnotated_Click" Foreground="#00ffcc" Background="#3a3f4b" Margin="0,0,10,0" Padding="12,6" FontWeight="Bold" BorderThickness="0"/>
                <Button Content="🌗 Theme (T)" Click="Theme_Click" Foreground="White" Background="#3a3f4b" Margin="0,0,10,0" Padding="12,6" FontWeight="Bold" BorderThickness="0"/>
                
                <Rectangle Width="2" Fill="#3a3f4b" Margin="0,0,15,0"/>
                
                <RadioButton Content="🖊️ Pen (P)" x:Name="PenBtn" IsChecked="True" Checked="Tool_Checked" Foreground="White" Margin="0,0,15,0" VerticalAlignment="Center" FontWeight="Bold"/>
                <RadioButton Content="🖍️ Highlight (M)" x:Name="HighlightBtn" Checked="Tool_Checked" Foreground="White" Margin="0,0,15,0" VerticalAlignment="Center" FontWeight="Bold"/>
                <RadioButton Content="☄️ Laser (L)" x:Name="LaserBtn" Checked="Tool_Checked" Foreground="#ff6b81" Margin="0,0,15,0" VerticalAlignment="Center" FontWeight="Bold"/>
                <RadioButton Content="🧽 Eraser (E)" x:Name="EraserBtn" Checked="Tool_Checked" Foreground="White" Margin="0,0,15,0" VerticalAlignment="Center" FontWeight="Bold"/>
                <RadioButton Content="⬚ Select (S)" x:Name="SelectBtn" Checked="Tool_Checked" Foreground="#FFFF00" Margin="0,0,15,0" VerticalAlignment="Center" FontWeight="Bold" ToolTip="Draw a lasso around ink to resize or hit Delete."/>
                
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
                
                <StackPanel x:Name="PaginationPanel" Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,15,0">
                    <Button Content="&lt;" Click="PrevPage_Click" Foreground="White" Background="#3a3f4b" Padding="10,4" FontWeight="Bold" BorderThickness="0" Margin="0,0,5,0"/>
                    <TextBlock x:Name="PageCounterText" Text="1 / 1" Foreground="#00ffcc" VerticalAlignment="Center" FontWeight="Bold" Margin="0,0,5,0" Width="45" TextAlignment="Center"/>
                    <Button Content="&gt;" Click="NextPage_Click" Foreground="White" Background="#3a3f4b" Padding="10,4" FontWeight="Bold" BorderThickness="0" Margin="0,0,10,0"/>
                    <Button Content="🗑️ Del Page" Click="DeletePage_Click" Foreground="#ff4757" Background="#3a3f4b" Padding="10,4" FontWeight="Bold" BorderThickness="0"/>
                </StackPanel>

                <Rectangle Width="2" Fill="#3a3f4b" Margin="0,0,15,0"/>

                <Button Content="🗑️ Clear All" Click="ClearInk_Click" Foreground="#ff4757" Background="#3a3f4b" Margin="0,0,10,0" Padding="12,6" FontWeight="Bold" BorderThickness="0"/>
                <TextBlock Text="[F] Full | [H] Hide | [Ctrl+Z] Undo" Foreground="#00ffcc" VerticalAlignment="Center" Margin="10,0,0,0" FontWeight="Bold"/>
            </WrapPanel>
        </Border>

        <ScrollViewer Grid.Row="1" x:Name="MainScroll" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto" PanningMode="Both" PreviewMouseWheel="MainScroll_PreviewMouseWheel">
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

                <AdornerDecorator>
                    <Grid x:Name="CanvasContainer" HorizontalAlignment="Left" VerticalAlignment="Top">
                        
                        <InkCanvas x:Name="MainInkCanvas" Background="Transparent" UseCustomCursor="True" Cursor="Arrow" Focusable="True"
                                   PreviewMouseLeftButtonDown="MainInkCanvas_PreviewMouseLeftButtonDown"
                                   PreviewMouseMove="MainInkCanvas_PreviewMouseMove"
                                   PreviewMouseLeftButtonUp="MainInkCanvas_PreviewMouseLeftButtonUp"
                                   MouseMove="MainInkCanvas_MouseMove" MouseLeave="MainInkCanvas_MouseLeave" MouseEnter="MainInkCanvas_MouseEnter"
                                   SelectionChanged="MainInkCanvas_SelectionChanged">
                        </InkCanvas>
                        
                        <InkCanvas x:Name="LaserInkCanvas" Background="Transparent" UseCustomCursor="True" Cursor="Arrow" Focusable="False" IsHitTestVisible="False"
                                   MouseMove="MainInkCanvas_MouseMove" MouseLeave="MainInkCanvas_MouseLeave" MouseEnter="MainInkCanvas_MouseEnter"
                                   StrokeCollected="LaserInkCanvas_StrokeCollected">
                        </InkCanvas>
                    </Grid>
                </AdornerDecorator>
                
                <Canvas x:Name="CursorCanvas" IsHitTestVisible="False" HorizontalAlignment="Stretch" VerticalAlignment="Stretch" Panel.ZIndex="999">
                    <Polygon x:Name="CustomLassoPolygon" Visibility="Hidden" Stroke="#FFFF00" StrokeThickness="2" StrokeDashArray="4,4" Fill="#33FFFF00" IsHitTestVisible="False" />
                    
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
using System.Reflection;
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

        private Stack<StrokeCollection> _undoStack = new Stack<StrokeCollection>();
        private Stack<StrokeCollection> _redoStack = new Stack<StrokeCollection>();

        private int _currentPage = 1;
        private int _totalPages = 1;
        private Dictionary<int, StrokeCollection> _whiteboardPages = new Dictionary<int, StrokeCollection>();

        private bool _isDarkTheme = true;

        // Custom Lasso variables
        private PointCollection _lassoPoints = new PointCollection();
        private bool _isLassoing = false;

        public MainWindow()
        {
            InitializeComponent();
            PdfItemsControl.ItemsSource = PdfPages;
            System.Text.Encoding.RegisterProvider(System.Text.CodePagesEncodingProvider.Instance);

            MainInkCanvas.Cursor = Cursors.Arrow;
            LaserInkCanvas.Cursor = Cursors.Arrow;

            Workspace.Width = 3840; Workspace.Height = 2160;
            MainInkCanvas.Width = 3840; MainInkCanvas.Height = 2160;
            LaserInkCanvas.Width = 3840; LaserInkCanvas.Height = 2160;
            CursorCanvas.Width = 3840; CursorCanvas.Height = 2160;

            _laserTimer = new DispatcherTimer(DispatcherPriority.Render) { Interval = TimeSpan.FromMilliseconds(33) };
            _laserTimer.Tick += LaserTimer_Tick;
            _laserTimer.Start();

            SyncToolToUI();
            UpdatePageUI();
            ApplyTheme();
        }

        // --- SURGICAL VISUAL TREE REFLECTION (The True Yellow Resizing Box Fix) ---
        private void MainInkCanvas_SelectionChanged(object sender, EventArgs e)
        {
            // Delay injection until the application is fully idle and Adorner is drawn
            Dispatcher.BeginInvoke(new Action(() => ForceYellowSelectionBox(MainInkCanvas)), DispatcherPriority.ApplicationIdle);
        }

        private void ForceYellowSelectionBox(DependencyObject parent)
        {
            if (parent == null) return;

            int childrenCount = VisualTreeHelper.GetChildrenCount(parent);
            for (int i = 0; i < childrenCount; i++)
            {
                var child = VisualTreeHelper.GetChild(parent, i);
                
                if (child is UIElement uiElement)
                {
                    var layer = System.Windows.Documents.AdornerLayer.GetAdornerLayer(uiElement);
                    if (layer != null)
                    {
                        var adorners = layer.GetAdorners(uiElement);
                        if (adorners != null)
                        {
                            foreach (var adorner in adorners)
                            {
                                if (adorner.GetType().Name == "InkCanvasSelectionAdorner")
                                {
                                    ModifyAdorner(adorner);
                                }
                            }
                        }
                    }
                }
                ForceYellowSelectionBox(child);
            }
        }

        private void ModifyAdorner(System.Windows.Documents.Adorner adorner)
        {
            var flags = BindingFlags.NonPublic | BindingFlags.Instance;
            
            var hatchPenField = adorner.GetType().GetField("_hatchPen", flags);
            if (hatchPenField != null)
            {
                Pen yellowDash = new Pen(Brushes.Yellow, 1.5) { DashStyle = DashStyles.Dash };
                hatchPenField.SetValue(adorner, yellowDash);
            }

            var elementsPenField = adorner.GetType().GetField("_elementsPen", flags);
            if (elementsPenField != null)
            {
                Pen yellowSolid = new Pen(Brushes.Yellow, 1.5);
                elementsPenField.SetValue(adorner, yellowSolid);
            }

            var elementsFillBrushField = adorner.GetType().GetField("_elementsFillBrush", flags);
            if (elementsFillBrushField != null)
            {
                elementsFillBrushField.SetValue(adorner, Brushes.Yellow);
            }
            
            adorner.InvalidateVisual(); 
        }

        private void Theme_Click(object sender, RoutedEventArgs e)
        {
            _isDarkTheme = !_isDarkTheme;
            ApplyTheme();
            UpdateCustomCursorAppearance();
        }

        private void ApplyTheme()
        {
            if (_isDarkTheme)
            {
                MainScroll.Background = new SolidColorBrush(Color.FromRgb(15, 17, 21)); 
                if (string.IsNullOrEmpty(_currentPdfPath)) Workspace.Background = CreateGridBrush(Color.FromRgb(42, 46, 57)); 
            }
            else
            {
                MainScroll.Background = new SolidColorBrush(Color.FromRgb(245, 245, 245)); 
                if (string.IsNullOrEmpty(_currentPdfPath)) Workspace.Background = CreateGridBrush(Color.FromRgb(224, 224, 224)); 
            }
        }

        private DrawingBrush CreateGridBrush(Color lineColor)
        {
            DrawingBrush brush = new DrawingBrush { TileMode = TileMode.Tile, Viewport = new Rect(0, 0, 40, 40), ViewportUnits = BrushMappingMode.Absolute };
            GeometryDrawing drawing = new GeometryDrawing { Pen = new Pen(new SolidColorBrush(lineColor), 1) };
            GeometryGroup group = new GeometryGroup();
            group.Children.Add(new LineGeometry(new Point(0, 0), new Point(0, 40)));
            group.Children.Add(new LineGeometry(new Point(0, 0), new Point(40, 0)));
            drawing.Geometry = group;
            brush.Drawing = drawing;
            return brush;
        }

        private void SaveCurrentPage()
        {
            if (!string.IsNullOrEmpty(_currentPdfPath)) return;
            _whiteboardPages[_currentPage] = MainInkCanvas.Strokes.Clone();
        }

        private void LoadPage(int page)
        {
            if (_whiteboardPages.ContainsKey(page)) MainInkCanvas.Strokes = _whiteboardPages[page].Clone();
            else MainInkCanvas.Strokes.Clear();
            
            _undoStack.Clear();
            _redoStack.Clear();
            LaserInkCanvas.Strokes.Clear();
            _laserStrokes.Clear();
        }

        private void UpdatePageUI()
        {
            PageCounterText.Text = $"{_currentPage} / {_totalPages}";
        }

        private void PrevPage_Click(object sender, RoutedEventArgs e)
        {
            if (string.IsNullOrEmpty(_currentPdfPath) && _currentPage > 1)
            {
                SaveCurrentPage();
                _currentPage--;
                LoadPage(_currentPage);
                UpdatePageUI();
            }
        }

        private void NextPage_Click(object sender, RoutedEventArgs e)
        {
            if (string.IsNullOrEmpty(_currentPdfPath))
            {
                SaveCurrentPage();
                if (_currentPage == _totalPages) _totalPages++;
                _currentPage++;
                LoadPage(_currentPage);
                UpdatePageUI();
            }
        }

        private void DeletePage_Click(object sender, RoutedEventArgs e)
        {
            if (!string.IsNullOrEmpty(_currentPdfPath) || _totalPages <= 1) return;

            SaveCurrentPage();
            _whiteboardPages.Remove(_currentPage);

            for (int i = _currentPage + 1; i <= _totalPages; i++)
            {
                if (_whiteboardPages.ContainsKey(i))
                {
                    _whiteboardPages[i - 1] = _whiteboardPages[i];
                    _whiteboardPages.Remove(i);
                }
            }

            _totalPages--;
            if (_currentPage > _totalPages) _currentPage = _totalPages;

            LoadPage(_currentPage);
            UpdatePageUI();
        }

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
                _isUpdatingUI = false;
            }
        }

        // --- THE CUSTOM YELLOW LASSO ENGINE ---
        private void MainInkCanvas_PreviewMouseLeftButtonDown(object sender, MouseButtonEventArgs e)
        {
            if (MainInkCanvas.EditingMode != InkCanvasEditingMode.None && MainInkCanvas.EditingMode != InkCanvasEditingMode.Select)
            {
                SaveUndoState();
            }

            if (SelectBtn.IsChecked == true)
            {
                var hitResult = MainInkCanvas.HitTestSelection(e.GetPosition(MainInkCanvas));
                if (hitResult == InkCanvasSelectionHitResult.None)
                {
                    // Starts the Custom Yellow Lasso
                    MainInkCanvas.EditingMode = InkCanvasEditingMode.None; // Defeats the Microsoft default black lasso
                    _isLassoing = true;
                    _lassoPoints.Clear();
                    _lassoPoints.Add(e.GetPosition(CursorCanvas));
                    CustomLassoPolygon.Points = _lassoPoints;
                    CustomLassoPolygon.Visibility = Visibility.Visible;
                    MainInkCanvas.CaptureMouse();
                    e.Handled = true;
                }
                else
                {
                    // Allow normal WPF resizing logic if they clicked on a selected bounding box
                    MainInkCanvas.EditingMode = InkCanvasEditingMode.Select;
                }
            }
        }

        private void MainInkCanvas_PreviewMouseMove(object sender, MouseEventArgs e)
        {
            if (_isLassoing && e.LeftButton == MouseButtonState.Pressed)
            {
                _lassoPoints.Add(e.GetPosition(CursorCanvas));
            }
        }

        private void MainInkCanvas_PreviewMouseLeftButtonUp(object sender, MouseButtonEventArgs e)
        {
            if (_isLassoing)
            {
                _isLassoing = false;
                MainInkCanvas.ReleaseMouseCapture();
                CustomLassoPolygon.Visibility = Visibility.Hidden;

                if (_lassoPoints.Count > 3)
                {
                    // Mathematically select strokes inside the custom lasso
                    var selected = MainInkCanvas.Strokes.HitTest(_lassoPoints, 50); 
                    MainInkCanvas.Select(selected);
                }
                
                // Restore Select Mode so the bounding box and resize handles activate
                MainInkCanvas.EditingMode = InkCanvasEditingMode.Select;
                e.Handled = true;
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
            if (Keyboard.Modifiers == ModifierKeys.Control)
            {
                if (e.Key == Key.Z) { PerformUndo(); return; }
                if (e.Key == Key.Y) { PerformRedo(); return; }
            }

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

            if (e.Key == Key.T) { Theme_Click(null, null); return; }

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

            if (e.Key == Key.OemComma) SizeSlider.Value = Math.Max(SizeSlider.Minimum, SizeSlider.Value - 1.0);
            if (e.Key == Key.OemPeriod) SizeSlider.Value = Math.Min(SizeSlider.Maximum, SizeSlider.Value + 1.0);

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
            if (MainInkCanvas == null || LaserInkCanvas == null) return;

            bool ignorePressure = PressureToggle.IsChecked == false;
            Color activeColor = GetComboColor();
            double activeSize = SizeSlider.Value;

            if (LaserBtn.IsChecked == true)
            {
                MainInkCanvas.IsHitTestVisible = false;
                LaserInkCanvas.IsHitTestVisible = true;
                
                LaserInkCanvas.EditingMode = InkCanvasEditingMode.Ink;
                LaserInkCanvas.DefaultDrawingAttributes = new DrawingAttributes { Color = activeColor, Width = activeSize, Height = activeSize, FitToCurve = true, IgnorePressure = true };
                LaserInkCanvas.Effect = new System.Windows.Media.Effects.DropShadowEffect { Color = activeColor, BlurRadius = 15, ShadowDepth = 0, Opacity = 0.5 };
            }
            else
            {
                MainInkCanvas.IsHitTestVisible = true;
                LaserInkCanvas.IsHitTestVisible = false;

                if (PenBtn.IsChecked == true)
                {
                    MainInkCanvas.EditingMode = InkCanvasEditingMode.Ink;
                    MainInkCanvas.DefaultDrawingAttributes = new DrawingAttributes { Color = activeColor, Width = activeSize, Height = activeSize, FitToCurve = true, IgnorePressure = ignorePressure };
                }
                else if (HighlightBtn.IsChecked == true)
                {
                    MainInkCanvas.EditingMode = InkCanvasEditingMode.Ink;
                    MainInkCanvas.DefaultDrawingAttributes = new DrawingAttributes { Color = Color.FromArgb(120, activeColor.R, activeColor.G, activeColor.B), Width = activeSize * 4, Height = activeSize * 4, StylusTip = StylusTip.Rectangle, IsHighlighter = true, IgnorePressure = true };
                }
                else if (EraserBtn.IsChecked == true)
                {
                    MainInkCanvas.EditingMode = InkCanvasEditingMode.EraseByStroke;
                }
                else if (SelectBtn.IsChecked == true)
                {
                    MainInkCanvas.EditingMode = InkCanvasEditingMode.Select; // Ensure default is loaded if not lassoing
                }
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
            
            if (LaserBtn.IsChecked == true) 
            {
                CustomDotCursor.Fill = new SolidColorBrush(c);
                // ABSOLUTELY ZERO OUTLINE FOR THE LASER DOT
                CustomDotCursor.StrokeThickness = 0;

                CursorGlow.Color = c; 
                CursorGlow.Opacity = 0.65; 
                CursorGlow.BlurRadius = 15; 
                CursorGlow.ShadowDepth = 0;
            } 
            else if (EraserBtn.IsChecked == true) 
            {
                size = 20; 
                CustomDotCursor.StrokeThickness = 1;
                CustomDotCursor.Stroke = new SolidColorBrush(Colors.Black);
                CustomDotCursor.Fill = new SolidColorBrush(Color.FromArgb(100, 255, 255, 255));
                CursorGlow.Opacity = 0.0;
            } 
            else 
            { 
                CustomDotCursor.StrokeThickness = 0;
                CustomDotCursor.Fill = new SolidColorBrush(Color.FromArgb(150, c.R, c.G, c.B)); 
                CursorGlow.Color = Colors.Black; 
                CursorGlow.Opacity = 0.5; 
                CursorGlow.BlurRadius = 4; 
                CursorGlow.ShadowDepth = 1;
            }

            CustomDotCursor.Width = size; 
            CustomDotCursor.Height = size;
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

        private void LaserInkCanvas_StrokeCollected(object sender, InkCanvasStrokeCollectedEventArgs e)
        {
            _laserStrokes.Add(new LaserStrokeData(e.Stroke));
            _lastLaserActivityTime = DateTime.Now; 
        }

        private void LaserTimer_Tick(object? sender, EventArgs e)
        {
            if (_laserStrokes.Count == 0) return;

            if ((DateTime.Now - _lastLaserActivityTime).TotalSeconds > 3.5)
            {
                _isUpdatingUI = true;
                LaserInkCanvas.Strokes.Clear();
                _laserStrokes.Clear();
                _isUpdatingUI = false;
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
                LaserInkCanvas.Strokes.Clear();
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

                    Workspace.Background = new SolidColorBrush(Colors.Transparent);
                    PaginationPanel.Visibility = Visibility.Collapsed;
                    
                    Workspace.Width = maxWidth; Workspace.Height = currentY;
                    MainInkCanvas.Width = maxWidth; MainInkCanvas.Height = currentY;
                    LaserInkCanvas.Width = maxWidth; LaserInkCanvas.Height = currentY;
                    CursorCanvas.Width = maxWidth; CursorCanvas.Height = currentY;
                    MainScroll.ScrollToTop();
                } 
                catch (Exception ex) { MessageBox.Show("Failed to load PDF: " + ex.Message); }
            }
        }

        private void ExportAnnotated_Click(object sender, RoutedEventArgs e)
        {
            if (string.IsNullOrEmpty(_currentPdfPath)) 
            { 
                SaveFileDialog wbdlg = new SaveFileDialog { Filter = "PDF (*.pdf)|*.pdf", FileName = "Whiteboard_Export.pdf" };
                if (wbdlg.ShowDialog() == true)
                {
                    try
                    {
                        SaveCurrentPage();
                        PdfSharp.Pdf.PdfDocument wbDoc = new PdfSharp.Pdf.PdfDocument();
                        
                        XColor bgColor = _isDarkTheme ? XColor.FromArgb(255, 15, 17, 21) : XColor.FromArgb(255, 245, 245, 245);
                        XColor gridColor = _isDarkTheme ? XColor.FromArgb(255, 42, 46, 57) : XColor.FromArgb(255, 224, 224, 224);

                        for (int i = 1; i <= _totalPages; i++)
                        {
                            PdfSharp.Pdf.PdfPage wbPage = wbDoc.AddPage();
                            wbPage.Width = XUnit.FromPoint(1920);
                            wbPage.Height = XUnit.FromPoint(1080);
                            XGraphics gfx = XGraphics.FromPdfPage(wbPage);

                            gfx.DrawRectangle(new XSolidBrush(bgColor), 0, 0, wbPage.Width.Point, wbPage.Height.Point);
                            XPen gridPen = new XPen(gridColor, 1);
                            for (double x = 0; x < wbPage.Width.Point; x += 40) gfx.DrawLine(gridPen, x, 0, x, wbPage.Height.Point);
                            for (double y = 0; y < wbPage.Height.Point; y += 40) gfx.DrawLine(gridPen, 0, y, wbPage.Width.Point, y);

                            double scaleX = wbPage.Width.Point / Workspace.Width;
                            double scaleY = wbPage.Height.Point / Workspace.Height;

                            StrokeCollection pageStrokes = (i == _currentPage) ? MainInkCanvas.Strokes : 
                                (_whiteboardPages.ContainsKey(i) ? _whiteboardPages[i] : new StrokeCollection());

                            foreach (Stroke stroke in pageStrokes)
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
                        }
                        wbDoc.Save(wbdlg.FileName);
                        MessageBox.Show("Multi-Page Theme Whiteboard Exported!");
                    }
                    catch (Exception ex) { MessageBox.Show("Export failed: " + ex.Message); }
                }
                return;
            }

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
            LaserInkCanvas.Strokes.Clear();
        }

        private void PerformZoomIn() { _zoom += 0.25; ZoomTransform.ScaleX = _zoom; ZoomTransform.ScaleY = _zoom; }
        private void PerformZoomOut() { _zoom = Math.Max(0.25, _zoom - 0.25); ZoomTransform.ScaleX = _zoom; ZoomTransform.ScaleY = _zoom; }

        private void ZoomIn_Click(object sender, RoutedEventArgs e) => PerformZoomIn();
        private void ZoomOut_Click(object sender, RoutedEventArgs e) => PerformZoomOut();
    }
}
EOF

echo "✅ Script generated flawlessly! Ready for zero-error execution."
