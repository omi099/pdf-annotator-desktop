#!/bin/bash
set -e

echo "🚀 Bootstrapping Native WinUI 3 Teaching Annotator..."

# 1. Install Community WinUI CLI Templates (Bypasses Microsoft's VS-only restriction)
dotnet new install VijayAnand.WinUITemplates

# 2. Explicitly create the project directory and move into it
mkdir -p TeachingAnnotator
cd TeachingAnnotator

# 3. Create the WinUI 3 Project inside the current folder
dotnet new winui -n TeachingAnnotator -f net8.0 --force

# 4. Overwrite the .csproj for Unpackaged, Self-Contained .EXE generation
cat << 'EOF' > TeachingAnnotator.csproj
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net8.0-windows10.0.19041.0</TargetFramework>
    <TargetPlatformMinVersion>10.0.17763.0</TargetPlatformMinVersion>
    <RootNamespace>TeachingAnnotator</RootNamespace>
    <ApplicationManifest>app.manifest</ApplicationManifest>
    <Platforms>x86;x64;ARM64</Platforms>
    <RuntimeIdentifiers>win-x86;win-x64;win-arm64</RuntimeIdentifiers>
    <UseWinUI>true</UseWinUI>
    <EnableMsixTooling>true</EnableMsixTooling>
    
    <WindowsPackageType>None</WindowsPackageType>
    <WindowsAppSDKSelfContained>true</WindowsAppSDKSelfContained>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Microsoft.WindowsAppSDK" Version="1.5.240311000" />
    <PackageReference Include="Microsoft.Windows.SDK.BuildTools" Version="10.0.22621.3233" />
    <Manifest Include="$(ApplicationManifest)" />
  </ItemGroup>
</Project>
EOF

# 5. Overwrite MainWindow.xaml (Native Hardware-Accelerated UI)
cat << 'EOF' > MainWindow.xaml
<Window
    x:Class="TeachingAnnotator.MainWindow"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Apex Native Annotator">

    <Grid Background="#0f1115">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <CommandBar Grid.Row="0" Background="#1a1c23" DefaultLabelPosition="Right">
            <AppBarButton Icon="OpenFile" Label="Open PDF" Click="OpenPdf_Click" Foreground="White"/>
            <AppBarButton Icon="Save" Label="Save Vector Ink" Click="SaveInk_Click" Foreground="#00ffcc"/>
            <AppBarButton Icon="Document" Label="Load Ink" Click="LoadInk_Click" Foreground="White"/>
            
            <AppBarSeparator/>
            
            <AppBarToggleButton Icon="Edit" Label="Pen" x:Name="PenButton" Click="Tool_Click" IsChecked="True" Foreground="White"/>
            <AppBarToggleButton Icon="Highlight" Label="Highlighter" x:Name="HighlightButton" Click="Tool_Click" Foreground="White"/>
            <AppBarToggleButton Icon="Clear" Label="Eraser" x:Name="EraserButton" Click="Tool_Click" Foreground="White"/>
            
            <AppBarSeparator/>
            
            <AppBarButton Icon="ZoomIn" Label="Zoom In" Click="ZoomIn_Click" Foreground="White"/>
            <AppBarButton Icon="ZoomOut" Label="Zoom Out" Click="ZoomOut_Click" Foreground="White"/>
        </CommandBar>

        <ScrollViewer Grid.Row="1" x:Name="MainScrollViewer" 
                      ZoomMode="Enabled" MinZoomFactor="0.5" MaxZoomFactor="5.0" 
                      HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto"
                      Background="#0f1115">
            
            <Grid x:Name="WorkspaceGrid" HorizontalAlignment="Center" VerticalAlignment="Top" Margin="40">
                
                <ItemsControl x:Name="PdfPagesControl">
                    <ItemsControl.ItemTemplate>
                        <DataTemplate>
                            <Grid Margin="0,0,0,20" Background="White" CornerRadius="4">
                                <Image Source="{Binding ImageSource}" Width="{Binding Width}" Height="{Binding Height}" Stretch="Uniform"/>
                            </Grid>
                        </DataTemplate>
                    </ItemsControl.ItemTemplate>
                </ItemsControl>

                <InkCanvas x:Name="MainInkCanvas" HorizontalAlignment="Stretch" VerticalAlignment="Stretch"/>
                
            </Grid>
        </ScrollViewer>
    </Grid>
</Window>
EOF

# 6. Overwrite MainWindow.xaml.cs (C# Kernel-Level Logic)
cat << 'EOF' > MainWindow.xaml.cs
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media.Imaging;
using System;
using System.Collections.ObjectModel;
using Windows.Storage;
using Windows.Storage.Pickers;
using Windows.Data.Pdf;
using Windows.Storage.Streams;
using Microsoft.UI.Input.Inking;
using Windows.UI.Core;

namespace TeachingAnnotator
{
    public class PdfPageModel
    {
        public BitmapImage ImageSource { get; set; }
        public double Width { get; set; }
        public double Height { get; set; }
    }

    public sealed partial class MainWindow : Window
    {
        private ObservableCollection<PdfPageModel> PdfPages { get; set; } = new ObservableCollection<PdfPageModel>();

        public MainWindow()
        {
            this.InitializeComponent();
            PdfPagesControl.ItemsSource = PdfPages;

            // Direct Kernel Ink Handling - Flawless Palm Rejection & Erasers
            MainInkCanvas.InkPresenter.InputDeviceTypes = 
                CoreInputDeviceTypes.Mouse | 
                CoreInputDeviceTypes.Pen | 
                CoreInputDeviceTypes.Touch;

            InkDrawingAttributes drawingAttributes = new InkDrawingAttributes();
            drawingAttributes.Color = Windows.UI.Color.FromArgb(255, 255, 71, 87);
            drawingAttributes.Size = new Windows.Foundation.Size(4, 4);
            drawingAttributes.FitToCurve = true;
            MainInkCanvas.InkPresenter.UpdateDefaultDrawingAttributes(drawingAttributes);
        }

        private async void OpenPdf_Click(object sender, RoutedEventArgs e)
        {
            var picker = new FileOpenPicker();
            var hwnd = WinRT.Interop.WindowNative.GetWindowHandle(this);
            WinRT.Interop.InitializeWithWindow.Initialize(picker, hwnd);
            picker.ViewMode = PickerViewMode.Thumbnail;
            picker.FileTypeFilter.Add(".pdf");

            StorageFile file = await picker.PickSingleFileAsync();
            if (file == null) return;

            PdfPages.Clear();
            MainInkCanvas.InkPresenter.StrokeContainer.Clear();

            try
            {
                PdfDocument pdfDoc = await PdfDocument.LoadFromFileAsync(file);
                double totalHeight = 0;
                double maxWidth = 0;

                for (uint i = 0; i < pdfDoc.PageCount; i++)
                {
                    using (PdfPage page = pdfDoc.GetPage(i))
                    {
                        InMemoryRandomAccessStream stream = new InMemoryRandomAccessStream();
                        PdfPageRenderOptions options = new PdfPageRenderOptions();
                        options.DestinationWidth = (uint)(page.Size.Width * 2);
                        options.DestinationHeight = (uint)(page.Size.Height * 2);
                        
                        await page.RenderToStreamAsync(stream, options);

                        BitmapImage bitmap = new BitmapImage();
                        await bitmap.SetSourceAsync(stream);

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

                WorkspaceGrid.Width = maxWidth;
                WorkspaceGrid.Height = totalHeight;
                MainInkCanvas.Width = maxWidth;
                MainInkCanvas.Height = totalHeight;
                MainScrollViewer.ChangeView(null, null, 1.0f);
            }
            catch { }
        }

        private void Tool_Click(object sender, RoutedEventArgs e)
        {
            PenButton.IsChecked = false; HighlightButton.IsChecked = false; EraserButton.IsChecked = false;
            var button = sender as AppBarToggleButton;
            button.IsChecked = true;

            if (button == PenButton)
            {
                MainInkCanvas.InkPresenter.InputProcessingConfiguration.Mode = InkInputProcessingMode.Inking;
                var attr = MainInkCanvas.InkPresenter.CopyDefaultDrawingAttributes();
                attr.Color = Windows.UI.Color.FromArgb(255, 255, 71, 87);
                attr.Size = new Windows.Foundation.Size(4, 4);
                attr.PenTip = PenTipShape.Circle;
                MainInkCanvas.InkPresenter.UpdateDefaultDrawingAttributes(attr);
            }
            else if (button == HighlightButton)
            {
                MainInkCanvas.InkPresenter.InputProcessingConfiguration.Mode = InkInputProcessingMode.Inking;
                var attr = MainInkCanvas.InkPresenter.CopyDefaultDrawingAttributes();
                attr.Color = Windows.UI.Color.FromArgb(100, 253, 255, 182);
                attr.Size = new Windows.Foundation.Size(24, 24);
                attr.PenTip = PenTipShape.Rectangle;
                MainInkCanvas.InkPresenter.UpdateDefaultDrawingAttributes(attr);
            }
            else if (button == EraserButton)
            {
                MainInkCanvas.InkPresenter.InputProcessingConfiguration.Mode = InkInputProcessingMode.Erasing;
            }
        }

        private async void SaveInk_Click(object sender, RoutedEventArgs e)
        {
            var picker = new FileSavePicker();
            var hwnd = WinRT.Interop.WindowNative.GetWindowHandle(this);
            WinRT.Interop.InitializeWithWindow.Initialize(picker, hwnd);
            picker.SuggestedStartLocation = PickerLocationId.DocumentsLibrary;
            picker.FileTypeChoices.Add("Vector Ink Format", new[] { ".ink" });
            picker.SuggestedFileName = "Annotations";

            StorageFile file = await picker.PickSaveFileAsync();
            if (file != null)
            {
                using (IRandomAccessStream stream = await file.OpenAsync(FileAccessMode.ReadWrite))
                {
                    await MainInkCanvas.InkPresenter.StrokeContainer.SaveAsync(stream);
                }
            }
        }

        private async void LoadInk_Click(object sender, RoutedEventArgs e)
        {
            var picker = new FileOpenPicker();
            var hwnd = WinRT.Interop.WindowNative.GetWindowHandle(this);
            WinRT.Interop.InitializeWithWindow.Initialize(picker, hwnd);
            picker.FileTypeFilter.Add(".ink");

            StorageFile file = await picker.PickSingleFileAsync();
            if (file != null)
            {
                using (IRandomAccessStream stream = await file.OpenAsync(FileAccessMode.Read))
                {
                    await MainInkCanvas.InkPresenter.StrokeContainer.LoadAsync(stream);
                }
            }
        }

        private void ZoomIn_Click(object sender, RoutedEventArgs e) { MainScrollViewer.ChangeView(null, null, MainScrollViewer.ZoomFactor + 0.25f); }
        private void ZoomOut_Click(object sender, RoutedEventArgs e) { MainScrollViewer.ChangeView(null, null, Math.Max(0.5f, MainScrollViewer.ZoomFactor - 0.25f)); }
    }
}
EOF

echo "✅ Native WinUI 3 Codebase Successfully Generated!"
