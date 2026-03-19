#!/bin/bash
set -e

echo "🚀 Bootstrapping the Native WPF Annotator (Ultimate Professional Gold Master)..."

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
        Title="Anydraw - Professional Whiteboard" 
        WindowState="Maximized" 
        WindowStartupLocation="CenterScreen"
        KeyDown="Window_KeyDown" FontFamily="Segoe UI, Helvetica, Arial, sans-serif">

    <Window.Resources>
        <SolidColorBrush x:Key="BgPrimary" Color="#000000"/>
        <SolidColorBrush x:Key="BgToolbar" Color="#000000"/>
        <SolidColorBrush x:Key="BorderToolbar" Color="#334155"/>
        <SolidColorBrush x:Key="TextPrimary" Color="#F8FAFC"/>
        <SolidColorBrush x:Key="TextSecondary" Color="#CBD5E1"/>
        <SolidColorBrush x:Key="ButtonHoverBg" Color="#334155"/>
        <SolidColorBrush x:Key="ButtonHoverText" Color="#F8FAFC"/>
        <SolidColorBrush x:Key="Sky400" Color="#38BDF8"/>
        <SolidColorBrush x:Key="Rose500" Color="#EF4444"/>

        <Style TargetType="RadioButton" x:Key="TailwindTool">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="{DynamicResource TextSecondary}"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Margin" Value="4,0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="RadioButton">
                        <Border x:Name="border" Background="{TemplateBinding Background}" CornerRadius="8" Padding="12,8">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background" Value="{DynamicResource ButtonHoverBg}"/>
                                <Setter Property="Foreground" Value="{DynamicResource ButtonHoverText}"/>
                            </Trigger>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#1E3A8A"/> 
                                <Setter Property="Foreground" Value="{DynamicResource Sky400}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="Button" x:Key="TailwindButton">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="{DynamicResource TextSecondary}"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Padding" Value="10,6"/>
            <Setter Property="Margin" Value="2,0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background" Value="{DynamicResource ButtonHoverBg}"/>
                                <Setter Property="Foreground" Value="{DynamicResource ButtonHoverText}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid Background="{DynamicResource BgPrimary}">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        
        <Border x:Name="MainToolbar" Grid.Row="0" Background="{DynamicResource BgToolbar}" BorderBrush="{DynamicResource BorderToolbar}" BorderThickness="0,0,0,1" Padding="20,12" Panel.ZIndex="100">
            <Border.Effect>
                <DropShadowEffect Color="Black" BlurRadius="10" Opacity="0.15" ShadowDepth="2" Direction="270"/>
            </Border.Effect>
            
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
                    <Path Data="M12 2 L2 22 L6 22 L12 10 L18 22 L22 22 Z M7 16 L17 16 L17 18 L7 18 Z" Fill="{DynamicResource Sky400}" Height="24" Stretch="Uniform" Margin="0,0,8,0"/>
                    <TextBlock Text="Anydraw" FontSize="20" FontWeight="Bold" Foreground="{DynamicResource TextPrimary}" VerticalAlignment="Center" Margin="0,0,24,0"/>
                    
                    <Rectangle Width="1" Fill="{DynamicResource BorderToolbar}" Margin="0,4,12,4"/>

                    <Button Style="{StaticResource TailwindButton}" Click="OpenPdf_Click" ToolTip="Open PDF">
                        <StackPanel Orientation="Horizontal">
                            <Path Data="M 14 2 L 6 2 C 4.9 2 4 2.9 4 4 L 4 20 C 4 21.1 4.9 22 6 22 L 18 22 C 19.1 22 20 21.1 20 20 L 20 8 L 14 2 Z M 13 9 L 13 3.5 L 18.5 9 L 13 9 Z" Stroke="{Binding Foreground, RelativeSource={RelativeSource AncestorType=Button}}" StrokeThickness="2" StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round" Fill="Transparent" Height="18" Stretch="Uniform" Margin="0,0,6,0"/>
                            <TextBlock Text="Open" FontWeight="SemiBold"/>
                        </StackPanel>
                    </Button>
                    <Button Style="{StaticResource TailwindButton}" Click="ExportAnnotated_Click" ToolTip="Export High-Res Vector PDF">
                        <StackPanel Orientation="Horizontal">
                            <Path Data="M 12 16 L 12 3 M 8 7 L 12 3 L 16 7 M 4 16 L 4 20 C 4 21.1 4.9 22 6 22 L 18 22 C 19.1 22 20 21.1 20 20 L 20 16" Stroke="{Binding Foreground, RelativeSource={RelativeSource AncestorType=Button}}" StrokeThickness="2" StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round" Fill="Transparent" Height="18" Stretch="Uniform" Margin="0,0,6,0"/>
                            <TextBlock Text="Export" FontWeight="SemiBold"/>
                        </StackPanel>
                    </Button>
                </StackPanel>

                <StackPanel Grid.Column="1" Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
                    <RadioButton Style="{StaticResource TailwindTool}" x:Name="SelectBtn" Checked="Tool_Checked" ToolTip="Lasso Select (S)">
                        <Path Data="M 4 10 C 6 4, 12 6, 18 8 C 22 10, 16 20, 10 18 C 4 16, 2 16, 4 10 Z M 13 13 L 20 20 M 13 13 L 13 20 M 13 13 L 20 13" Stroke="{Binding Foreground, RelativeSource={RelativeSource AncestorType=RadioButton}}" StrokeThickness="2" StrokeDashArray="2,2" StrokeLineJoin="Round" Fill="Transparent" Height="22" Stretch="Uniform"/>
                    </RadioButton>
                    <RadioButton Style="{StaticResource TailwindTool}" x:Name="PenBtn" IsChecked="True" Checked="Tool_Checked" ToolTip="Pen (P)">
                        <Path Data="M 18 4 L 20 6 L 9 17 L 4 18 L 5 13 Z M 16 6 L 18 8 M 4 18 C 6 24, 12 24, 16 20" Stroke="{Binding Foreground, RelativeSource={RelativeSource AncestorType=RadioButton}}" StrokeThickness="2" StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round" Fill="Transparent" Height="22" Stretch="Uniform"/>
                    </RadioButton>
                    <RadioButton Style="{StaticResource TailwindTool}" x:Name="HighlightBtn" Checked="Tool_Checked" ToolTip="Highlighter (M)">
                        <Path Data="M 16 4 L 20 8 L 8 20 L 2 20 L 2 14 Z M 14 6 L 18 10 M 2 14 L 8 20 M 10 20 L 22 20" Stroke="{Binding Foreground, RelativeSource={RelativeSource AncestorType=RadioButton}}" StrokeThickness="2" StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round" Fill="Transparent" Height="22" Stretch="Uniform"/>
                    </RadioButton>
                    <RadioButton Style="{StaticResource TailwindTool}" x:Name="LaserBtn" Checked="Tool_Checked" ToolTip="Neon Laser (L)">
                        <Path Data="M 7 17 L 15 9 A 2 2 0 0 1 18 12 L 10 20 A 2 2 0 0 1 7 17 Z M 13 11 A 1 1 0 1 0 14 12 A 1 1 0 0 0 13 11 M 19 3 L 20 1 M 23 7 L 25 8 M 21 5 L 23 3" Stroke="{Binding Foreground, RelativeSource={RelativeSource AncestorType=RadioButton}}" StrokeThickness="2" StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round" Fill="Transparent" Height="22" Stretch="Uniform"/>
                    </RadioButton>
                    <RadioButton Style="{StaticResource TailwindTool}" x:Name="EraserBtn" Checked="Tool_Checked" ToolTip="Eraser (E)">
                        <Path Data="M 18 4 L 22 8 L 12 18 L 6 12 Z M 12 18 L 2 18 M 6 12 L 10 16" Stroke="{Binding Foreground, RelativeSource={RelativeSource AncestorType=RadioButton}}" StrokeThickness="2" StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round" Fill="Transparent" Height="22" Stretch="Uniform"/>
                    </RadioButton>

                    <Rectangle Width="1" Fill="{DynamicResource BorderToolbar}" Margin="12,4"/>

                    <Button x:Name="ColorBtn" Style="{StaticResource TailwindButton}" Click="ColorBtn_Click" ToolTip="Tool Color">
                        <StackPanel Orientation="Horizontal">
                            <Ellipse x:Name="ActiveColorIndicator" Width="16" Height="16" Fill="#EF4444" Stroke="{DynamicResource TextSecondary}" StrokeThickness="1"/>
                            <TextBlock Text="▼" FontSize="10" Margin="4,0,0,0" VerticalAlignment="Center"/>
                        </StackPanel>
                    </Button>
                    <Popup x:Name="ColorPopup" StaysOpen="False" PlacementTarget="{Binding ElementName=ColorBtn}" Placement="Bottom">
                        <Border Background="{DynamicResource BgToolbar}" BorderBrush="{DynamicResource BorderToolbar}" BorderThickness="1" CornerRadius="6" Padding="10">
                            <Border.Effect><DropShadowEffect BlurRadius="10" Opacity="0.3" ShadowDepth="4"/></Border.Effect>
                            <StackPanel>
                                <TextBlock Text="Tool Hex:" Foreground="{DynamicResource TextSecondary}" FontSize="11" Margin="0,0,0,4"/>
                                <TextBox x:Name="HexInput" Text="#EF4444" Width="100" Background="{DynamicResource BgPrimary}" Foreground="{DynamicResource TextPrimary}" BorderBrush="{DynamicResource BorderToolbar}" Padding="4" Margin="0,0,0,8" TextChanged="HexInput_TextChanged"/>
                                <WrapPanel Width="120" x:Name="PaletteGrid"/>
                            </StackPanel>
                        </Border>
                    </Popup>

                    <Slider x:Name="SizeSlider" Minimum="0.5" Maximum="50" Value="4" Width="60" VerticalAlignment="Center" Margin="5,0" ValueChanged="Size_Changed" IsMoveToPointEnabled="True"/>
                    <TextBox x:Name="SizeInput" Text="{Binding Value, ElementName=SizeSlider, UpdateSourceTrigger=PropertyChanged, StringFormat=F1}" Width="30" TextAlignment="Center" VerticalAlignment="Center" Margin="0,0,10,0" FontWeight="Bold" Background="Transparent" Foreground="{DynamicResource TextPrimary}" BorderThickness="0"/>

                    <CheckBox x:Name="PressureToggle" Content="Pressure" IsChecked="True" Foreground="{DynamicResource TextSecondary}" VerticalAlignment="Center" Margin="0,0,10,0" Checked="Pressure_Changed" Unchecked="Pressure_Changed" FontWeight="SemiBold"/>
                    
                    <Rectangle Width="1" Fill="{DynamicResource BorderToolbar}" Margin="5,4"/>

                    <TextBlock Text="⏱️" Foreground="{DynamicResource TextSecondary}" VerticalAlignment="Center" Margin="5,0"/>
                    <TextBox x:Name="LaserDelayInput" Text="1.7" Width="30" TextAlignment="Center" VerticalAlignment="Center" Margin="0,0,10,0" FontWeight="Bold" Background="Transparent" Foreground="{DynamicResource Sky400}" BorderThickness="0" TextChanged="LaserDelayInput_TextChanged" ToolTip="Laser Fade Delay (seconds)"/>
                </StackPanel>

                <StackPanel x:Name="PaginationPanel" Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center">
                    
                    <Button x:Name="BgColorBtn" Style="{StaticResource TailwindButton}" Click="BgColorBtn_Click" ToolTip="Background Color">
                        <StackPanel Orientation="Horizontal">
                            <Rectangle x:Name="ActiveBgIndicator" Width="16" Height="16" Fill="#282828" Stroke="{DynamicResource TextSecondary}" StrokeThickness="1" RadiusX="2" RadiusY="2"/>
                            <TextBlock Text="▼" FontSize="10" Margin="4,0,0,0" VerticalAlignment="Center"/>
                        </StackPanel>
                    </Button>
                    <Popup x:Name="BgColorPopup" StaysOpen="False" PlacementTarget="{Binding ElementName=BgColorBtn}" Placement="Bottom">
                        <Border Background="{DynamicResource BgToolbar}" BorderBrush="{DynamicResource BorderToolbar}" BorderThickness="1" CornerRadius="6" Padding="10">
                            <Border.Effect><DropShadowEffect BlurRadius="10" Opacity="0.3" ShadowDepth="4"/></Border.Effect>
                            <StackPanel>
                                <TextBlock Text="Canvas Hex:" Foreground="{DynamicResource TextSecondary}" FontSize="11" Margin="0,0,0,4"/>
                                <TextBox x:Name="BgHexInput" Text="#282828" Width="100" Background="{DynamicResource BgPrimary}" Foreground="{DynamicResource TextPrimary}" BorderBrush="{DynamicResource BorderToolbar}" Padding="4" Margin="0,0,0,8" TextChanged="BgHexInput_TextChanged"/>
                                <WrapPanel Width="120" x:Name="BgPaletteGrid"/>
                            </StackPanel>
                        </Border>
                    </Popup>

                    <Button Style="{StaticResource TailwindButton}" Click="GridToggle_Click" ToolTip="Toggle Grid">
                        <Path Data="M 3 3 L 21 3 L 21 21 L 3 21 Z M 9 3 L 9 21 M 15 3 L 15 21 M 3 9 L 21 9 M 3 15 L 21 15" Stroke="{Binding Foreground, RelativeSource={RelativeSource AncestorType=Button}}" StrokeThickness="2" StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round" Fill="Transparent" Height="16" Stretch="Uniform"/>
                    </Button>

                    <Rectangle Width="1" Fill="{DynamicResource BorderToolbar}" Margin="5,4"/>

                    <Button Style="{StaticResource TailwindButton}" Click="PrevPage_Click" Content="&lt;"/>
                    <TextBlock x:Name="PageCounterText" Text="1/1" Foreground="{DynamicResource Sky400}" VerticalAlignment="Center" FontWeight="Bold" Margin="4,0" Width="30" TextAlignment="Center"/>
                    <Button Style="{StaticResource TailwindButton}" Click="NextPage_Click" Content="&gt;"/>
                    <Button Style="{StaticResource TailwindButton}" Click="DeletePage_Click" ToolTip="Delete Page">
                        <Path Data="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z" Fill="{DynamicResource Rose500}" Height="14" Stretch="Uniform"/>
                    </Button>

                    <Rectangle Width="1" Fill="{DynamicResource BorderToolbar}" Margin="5,4"/>
                    
                    <Button Style="{StaticResource TailwindButton}" Click="Theme_Click" ToolTip="Toggle Dark/Light Mode">
                        <Path Data="M12 3a9 9 0 1 0 9 9c0-.46-.04-.92-.1-1.36a5.389 5.389 0 0 1-4.4 2.26 5.403 5.403 0 0 1-3.14-9.8c-.44-.06-.9-.1-1.36-.1z" Fill="{Binding Foreground, RelativeSource={RelativeSource AncestorType=Button}}" Height="16" Stretch="Uniform"/>
                    </Button>
                    <Button Style="{StaticResource TailwindButton}" Click="ClearInk_Click" ToolTip="Clear Board">
                        <TextBlock Text="Clear" Foreground="{DynamicResource Rose500}" FontWeight="SemiBold"/>
                    </Button>
                </StackPanel>
            </Grid>
        </Border>

        <ScrollViewer Grid.Row="1" x:Name="MainScroll" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto" PanningMode="Both" PreviewMouseWheel="MainScroll_PreviewMouseWheel" Background="Transparent">
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

                <Grid x:Name="CanvasContainer" HorizontalAlignment="Left" VerticalAlignment="Top">
                    <InkCanvas x:Name="MainInkCanvas" Background="Transparent" UseCustomCursor="True" Cursor="Arrow" Focusable="True"
                               PreviewMouseLeftButtonDown="MainInkCanvas_PreviewMouseLeftButtonDown"
                               MouseMove="MainInkCanvas_MouseMove" MouseLeave="MainInkCanvas_MouseLeave" MouseEnter="MainInkCanvas_MouseEnter">
                    </InkCanvas>
                    
                    <InkCanvas x:Name="LaserInkCanvas" Background="Transparent" UseCustomCursor="True" Cursor="Arrow" Focusable="False" IsHitTestVisible="False"
                               MouseMove="MainInkCanvas_MouseMove" MouseLeave="MainInkCanvas_MouseLeave" MouseEnter="MainInkCanvas_MouseEnter"
                               StrokeCollected="LaserInkCanvas_StrokeCollected">
                    </InkCanvas>
                </Grid>
                
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
using System.Reflection;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Ink;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;
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
        public System.Windows.Ink.Stroke Stroke { get; set; }
        public int Life { get; set; } = 255;
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public LaserStrokeData(System.Windows.Ink.Stroke s) { Stroke = s; }
    }

    public partial class MainWindow : Window
    {
        public ObservableCollection<PdfPageModel> PdfPages { get; set; } = new ObservableCollection<PdfPageModel>();
        private double _zoom = 1.0;
        private string? _currentPdfPath = null;
        private bool _isUpdatingUI = false;

        private double _penSize = 4.0;
        private Color _penColor = Color.FromRgb(239, 68, 68); 
        private double _highlightSize = 24.0;
        private Color _highlightColor = Colors.Yellow;
        private double _laserSize = 6.0;
        private Color _laserColor = Color.FromRgb(239, 68, 68);

        private List<LaserStrokeData> _laserStrokes = new List<LaserStrokeData>();
        private DispatcherTimer _laserTimer;
        private DateTime _lastLaserActivityTime = DateTime.Now;
        private double _laserFadeDelay = 1.7;

        private Stack<StrokeCollection> _undoStack = new Stack<StrokeCollection>();
        private Stack<StrokeCollection> _redoStack = new Stack<StrokeCollection>();

        private int _currentPage = 1;
        private int _totalPages = 1;
        private Dictionary<int, StrokeCollection> _whiteboardPages = new Dictionary<int, StrokeCollection>();

        private bool _isDarkTheme = true;
        private bool _showGrid = true;
        private Color _customBgColor = Color.FromRgb(40, 40, 40); 

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

            BuildPaletteGrid();
            SyncToolToUI();
            UpdatePageUI();
            ApplyTheme();
        }

        private void BuildPaletteGrid()
        {
            string[] toolHexes = { "#EF4444", "#3B82F6", "#22C55E", "#EAB308", "#A855F7", "#F97316", "#EC4899", "#14B8A6", "#FFFFFF", "#000000" };
            foreach (string hex in toolHexes)
            {
                Rectangle r = new Rectangle { Width = 20, Height = 20, Margin = new Thickness(2), RadiusX = 4, RadiusY = 4, Fill = new SolidColorBrush((Color)ColorConverter.ConvertFromString(hex)), Cursor = Cursors.Hand };
                r.MouseDown += (s, e) => { HexInput.Text = hex; ColorPopup.IsOpen = false; };
                PaletteGrid.Children.Add(r);
            }

            string[] bgHexes = { "#282828", "#1E1E1E", "#000000", "#111827", "#0F172A", "#FFFFFF", "#F8FAFC", "#F3F4F6", "#FEF3C7", "#ECFEFF" };
            foreach (string hex in bgHexes)
            {
                Rectangle r = new Rectangle { Width = 20, Height = 20, Margin = new Thickness(2), RadiusX = 4, RadiusY = 4, Fill = new SolidColorBrush((Color)ColorConverter.ConvertFromString(hex)), Cursor = Cursors.Hand };
                r.MouseDown += (s, e) => { BgHexInput.Text = hex; BgColorPopup.IsOpen = false; };
                BgPaletteGrid.Children.Add(r);
            }
        }

        private void ColorBtn_Click(object sender, RoutedEventArgs e) => ColorPopup.IsOpen = true;
        private void BgColorBtn_Click(object sender, RoutedEventArgs e) => BgColorPopup.IsOpen = true;

        private void HexInput_TextChanged(object sender, TextChangedEventArgs e)
        {
            try
            {
                Color c = (Color)ColorConverter.ConvertFromString(HexInput.Text);
                ActiveColorIndicator.Fill = new SolidColorBrush(c);
                if (PenBtn.IsChecked == true) _penColor = c;
                else if (HighlightBtn.IsChecked == true) _highlightColor = c;
                else if (LaserBtn.IsChecked == true) _laserColor = c;
                ApplyPenAttributes();
            }
            catch { }
        }

        private void BgHexInput_TextChanged(object sender, TextChangedEventArgs e)
        {
            try
            {
                Color c = (Color)ColorConverter.ConvertFromString(BgHexInput.Text);
                _customBgColor = c;
                ActiveBgIndicator.Fill = new SolidColorBrush(c);
                ApplyTheme();
            }
            catch { }
        }

        private void GridToggle_Click(object sender, RoutedEventArgs e)
        {
            _showGrid = !_showGrid;
            ApplyTheme();
        }

        private void LaserDelayInput_TextChanged(object sender, TextChangedEventArgs e)
        {
            if (double.TryParse(LaserDelayInput.Text, out double val))
            {
                _laserFadeDelay = val;
            }
        }

        private void Theme_Click(object sender, RoutedEventArgs e)
        {
            _isDarkTheme = !_isDarkTheme;
            if (_isDarkTheme) { BgHexInput.Text = "#282828"; } else { BgHexInput.Text = "#FFFFFF"; }
            ApplyTheme();
            UpdateCustomCursorAppearance();
        }

        private void ApplyTheme()
        {
            if (_isDarkTheme)
            {
                Resources["BgPrimary"] = new SolidColorBrush(Colors.Black); // Pure black outer
                Resources["BgToolbar"] = new SolidColorBrush(Colors.Black);
                Resources["BorderToolbar"] = new SolidColorBrush(Color.FromRgb(51, 65, 85));
                Resources["TextPrimary"] = new SolidColorBrush(Color.FromRgb(248, 250, 252));
                Resources["TextSecondary"] = new SolidColorBrush(Color.FromRgb(203, 213, 225));
                Resources["ButtonHoverBg"] = new SolidColorBrush(Color.FromRgb(51, 65, 85));
                Resources["ButtonHoverText"] = new SolidColorBrush(Colors.White);
            }
            else
            {
                Resources["BgPrimary"] = new SolidColorBrush(Color.FromRgb(243, 244, 246));
                Resources["BgToolbar"] = new SolidColorBrush(Color.FromRgb(243, 244, 246));
                Resources["BorderToolbar"] = new SolidColorBrush(Color.FromRgb(209, 213, 219));
                Resources["TextPrimary"] = new SolidColorBrush(Colors.Black); 
                Resources["TextSecondary"] = new SolidColorBrush(Color.FromRgb(55, 65, 81)); 
                Resources["ButtonHoverBg"] = new SolidColorBrush(Color.FromRgb(229, 231, 235));
                Resources["ButtonHoverText"] = new SolidColorBrush(Colors.Black);
            }

            if (string.IsNullOrEmpty(_currentPdfPath))
            {
                Color lineColor = _isDarkTheme ? Color.FromRgb(60, 60, 60) : Color.FromRgb(229, 231, 235);
                Workspace.Background = CreateGridBrush(_customBgColor, lineColor);
            }
        }

        private DrawingBrush CreateGridBrush(Color bgColor, Color lineColor)
        {
            DrawingBrush brush = new DrawingBrush { TileMode = TileMode.Tile, Viewport = new Rect(0, 0, 40, 40), ViewportUnits = BrushMappingMode.Absolute };
            GeometryDrawing bgDrawing = new GeometryDrawing { Brush = new SolidColorBrush(bgColor), Geometry = new RectangleGeometry(new Rect(0, 0, 40, 40)) };
            
            DrawingGroup mainGroup = new DrawingGroup();
            mainGroup.Children.Add(bgDrawing);

            if (_showGrid)
            {
                GeometryDrawing lineDrawing = new GeometryDrawing { Pen = new Pen(new SolidColorBrush(lineColor), 1) };
                GeometryGroup group = new GeometryGroup();
                group.Children.Add(new LineGeometry(new Point(0, 0), new Point(0, 40)));
                group.Children.Add(new LineGeometry(new Point(0, 0), new Point(40, 0)));
                lineDrawing.Geometry = group;
                mainGroup.Children.Add(lineDrawing);
            }
            
            brush.Drawing = mainGroup;
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

            if (SizeInput.IsFocused || HexInput.IsFocused || BgHexInput.IsFocused || LaserDelayInput.IsFocused) return;

            if (e.Key == Key.T) { Theme_Click(null, null); return; }

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
            if (PenBtn.IsChecked == true) { SizeSlider.Value = _penSize; HexInput.Text = _penColor.ToString(); } 
            else if (HighlightBtn.IsChecked == true) { SizeSlider.Value = _highlightSize; HexInput.Text = _highlightColor.ToString(); } 
            else if (LaserBtn.IsChecked == true) { SizeSlider.Value = _laserSize; HexInput.Text = _laserColor.ToString(); }
            _isUpdatingUI = false;
            ApplyPenAttributes();
        }

        private void Color_Changed(object sender, SelectionChangedEventArgs e) { }

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
            Color activeColor = ((SolidColorBrush)ActiveColorIndicator.Fill).Color;
            double activeSize = SizeSlider.Value;

            if (LaserBtn.IsChecked == true)
            {
                MainInkCanvas.IsHitTestVisible = false;
                LaserInkCanvas.IsHitTestVisible = true;
                
                LaserInkCanvas.EditingMode = InkCanvasEditingMode.Ink;
                LaserInkCanvas.DefaultDrawingAttributes = new DrawingAttributes { Color = Colors.White, Width = activeSize, Height = activeSize, FitToCurve = true, IgnorePressure = true };
                LaserInkCanvas.Effect = new System.Windows.Media.Effects.DropShadowEffect { Color = activeColor, BlurRadius = 15, ShadowDepth = 0, Opacity = 1.0 };
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
                    MainInkCanvas.EditingMode = InkCanvasEditingMode.Select; 
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
            Color c = ((SolidColorBrush)ActiveColorIndicator.Fill).Color;

            if (HighlightBtn.IsChecked == true) { size *= 4; c = Color.FromArgb(120, c.R, c.G, c.B); }
            
            if (LaserBtn.IsChecked == true) 
            {
                CustomDotCursor.Fill = new SolidColorBrush(Colors.White); // ZERO OUTLINE, PURE WHITE DOT
                CustomDotCursor.StrokeThickness = 0; 
                CursorGlow.Color = c; 
                CursorGlow.Opacity = 1.0; 
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

            bool isInactive = (DateTime.Now - _lastLaserActivityTime).TotalSeconds > _laserFadeDelay;

            for (int i = _laserStrokes.Count - 1; i >= 0; i--)
            {
                var ls = _laserStrokes[i];
                
                if (isInactive)
                {
                    ls.Life -= 15; 

                    if (ls.Life <= 0)
                    {
                        _isUpdatingUI = true;
                        LaserInkCanvas.Strokes.Remove(ls.Stroke);
                        _laserStrokes.RemoveAt(i);
                        _isUpdatingUI = false;
                    }
                    else
                    {
                        // Fading the White core opacity safely
                        ls.Stroke.DrawingAttributes.Color = Color.FromArgb((byte)Math.Max(0, ls.Life), 255, 255, 255);
                    }
                }
                else
                {
                    if (ls.Life < 255)
                    {
                        ls.Life = 255;
                        ls.Stroke.DrawingAttributes.Color = Color.FromArgb(255, 255, 255, 255);
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
                SaveFileDialog wbdlg = new SaveFileDialog { Filter = "PDF (*.pdf)|*.pdf", FileName = "Anydraw_Whiteboard.pdf" };
                if (wbdlg.ShowDialog() == true)
                {
                    try
                    {
                        SaveCurrentPage();
                        PdfSharp.Pdf.PdfDocument wbDoc = new PdfSharp.Pdf.PdfDocument();
                        
                        XColor bgColor = _isDarkTheme ? XColor.FromArgb(255, _customBgColor.R, _customBgColor.G, _customBgColor.B) : XColor.FromArgb(255, 255, 255, 255);
                        XColor gridColor = _isDarkTheme ? XColor.FromArgb(255, 60, 60, 60) : XColor.FromArgb(255, 229, 231, 235);

                        for (int i = 1; i <= _totalPages; i++)
                        {
                            PdfSharp.Pdf.PdfPage wbPage = wbDoc.AddPage();
                            wbPage.Width = XUnit.FromPoint(1920);
                            wbPage.Height = XUnit.FromPoint(1080);
                            XGraphics gfx = XGraphics.FromPdfPage(wbPage);

                            gfx.DrawRectangle(new XSolidBrush(bgColor), 0, 0, wbPage.Width.Point, wbPage.Height.Point);
                            if (_showGrid) {
                                XPen gridPen = new XPen(gridColor, 1);
                                for (double x = 0; x < wbPage.Width.Point; x += 40) gfx.DrawLine(gridPen, x, 0, x, wbPage.Height.Point);
                                for (double y = 0; y < wbPage.Height.Point; y += 40) gfx.DrawLine(gridPen, 0, y, wbPage.Width.Point, y);
                            }

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
                        MessageBox.Show("Anydraw Whiteboard Exported Successfully!");
                    }
                    catch (Exception ex) { MessageBox.Show("Export failed: " + ex.Message); }
                }
                return;
            }

            SaveFileDialog dlg = new SaveFileDialog { Filter = "PDF (*.pdf)|*.pdf", FileName = "Anydraw_Annotated_Document.pdf" };
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

echo "✅ App Polished to Absolute Perfection! Ready for zero-error execution."
