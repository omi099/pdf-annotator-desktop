name: Build Apex Annotator (Platinum)

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

      # 🔥 THE ARCHITECT'S FIX: Inject NuGet Caching
      # This skips downloading the heavy libraries on every push, saving massive amounts of time.
      - name: Cache NuGet Packages
        uses: actions/cache@v4
        with:
          path: ~/.nuget/packages
          key: ${{ runner.os }}-nuget-v1
          restore-keys: |
            ${{ runner.os }}-nuget-

      - name: Generate Codebase
        shell: bash
        run: |
          chmod +x generate_wpf_app.sh
          ./generate_wpf_app.sh

      - name: Compile Application to Hardcoded Folder
        working-directory: ./TeachingAnnotator
        run: >
          dotnet publish 
          -c Release 
          -r win-x64 
          --self-contained true 
          -o ./Final_Build

      - name: Upload Application Folder
        uses: actions/upload-artifact@v4
        with:
          name: Apex-Teaching-Annotator-Platinum
          path: TeachingAnnotator/Final_Build/
