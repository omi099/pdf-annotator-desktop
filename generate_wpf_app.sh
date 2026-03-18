#!/bin/bash
set -e

echo "🚀 Bootstrapping Native WPF Teaching Annotator..."

# 1. Create a modern .NET 8 WPF App
mkdir -p TeachingAnnotator
cd TeachingAnnotator
dotnet new wpf -n TeachingAnnotator --force

# 2. Overwrite .csproj to target Windows 10 APIs (required for Native PDF Rendering)
cat << 'EOF' > TeachingAnnotator.csproj
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net8.0-windows10.0.19041.0</TargetFramework>
    <Nullable>enable</Nullable>
    <UseWPF>true</UseWPF>
  </PropertyGroup>
</Project>
EOF

# 3. Overwrite MainWindow.xaml (The Hardware-Accelerated UI)
cat << 'EOF' > MainWindow.xaml
<Window x:Class="TeachingAnnotator.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Apex Native Annotator (WPF)" Height="900" Width="1400"
        Background="#0f1115">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        
        <ToolBar Grid.Row="0" Background="#1a1c23" Foreground="White" Padding="10">
            <Button Content="📂 Open PDF" Click="OpenPdf_Click" Foreground="White" Background="#3a3f4b" Margin="0,0,10,0" Padding="10,5"/>
            <Button Content="💾 Save Ink Vector" Click="SaveInk_Click" Foreground="#00ffcc" Background="#3a3f4b" Margin="0,0,10,0" Padding="10,5"/>
            <Button Content="📄 Load Ink" Click="LoadInk_Click" Foreground="White" Background="#3a3f4b" Margin="0,0,20,0" Padding="10,5"/>
            
            <RadioButton Content="🖊️ Pen" x:Name="PenBtn" IsChecked="True" Checked="Tool_Checked" Foreground="White" Margin="0,0,10,0"/>
            <RadioButton Content="🖍️ Highlighter" x:Name="HighlightBtn" Checked="Tool_Checked" Foreground="White" Margin="0,0,10,0"/>
            <RadioButton Content="🧽 Eraser" x:Name="EraserBtn" Checked="Tool_Checked" Foreground="White" Margin="0,0,20,0"/>
            
            <Button Content="🔍 Zoom In" Click="ZoomIn_Click" Foreground="White" Background="#3a3f4b" Margin="0,0,10,0" Padding="10,5"/>
            <Button Content="🔍 Zoom Out" Click="ZoomOut_Click" Foreground="White" Background="#3a3f4b" Padding="10,5"/>
        </ToolBar>

        <ScrollViewer Grid.Row="1" x:Name="MainScroll" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto">
            <Grid x:Name="Workspace" HorizontalAlignment="Center" VerticalAlignment="Top" Margin="40">
                <Grid.LayoutTransform>
                    <ScaleTransform x:Name="ZoomTransform" ScaleX="1" ScaleY="1"/>
                </Grid.LayoutTransform>
                
                <ItemsControl x:Name="PdfItemsControl">
                    <ItemsControl.ItemTemplate>
                        <DataTemplate>
                            <Image Source="{Binding ImageSource}" Width="{Binding Width}" Height="{Binding Height}" Margin="0,0,0,20" Stretch="Uniform"/>
                        </DataTemplate>
                    </ItemsControl.ItemTemplate>
                </ItemsControl>

                <InkCanvas x:Name="MainInkCanvas" Background="Transparent" UseCustomCursor="False"/>
            </Grid>
        </ScrollViewer>
    </Grid>
</Window>
EOF

# 4. Overwrite MainWindow.xaml.cs (The C# Backend Logic)
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

namespace TeachingAnnotator
{
    public class PdfPageModel
    {
        public BitmapImage ImageSource { get; set; }
        public double Width { get; set; }
        public double Height { get; set; }
    }

    public partial class MainWindow : Window
    {
        public ObservableCollection<PdfPageModel> PdfPages { get; set; } = new ObservableCollection<PdfPageModel>();
        private double _zoom = 1.0;

        public MainWindow()
        {
            InitializeComponent();
            PdfItemsControl.ItemsSource = PdfPages;
            
            // Configure Native Pen Settings
            var drawingAttributes = new DrawingAttributes
            {
                Color = Colors.Red,
                Width = 4,
                Height = 4,
                FitToCurve = true,
                IgnorePressure = false // Hardware pressure enabled natively!
            };
            MainInkCanvas.DefaultDrawingAttributes = drawingAttributes;
        }

        private async void OpenPdf_Click(object sender, RoutedEventArgs e)
        {
            OpenFileDialog dlg = new OpenFileDialog { Filter = "PDF Files (*.pdf)|*.pdf" };
            if (dlg.ShowDialog() == true)
            {
                PdfPages.Clear();
                MainInkCanvas.Strokes.Clear();

                // Load PDF via Native Windows 10/11 Engine
                StorageFile file = await StorageFile.GetFileFromPathAsync(dlg.FileName);
                PdfDocument pdfDoc = await PdfDocument.LoadFromFileAsync(file);

                double totalHeight = 0;
                double maxWidth = 0;

                for (uint i = 0; i < pdfDoc.PageCount; i++)
                {
                    using (PdfPage page = pdfDoc.GetPage(i))
                    {
                        using (var stream = new InMemoryRandomAccessStream())
                        {
                            // Render crisp at 2x scale
                            var options = new PdfPageRenderOptions
                            {
                                DestinationWidth = (uint)(page.Size.Width * 2),
                                DestinationHeight = (uint)(page.Size.Height * 2)
                            };
                            await page.RenderToStreamAsync(stream, options);

                            var bitmap = new BitmapImage();
                            bitmap.BeginInit();
                            bitmap.CacheOption = BitmapCacheOption.OnLoad;
                            bitmap.StreamSource = stream.AsStream();
                            bitmap.EndInit();

                            PdfPages.Add(new PdfPageModel
                            {
                                ImageSource = bitmap,
                                Width = page.Size.Width,
                                Height = page.Size.Height
                            });

                            totalHeight += page.Size.Height + 20;
                            maxWidth = Math.Max(maxWidth, page.Size.Width);
                        }
                    }
                }

                Workspace.Width = maxWidth;
                Workspace.Height = totalHeight;
                MainInkCanvas.Width = maxWidth;
                MainInkCanvas.Height = totalHeight;
            }
        }

        private void Tool_Checked(object sender, RoutedEventArgs e)
        {
            if (MainInkCanvas == null) return;

            if (PenBtn.IsChecked == true)
            {
                MainInkCanvas.EditingMode = InkCanvasEditingMode.Ink;
                MainInkCanvas.DefaultDrawingAttributes.IsHighlighter = false;
                MainInkCanvas.DefaultDrawingAttributes.Color = Colors.Red;
                MainInkCanvas.DefaultDrawingAttributes.Width = 4;
                MainInkCanvas.DefaultDrawingAttributes.Height = 4;
            }
            else if (HighlightBtn.IsChecked == true)
            {
                MainInkCanvas.EditingMode = InkCanvasEditingMode.Ink;
                MainInkCanvas.DefaultDrawingAttributes.IsHighlighter = true;
                MainInkCanvas.DefaultDrawingAttributes.Color = Colors.Yellow;
                MainInkCanvas.DefaultDrawingAttributes.Width = 24;
                MainInkCanvas.DefaultDrawingAttributes.Height = 24;
            }
            else if (EraserBtn.IsChecked == true)
            {
                // Native stroke eraser - removes the whole line mathematically
                MainInkCanvas.EditingMode = InkCanvasEditingMode.EraseByStroke;
            }
        }

        private void SaveInk_Click(object sender, RoutedEventArgs e)
        {
            // Saves pure vector paths to an ISF file (Ink Serialized Format) - Extremely lightweight!
            SaveFileDialog dlg = new SaveFileDialog { Filter = "Vector Ink Data (*.isf)|*.isf" };
            if (dlg.ShowDialog() == true)
            {
                using (FileStream fs = new FileStream(dlg.FileName, FileMode.Create))
                {
                    MainInkCanvas.Strokes.Save(fs);
                }
                MessageBox.Show("Vector Ink saved successfully!");
            }
        }

        private void LoadInk_Click(object sender, RoutedEventArgs e)
        {
            OpenFileDialog dlg = new OpenFileDialog { Filter = "Vector Ink Data (*.isf)|*.isf" };
            if (dlg.ShowDialog() == true)
            {
                using (FileStream fs = new FileStream(dlg.FileName, FileMode.Open))
                {
                    StrokeCollection strokes = new StrokeCollection(fs);
                    MainInkCanvas.Strokes = strokes;
                }
            }
        }

        private void ZoomIn_Click(object sender, RoutedEventArgs e)
        {
            _zoom += 0.25;
            ZoomTransform.ScaleX = _zoom;
            ZoomTransform.ScaleY = _zoom;
        }

        private void ZoomOut_Click(object sender, RoutedEventArgs e)
        {
            _zoom = Math.Max(0.25, _zoom - 0.25);
            ZoomTransform.ScaleX = _zoom;
            ZoomTransform.ScaleY = _zoom;
        }
    }
}
EOF

echo "✅ Perfect Native WPF Codebase Generated!"
