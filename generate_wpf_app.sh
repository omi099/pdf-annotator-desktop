#!/bin/bash
set -e

echo "🚀 Bootstrapping the Ultimate Chromium-Backed Annotator..."

# 1. Clean environment to ensure a fresh build
rm -rf TeachingAnnotator

# 2. Let .NET create the project AND the folder automatically
dotnet new wpf -n TeachingAnnotator -f net8.0 --force

# 3. Move into the newly created folder
cd TeachingAnnotator

# 4. Install the Microsoft WebView2 Engine (The magic ingredient for perfect PDFs)
dotnet add package Microsoft.Web.WebView2 --version 1.0.2420.47

# 5. Overwrite .csproj
cat << 'EOF' > TeachingAnnotator.csproj
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net8.0-windows</TargetFramework>
    <Nullable>enable</Nullable>
    <UseWPF>true</UseWPF>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Microsoft.Web.WebView2" Version="1.0.2420.47" />
  </ItemGroup>
</Project>
EOF

# 6. Overwrite MainWindow.xaml
cat << 'EOF' > MainWindow.xaml
<Window x:Class="TeachingAnnotator.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:wv2="clr-namespace:Microsoft.Web.WebView2.Wpf;assembly=Microsoft.Web.WebView2.Wpf"
        Title="Apex Annotator (Chromium Engine)" Height="900" Width="1400"
        Background="#0f1115" WindowStartupLocation="CenterScreen">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        
        <ToolBar Grid.Row="0" Background="#1a1c23" Foreground="White" Padding="15,10">
            <Button Content="📂 Open PDF" Click="OpenPdf_Click" Foreground="White" Background="#3a3f4b" Margin="0,0,10,0" Padding="12,6" FontWeight="Bold" BorderThickness="0"/>
            <TextBlock Text="💡 Use the built-in PDF toolbar below to Draw, Highlight, Select Text, Search, and Save." Foreground="#00ffcc" VerticalAlignment="Center" Margin="20,0,0,0" FontWeight="Bold"/>
        </ToolBar>

        <wv2:WebView2 Grid.Row="1" x:Name="PdfWebViewer" />
    </Grid>
</Window>
EOF

# 7. Overwrite MainWindow.xaml.cs 
cat << 'EOF' > MainWindow.xaml.cs
using System;
using System.IO;
using System.Windows;
using Microsoft.Win32;

namespace TeachingAnnotator
{
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
            InitializeAsync();
        }

        async void InitializeAsync()
        {
            // Initialize the WebView2 environment
            await PdfWebViewer.EnsureCoreWebView2Async(null);
            
            // Set a dark theme default background
            PdfWebViewer.DefaultBackgroundColor = System.Drawing.Color.FromArgb(255, 15, 17, 21);
        }

        private void OpenPdf_Click(object sender, RoutedEventArgs e)
        {
            OpenFileDialog dlg = new OpenFileDialog { Filter = "PDF Files (*.pdf)|*.pdf" };
            if (dlg.ShowDialog() == true)
            {
                // The Chromium engine requires a proper URI to load local files safely
                string fileUri = new Uri(dlg.FileName).AbsoluteUri;
                
                // Add #toolbar=1 to ensure the PDF drawing tools are visible immediately
                PdfWebViewer.CoreWebView2.Navigate(fileUri + "#toolbar=1");
            }
        }
    }
}
EOF

echo "✅ Chromium WebView2 App Generated!"
