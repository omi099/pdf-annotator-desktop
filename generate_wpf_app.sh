#!/bin/bash
set -e

echo "🚀 Bootstrapping the Ultimate Native WPF Teaching Annotator..."

# 1. Clean environment and create a pristine .NET 8 WPF App
rm -rf TeachingAnnotator
dotnet new wpf -n TeachingAnnotator --force
cd TeachingAnnotator

# 2. Install the Industry-Standard Native PDF Writer Libraries
dotnet add package PdfSharp --version 6.1.1
dotnet add package System.Text.Encoding.CodePages --version 8.0.0

# 3. Overwrite .csproj to target Windows 10 APIs for the Native PDF Reader Engine
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

# 4. Overwrite MainWindow.xaml (The Complete Feature-Rich UI)
cat << 'EOF' > MainWindow.xaml
<Window x:Class="TeachingAnnotator.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Apex Native Annotator - Ultimate Edition" Height="900" Width="1400"
        Background="#0f1115" WindowStartupLocation="CenterScreen">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        
        <Border Grid.Row="0" Background="#1a1c23" BorderBrush="#3a3f4b" BorderThickness="0,0,0,1">
            <WrapPanel Orientation="Horizontal" Padding="15,10">
                <Button Content="📂 Open PDF" Click="OpenPdf_Click" Foreground="White" Background="#3a3f4b" Margin="0,0,10,0" Padding="12,6" FontWeight="Bold" BorderThickness="0"/>
                <Button Content="💾 Export Annotated PDF" Click="ExportAnnotated_Click" Foreground="#00ffcc" Background="#3a3f4b" Margin="0,0,10,0" Padding="12,6" FontWeight="Bold" BorderThickness="0"/>
                <Button Content="💾 Save Original PDF" Click="ExportOriginal_Click" Foreground="White" Background="#3a3f4b" Margin="0,0,20,0" Padding="12,6" FontWeight="Bold" BorderThickness="0"/>
                
                <Rectangle Width="2" Fill="#3a3f4b" Margin="0,0,20,0"/>
                
                <RadioButton Content="🖊️ Pen" x:Name="PenBtn" IsChecked="True" Checked="Tool_Checked" Foreground="White" Margin="0,0,15,0" VerticalAlignment="Center" FontWeight="Bold"/>
                <RadioButton Content="🖍️ Highlight" x:Name="HighlightBtn" Checked="Tool_Checked" Foreground="White" Margin="0,0,15,0" VerticalAlignment="Center" FontWeight="Bold"/>
                <RadioButton Content="🧽 Eraser" x:Name="EraserBtn" Checked="Tool_Checked" Foreground="White" Margin="0,0,20,0" VerticalAlignment="Center" FontWeight="Bold"/>
                
                <Rectangle Width="2" Fill="#3a3f4b" Margin="0,0,20,0"/>
                
                <TextBlock Text="Color:" Foreground="White" VerticalAlignment="Center" Margin="0,0,5,0" FontWeight="Bold"/>
                <ComboBox x:Name="ColorPicker" SelectionChanged="Color_Changed" Width="80" Margin="0,0,15,0" SelectedIndex="0">
                    <ComboBoxItem Content="Red"/>
                    <ComboBoxItem Content="Blue"/>
                    <ComboBoxItem Content="Green"/>
                    <ComboBoxItem Content="Black"/>
                    <ComboBoxItem Content="White"/>
                    <ComboBoxItem Content="Yellow"/>
                </ComboBox>

                <TextBlock Text="Size:" Foreground="White" VerticalAlignment="Center" Margin="0,0,5,0" FontWeight="Bold"/>
                <Slider x:Name="SizeSlider" Minimum="1" Maximum="50" Value="4" Width="100" VerticalAlignment="Center" Margin="0,0,10,0" ValueChanged="Size_Changed"/>
                <TextBlock Text="{Binding Value, ElementName=SizeSlider, StringFormat={}{0:0}}" Foreground="#00ffcc" VerticalAlignment="Center" Margin="0,0,15,0" Width="20" FontWeight="Bold"/>

                <CheckBox x:Name="PressureToggle" Content="Pressure Effect" IsChecked="True" Foreground="White" VerticalAlignment="Center" Margin="0,0,20,0" Checked="Pressure_Changed" Unchecked="Pressure_Changed" FontWeight="Bold"/>

                <Rectangle Width="2" Fill="#3a3f4b" Margin="0,0,20,0"/>

                <Button Content="🗑️ Clear Ink" Click="ClearInk_Click" Foreground="#ff4757" Background="#3a3f4b" Margin="0,0,10,0" Padding="12,6" FontWeight="Bold" BorderThickness="0"/>
                <Button Content="🔍 +" Click="ZoomIn_Click" Foreground="White" Background="#3a3f4b" Margin="0,0,5,0" Padding="10,6" FontWeight="Bold" BorderThickness="0"/>
                <Button Content="🔍 -" Click="ZoomOut_Click" Foreground="White" Background="#3a3f4b" Padding="10,6" FontWeight="Bold" BorderThickness="0"/>
            </WrapPanel>
        </Border>

        <ScrollViewer Grid.Row="1" x:Name="MainScroll" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto" PanningMode="Both">
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
                                <Image Source="{Binding ImageSource}" Width="{Binding Width}" Height="{Binding Height}" Stretch="Uniform"/>
                            </Border>
                        </DataTemplate>
                    </ItemsControl.ItemTemplate>
                </ItemsControl>

                <InkCanvas x:Name="MainInkCanvas" Background="Transparent" UseCustomCursor="False" HorizontalAlignment="Left" VerticalAlignment="Top"/>
            </Grid>
        </ScrollViewer>
    </Grid>
</Window>
EOF

# 6. Overwrite MainWindow.xaml.cs (The Complete Physics & Export Backend)
cat << 'EOF' > MainWindow.xaml.cs
using System;
using System.Collections.ObjectModel;
using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Ink;
using System.Windows.Media;
using System.Windows.Media.Imaging;
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

    public partial class MainWindow : Window
    {
        public ObservableCollection<PdfPageModel> PdfPages { get; set; } = new ObservableCollection<PdfPageModel>();
        private double _zoom = 1.0;
        private string? _currentPdfPath = null;

        public MainWindow()
        {
            InitializeComponent();
            PdfItemsControl.ItemsSource = PdfPages;
            
            // Required for PdfSharp in .NET 8
            System.Text.Encoding.RegisterProvider(System.Text.CodePagesEncodingProvider.Instance);

            UpdatePenAttributes();
        }

        // --- DYNAMIC TOOL ATTRIBUTES ---
        private void UpdatePenAttributes()
        {
            if (MainInkCanvas == null || ColorPicker == null || SizeSlider == null || PressureToggle == null) return;

            Color selectedColor = Colors.Red;
            if (ColorPicker.Text == "Blue") selectedColor = Colors.Blue;
            else if (ColorPicker.Text == "Green") selectedColor = Colors.Green;
            else if (ColorPicker.Text == "Black") selectedColor = Colors.Black;
            else if (ColorPicker.Text == "White") selectedColor = Colors.White;
            else if (ColorPicker.Text == "Yellow") selectedColor = Colors.Yellow;

            double size = SizeSlider.Value;
            bool ignorePressure = PressureToggle.IsChecked == false;

            if (PenBtn.IsChecked == true)
            {
                MainInkCanvas.EditingMode = InkCanvasEditingMode.Ink;
                MainInkCanvas.DefaultDrawingAttributes = new DrawingAttributes
                {
                    Color = selectedColor,
                    Width = size,
                    Height = size,
                    FitToCurve = true,
                    IgnorePressure = ignorePressure,
                    IsHighlighter = false
                };
            }
            else if (HighlightBtn.IsChecked == true)
            {
                MainInkCanvas.EditingMode = InkCanvasEditingMode.Ink;
                MainInkCanvas.DefaultDrawingAttributes = new DrawingAttributes
                {
                    // Highlighters are traditionally yellow with lower opacity, but we map the selected color
                    Color = Color.FromArgb(120, selectedColor.R, selectedColor.G, selectedColor.B),
                    Width = size * 4,
                    Height = size * 4,
                    StylusTip = StylusTip.Rectangle,
                    IsHighlighter = true,
                    IgnorePressure = true
                };
            }
            else if (EraserBtn.IsChecked == true)
            {
                MainInkCanvas.EditingMode = InkCanvasEditingMode.EraseByStroke;
            }
        }

        private void Tool_Checked(object sender, RoutedEventArgs e) => UpdatePenAttributes();
        private void Color_Changed(object sender, SelectionChangedEventArgs e) => UpdatePenAttributes();
        private void Size_Changed(object sender, RoutedPropertyChangedEventArgs<double> e) => UpdatePenAttributes();
        private void Pressure_Changed(object sender, RoutedEventArgs e) => UpdatePenAttributes();

        // --- NATIVE PDF RENDERING ---
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
                    PdfDocument pdfDoc = await PdfDocument.LoadFromFileAsync(file);

                    double currentY = 0;
                    double maxWidth = 0;

                    for (uint i = 0; i < pdfDoc.PageCount; i++)
                    {
                        using (PdfPage page = pdfDoc.GetPage(i))
                        {
                            using (var stream = new InMemoryRandomAccessStream())
                            {
                                var options = new PdfPageRenderOptions
                                {
                                    DestinationWidth = (uint)(page.Size.Width * 2),
                                    DestinationHeight = (uint)(page.Size.Height * 2)
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

                                    PdfPages.Add(new PdfPageModel
                                    {
                                        ImageSource = bitmap,
                                        Width = page.Size.Width,
                                        Height = page.Size.Height,
                                        StartY = currentY
                                    });

                                    currentY += page.Size.Height + 25; // 25px Margin matches XAML
                                    maxWidth = Math.Max(maxWidth, page.Size.Width);
                                }
                            }
                        }
                    }

                    Workspace.Width = maxWidth;
                    Workspace.Height = currentY;
                    MainInkCanvas.Width = maxWidth;
                    MainInkCanvas.Height = currentY;
                } 
                catch (Exception ex) 
                {
                    MessageBox.Show("Failed to load PDF: " + ex.Message, "Error", MessageBoxButton.OK, MessageBoxImage.Error);
                }
            }
        }

        // --- 100% MATHEMATICAL VECTOR EXPORT ---
        private void ExportAnnotated_Click(object sender, RoutedEventArgs e)
        {
            if (string.IsNullOrEmpty(_currentPdfPath))
            {
                MessageBox.Show("Please open a PDF first.", "Warning", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            SaveFileDialog dlg = new SaveFileDialog { Filter = "PDF Files (*.pdf)|*.pdf", DefaultExt = ".pdf", FileName = "Annotated_Document.pdf" };
            if (dlg.ShowDialog() == true)
            {
                try
                {
                    // Open the pristine original PDF
                    PdfDocument document = PdfReader.Open(_currentPdfPath, PdfDocumentOpenMode.Modify);

                    for (int i = 0; i < document.Pages.Count; i++)
                    {
                        if (i >= PdfPages.Count) break;
                        
                        PdfSharp.Pdf.PdfPage pdfPage = document.Pages[i];
                        XGraphics gfx = XGraphics.FromPdfPage(pdfPage);

                        PdfPageModel uiPage = PdfPages[i];
                        double pageTopY = uiPage.StartY;
                        double pageBottomY = uiPage.StartY + uiPage.Height;

                        // Calculate mathematical scaling between the UI coordinates and PDF point coordinates
                        double scaleX = pdfPage.Width / uiPage.Width;
                        double scaleY = pdfPage.Height / uiPage.Height;

                        foreach (Stroke stroke in MainInkCanvas.Strokes)
                        {
                            Rect bounds = stroke.GetBounds();
                            
                            // Optimization: Only process strokes that physically touch this page
                            if (bounds.Bottom >= pageTopY && bounds.Top <= pageBottomY)
                            {
                                XColor color = XColor.FromArgb(stroke.DrawingAttributes.Color.A, stroke.DrawingAttributes.Color.R, stroke.DrawingAttributes.Color.G, stroke.DrawingAttributes.Color.B);
                                double baseThickness = stroke.DrawingAttributes.Width * scaleX;

                                StylusPointCollection points = stroke.StylusPoints;
                                if (points.Count > 1)
                                {
                                    for (int j = 0; j < points.Count - 1; j++)
                                    {
                                        var p1 = points[j];
                                        var p2 = points[j + 1];

                                        // Map UI coordinates exactly to the PDF matrix
                                        double x1 = p1.X * scaleX;
                                        double y1 = (p1.Y - pageTopY) * scaleY;
                                        double x2 = p2.X * scaleX;
                                        double y2 = (p2.Y - pageTopY) * scaleY;

                                        // Map Hardware Pressure
                                        double pFactor = stroke.DrawingAttributes.IgnorePressure ? 1.0 : p1.PressureFactor * 2.0;
                                        
                                        XPen segmentPen = new XPen(color, baseThickness * pFactor);
                                        segmentPen.LineCap = XLineCap.Round;

                                        // Inject pure vector line into the PDF
                                        gfx.DrawLine(segmentPen, x1, y1, x2, y2);
                                    }
                                }
                            }
                        }
                    }

                    document.Save(dlg.FileName);
                    MessageBox.Show("Vector PDF Exported Successfully! Text is selectable and ink is infinitely crisp.", "Success", MessageBoxButton.OK, MessageBoxImage.Information);
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Failed to export Annotated PDF: " + ex.Message, "Error", MessageBoxButton.OK, MessageBoxImage.Error);
                }
            }
        }

        private void ExportOriginal_Click(object sender, RoutedEventArgs e)
        {
            if (string.IsNullOrEmpty(_currentPdfPath)) return;
            
            SaveFileDialog dlg = new SaveFileDialog { Filter = "PDF Files (*.pdf)|*.pdf", DefaultExt = ".pdf", FileName = "Original_Document.pdf" };
            if (dlg.ShowDialog() == true)
            {
                File.Copy(_currentPdfPath, dlg.FileName, true);
                MessageBox.Show("Original PDF saved successfully.", "Success", MessageBoxButton.OK, MessageBoxImage.Information);
            }
        }

        private void ClearInk_Click(object sender, RoutedEventArgs e)
        {
            if (MessageBox.Show("Are you sure you want to clear all annotations?", "Confirm", MessageBoxButton.YesNo, MessageBoxImage.Warning) == MessageBoxResult.Yes)
            {
                MainInkCanvas.Strokes.Clear();
            }
        }

        private void ZoomIn_Click(object sender, RoutedEventArgs e)
        {
            _zoom += 0.25;
            ZoomTransform.ScaleX = _zoom; ZoomTransform.ScaleY = _zoom;
        }

        private void ZoomOut_Click(object sender, RoutedEventArgs e)
        {
            _zoom = Math.Max(0.25, _zoom - 0.25);
            ZoomTransform.ScaleX = _zoom; ZoomTransform.ScaleY = _zoom;
        }
    }
}
EOF

echo "✅ Apex Native WPF Codebase Generated Flawlessly!"
