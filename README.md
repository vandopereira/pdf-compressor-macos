# PDF Compressor macOS

A native macOS desktop app for compressing PDF files toward a target size in MB.

The app only processes files that are larger than the selected target. PDFs that are already at or below the target are marked as skipped and left untouched.

## Features

- Batch PDF compression
- Target size control in MB
- Drag and drop or file picker input
- Optional output folder selection
- Per-file progress and status
- Concurrent background processing with a bounded worker count
- Native SwiftUI macOS interface

## How It Works

PDF Compressor uses PDFKit and CoreGraphics to render compressed PDF outputs through multiple quality profiles. The app starts with higher-quality attempts and progressively reduces quality only when needed to approach the selected target size.

The compressor preserves the original page aspect ratio when rendering pages.

## Important Limitation

The current compression strategy rasterizes pages. This can greatly reduce image-heavy PDFs, but text and vector content may no longer remain selectable in the compressed output.

## Requirements

- macOS 14 or newer
- Xcode command line tools
- Swift 6 toolchain

## Build

```bash
swift build
```

## Test

```bash
swift test
```

## Run

```bash
./script/build_and_run.sh
```

The script builds the SwiftPM executable, stages a local `.app` bundle under `dist/`, and launches it as a regular macOS app.

## Development

Project structure:

- `Sources/PDFCompressorApp`: SwiftUI desktop app
- `Sources/PDFCompressorCore`: compression logic, planning, formatting, and helpers
- `Tests/PDFCompressorCoreTests`: core behavior tests
- `script/build_and_run.sh`: local build and launch script

## Repository

GitHub: [vandopereira/pdf-compressor-macos](https://github.com/vandopereira/pdf-compressor-macos)
