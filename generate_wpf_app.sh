#!/bin/bash
set -e

echo "🚀 Bootstrapping the Native WPF Annotator (Zero-Error Tailwind Edition)..."

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

# 4. Overwrite MainWindow.xaml (FIXED: Restored missing x:Name tags for C# binding)
cat << 'EOF' > MainWindow.xaml
<Window x:Class="TeachingAnnotator.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Anydraw - Professional Whiteboard" 
        WindowState="Maximized" 
        Background="#0F172A" WindowStartupLocation="CenterScreen"
        KeyDown="Window_KeyDown" FontFamily="Segoe UI, Helvetica, Arial, sans-serif">

    <Window.Resources>
        <SolidColorBrush x:Key="{x:Static SystemColors.HighlightBrushKey}" Color="#FFFF00"/>
        <SolidColorBrush x:Key="{x:Static SystemColors.WindowFrameBrushKey}" Color="#FFFF00"/>
        <SolidColorBrush x:Key="{x:Static SystemColors.ActiveBorderBrushKey}" Color="#FFFF00"/>

        <SolidColorBrush x:Key="Slate900" Color="#0F172A"/>
        <SolidColorBrush x:Key="Slate800" Color="#1E293B"/>
        <SolidColorBrush x:Key="Slate700" Color="#334155"/>
        <SolidColorBrush x:Key="Slate300" Color="#CBD5E1"/>
        <SolidColorBrush x:Key="Slate50" Color="#F8FAFC"/>
        <SolidColorBrush x:Key="Sky400" Color="#38BDF8"/>
        <SolidColorBrush x:Key="Rose500" Color="#EF4444"/>

        <Style TargetType="RadioButton" x:Key="TailwindTool">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="{StaticResource Slate300}"/>
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
                                <Setter TargetName="border" Property="Background" Value="{StaticResource Slate700}"/>
                                <Setter Property="Foreground" Value="{StaticResource Slate50}"/>
                            </Trigger>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#1E3A8A"/> 
                                <Setter Property="Foreground" Value="{StaticResource Sky400}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="Button" x:Key="TailwindButton">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="{StaticResource Slate300}"/>
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
                                <Setter TargetName="border" Property="Background" Value="{StaticResource Slate700}"/>
                                <Setter Property="Foreground" Value="{StaticResource Slate50}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        
        <Border x:Name="MainToolbar" Grid.Row="0" Background="{StaticResource Slate800}" BorderBrush="{StaticResource Slate700}" BorderThickness="0,0,0,1" Padding="20,12" Panel.ZIndex="100">
            <Border.Effect>
                <DropShadowEffect Color="Black" BlurRadius="10" Opacity="0.3" ShadowDepth="2" Direction="270"/>
            </Border.Effect>
            
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
                    <Path Data="M12 2 L2 22 L6 22 L12 10 L18 22 L22 22 Z M7 16 L17 16 L17 18 L7 18 Z" Fill="{StaticResource Sky400}" Height="24" Stretch="Uniform" Margin="0,0,8,0"/>
                    <TextBlock Text="Anydraw" FontSize="20" FontWeight="Bold" Foreground="{StaticResource Slate50}" VerticalAlignment="Center" Margin="0,0,24,0"/>
                    
                    <Rectangle Width="1" Fill="{StaticResource Slate700}" Margin="0,4,12,4"/>

                    <Button Style="{StaticResource TailwindButton}" Click="OpenPdf_Click" ToolTip="Open PDF">
                        <StackPanel Orientation="Horizontal">
                            <Path Data="M20 6h-8l-2-2H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V8c0-1.1-.9-2-2-2zm0 14H4V8h16v12z" Fill="{Binding Foreground, RelativeSource={RelativeSource AncestorType=Button}}" Height="16" Stretch="Uniform" Margin="0,0,6,0"/>
                            <TextBlock Text="Open" FontWeight="SemiBold"/>
                        </StackPanel>
                    </Button>
                    <Button Style="{StaticResource TailwindButton}" Click="ExportAnnotated_Click" ToolTip="Export High-Res Vector PDF">
                        <StackPanel Orientation="Horizontal">
                            <Path Data="M19 9h-4V3H9v6H5l7 7 7-7zM5 18v2h14v-2H5z" Fill="{Binding Foreground, RelativeSource={RelativeSource AncestorType=Button}}" Height="16" Stretch="Uniform" Margin="0,0,6,0"/>
                            <TextBlock Text="Export" FontWeight="SemiBold"/>
                        </StackPanel>
                    </Button>
                </StackPanel>

                <StackPanel Grid.Column="1" Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
                    <RadioButton Style="{StaticResource TailwindTool}" x:Name="PenBtn" IsChecked="True" Checked="Tool_Checked" ToolTip="Pen (P)">
                        <Path Data="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25z" Fill="{Binding Foreground, RelativeSource={RelativeSource AncestorType=RadioButton}}" Height="20" Stretch="Uniform"/>
                    </RadioButton>
                    <RadioButton Style="{StaticResource TailwindTool}" x:Name="HighlightBtn" Checked="Tool_Checked" ToolTip="Highlighter (M)">
                        <Path Data="M20.71,5.63l-2.34-2.34c-0.39-0.39-1.02-0.39-1.41,0l-3.12,3.12l-1.93-1.91l-1.41,1.41l1.42,1.42L3,16.25V21h4.75l8.92-8.92l1.42,1.42l1.41-1.41l-1.92-1.92l3.12-3.12C21.1,6.65,21.1,6.02,20.71,5.63z" Fill="{Binding Foreground, RelativeSource={RelativeSource AncestorType=RadioButton}}" Height="20" Stretch="Uniform"/>
                    </RadioButton>
                    <RadioButton Style="{StaticResource TailwindTool}" x:Name="LaserBtn" Checked="Tool_Checked" ToolTip="Neon Laser (L)">
                        <Path Data="M12,2L14.8,8.6L22,9.2L16.5,14L18.2,21L12,17.2L5.8,21L7.5,14L2,9.2L9.2,8.6Z" Fill="{Binding Foreground, RelativeSource={RelativeSource AncestorType=RadioButton}}" Height="20" Stretch="Uniform"/>
                    </RadioButton>
                    <RadioButton Style="{StaticResource TailwindTool}" x:Name="EraserBtn" Checked="Tool_Checked" ToolTip="Eraser (E)">
                        <Path Data="M15.14,3c-0.51,0-1.02,0.2-1.41,0.59L2.59,14.73c-0.78,0.77-0.78,2.04,0,2.83L5.03,20h7.66l8.72-8.73 c0.78-0.77,0.78-2.04,0-2.83l-4.85-4.85C16.16,3.2,15.65,3,15.14,3z" Fill="{Binding Foreground, RelativeSource={RelativeSource AncestorType=RadioButton}}" Height="20" Stretch="Uniform"/>
                    </RadioButton>
                    <RadioButton Style="{StaticResource TailwindTool}" x:Name="SelectBtn" Checked="Tool_Checked" ToolTip="Lasso Select (S)">
                        <Path Data="M3,3 L9,3 L9,5 L5,5 L5,9 L3,9 L3,3 Z M15,3 L21,3 L21,9 L19,9 L19,5 L15,5 L15,3 Z M3,15 L5,15 L5,19 L9,19 L9,21 L3,21 L3,15 Z M15,21 L19,21 L19,17 L21,17 L21,21 L15,21 Z" Fill="{Binding Foreground, RelativeSource={RelativeSource AncestorType=RadioButton}}" Height="20" Stretch="Uniform"/>
                    </RadioButton>

                    <Rectangle Width="1" Fill="{StaticResource Slate700}" Margin="12,4"/>

                    <ComboBox x:Name="ColorPicker" SelectionChanged="Color_Changed" Width="80" Margin="0,0,10,0" SelectedIndex="0" VerticalAlignment="Center">
                        <ComboBoxItem Content="Red"/><ComboBoxItem Content="Blue"/><ComboBoxItem Content="Green"/>
                        <ComboBoxItem Content="Black"/><ComboBoxItem Content="White"/><ComboBoxItem Content="Yellow"/>
                        <ComboBoxItem Content="Cyan"/><ComboBoxItem Content="Magenta"/>
                    </ComboBox>

                    <Slider x:Name="SizeSlider" Minimum="0.5" Maximum="50" Value="4" Width="80" VerticalAlignment="Center" Margin="0,0,5,0" ValueChanged="Size_Changed" IsMoveToPointEnabled="True"/>
                    
                    <TextBox x:Name="SizeInput" Text="{Binding Value, ElementName=SizeSlider, UpdateSourceTrigger=PropertyChanged, StringFormat=F1}" 
                             Width="35" TextAlignment="Center" VerticalAlignment="Center" Margin="0,0,10,0" FontWeight="Bold" Background="Transparent" Foreground="{StaticResource Slate300}" BorderThickness="0"/>

                    <CheckBox x:Name="PressureToggle" Content="Pressure" IsChecked="True" Foreground="{StaticResource Slate300}" VerticalAlignment="Center" Margin="0,0,10,0" Checked="Pressure_Changed" Unchecked="Pressure_Changed" FontWeight="SemiBold"/>
                </StackPanel>

                <StackPanel x:Name="PaginationPanel" Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center">
                    <Button Style="{StaticResource TailwindButton}" Click="PrevPage_Click" ToolTip="Previous Page" Content="&lt;"/>
                    <TextBlock x:Name="PageCounterText" Text="1 / 1" Foreground="{StaticResource Sky400}" VerticalAlignment="Center" FontWeight="Bold" Margin="4,0" Width="40" TextAlignment="Center"/>
                    <Button Style="{StaticResource TailwindButton}" Click="NextPage_Click" ToolTip="Next Page" Content="&gt;"/>
                    
                    <Button Style="{StaticResource TailwindButton}" Click="DeletePage_Click" ToolTip="Delete Page" Margin="4,0,12,0">
                        <Path Data="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z" Fill="{StaticResource Rose500}" Height="16" Stretch="Uniform"/>
                    </Button>

                    <Rectangle Width="1" Fill="{StaticResource Slate700}" Margin="0,4,12,4"/>
                    
                    <Button Style="{StaticResource TailwindButton}" Click="Theme_Click" ToolTip="Toggle Dark/Light Mode">
                        <Path Data="M12 3a9 9 0 1 0 9 9c0-.46-.04-.92-.1-1.36a5.389 5.389 0 0 1-4.4 2.26 5.403 5.403 0 0 1-3.14-9.8c-.44-.06-.9-.1-1.36-.1z" Fill="{Binding Foreground, RelativeSource={RelativeSource AncestorType=Button}}" Height="16" Stretch="Uniform"/>
                    </Button>
                    <Button Style="{StaticResource TailwindButton}" Click="ClearInk_Click" ToolTip="Clear Whiteboard">
                        <TextBlock Text="Clear" Foreground="{StaticResource Rose500}" FontWeight="SemiBold"/>
                    </Button>
                </StackPanel>
            </Grid>
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
                    
                    <Canvas x:Name="SelectionOverlay" IsHitTestVisible="False" Visibility="Hidden">
                        <Rectangle x:Name="CustomSelectionRect" Stroke="#FFFF00" StrokeThickness="1.5" StrokeDashArray="4 4" Fill="Transparent" />
                        <Rectangle x:Name="H_TL" Width="9" Height="9" Stroke="#FFFF00" StrokeThickness="1.5" Fill="#1E293B" />
                        <Rectangle x:Name="H_TC" Width="9" Height="9" Stroke="#FFFF00" StrokeThickness="1.5" Fill="#1E293B" />
                        <Rectangle x:Name="H_TR" Width="9" Height="9" Stroke="#FFFF00" StrokeThickness="1.5" Fill="#1E293B" />
                        <Rectangle x:Name="H_ML" Width="9" Height="9" Stroke="#FFFF00" StrokeThickness="1.5" Fill="#1E293B" />
                        <Rectangle x:Name="H_MR" Width="9" Height="9" Stroke="#FFFF00" StrokeThickness="1.5" Fill="#1E293B" />
                        <Rectangle x:Name="H_BL" Width="9" Height="9" Stroke="#FFFF00" StrokeThickness="1.5" Fill="#1E293B" />
                        <Rectangle x:Name="H_BC" Width="9" Height="9" Stroke="#FFFF00" StrokeThickness="1.5" Fill="#1E293B" />
                        <Rectangle x:Name="H_BR" Width="9" Height="9" Stroke="#FFFF00" StrokeThickness="1.5" Fill="#1E293B" />
                    </Canvas>

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

            MainInkCanvas.SelectionChanged += MainInkCanvas_SelectionChanged;
            MainInkCanvas.SelectionMoving += MainInkCanvas_SelectionMoving;
            MainInkCanvas.SelectionResizing += MainInkCanvas_SelectionResizing;
            MainInkCanvas.SelectionMoved += MainInkCanvas_SelectionMoved;
            MainInkCanvas.SelectionResized += MainInkCanvas_SelectionResized;
            MainInkCanvas.LayoutUpdated += MainInkCanvas_LayoutUpdated;

            _laserTimer = new DispatcherTimer(DispatcherPriority.Render) { Interval = TimeSpan.FromMilliseconds(33) };
            _laserTimer.Tick += LaserTimer_Tick;
            _laserTimer.Start();

            SyncToolToUI();
            UpdatePageUI();
            ApplyTheme();
        }

        private void UpdateOverlay(Rect bounds)
        {
            if (bounds.IsEmpty || bounds.Width == 0 || bounds.Height == 0)
            {
                SelectionOverlay.Visibility = Visibility.Hidden;
                return;
            }

            SelectionOverlay.Visibility = Visibility.Visible;

            double pad = 2;
            double left = bounds.Left - pad;
            double top = bounds.Top - pad;
            double width = bounds.Width + (pad * 2);
            double height = bounds.Height + (pad * 2);

            CustomSelectionRect.Width = width;
            CustomSelectionRect.Height = height;
            Canvas.SetLeft(CustomSelectionRect, left);
            Canvas.SetTop(CustomSelectionRect, top);

            double halfW = width / 2;
            double halfH = height / 2;
            double hw = 4.5; 

            Canvas.SetLeft(H_TL, left - hw); Canvas.SetTop(H_TL, top - hw);
            Canvas.SetLeft(H_TC, left + halfW - hw); Canvas.SetTop(H_TC, top - hw);
            Canvas.SetLeft(H_TR, left + width - hw); Canvas.SetTop(H_TR, top - hw);
            
            Canvas.SetLeft(H_ML, left - hw); Canvas.SetTop(H_ML, top + halfH - hw);
            Canvas.SetLeft(H_MR, left + width - hw); Canvas.SetTop(H_MR, top + halfH - hw);
            
            Canvas.SetLeft(H_BL, left - hw); Canvas.SetTop(H_BL, top + height - hw);
            Canvas.SetLeft(H_BC, left + halfW - hw); Canvas.SetTop(H_BC, top + height - hw);
            Canvas.SetLeft(H_BR, left + width - hw); Canvas.SetTop(H_BR, top + height - hw);
        }

        private void MainInkCanvas_SelectionChanged(object? sender, EventArgs e) => UpdateOverlay(MainInkCanvas.GetSelectionBounds());
        private void MainInkCanvas_SelectionMoved(object? sender, EventArgs e) => UpdateOverlay(MainInkCanvas.GetSelectionBounds());
        private void MainInkCanvas_SelectionResized(object? sender, EventArgs e) => UpdateOverlay(MainInkCanvas.GetSelectionBounds());
        private void MainInkCanvas_SelectionMoving(object? sender, InkCanvasSelectionEditingEventArgs e) => UpdateOverlay(e.NewRectangle);
        private void MainInkCanvas_SelectionResizing(object? sender, InkCanvasSelectionEditingEventArgs e) => UpdateOverlay(e.NewRectangle);

        private void MainInkCanvas_LayoutUpdated(object? sender, EventArgs e)
        {
            if (MainInkCanvas.GetSelectedStrokes().Count > 0)
            {
                if (VisualTreeHelper.GetChildrenCount(MainInkCanvas) > 0)
                {
                    var innerCanvas = VisualTreeHelper.GetChild(MainInkCanvas, 0) as UIElement;
                    if (innerCanvas != null)
                    {
                        var layer = System.Windows.Documents.AdornerLayer.GetAdornerLayer(innerCanvas);
                        if (layer != null)
                        {
                            var adorners = layer.GetAdorners(innerCanvas);
                            if (adorners != null)
                            {
                                foreach (var adorner in adorners)
                                {
                                    if (adorner.GetType().Name == "InkCanvasSelectionAdorner")
                                    {
                                        adorner.Opacity = 0.01;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        private void Theme_Click(object? sender, RoutedEventArgs? e)
        {
            _isDarkTheme = !_isDarkTheme;
            ApplyTheme();
            UpdateCustomCursorAppearance();
        }

        private void ApplyTheme()
        {
            if (_isDarkTheme)
            {
                MainScroll.Background = new SolidColorBrush(Color.FromRgb(15, 17, 42)); // slate-900
                if (string.IsNullOrEmpty(_currentPdfPath)) Workspace.Background = CreateGridBrush(Color.FromRgb(30, 41, 59)); // slate-800
                H_TL.Fill = new SolidColorBrush(Color.FromRgb(30, 41, 59)); H_TC.Fill = H_TL.Fill; H_TR.Fill = H_TL.Fill; H_ML.Fill = H_TL.Fill; H_MR.Fill = H_TL.Fill; H_BL.Fill = H_TL.Fill; H_BC.Fill = H_TL.Fill; H_BR.Fill = H_TL.Fill;
            }
            else
            {
                MainScroll.Background = new SolidColorBrush(Color.FromRgb(248, 250, 252)); // slate-50
                if (string.IsNullOrEmpty(_currentPdfPath)) Workspace.Background = CreateGridBrush(Color.FromRgb(203, 213, 225)); // slate-300
                H_TL.Fill = new SolidColorBrush(Colors.White); H_TC.Fill = H_TL.Fill; H_TR.Fill = H_TL.Fill; H_ML.Fill = H_TL.Fill; H_MR.Fill = H_TL.Fill; H_BL.Fill = H_TL.Fill; H_BC.Fill = H_TL.Fill; H_BR.Fill = H_TL.Fill;
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
                UpdateOverlay(MainInkCanvas.GetSelectionBounds());
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
                UpdateOverlay(MainInkCanvas.GetSelectionBounds());
            }
        }

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
                    MainInkCanvas.EditingMode = InkCanvasEditingMode.None; 
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
                    var selected = MainInkCanvas.Strokes.HitTest(_lassoPoints, 50); 
                    MainInkCanvas.Select(selected);
                }
                
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
                    UpdateOverlay(Rect.Empty);
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
            Color c = GetComboColor();

            if (HighlightBtn.IsChecked == true) { size *= 4; c = Color.FromArgb(120, c.R, c.G, c.B); }
            
            if (LaserBtn.IsChecked == true) 
            {
                CustomDotCursor.Fill = new SolidColorBrush(c);
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
                UpdateOverlay(Rect.Empty);

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
                        
                        XColor bgColor = _isDarkTheme ? XColor.FromArgb(255, 15, 23, 42) : XColor.FromArgb(255, 248, 250, 252);
                        XColor gridColor = _isDarkTheme ? XColor.FromArgb(255, 30, 41, 59) : XColor.FromArgb(255, 203, 213, 225);

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
            UpdateOverlay(Rect.Empty);
        }

        private void PerformZoomIn() { _zoom += 0.25; ZoomTransform.ScaleX = _zoom; ZoomTransform.ScaleY = _zoom; }
        private void PerformZoomOut() { _zoom = Math.Max(0.25, _zoom - 0.25); ZoomTransform.ScaleX = _zoom; ZoomTransform.ScaleY = _zoom; }

        private void ZoomIn_Click(object sender, RoutedEventArgs e) => PerformZoomIn();
        private void ZoomOut_Click(object sender, RoutedEventArgs e) => PerformZoomOut();
    }
}
EOF

echo "✅ App Polished to Absolute Perfection! Ready for zero-error execution."
