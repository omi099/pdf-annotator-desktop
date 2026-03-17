name: Build Teaching PDF Annotator (Windows)

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

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Setup Rust
        uses: dtolnay/rust-toolchain@stable
        with:
          targets: x86_64-pc-windows-msvc

      # 1. GENERATE FIRST: We must create the files before we can cache them!
      - name: Run Bash Generator Script
        shell: bash
        run: |
          chmod +x generate_app.sh
          ./generate_app.sh

      # 2. CACHE NPM: Saves all your Node modules
      - name: Cache NPM dependencies
        uses: actions/cache@v4
        with:
          path: ~/.npm
          key: ${{ runner.os }}-node-${{ hashFiles('annotator-app/package-lock.json') }}
          restore-keys: |
            ${{ runner.os }}-node-

      # 3. CACHE RUST/TAURI: Saves the heavy backend compilation
      - name: Cache Rust / Cargo Registry
        uses: Swatinem/rust-cache@v2
        with:
          workspaces: "annotator-app/src-tauri -> target"

      # 4. INSTALL (Fast, uses cache)
      - name: Install NPM Dependencies
        working-directory: ./annotator-app
        run: npm install

      # 5. BUILD (Fast, uses NPM's Tauri CLI instead of Cargo's)
      - name: Build Tauri App
        working-directory: ./annotator-app
        run: npx tauri build

      # 6. UPLOAD
      - name: Upload Windows Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: Teaching-Annotator-Windows
          path: |
            annotator-app/src-tauri/target/release/bundle/msi/*.msi
            annotator-app/src-tauri/target/release/bundle/nsis/*.exe
