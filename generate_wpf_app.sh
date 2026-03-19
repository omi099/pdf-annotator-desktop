#!/bin/bash
set -e

echo "🚀 Bootstrapping Anydraw V8 (Enterprise PDF Virtualization & Zero-Lag Edition)..."

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
    <Nullable>disable</Nullable>
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
        KeyDown="Window_KeyDown" Closing="Window_Closing" FontFamily="Segoe UI, Helvetica, Arial, sans-serif">

    <Window.Resources>
        <SolidColorBrush x:Key="BgPrimary" Color="#000000"/>
        <SolidColorBrush x:Key="BgToolbar" Color="#15171B"/>
        <SolidColorBrush x:Key="BorderToolbar" Color="#2A2D35"/>
        <SolidColorBrush x:Key="TextPrimary" Color="#F8FAFC"/>
        <SolidColorBrush x:Key="TextSecondary" Color="#A1A1AA"/>
        <SolidColorBrush x:Key="ButtonHoverBg" Color="#25282D"/>
        <SolidColorBrush x:Key="ButtonHoverText" Color="#FFFFFF"/>
        <SolidColorBrush x:Key="Sky400" Color="#38BDF8"/>
        <SolidColorBrush x:Key="Rose500" Color="#EF4444"/>

        <Style TargetType="Button" x:Key="TabButton">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="{DynamicResource TextSecondary}"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Padding" Value="15,8"/>
            <Setter Property="Margin" Value="0,0,2,0"/>
            <Setter Property="BorderThickness" Value="1,1,1,0"/>
            <Setter Property="BorderBrush" Value="Transparent"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="8,8,0,0" Padding="{TemplateBinding Padding}">
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

        <Border Grid.Row="0" Background="{DynamicResource BgToolbar}" BorderBrush="{DynamicResource BorderToolbar}" BorderThickness="0,0,0,1" Padding="10,8,10,0" Panel.ZIndex="100">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                
                <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Bottom" Margin="0,0,15,0">
                    <Path Data="M12 2 L2 22 L6 22 L12 10 L18 22 L22 22 Z M7 16 L17 16 L17 18 L7 18 Z" Fill="{DynamicResource Sky400}" Height="18" Stretch="Uniform" Margin="0,0,8,4"/>
                    <TextBlock Text="Anydraw" FontSize="16" FontWeight="Bold" Foreground="{DynamicResource TextPrimary}" Margin="0,0,0,4"/>
                </StackPanel>

                <ScrollViewer Grid.Column="1" HorizontalScrollBarVisibility="Hidden" VerticalScrollBarVisibility="Disabled" VerticalAlignment="Bottom">
                    <StackPanel x:Name="TabsPanel" Orientation="Horizontal" VerticalAlignment="Bottom"/>
                </ScrollViewer>

                <Button Grid.Column="2" Style="{StaticResource TailwindButton}" Click="NewTab_Click" ToolTip="New Draw Mode Tab (+)" Margin="5,0,0,4" Padding="8,4">
                    <Path Data="M 12 2 L 12 22 M 2 12 L 22 12" Stroke="{Binding Foreground, RelativeSource={RelativeSource AncestorType=Button}}" StrokeThickness="3" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Fill="Transparent" Height="14" Stretch="Uniform"/>
                </Button>
            </Grid>
        </Border>

        <ScrollViewer Grid.Row="1" x:Name="MainScroll" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto" PanningMode="Both" PreviewMouseWheel="MainScroll_PreviewMouseWheel" Background="Transparent" Panel.ZIndex="10">
            
            <Grid x:Name="Workspace" HorizontalAlignment="Center" VerticalAlignment="Center" Margin="50">
                <Grid.LayoutTransform>
                    <ScaleTransform x:Name="ZoomTransform" ScaleX="1" ScaleY="1"/>
                </Grid.LayoutTransform>
                
                <Border x:Name="PdfPageBorder" Background="White" Visibility="Hidden" HorizontalAlignment="Stretch" VerticalAlignment="Stretch" CornerRadius="4">
                    <Border.Effect>
                        <DropShadowEffect Color="Black" BlurRadius="15" Opacity="0.5" Direction="270" ShadowDepth="5"/>
                    </Border.Effect>
                    <Image x:Name="PdfSinglePageImage" Stretch="Fill" RenderOptions.BitmapScalingMode="HighQuality"/>
                </Border>

                <AdornerDecorator>
                    <Grid x:Name="CanvasContainer" HorizontalAlignment="Stretch" VerticalAlignment="Stretch">
                        
                        <Grid x:Name="A4GuideContainer" IsHitTestVisible="False" HorizontalAlignment="Center" VerticalAlignment="Center" Width="1123" Height="794">
                            <Rectangle Stroke="{DynamicResource TextSecondary}" StrokeThickness="2" StrokeDashArray="6 6" Opacity="0.4"/>
                            <TextBlock Text="A4 Boundary (297 x 210 mm)" Foreground="{DynamicResource TextSecondary}" Opacity="0.6" Margin="12" VerticalAlignment="Bottom" HorizontalAlignment="Right" FontSize="14" FontWeight="SemiBold"/>
                        </Grid>

                        <InkCanvas x:Name="MainInkCanvas" Background="Transparent" UseCustomCursor="True" Cursor="Arrow" Focusable="True"
                                   PreviewMouseLeftButtonDown="MainInkCanvas_PreviewMouseLeftButtonDown"
                                   MouseMove="MainInkCanvas_MouseMove" MouseLeave="MainInkCanvas_MouseLeave" MouseEnter="MainInkCanvas_MouseEnter">
                        </InkCanvas>
                        
                        <InkCanvas x:Name="LaserInkCanvas" Background="Transparent" UseCustomCursor="True" Cursor="Arrow" Focusable="False" IsHitTestVisible="False"
                                   MouseMove="MainInkCanvas_MouseMove" MouseLeave="MainInkCanvas_MouseLeave" MouseEnter="MainInkCanvas_MouseEnter"
                                   PreviewMouseDown="LaserActivity_MouseDown" PreviewStylusDown="LaserActivity_StylusDown" PreviewStylusMove="LaserActivity_StylusMove">
                        </InkCanvas>
                    </Grid>
                </AdornerDecorator>
                
                <Canvas x:Name="CursorCanvas" IsHitTestVisible="False" HorizontalAlignment="Stretch" VerticalAlignment="Stretch" Panel.ZIndex="999">
                    <Ellipse x:Name="CustomDotCursor" Visibility="Hidden" IsHitTestVisible="False">
                        <Ellipse.Effect>
                            <DropShadowEffect x:Name="CursorGlow" BlurRadius="4" ShadowDepth="1" Opacity="0.6" />
                        </Ellipse.Effect>
                    </Ellipse>
                </Canvas>
            </Grid>
        </ScrollViewer>

        <Border Grid.Row="1" x:Name="MainToolbar" Background="{DynamicResource BgToolbar}" BorderBrush="{DynamicResource BorderToolbar}" BorderThickness="1" CornerRadius="16" Padding="5,8" HorizontalAlignment="Center" VerticalAlignment="Bottom" Margin="0,0,0,30" Panel.ZIndex="100">
            <Border.RenderTransform>
                <TranslateTransform x:Name="ToolbarTransform" X="0" Y="0"/>
            </Border.RenderTransform>
            <Border.Effect>
                <DropShadowEffect Color="Black" BlurRadius="25" Opacity="0.4" ShadowDepth="8" Direction="270"/>
            </Border.Effect>
            
            <WrapPanel Orientation="Horizontal" VerticalAlignment="Center">
                
                <Border Background="Transparent" Cursor="SizeAll" MouseLeftButtonDown="ToolbarDrag_MouseDown" MouseMove="ToolbarDrag_MouseMove" MouseLeftButtonUp="ToolbarDrag_MouseUp" Padding="8,10" Margin="4,0,8,0" ToolTip="Drag Toolbar">
                    <Path Data="M 2 4 A 1.5 1.5 0 1 1 2 7 A 1.5 1.5 0 1 1 2 4 Z M 2 10 A 1.5 1.5 0 1 1 2 13 A 1.5 1.5 0 1 1 2 10 Z M 2 16 A 1.5 1.5 0 1 1 2 19 A 1.5 1.5 0 1 1 2 16 Z M 8 4 A 1.5 1.5 0 1 1 8 7 A 1.5 1.5 0 1 1 8 4 Z M 8 10 A 1.5 1.5 0 1 1 8 13 A 1.5 1.5 0 1 1 8 10 Z M 8 16 A 1.5 1.5 0 1 1 8 19 A 1.5 1.5 0 1 1 8 16 Z" Fill="{DynamicResource TextSecondary}" Stretch="Uniform" Width="8"/>
                </Border>

                <StackPanel x:Name="PaginationPanel" Orientation="Horizontal" VerticalAlignment="Center">
                    <Button Style="{StaticResource TailwindButton}" Click="PrevPage_Click" ToolTip="Previous Page" Padding="6,6">
                        <Path Data="M 15 4 L 7 12 L 15 20" Stroke="{Binding Foreground, RelativeSource={RelativeSource AncestorType=Button}}" StrokeThickness="2.5" StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round" Fill="Transparent" Height="14" Stretch="Uniform"/>
                    </Button>
                    <TextBlock x:Name="PageCounterText" Text="1/1" Foreground="{DynamicResource Sky400}" VerticalAlignment="Center" FontWeight="Bold" Margin="4,0" Width="30" TextAlignment="Center"/>
                    <Button Style="{StaticResource TailwindButton}" Click="NextPage_Click" ToolTip="Next Page" Padding="6,6">
                        <Path Data="M 9 4 L 17 12 L 9 20" Stroke="{Binding Foreground, RelativeSource={RelativeSource AncestorType=Button}}" StrokeThickness="2.5" StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round" Fill="Transparent" Height="14" Stretch="Uniform"/>
                    </Button>
                    <Button Style="{StaticResource TailwindButton}" Click="AddPage_Click" ToolTip="Add Page to Current Document" Margin="0,0,8,0">
                        <Path Data="M 14 2 L 6 2 C 4.9 2 4 2.9 4 4 L 4 20 C 4 21.1 4.9 22 6 22 L 18 22 C 19.1 22 20 21.1 20 20 L 20 8 L 14 2 Z M 12 18 L 12 14 L 8 14 L 8 12 L 12 12 L 12 8 L 14 8 L 14 12 L 18 12 L 18 14 L 14 14 L 14 18 Z" Fill="{DynamicResource Sky400}" Height="18" Stretch="Uniform"/>
                    </Button>
                    <Button Style="{StaticResource TailwindButton}" Click="DeletePage_Click" ToolTip="Delete Page" Margin="0,0,8,0">
                        <Path Data="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z" Fill="{DynamicResource Rose500}" Height="16" Stretch="Uniform"/>
                    </Button>
                </StackPanel>

                <Rectangle Width="1" Fill="{DynamicResource BorderToolbar}" Margin="4,4"/>

                <Button Style="{StaticResource TailwindButton}" Click="OpenPdf_Click" ToolTip="Upload PDF to Current Tab">
                    <Path Data="M 14 2 L 6 2 C 4.9 2 4 2.9 4 4 L 4 20 C 4 21.1 4.9 22 6 22 L 18 22 C 19.1 22 20 21.1 20 20 L 20 8 L 14 2 Z M 13 9 L 13 3.5 L 18.5 9 L 13 9 Z" Stroke="{Binding Foreground, RelativeSource={RelativeSource AncestorType=Button}}" StrokeThickness="2" StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round" Fill="Transparent" Height="18" Stretch="Uniform"/>
                </Button>
                <Button Style="{StaticResource TailwindButton}" Click="ExportAnnotated_Click" ToolTip="Export PDF">
                    <Path Data="M 12 16 L 12 3 M 8 7 L 12 3 L 16 7 M 4 16 L 4 20 C 4 21.1 4.9 22 6 22 L 18 22 C 19.1 22 20 21.1 20 20 L 20 16" Stroke="{Binding Foreground, RelativeSource={RelativeSource AncestorType=Button}}" StrokeThickness="2" StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round" Fill="Transparent" Height="18" Stretch="Uniform"/>
                </Button>

                <Rectangle Width="1" Fill="{DynamicResource BorderToolbar}" Margin="12,4"/>

                <RadioButton Style="{StaticResource TailwindTool}" x:Name="PointerBtn" Checked="Tool_Checked" ToolTip="Mouse Pointer (Esc)">
                    <Path Data="M 6 4 L 14 24 L 17 17 L 24 14 Z" Stroke="{Binding Foreground, RelativeSource={RelativeSource AncestorType=RadioButton}}" StrokeThickness="2" StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round" Fill="Transparent" Height="22" Stretch="Uniform"/>
                </RadioButton>
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

                <Button x:Name="ColorBtn" Style="{StaticResource TailwindButton}" Click="ColorBtn_Click" ToolTip="Main Color">
                    <StackPanel Orientation="Horizontal">
                        <Ellipse x:Name="ActiveColorIndicator" Width="16" Height="16" Fill="#EF4444" Stroke="{DynamicResource BorderToolbar}" StrokeThickness="1"/>
                        <TextBlock Text="▼" FontSize="9" Margin="4,0,0,0" VerticalAlignment="Center"/>
                    </StackPanel>
                </Button>
                
                <Button x:Name="CoreColorBtn" Style="{StaticResource TailwindButton}" Click="CoreColorBtn_Click" ToolTip="Laser Core Color">
                    <StackPanel Orientation="Horizontal">
                        <Ellipse x:Name="ActiveCoreColorIndicator" Width="16" Height="16" Fill="#FFFFFF" Stroke="{DynamicResource BorderToolbar}" StrokeThickness="1"/>
                        <TextBlock Text="▼" FontSize="9" Margin="4,0,0,0" VerticalAlignment="Center"/>
                    </StackPanel>
                </Button>

                <Popup x:Name="ColorPopup" StaysOpen="False" PlacementTarget="{Binding ElementName=ColorBtn}" Placement="Top" VerticalOffset="-10">
                    <Border Background="{DynamicResource BgToolbar}" BorderBrush="{DynamicResource BorderToolbar}" BorderThickness="1" CornerRadius="6" Padding="10">
                        <Border.Effect><DropShadowEffect BlurRadius="10" Opacity="0.3" ShadowDepth="4"/></Border.Effect>
                        <StackPanel>
                            <TextBlock x:Name="PopupColorLabel" Text="Color Hex:" Foreground="{DynamicResource TextSecondary}" FontSize="11" Margin="0,0,0,4"/>
                            <TextBox x:Name="HexInput" Text="#EF4444" Width="100" Background="{DynamicResource BgPrimary}" Foreground="{DynamicResource TextPrimary}" BorderBrush="{DynamicResource BorderToolbar}" Padding="4" Margin="0,0,0,8" TextChanged="HexInput_TextChanged"/>
                            <WrapPanel Width="120" x:Name="PaletteGrid"/>
                        </StackPanel>
                    </Border>
                </Popup>

                <Slider x:Name="SizeSlider" Minimum="0.5" Maximum="50" Value="4" Width="60" VerticalAlignment="Center" Margin="5,0" ValueChanged="Size_Changed" IsMoveToPointEnabled="True"/>
                <TextBox x:Name="SizeInput" Text="{Binding Value, ElementName=SizeSlider, UpdateSourceTrigger=PropertyChanged, StringFormat=F1}" Width="28" TextAlignment="Center" VerticalAlignment="Center" Margin="0,0,8,0" FontWeight="Bold" Background="Transparent" Foreground="{DynamicResource TextPrimary}" BorderThickness="0"/>

                <CheckBox x:Name="PressureToggle" Content="Pressure" IsChecked="True" Foreground="{DynamicResource TextSecondary}" VerticalAlignment="Center" Margin="0,0,10,0" Checked="Pressure_Changed" Unchecked="Pressure_Changed" FontWeight="SemiBold" ToolTip="Enable Pen Pressure Sensitivity"/>
                <CheckBox x:Name="StrokeEraserToggle" Content="Stroke Erase" IsChecked="True" Foreground="{DynamicResource TextSecondary}" VerticalAlignment="Center" Margin="0,0,10,0" Checked="EraserMode_Changed" Unchecked="EraserMode_Changed" FontWeight="SemiBold" ToolTip="Uncheck to erase exact pixels instead of whole strokes."/>

                <Rectangle Width="1" Fill="{DynamicResource BorderToolbar}" Margin="5,4"/>

                <Button x:Name="BgColorBtn" Style="{StaticResource TailwindButton}" Click="BgColorBtn_Click" ToolTip="Background Color">
                    <StackPanel Orientation="Horizontal">
                        <Rectangle x:Name="ActiveBgIndicator" Width="16" Height="16" Fill="#151515" Stroke="{DynamicResource BorderToolbar}" StrokeThickness="1" RadiusX="2" RadiusY="2"/>
                        <TextBlock Text="▼" FontSize="9" Margin="4,0,0,0" VerticalAlignment="Center"/>
                    </StackPanel>
                </Button>
                <Popup x:Name="BgColorPopup" StaysOpen="False" PlacementTarget="{Binding ElementName=BgColorBtn}" Placement="Top" VerticalOffset="-10">
                    <Border Background="{DynamicResource BgToolbar}" BorderBrush="{DynamicResource BorderToolbar}" BorderThickness="1" CornerRadius="6" Padding="10">
                        <Border.Effect><DropShadowEffect BlurRadius="10" Opacity="0.3" ShadowDepth="4"/></Border.Effect>
                        <StackPanel>
                            <TextBlock Text="Canvas Hex:" Foreground="{DynamicResource TextSecondary}" FontSize="11" Margin="0,0,0,4"/>
                            <TextBox x:Name="BgHexInput" Text="#151515" Width="100" Background="{DynamicResource BgPrimary}" Foreground="{DynamicResource TextPrimary}" BorderBrush="{DynamicResource BorderToolbar}" Padding="4" Margin="0,0,0,8" TextChanged="BgHexInput_TextChanged"/>
                            <WrapPanel Width="120" x:Name="BgPaletteGrid"/>
                        </StackPanel>
                    </Border>
                </Popup>

                <Button Style="{StaticResource TailwindButton}" Click="GridToggle_Click" ToolTip="Cycle Grid Patterns (G)">
                    <Path Data="M 3 3 L 21 3 L 21 21 L 3 21 Z M 9 3 L 9 21 M 15 3 L 15 21 M 3 9 L 21 9 M 3 15 L 21 15" Stroke="{Binding Foreground, RelativeSource={RelativeSource AncestorType=Button}}" StrokeThickness="2" StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round" Fill="Transparent" Height="16" Stretch="Uniform"/>
                </Button>

                <TextBlock Text="⏱️" Foreground="{DynamicResource TextSecondary}" VerticalAlignment="Center" Margin="5,0"/>
                <TextBox x:Name="LaserDelayInput" Text="1.7" Width="28" TextAlignment="Center" VerticalAlignment="Center" Margin="0,0,10,0" FontWeight="Bold" Background="Transparent" Foreground="{DynamicResource Sky400}" BorderThickness="0" TextChanged="LaserDelayInput_TextChanged" ToolTip="Laser Fade Delay (seconds)"/>
                
                <TextBlock Text="🌟" Foreground="{DynamicResource TextSecondary}" VerticalAlignment="Center" Margin="5,0" ToolTip="Laser Glow Intensity"/>
                <Slider x:Name="LaserGlowSlider" Minimum="1" Maximum="50" Value="15" Width="40" VerticalAlignment="Center" Margin="0,0,5,0" ValueChanged="Size_Changed" IsMoveToPointEnabled="True"/>
                <TextBox x:Name="LaserGlowInput" Text="{Binding Value, ElementName=LaserGlowSlider, UpdateSourceTrigger=PropertyChanged, StringFormat=F1}" Width="28" TextAlignment="Center" VerticalAlignment="Center" Margin="0,0,10,0" FontWeight="Bold" Background="Transparent" Foreground="{DynamicResource Sky400}" BorderThickness="0"/>

                <Rectangle Width="1" Fill="{DynamicResource BorderToolbar}" Margin="0,4,12,4"/>
                
                <Button Style="{StaticResource TailwindButton}" Click="FullScreen_Click" ToolTip="Cycle Full Screen Modes (F)">
                    <Path Data="M 3 3 L 9 3 L 9 5 L 5 5 L 5 9 L 3 9 Z M 21 3 L 15 3 L 15 5 L 19 5 L 19 9 L 21 9 Z M 3 21 L 9 21 L 9 19 L 5 19 L 5 15 L 3 15 Z M 21 21 L 15 21 L 15 19 L 19 19 L 19 15 L 21 15 Z" Fill="{Binding Foreground, RelativeSource={RelativeSource AncestorType=Button}}" Height="16" Stretch="Uniform"/>
                </Button>
                <Button Style="{StaticResource TailwindButton}" Click="Theme_Click" ToolTip="Toggle Dark/Light Mode">
                    <Path Data="M12 3a9 9 0 1 0 9 9c0-.46-.04-.92-.1-1.36a5.389 5.389 0 0 1-4.4 2.26 5.403 5.403 0 0 1-3.14-9.8c-.44-.06-.9-.1-1.36-.1z" Fill="{Binding Foreground, RelativeSource={RelativeSource AncestorType=Button}}" Height="16" Stretch="Uniform"/>
                </Button>
                <Button Style="{StaticResource TailwindButton}" Click="ClearInk_Click" ToolTip="Clear Board">
                    <TextBlock Text="Clear" Foreground="{DynamicResource Rose500}" FontWeight="SemiBold"/>
                </Button>
            </WrapPanel>
        </Border>
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
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Tasks;
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
    public class LaserStrokeData
    {
        public System.Windows.Ink.Stroke Stroke { get; set; }
        public int Life { get; set; } = 255;
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public LaserStrokeData(System.Windows.Ink.Stroke s) { Stroke = s; }
    }

    public class WorkspaceTab
    {
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public string Title { get; set; } = "Draw Mode";
        public string PdfFilePath { get; set; } = null;
        public int CurrentPage { get; set; } = 1;
        public int TotalPages { get; set; } = 1;
        
        [JsonIgnore]
        public Dictionary<int, StrokeCollection> StrokesPerPage { get; set; } = new Dictionary<int, StrokeCollection>();
    }

    public class AppSettings
    {
        public double PenSize { get; set; } = 4.0;
        public string PenColor { get; set; } = "#EF4444";
        public double HighlightSize { get; set; } = 24.0;
        public string HighlightColor { get; set; } = "#FFFF00";
        public double LaserSize { get; set; } = 6.0;
        public string LaserColor { get; set; } = "#EF4444";
        public string LaserCoreColor { get; set; } = "#FFFFFF";
        public double LaserFadeDelay { get; set; } = 1.7;
        public double LaserGlow { get; set; } = 15.0;
        public bool IsDarkTheme { get; set; } = true;
        public int GridPattern { get; set; } = 1; 
        public string CustomBgColor { get; set; } = "#15171B";
        public bool PressureEnabled { get; set; } = true;
        public bool StrokeEraserEnabled { get; set; } = true;
    }

    public partial class MainWindow : Window
    {
        private List<WorkspaceTab> _tabs = new List<WorkspaceTab>();
        private WorkspaceTab _activeTab;

        private double _zoom = 1.0;
        private bool _isUpdatingUI = false;
        private bool _appLoaded = false;
        private bool _isEditingCoreColor = false;
        private int _fullScreenLevel = 1; 

        private double _penSize;
        private Color _penColor;
        private double _highlightSize;
        private Color _highlightColor;
        private double _laserSize;
        private Color _laserColor;
        private Color _laserCoreColor;
        private double _laserFadeDelay;
        private bool _isDarkTheme;
        private int _gridPattern = 1;
        private Color _customBgColor;

        private List<LaserStrokeData> _laserStrokes = new List<LaserStrokeData>();
        private DispatcherTimer _laserTimer;
        private DateTime _lastLaserActivityTime = DateTime.Now;

        private Stack<StrokeCollection> _undoStack = new Stack<StrokeCollection>();
        private Stack<StrokeCollection> _redoStack = new Stack<StrokeCollection>();

        private bool _isDraggingToolbar = false;
        private Point _toolbarDragStart;

        private readonly string _appDataFolder;

        public MainWindow()
        {
            InitializeComponent();

            _appDataFolder = System.IO.Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Anydraw");
            if (!Directory.Exists(_appDataFolder)) Directory.CreateDirectory(_appDataFolder);

            System.Text.Encoding.RegisterProvider(System.Text.CodePagesEncodingProvider.Instance);

            MainInkCanvas.Cursor = Cursors.Arrow;
            LaserInkCanvas.Cursor = Cursors.Arrow;

            LaserInkCanvas.Strokes.StrokesChanged += LaserInkCanvas_StrokesChanged;

            _laserTimer = new DispatcherTimer(DispatcherPriority.Render) { Interval = TimeSpan.FromMilliseconds(33) };
            _laserTimer.Tick += LaserTimer_Tick;
            _laserTimer.Start();

            BuildPaletteGrid();
            LoadState(); 

            _appLoaded = true;
            SyncToolToUI();
            UpdatePageUI();
            ApplyTheme();
        }

        private void LaserActivity_MouseDown(object sender, MouseButtonEventArgs e) { if (LaserBtn.IsChecked == true) _lastLaserActivityTime = DateTime.Now; }
        private void LaserActivity_StylusDown(object sender, StylusDownEventArgs e) { if (LaserBtn.IsChecked == true) _lastLaserActivityTime = DateTime.Now; }
        private void LaserActivity_StylusMove(object sender, StylusEventArgs e) { if (LaserBtn.IsChecked == true && !e.InAir) _lastLaserActivityTime = DateTime.Now; }

        private void LaserInkCanvas_StrokesChanged(object sender, System.Windows.Ink.StrokeCollectionChangedEventArgs e)
        {
            if (_isUpdatingUI) return;
            if (e.Added.Count > 0)
            {
                foreach (var stroke in e.Added) _laserStrokes.Add(new LaserStrokeData(stroke));
                _lastLaserActivityTime = DateTime.Now;
            }
        }

        private void LoadState()
        {
            string settingsPath = System.IO.Path.Combine(_appDataFolder, "settings.json");
            AppSettings settings = new AppSettings();
            if (File.Exists(settingsPath))
            {
                try { settings = JsonSerializer.Deserialize<AppSettings>(File.ReadAllText(settingsPath)) ?? new AppSettings(); } catch { }
            }

            _penSize = settings.PenSize; _penColor = (Color)ColorConverter.ConvertFromString(settings.PenColor);
            _highlightSize = settings.HighlightSize; _highlightColor = (Color)ColorConverter.ConvertFromString(settings.HighlightColor);
            _laserSize = settings.LaserSize; _laserColor = (Color)ColorConverter.ConvertFromString(settings.LaserColor);
            _laserCoreColor = (Color)ColorConverter.ConvertFromString(settings.LaserCoreColor);
            _laserFadeDelay = settings.LaserFadeDelay;
            _isDarkTheme = settings.IsDarkTheme;
            _gridPattern = settings.GridPattern;
            _customBgColor = (Color)ColorConverter.ConvertFromString(settings.CustomBgColor);

            _isUpdatingUI = true;
            LaserDelayInput.Text = _laserFadeDelay.ToString("F1");
            LaserGlowSlider.Value = settings.LaserGlow;
            BgHexInput.Text = settings.CustomBgColor;
            PressureToggle.IsChecked = settings.PressureEnabled;
            StrokeEraserToggle.IsChecked = settings.StrokeEraserEnabled;
            _isUpdatingUI = false;

            string tabsFile = System.IO.Path.Combine(_appDataFolder, "tabs.json");
            if (File.Exists(tabsFile))
            {
                try 
                { 
                    var savedTabs = JsonSerializer.Deserialize<List<WorkspaceTab>>(File.ReadAllText(tabsFile)); 
                    if (savedTabs != null && savedTabs.Count > 0)
                    {
                        foreach(var t in savedTabs)
                        {
                            foreach(var file in Directory.GetFiles(_appDataFolder, $"ink_{t.Id}_*.isf"))
                            {
                                int pageNum = int.Parse(file.Split('_').Last().Replace(".isf", ""));
                                using (FileStream fs = new FileStream(file, FileMode.Open, FileAccess.Read))
                                {
                                    t.StrokesPerPage[pageNum] = new StrokeCollection(fs);
                                }
                            }
                            _tabs.Add(t);
                        }
                    }
                } 
                catch { }
            }

            if (_tabs.Count == 0) _tabs.Add(new WorkspaceTab());
            SwitchToTab(_tabs[0]);
            RenderTabsUI();
        }

        private void SaveState()
        {
            if (_activeTab != null) _activeTab.StrokesPerPage[_activeTab.CurrentPage] = MainInkCanvas.Strokes.Clone();

            AppSettings settings = new AppSettings
            {
                PenSize = _penSize, PenColor = _penColor.ToString(),
                HighlightSize = _highlightSize, HighlightColor = _highlightColor.ToString(),
                LaserSize = _laserSize, LaserColor = _laserColor.ToString(),
                LaserCoreColor = _laserCoreColor.ToString(),
                LaserFadeDelay = _laserFadeDelay, LaserGlow = LaserGlowSlider.Value,
                IsDarkTheme = _isDarkTheme, GridPattern = _gridPattern, CustomBgColor = _customBgColor.ToString(),
                PressureEnabled = PressureToggle.IsChecked == true, StrokeEraserEnabled = StrokeEraserToggle.IsChecked == true
            };
            File.WriteAllText(System.IO.Path.Combine(_appDataFolder, "settings.json"), JsonSerializer.Serialize(settings));

            foreach(var file in Directory.GetFiles(_appDataFolder, "*.isf")) File.Delete(file);

            File.WriteAllText(System.IO.Path.Combine(_appDataFolder, "tabs.json"), JsonSerializer.Serialize(_tabs));
            foreach(var tab in _tabs)
            {
                foreach(var kvp in tab.StrokesPerPage)
                {
                    if (kvp.Value.Count > 0)
                    {
                        using (FileStream fs = new FileStream(System.IO.Path.Combine(_appDataFolder, $"ink_{tab.Id}_{kvp.Key}.isf"), FileMode.Create))
                        {
                            kvp.Value.Save(fs);
                        }
                    }
                }
            }
        }

        private void Window_Closing(object sender, System.ComponentModel.CancelEventArgs e) => SaveState();

        private void RenderTabsUI()
        {
            TabsPanel.Children.Clear();
            foreach (var tab in _tabs)
            {
                Button btn = new Button { Style = (Style)FindResource("TabButton") };
                StackPanel sp = new StackPanel { Orientation = Orientation.Horizontal };
                TextBlock tb = new TextBlock { Text = tab.Title, VerticalAlignment = VerticalAlignment.Center, FontWeight = FontWeights.SemiBold, Margin = new Thickness(0,0,10,0) };
                if (tab == _activeTab) tb.Foreground = new SolidColorBrush(Color.FromRgb(56, 189, 248)); 
                
                Button closeBtn = new Button { Content = "×", Background = Brushes.Transparent, BorderThickness = new Thickness(0), Foreground = (Brush)FindResource("TextSecondary"), Cursor = Cursors.Hand, FontSize = 14, FontWeight = FontWeights.Bold };
                closeBtn.Click += (s, e) => { e.Handled = true; CloseTab(tab); };

                sp.Children.Add(tb); sp.Children.Add(closeBtn); btn.Content = sp;
                if (tab == _activeTab) { btn.Background = (Brush)FindResource("ButtonHoverBg"); btn.BorderBrush = (Brush)FindResource("BorderToolbar"); }

                btn.Click += (s, e) => SwitchToTab(tab);
                TabsPanel.Children.Add(btn);
            }
        }

        private async void SwitchToTab(WorkspaceTab targetTab)
        {
            if (_activeTab != null && _activeTab != targetTab)
            {
                _activeTab.StrokesPerPage[_activeTab.CurrentPage] = MainInkCanvas.Strokes.Clone();
            }

            _activeTab = targetTab;
            _undoStack.Clear(); _redoStack.Clear(); LaserInkCanvas.Strokes.Clear(); _laserStrokes.Clear();

            if (!string.IsNullOrEmpty(_activeTab.PdfFilePath))
            {
                await RenderSinglePdfPage(_activeTab.PdfFilePath, _activeTab.CurrentPage);
            }
            else
            {
                PdfPageBorder.Visibility = Visibility.Hidden;
                PdfSinglePageImage.Source = null;
                
                Workspace.Width = 10000; Workspace.Height = 10000;
                MainInkCanvas.Width = 10000; MainInkCanvas.Height = 10000;
                LaserInkCanvas.Width = 10000; LaserInkCanvas.Height = 10000;
                
                A4GuideContainer.Visibility = Visibility.Visible;
                A4GuideContainer.Margin = new Thickness((Workspace.Width - 1123) / 2.0, (Workspace.Height - 794) / 2.0, 0, 0);
            }

            MainInkCanvas.Strokes = _activeTab.StrokesPerPage.ContainsKey(_activeTab.CurrentPage) ? _activeTab.StrokesPerPage[_activeTab.CurrentPage].Clone() : new StrokeCollection();
            
            RenderTabsUI(); UpdatePageUI(); ApplyTheme();
            
            if (string.IsNullOrEmpty(_activeTab.PdfFilePath))
            {
                Workspace.UpdateLayout();
                MainScroll.ScrollToHorizontalOffset((Workspace.Width / 2.0) - (SystemParameters.PrimaryScreenWidth / 2.0));
                MainScroll.ScrollToVerticalOffset((Workspace.Height / 2.0) - (SystemParameters.PrimaryScreenHeight / 2.0));
            }
        }

        // ARCHITECT FIX: Loads ONLY the current page to completely eliminate massive PDF memory spikes
        private async Task RenderSinglePdfPage(string filePath, int pageNumber)
        {
            try 
            {
                StorageFile file = await StorageFile.GetFileFromPathAsync(filePath);
                Windows.Data.Pdf.PdfDocument pdfDoc = await Windows.Data.Pdf.PdfDocument.LoadFromFileAsync(file);
                _activeTab.TotalPages = (int)pdfDoc.PageCount;

                using (Windows.Data.Pdf.PdfPage page = pdfDoc.GetPage((uint)(pageNumber - 1)))
                {
                    using (var stream = new InMemoryRandomAccessStream())
                    {
                        var options = new Windows.Data.Pdf.PdfPageRenderOptions { DestinationWidth = (uint)(page.Size.Width * 3.0), DestinationHeight = (uint)(page.Size.Height * 3.0) };
                        await page.RenderToStreamAsync(stream, options);

                        var reader = new DataReader(stream.GetInputStreamAt(0));
                        await reader.LoadAsync((uint)stream.Size);
                        byte[] buffer = new byte[stream.Size];
                        reader.ReadBytes(buffer);

                        using (var ms = new MemoryStream(buffer))
                        {
                            var bitmap = new BitmapImage();
                            bitmap.BeginInit(); bitmap.CacheOption = BitmapCacheOption.OnLoad; bitmap.StreamSource = ms; bitmap.EndInit();
                            
                            PdfSinglePageImage.Source = bitmap;
                            PdfSinglePageImage.Width = page.Size.Width;
                            PdfSinglePageImage.Height = page.Size.Height;
                            
                            Workspace.Width = page.Size.Width; Workspace.Height = page.Size.Height;
                            MainInkCanvas.Width = page.Size.Width; MainInkCanvas.Height = page.Size.Height;
                            LaserInkCanvas.Width = page.Size.Width; LaserInkCanvas.Height = page.Size.Height;
                            
                            PdfPageBorder.Visibility = Visibility.Visible;
                            A4GuideContainer.Visibility = Visibility.Hidden;
                        }
                    }
                }
            } 
            catch { }
        }

        private void NewTab_Click(object sender, RoutedEventArgs e)
        {
            var newTab = new WorkspaceTab(); _tabs.Add(newTab); SwitchToTab(newTab);
        }

        private void CloseTab(WorkspaceTab tab)
        {
            _tabs.Remove(tab);
            if (_tabs.Count == 0) { var freshTab = new WorkspaceTab(); _tabs.Add(freshTab); SwitchToTab(freshTab); }
            else if (_activeTab == tab) SwitchToTab(_tabs.Last());
            else RenderTabsUI();
        }

        private void FullScreen_Click(object sender, RoutedEventArgs e) => ToggleFullScreen();

        private void ToggleFullScreen()
        {
            _fullScreenLevel = (_fullScreenLevel + 1) % 3;
            if (_fullScreenLevel == 0)
            {
                this.WindowState = WindowState.Normal;
                this.WindowStyle = WindowStyle.SingleBorderWindow;
                this.ResizeMode = ResizeMode.CanResize;
                this.Topmost = false;
            }
            else if (_fullScreenLevel == 1)
            {
                this.WindowStyle = WindowStyle.SingleBorderWindow;
                this.ResizeMode = ResizeMode.CanResize;
                this.WindowState = WindowState.Maximized;
                this.Topmost = false;
            }
            else
            {
                this.WindowState = WindowState.Normal; 
                this.WindowStyle = WindowStyle.None;
                this.ResizeMode = ResizeMode.NoResize; 
                this.Topmost = true;
                this.WindowState = WindowState.Maximized;
            }
        }

        private void ToolbarDrag_MouseDown(object sender, MouseButtonEventArgs e) { _isDraggingToolbar = true; _toolbarDragStart = e.GetPosition(this); ((UIElement)sender).CaptureMouse(); }
        private void ToolbarDrag_MouseMove(object sender, MouseEventArgs e) { if (_isDraggingToolbar) { Point current = e.GetPosition(this); ToolbarTransform.X += current.X - _toolbarDragStart.X; ToolbarTransform.Y += current.Y - _toolbarDragStart.Y; _toolbarDragStart = current; } }
        private void ToolbarDrag_MouseUp(object sender, MouseButtonEventArgs e) { _isDraggingToolbar = false; ((UIElement)sender).ReleaseMouseCapture(); }

        private void BuildPaletteGrid()
        {
            string[] toolHexes = { "#EF4444", "#3B82F6", "#22C55E", "#EAB308", "#A855F7", "#F97316", "#EC4899", "#14B8A6", "#FFFFFF", "#000000" };
            foreach (string hex in toolHexes) { Rectangle r = new Rectangle { Width = 20, Height = 20, Margin = new Thickness(2), RadiusX = 4, RadiusY = 4, Fill = new SolidColorBrush((Color)ColorConverter.ConvertFromString(hex)), Cursor = Cursors.Hand }; r.MouseDown += (s, e) => { HexInput.Text = hex; ColorPopup.IsOpen = false; }; PaletteGrid.Children.Add(r); }
            string[] bgHexes = { "#15171B", "#1E1E1E", "#282828", "#000000", "#111827", "#0F172A", "#FFFFFF", "#F8FAFC", "#F3F4F6", "#FEF3C7" };
            foreach (string hex in bgHexes) { Rectangle r = new Rectangle { Width = 20, Height = 20, Margin = new Thickness(2), RadiusX = 4, RadiusY = 4, Fill = new SolidColorBrush((Color)ColorConverter.ConvertFromString(hex)), Cursor = Cursors.Hand }; r.MouseDown += (s, e) => { BgHexInput.Text = hex; BgColorPopup.IsOpen = false; }; BgPaletteGrid.Children.Add(r); }
        }

        private void ColorBtn_Click(object sender, RoutedEventArgs e) { _isEditingCoreColor = false; PopupColorLabel.Text = "Color Hex:"; HexInput.Text = ((SolidColorBrush)ActiveColorIndicator.Fill).Color.ToString(); ColorPopup.IsOpen = true; }
        private void CoreColorBtn_Click(object sender, RoutedEventArgs e) { _isEditingCoreColor = true; PopupColorLabel.Text = "Core Hex:"; HexInput.Text = ((SolidColorBrush)ActiveCoreColorIndicator.Fill).Color.ToString(); ColorPopup.IsOpen = true; }
        private void BgColorBtn_Click(object sender, RoutedEventArgs e) => BgColorPopup.IsOpen = true;

        private void HexInput_TextChanged(object sender, TextChangedEventArgs e)
        {
            if (!_appLoaded) return;
            try
            {
                Color c = (Color)ColorConverter.ConvertFromString(HexInput.Text);
                if (_isEditingCoreColor) { _laserCoreColor = c; ActiveCoreColorIndicator.Fill = new SolidColorBrush(c); }
                else { ActiveColorIndicator.Fill = new SolidColorBrush(c); if (PenBtn.IsChecked == true) _penColor = c; else if (HighlightBtn.IsChecked == true) _highlightColor = c; else if (LaserBtn.IsChecked == true) _laserColor = c; }
                ApplyPenAttributes();
            } catch { }
        }

        private void BgHexInput_TextChanged(object sender, TextChangedEventArgs e) { if (!_appLoaded) return; try { _customBgColor = (Color)ColorConverter.ConvertFromString(BgHexInput.Text); ActiveBgIndicator.Fill = new SolidColorBrush(_customBgColor); ApplyTheme(); } catch { } }
        
        private void GridToggle_Click(object sender, RoutedEventArgs e) 
        { 
            _gridPattern = (_gridPattern + 1) % 4; 
            ApplyTheme(); 
        }

        private void LaserDelayInput_TextChanged(object sender, TextChangedEventArgs e) { if (!_appLoaded) return; if (double.TryParse(LaserDelayInput.Text, out double val)) _laserFadeDelay = val; }

        private void Theme_Click(object sender, RoutedEventArgs e)
        {
            _isDarkTheme = !_isDarkTheme;
            if (_isDarkTheme) { BgHexInput.Text = "#15171B"; } else { BgHexInput.Text = "#FFFFFF"; }
            ApplyTheme(); UpdateCustomCursorAppearance();
        }

        private void ApplyTheme()
        {
            if (_isDarkTheme)
            {
                Resources["BgPrimary"] = new SolidColorBrush(Colors.Black); 
                Resources["BgToolbar"] = new SolidColorBrush(Color.FromRgb(21, 23, 27)); 
                Resources["BorderToolbar"] = new SolidColorBrush(Color.FromRgb(42, 45, 53)); 
                Resources["TextPrimary"] = new SolidColorBrush(Color.FromRgb(248, 250, 252));
                Resources["TextSecondary"] = new SolidColorBrush(Color.FromRgb(161, 161, 170));
                Resources["ButtonHoverBg"] = new SolidColorBrush(Color.FromRgb(37, 40, 45));
                Resources["ButtonHoverText"] = new SolidColorBrush(Colors.White);
                if (A4GuideContainer != null && A4GuideContainer.Children.Count > 0) ((Rectangle)A4GuideContainer.Children[0]).Stroke = new SolidColorBrush(Color.FromArgb(80, 255, 255, 255));
            }
            else
            {
                Resources["BgPrimary"] = new SolidColorBrush(Color.FromRgb(243, 244, 246));
                Resources["BgToolbar"] = new SolidColorBrush(Colors.White);
                Resources["BorderToolbar"] = new SolidColorBrush(Color.FromRgb(229, 231, 235));
                Resources["TextPrimary"] = new SolidColorBrush(Colors.Black); 
                Resources["TextSecondary"] = new SolidColorBrush(Color.FromRgb(75, 85, 99)); 
                Resources["ButtonHoverBg"] = new SolidColorBrush(Color.FromRgb(243, 244, 246));
                Resources["ButtonHoverText"] = new SolidColorBrush(Colors.Black);
                if (A4GuideContainer != null && A4GuideContainer.Children.Count > 0) ((Rectangle)A4GuideContainer.Children[0]).Stroke = new SolidColorBrush(Color.FromArgb(80, 0, 0, 0));
            }

            if (_activeTab != null && string.IsNullOrEmpty(_activeTab.PdfFilePath))
            {
                Color lineColor = _isDarkTheme ? Color.FromRgb(42, 45, 53) : Color.FromRgb(209, 213, 219);
                Workspace.Background = CreateGridBrush(_customBgColor, lineColor);
            }
            else Workspace.Background = new SolidColorBrush(Colors.Transparent);
        }

        private DrawingBrush CreateGridBrush(Color bgColor, Color lineColor)
        {
            DrawingGroup mainGroup = new DrawingGroup();
            mainGroup.Children.Add(new GeometryDrawing { Brush = new SolidColorBrush(bgColor), Geometry = new RectangleGeometry(new Rect(0, 0, 100, 100)) });

            if (_gridPattern == 1) 
            {
                Color minorColor = Color.FromArgb(100, lineColor.R, lineColor.G, lineColor.B);
                Pen minorPen = new Pen(new SolidColorBrush(minorColor), 0.5);
                Pen majorPen = new Pen(new SolidColorBrush(lineColor), 1.5);

                GeometryGroup minorGroup = new GeometryGroup();
                for (int i = 20; i < 100; i += 20)
                {
                    minorGroup.Children.Add(new LineGeometry(new Point(i, 0), new Point(i, 100)));
                    minorGroup.Children.Add(new LineGeometry(new Point(0, i), new Point(100, i)));
                }
                mainGroup.Children.Add(new GeometryDrawing { Pen = minorPen, Geometry = minorGroup });

                GeometryGroup majorGroup = new GeometryGroup();
                majorGroup.Children.Add(new LineGeometry(new Point(0, 0), new Point(0, 100)));
                majorGroup.Children.Add(new LineGeometry(new Point(0, 0), new Point(100, 0)));
                mainGroup.Children.Add(new GeometryDrawing { Pen = majorPen, Geometry = majorGroup });

                return new DrawingBrush { TileMode = TileMode.Tile, Viewport = new Rect(0, 0, 100, 100), ViewportUnits = BrushMappingMode.Absolute, Drawing = mainGroup };
            }
            else if (_gridPattern == 2) 
            {
                mainGroup.Children.Add(new GeometryDrawing { Brush = new SolidColorBrush(lineColor), Geometry = new EllipseGeometry(new Point(20, 20), 1.5, 1.5) });
                return new DrawingBrush { TileMode = TileMode.Tile, Viewport = new Rect(0, 0, 40, 40), ViewportUnits = BrushMappingMode.Absolute, Drawing = mainGroup };
            }
            else if (_gridPattern == 3) 
            {
                GeometryGroup ruledGroup = new GeometryGroup();
                ruledGroup.Children.Add(new LineGeometry(new Point(0, 40), new Point(40, 40)));
                mainGroup.Children.Add(new GeometryDrawing { Pen = new Pen(new SolidColorBrush(lineColor), 1.0), Geometry = ruledGroup });
                return new DrawingBrush { TileMode = TileMode.Tile, Viewport = new Rect(0, 0, 40, 40), ViewportUnits = BrushMappingMode.Absolute, Drawing = mainGroup };
            }
            
            return new DrawingBrush { TileMode = TileMode.Tile, Viewport = new Rect(0, 0, 100, 100), ViewportUnits = BrushMappingMode.Absolute, Drawing = mainGroup };
        }

        private void UpdatePageUI() { if (_activeTab == null) return; PageCounterText.Text = $"{_activeTab.CurrentPage}/{_activeTab.TotalPages}"; }
        private void SaveCurrentPage() { if (_activeTab == null) return; _activeTab.StrokesPerPage[_activeTab.CurrentPage] = MainInkCanvas.Strokes.Clone(); }
        
        private async void LoadPage(int page)
        {
            if (_activeTab == null) return;

            if (!string.IsNullOrEmpty(_activeTab.PdfFilePath))
            {
                await RenderSinglePdfPage(_activeTab.PdfFilePath, page);
            }

            if (_activeTab.StrokesPerPage.ContainsKey(page)) MainInkCanvas.Strokes = _activeTab.StrokesPerPage[page].Clone();
            else MainInkCanvas.Strokes.Clear();
            _undoStack.Clear(); _redoStack.Clear(); LaserInkCanvas.Strokes.Clear(); _laserStrokes.Clear();
        }

        private void PrevPage_Click(object sender, RoutedEventArgs e) 
        { 
            if (_activeTab != null && _activeTab.CurrentPage > 1) { 
                SaveCurrentPage(); _activeTab.CurrentPage--; LoadPage(_activeTab.CurrentPage); UpdatePageUI(); 
            } 
        }

        private void NextPage_Click(object sender, RoutedEventArgs e) 
        { 
            if (_activeTab != null && _activeTab.CurrentPage < _activeTab.TotalPages) { 
                SaveCurrentPage(); _activeTab.CurrentPage++; LoadPage(_activeTab.CurrentPage); UpdatePageUI(); 
            } 
        }

        private void AddPage_Click(object sender, RoutedEventArgs e) { if (_activeTab == null || !string.IsNullOrEmpty(_activeTab.PdfFilePath)) return; SaveCurrentPage(); _activeTab.TotalPages++; _activeTab.CurrentPage = _activeTab.TotalPages; LoadPage(_activeTab.CurrentPage); UpdatePageUI(); }
        
        private void DeletePage_Click(object sender, RoutedEventArgs e)
        {
            if (_activeTab == null || !string.IsNullOrEmpty(_activeTab.PdfFilePath) || _activeTab.TotalPages <= 1) return;
            SaveCurrentPage(); _activeTab.StrokesPerPage.Remove(_activeTab.CurrentPage);
            for (int i = _activeTab.CurrentPage + 1; i <= _activeTab.TotalPages; i++) { if (_activeTab.StrokesPerPage.ContainsKey(i)) { _activeTab.StrokesPerPage[i - 1] = _activeTab.StrokesPerPage[i]; _activeTab.StrokesPerPage.Remove(i); } }
            _activeTab.TotalPages--; if (_activeTab.CurrentPage > _activeTab.TotalPages) _activeTab.CurrentPage = _activeTab.TotalPages;
            LoadPage(_activeTab.CurrentPage); UpdatePageUI();
        }

        private void SaveUndoState() { if (_isUpdatingUI) return; _undoStack.Push(MainInkCanvas.Strokes.Clone()); _redoStack.Clear(); }
        private void PerformUndo() { if (_undoStack.Count > 0) { _isUpdatingUI = true; _redoStack.Push(MainInkCanvas.Strokes.Clone()); MainInkCanvas.Strokes = _undoStack.Pop(); _isUpdatingUI = false; } }
        private void PerformRedo() { if (_redoStack.Count > 0) { _isUpdatingUI = true; _undoStack.Push(MainInkCanvas.Strokes.Clone()); MainInkCanvas.Strokes = _redoStack.Pop(); _isUpdatingUI = false; } }

        private void MainInkCanvas_PreviewMouseLeftButtonDown(object sender, MouseButtonEventArgs e) { if (MainInkCanvas.EditingMode != InkCanvasEditingMode.None && MainInkCanvas.EditingMode != InkCanvasEditingMode.Select) SaveUndoState(); }

        private void PerformZoom(double zoomDelta, Point? mousePos = null)
        {
            double newZoom = Math.Max(0.25, Math.Min(_zoom + zoomDelta, 10.0));
            if (newZoom == _zoom) return;

            Point targetPos = mousePos.HasValue ? mousePos.Value : new Point(MainScroll.ViewportWidth / 2, MainScroll.ViewportHeight / 2);
            Point pointInCanvas = MainScroll.TranslatePoint(targetPos, Workspace);

            _zoom = newZoom;
            ZoomTransform.ScaleX = _zoom; ZoomTransform.ScaleY = _zoom;

            Workspace.UpdateLayout();
            MainScroll.ScrollToHorizontalOffset(pointInCanvas.X * _zoom - targetPos.X);
            MainScroll.ScrollToVerticalOffset(pointInCanvas.Y * _zoom - targetPos.Y);
        }

        private void MainScroll_PreviewMouseWheel(object sender, MouseWheelEventArgs e) 
        { 
            e.Handled = true; 
            if (Keyboard.Modifiers == ModifierKeys.Control) 
            { 
                double delta = e.Delta > 0 ? 0.15 : -0.15; 
                PerformZoom(delta, e.GetPosition(MainScroll)); 
            } 
            else 
            { 
                double sf = 0.3; 
                if (Keyboard.Modifiers == ModifierKeys.Shift) MainScroll.ScrollToHorizontalOffset(MainScroll.HorizontalOffset - (e.Delta * sf)); 
                else MainScroll.ScrollToVerticalOffset(MainScroll.VerticalOffset - (e.Delta * sf)); 
            } 
        }

        private void Window_KeyDown(object sender, KeyEventArgs e)
        {
            if ((Keyboard.Modifiers & ModifierKeys.Alt) == ModifierKeys.Alt)
            {
                if (e.SystemKey == Key.Z) { int idx = _tabs.IndexOf(_activeTab) - 1; if (idx < 0) idx = _tabs.Count - 1; SwitchToTab(_tabs[idx]); e.Handled = true; return; }
                if (e.SystemKey == Key.X) { int idx = (_tabs.IndexOf(_activeTab) + 1) % _tabs.Count; SwitchToTab(_tabs[idx]); e.Handled = true; return; }
            }

            if (Keyboard.Modifiers == ModifierKeys.Control) { if (e.Key == Key.Z) { PerformUndo(); return; } if (e.Key == Key.Y) { PerformRedo(); return; } }
            if (e.Key == Key.Delete) { var s = MainInkCanvas.GetSelectedStrokes(); if (s.Count > 0) { SaveUndoState(); MainInkCanvas.Strokes.Remove(s); return; } }
            if (SizeInput.IsFocused || HexInput.IsFocused || BgHexInput.IsFocused || LaserDelayInput.IsFocused || LaserGlowInput.IsFocused) return;
            
            if (e.Key == Key.Escape) { PointerBtn.IsChecked = true; return; }
            if (e.Key == Key.H) MainToolbar.Visibility = MainToolbar.Visibility == Visibility.Visible ? Visibility.Collapsed : Visibility.Visible;
            if (e.Key == Key.F) { ToggleFullScreen(); return; }
            if (e.Key == Key.G) { GridToggle_Click(null, null); return; }
            if (e.Key == Key.T) { Theme_Click(this, new RoutedEventArgs()); return; }
            if (e.Key == Key.OemComma) SizeSlider.Value = Math.Max(SizeSlider.Minimum, SizeSlider.Value - 1.0);
            if (e.Key == Key.OemPeriod) SizeSlider.Value = Math.Min(SizeSlider.Maximum, SizeSlider.Value + 1.0);
            if (e.Key == Key.P) PenBtn.IsChecked = true; else if (e.Key == Key.M) HighlightBtn.IsChecked = true; else if (e.Key == Key.E) EraserBtn.IsChecked = true; else if (e.Key == Key.S) SelectBtn.IsChecked = true; else if (e.Key == Key.L) LaserBtn.IsChecked = true;
        }

        private void Tool_Checked(object sender, RoutedEventArgs e) { if (!_appLoaded || _isUpdatingUI || MainInkCanvas == null) return; SyncToolToUI(); }
        private void SyncToolToUI() { _isUpdatingUI = true; if (PenBtn.IsChecked == true) { SizeSlider.Value = _penSize; HexInput.Text = _penColor.ToString(); } else if (HighlightBtn.IsChecked == true) { SizeSlider.Value = _highlightSize; HexInput.Text = _highlightColor.ToString(); } else if (LaserBtn.IsChecked == true) { SizeSlider.Value = _laserSize; HexInput.Text = _laserColor.ToString(); } _isUpdatingUI = false; ApplyPenAttributes(); }
        private void Size_Changed(object sender, RoutedPropertyChangedEventArgs<double> e) { if (!_appLoaded || _isUpdatingUI) return; double s = SizeSlider.Value; if (PenBtn.IsChecked == true) _penSize = s; else if (HighlightBtn.IsChecked == true) _highlightSize = s; else if (LaserBtn.IsChecked == true) _laserSize = s; ApplyPenAttributes(); }
        private void Pressure_Changed(object sender, RoutedEventArgs e) { if (!_appLoaded) return; ApplyPenAttributes(); }
        private void EraserMode_Changed(object sender, RoutedEventArgs e) { if (!_appLoaded) return; ApplyPenAttributes(); }

        private void ApplyPenAttributes()
        {
            if (MainInkCanvas == null || LaserInkCanvas == null || ActiveColorIndicator == null || SizeSlider == null || LaserGlowSlider == null) return;
            bool ignorePressure = PressureToggle.IsChecked == false; Color activeColor = ((SolidColorBrush)ActiveColorIndicator.Fill).Color; double activeSize = SizeSlider.Value;

            if (PointerBtn.IsChecked == true)
            {
                MainInkCanvas.IsHitTestVisible = true; LaserInkCanvas.IsHitTestVisible = false;
                MainInkCanvas.EditingMode = InkCanvasEditingMode.None;
            }
            else if (LaserBtn.IsChecked == true)
            {
                MainInkCanvas.IsHitTestVisible = false; LaserInkCanvas.IsHitTestVisible = true; LaserInkCanvas.EditingMode = InkCanvasEditingMode.Ink;
                LaserInkCanvas.DefaultDrawingAttributes = new DrawingAttributes { Color = _laserCoreColor, Width = activeSize, Height = activeSize, FitToCurve = true, IgnorePressure = true, StylusTip = StylusTip.Ellipse };
                LaserInkCanvas.Effect = new System.Windows.Media.Effects.DropShadowEffect { Color = activeColor, BlurRadius = LaserGlowSlider.Value, ShadowDepth = 0, Opacity = 1.0 };
            }
            else
            {
                MainInkCanvas.IsHitTestVisible = true; LaserInkCanvas.IsHitTestVisible = false;
                if (PenBtn.IsChecked == true) { MainInkCanvas.EditingMode = InkCanvasEditingMode.Ink; MainInkCanvas.DefaultDrawingAttributes = new DrawingAttributes { Color = activeColor, Width = activeSize, Height = activeSize, FitToCurve = true, IgnorePressure = ignorePressure, StylusTip = StylusTip.Ellipse }; }
                else if (HighlightBtn.IsChecked == true) { MainInkCanvas.EditingMode = InkCanvasEditingMode.Ink; MainInkCanvas.DefaultDrawingAttributes = new DrawingAttributes { Color = Color.FromArgb(120, activeColor.R, activeColor.G, activeColor.B), Width = activeSize * 4, Height = activeSize * 4, StylusTip = StylusTip.Ellipse, IsHighlighter = true, IgnorePressure = true }; }
                else if (EraserBtn.IsChecked == true) { if (StrokeEraserToggle.IsChecked == true) MainInkCanvas.EditingMode = InkCanvasEditingMode.EraseByStroke; else { MainInkCanvas.EditingMode = InkCanvasEditingMode.EraseByPoint; MainInkCanvas.EraserShape = new EllipseStylusShape(activeSize * 4, activeSize * 4); } }
                else if (SelectBtn.IsChecked == true) MainInkCanvas.EditingMode = InkCanvasEditingMode.Select; 
            }
            UpdateCustomCursorAppearance();
        }

        private void UpdateCustomCursorAppearance()
        {
            if (SelectBtn.IsChecked == true || PointerBtn.IsChecked == true) { CustomDotCursor.Visibility = Visibility.Hidden; return; }
            double size = SizeSlider.Value; Color c = ((SolidColorBrush)ActiveColorIndicator.Fill).Color;
            if (HighlightBtn.IsChecked == true) { size *= 4; c = Color.FromArgb(120, c.R, c.G, c.B); }
            
            if (LaserBtn.IsChecked == true) { CustomDotCursor.Fill = new SolidColorBrush(_laserCoreColor); CustomDotCursor.StrokeThickness = 0; CursorGlow.Color = c; CursorGlow.Opacity = 1.0; CursorGlow.BlurRadius = LaserGlowSlider.Value; CursorGlow.ShadowDepth = 0; } 
            else if (EraserBtn.IsChecked == true) { if (StrokeEraserToggle.IsChecked == true) size = 20; else size *= 4; CustomDotCursor.StrokeThickness = 1; CustomDotCursor.Stroke = new SolidColorBrush(Colors.Black); CustomDotCursor.Fill = new SolidColorBrush(Color.FromArgb(100, 255, 255, 255)); CursorGlow.Opacity = 0.0; } 
            else { CustomDotCursor.StrokeThickness = 0; CustomDotCursor.Fill = new SolidColorBrush(Color.FromArgb(150, c.R, c.G, c.B)); CursorGlow.Color = Colors.Black; CursorGlow.Opacity = 0.5; CursorGlow.BlurRadius = 4; CursorGlow.ShadowDepth = 1; }
            CustomDotCursor.Width = size; CustomDotCursor.Height = size;
        }

        private void MainInkCanvas_MouseMove(object sender, MouseEventArgs e)
        {
            if (SelectBtn.IsChecked == true || PointerBtn.IsChecked == true) return;
            CustomDotCursor.Visibility = Visibility.Visible; Point p = e.GetPosition(CursorCanvas); Canvas.SetLeft(CustomDotCursor, p.X - (CustomDotCursor.Width / 2)); Canvas.SetTop(CustomDotCursor, p.Y - (CustomDotCursor.Height / 2));
        }

        private void MainInkCanvas_MouseLeave(object sender, MouseEventArgs e) => CustomDotCursor.Visibility = Visibility.Hidden;
        private void MainInkCanvas_MouseEnter(object sender, MouseEventArgs e) { if (SelectBtn.IsChecked != true && PointerBtn.IsChecked != true) CustomDotCursor.Visibility = Visibility.Visible; }

        private void LaserTimer_Tick(object sender, EventArgs e)
        {
            if (Mouse.LeftButton == MouseButtonState.Pressed && LaserBtn.IsChecked == true)
            {
                _lastLaserActivityTime = DateTime.Now;
            }

            if (_laserStrokes.Count == 0) return;
            bool isInactive = (DateTime.Now - _lastLaserActivityTime).TotalSeconds > _laserFadeDelay;

            for (int i = _laserStrokes.Count - 1; i >= 0; i--)
            {
                var ls = _laserStrokes[i];
                if (isInactive)
                {
                    ls.Life -= 15; 
                    if (ls.Life <= 0) { _isUpdatingUI = true; LaserInkCanvas.Strokes.Remove(ls.Stroke); _laserStrokes.RemoveAt(i); _isUpdatingUI = false; }
                    else ls.Stroke.DrawingAttributes.Color = Color.FromArgb((byte)Math.Max(0, ls.Life), _laserCoreColor.R, _laserCoreColor.G, _laserCoreColor.B);
                }
                else { if (ls.Life < 255) { ls.Life = 255; ls.Stroke.DrawingAttributes.Color = Color.FromArgb(255, _laserCoreColor.R, _laserCoreColor.G, _laserCoreColor.B); } }
            }
        }

        private async void OpenPdf_Click(object sender, RoutedEventArgs e)
        {
            OpenFileDialog dlg = new OpenFileDialog { Filter = "PDF Files (*.pdf)|*.pdf" };
            if (dlg.ShowDialog() == true)
            {
                if (!string.IsNullOrEmpty(_activeTab.PdfFilePath) || _activeTab.StrokesPerPage.Any(x => x.Value.Count > 0))
                {
                    var newTab = new WorkspaceTab { Title = System.IO.Path.GetFileName(dlg.FileName), PdfFilePath = dlg.FileName };
                    _tabs.Add(newTab); SwitchToTab(newTab);
                }
                else { _activeTab.Title = System.IO.Path.GetFileName(dlg.FileName); _activeTab.PdfFilePath = dlg.FileName; SwitchToTab(_activeTab); }
            }
        }

        private void ExportAnnotated_Click(object sender, RoutedEventArgs e)
        {
            MessageBoxResult exportType = MessageBox.Show("Do you want to include your ink annotations in the exported PDF?\n\nYes = Export Annotated PDF\nNo = Export Clean Original Document/Grid", "Export Options", MessageBoxButton.YesNoCancel, MessageBoxImage.Question);
            if (exportType == MessageBoxResult.Cancel) return;
            bool exportAnnotations = (exportType == MessageBoxResult.Yes);

            if (string.IsNullOrEmpty(_activeTab.PdfFilePath)) 
            { 
                SaveFileDialog wbdlg = new SaveFileDialog { Filter = "PDF (*.pdf)|*.pdf", FileName = "Anydraw_Whiteboard.pdf" };
                if (wbdlg.ShowDialog() == true)
                {
                    try
                    {
                        SaveCurrentPage();
                        PdfSharp.Pdf.PdfDocument wbDoc = new PdfSharp.Pdf.PdfDocument();
                        XColor bgColor = XColor.FromArgb(255, _customBgColor.R, _customBgColor.G, _customBgColor.B);
                        XColor gridColor = _isDarkTheme ? XColor.FromArgb(255, 42, 45, 53) : XColor.FromArgb(255, 209, 213, 219);
                        XColor minorGridColor = XColor.FromArgb(100, gridColor.R, gridColor.G, gridColor.B);

                        for (int i = 1; i <= _activeTab.TotalPages; i++)
                        {
                            StrokeCollection pageStrokes = (i == _activeTab.CurrentPage) ? MainInkCanvas.Strokes : (_activeTab.StrokesPerPage.ContainsKey(i) ? _activeTab.StrokesPerPage[i] : new StrokeCollection());
                            
                            double actualW = 1123; 
                            double actualH = 794;  
                            double originX = A4GuideContainer.Margin.Left;
                            double originY = A4GuideContainer.Margin.Top;
                            
                            Rect inkBounds = Rect.Empty;
                            foreach (Stroke s in pageStrokes) { inkBounds.Union(s.GetBounds()); }
                            
                            double minX = originX;
                            double minY = originY;
                            double maxX = originX + actualW;
                            double maxY = originY + actualH;

                            if (inkBounds != Rect.Empty) {
                                minX = Math.Min(originX, inkBounds.Left - 50);
                                minY = Math.Min(originY, inkBounds.Top - 50);
                                maxX = Math.Max(originX + actualW, inkBounds.Right + 50);
                                maxY = Math.Max(originY + actualH, inkBounds.Bottom + 50);
                            }

                            actualW = maxX - minX;
                            actualH = maxY - minY;

                            PdfSharp.Pdf.PdfPage wbPage = wbDoc.AddPage(); 
                            wbPage.Width = XUnit.FromPresentation(actualW); 
                            wbPage.Height = XUnit.FromPresentation(actualH);
                            XGraphics gfx = XGraphics.FromPdfPage(wbPage);
                            gfx.ScaleTransform(72.0 / 96.0, 72.0 / 96.0); 

                            gfx.DrawRectangle(new XSolidBrush(bgColor), 0, 0, actualW, actualH);
                            
                            if (_gridPattern == 1) {
                                XPen minorPen = new XPen(minorGridColor, 0.5); XPen majorPen = new XPen(gridColor, 1.5);
                                for (double x = 0; x < actualW; x += 20) { XPen p = (x % 100 == 0) ? majorPen : minorPen; gfx.DrawLine(p, x, 0, x, actualH); }
                                for (double y = 0; y < actualH; y += 20) { XPen p = (y % 100 == 0) ? majorPen : minorPen; gfx.DrawLine(p, 0, y, actualW, y); }
                            } else if (_gridPattern == 2) {
                                XSolidBrush dotBrush = new XSolidBrush(gridColor);
                                for (double x = 20; x < actualW; x += 40) for (double y = 20; y < actualH; y += 40) gfx.DrawEllipse(dotBrush, x - 1.5, y - 1.5, 3, 3);
                            } else if (_gridPattern == 3) {
                                XPen gridPen = new XPen(gridColor, 1.0);
                                for (double y = 40; y < actualH; y += 40) gfx.DrawLine(gridPen, 0, y, actualW, y);
                            }

                            if (exportAnnotations)
                            {
                                foreach (Stroke stroke in pageStrokes)
                                {
                                    XColor color = XColor.FromArgb(stroke.DrawingAttributes.Color.A, stroke.DrawingAttributes.Color.R, stroke.DrawingAttributes.Color.G, stroke.DrawingAttributes.Color.B);
                                    double baseThickness = stroke.DrawingAttributes.Width;
                                    StylusPointCollection points = stroke.StylusPoints;

                                    if (points.Count > 1)
                                    {
                                        if (stroke.DrawingAttributes.IsHighlighter || stroke.DrawingAttributes.IgnorePressure)
                                        {
                                            XGraphicsPath path = new XGraphicsPath(); XPoint[] xPoints = new XPoint[points.Count];
                                            for (int j = 0; j < points.Count; j++) { xPoints[j] = new XPoint(points[j].X - minX, points[j].Y - minY); }
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
                                                XPen segmentPen = new XPen(color, baseThickness * (p1.PressureFactor * 2.0)) { LineCap = XLineCap.Round };
                                                gfx.DrawLine(segmentPen, p1.X - minX, p1.Y - minY, p2.X - minX, p2.Y - minY);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        wbDoc.Save(wbdlg.FileName); MessageBox.Show("Anydraw Whiteboard Exported!");
                    }
                    catch (Exception ex) { MessageBox.Show("Export failed: " + ex.Message); }
                }
                return;
            }

            SaveFileDialog annotatedDlg = new SaveFileDialog { Filter = "PDF (*.pdf)|*.pdf", FileName = exportAnnotations ? "Anydraw_Annotated_Document.pdf" : "Anydraw_Clean_Document.pdf" };
            if (annotatedDlg.ShowDialog() == true)
            {
                try
                {
                    PdfSharp.Pdf.PdfDocument document = PdfReader.Open(_activeTab.PdfFilePath, PdfDocumentOpenMode.Modify);
                    if (exportAnnotations)
                    {
                        double workspaceWidth = Workspace.Width;
                        for (int i = 0; i < document.Pages.Count; i++)
                        {
                            if (i >= _activeTab.PdfRenderedPages.Count) break;
                            PdfSharp.Pdf.PdfPage pdfPage = document.Pages[i]; XGraphics gfx = XGraphics.FromPdfPage(pdfPage); PdfPageModel uiPage = _activeTab.PdfRenderedPages[i];
                            
                            double scaleX = pdfPage.Width.Point / uiPage.Width; 
                            double scaleY = pdfPage.Height.Point / uiPage.Height;
                            double offsetX = (workspaceWidth - uiPage.Width) / 2.0;

                            StrokeCollection pageStrokes = (i + 1 == _activeTab.CurrentPage) ? MainInkCanvas.Strokes : (_activeTab.StrokesPerPage.ContainsKey(i + 1) ? _activeTab.StrokesPerPage[i + 1] : new StrokeCollection());

                            foreach (Stroke stroke in pageStrokes)
                            {
                                XColor color = XColor.FromArgb(stroke.DrawingAttributes.Color.A, stroke.DrawingAttributes.Color.R, stroke.DrawingAttributes.Color.G, stroke.DrawingAttributes.Color.B);
                                double baseThickness = stroke.DrawingAttributes.Width * scaleX;
                                StylusPointCollection points = stroke.StylusPoints;

                                if (points.Count > 1)
                                {
                                    if (stroke.DrawingAttributes.IsHighlighter || stroke.DrawingAttributes.IgnorePressure)
                                    {
                                        XGraphicsPath path = new XGraphicsPath(); XPoint[] xPoints = new XPoint[points.Count];
                                        for (int j = 0; j < points.Count; j++) { xPoints[j] = new XPoint((points[j].X - offsetX) * scaleX, points[j].Y * scaleY); }
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
                                            XPen segmentPen = new XPen(color, baseThickness * (p1.PressureFactor * 2.0)) { LineCap = XLineCap.Round };
                                            gfx.DrawLine(segmentPen, (p1.X - offsetX) * scaleX, p1.Y * scaleY, (p2.X - offsetX) * scaleX, p2.Y * scaleY);
                                        }
                                    }
                                }
                            }
                        }
                    }
                    document.Save(annotatedDlg.FileName); MessageBox.Show("Vector PDF Exported Successfully!");
                }
                catch (Exception ex) { MessageBox.Show("Export failed: " + ex.Message); }
            }
        }

        private void ClearInk_Click(object sender, RoutedEventArgs e) { SaveUndoState(); MainInkCanvas.Strokes.Clear(); LaserInkCanvas.Strokes.Clear(); }
        private void PerformZoomIn() { _zoom += 0.25; ZoomTransform.ScaleX = _zoom; ZoomTransform.ScaleY = _zoom; }
        private void PerformZoomOut() { _zoom = Math.Max(0.25, _zoom - 0.25); ZoomTransform.ScaleX = _zoom; ZoomTransform.ScaleY = _zoom; }
    }
}
EOF

echo "✅ App Polished to Absolute Perfection! Ready for zero-error execution."
