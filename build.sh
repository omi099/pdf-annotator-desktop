name: Build Apex Annotator (WPF)

on:
  push:
    branches: [ "main" ]
  workflow_dispatch:

jobs:
  build-windows:
    runs-on: windows-latest

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Setup .NET 8.0
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '8.0.x'

      - name: Generate Codebase
        shell: bash
        run: |
          chmod +x generate_wpf_app.sh
          ./generate_wpf_app.sh

      - name: Compile Native Application Folder
        working-directory: ./TeachingAnnotator
        # -r win-x64 targeting 64-bit PCs natively
        # --self-contained true ensures no external .NET installations are required
        run: >
          dotnet publish 
          -c Release 
          -r win-x64 
          --self-contained true

      - name: Upload Application Folder
        uses: actions/upload-artifact@v4
        with:
          name: Apex-Teaching-Annotator
          # Uploads the entire folder containing the .exe and its native rendering libraries
          path: TeachingAnnotator/bin/Release/net8.0-windows10.0.19041.0/win-x64/publish/
