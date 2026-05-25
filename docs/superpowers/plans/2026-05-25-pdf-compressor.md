# PDF Compressor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS PDF compressor app with target-MB batch compression and responsive concurrent processing.

**Architecture:** Create a SwiftPM package with a SwiftUI executable and a reusable `PDFCompressorCore` library. Keep compression planning, output naming, size formatting, and concurrency policy in the core module so they are unit tested separately from the UI.

**Tech Stack:** Swift 6-style SwiftPM, SwiftUI, AppKit, PDFKit, CoreGraphics, XCTest.

---

### Task 1: Core Rules

**Files:**
- Create: `Package.swift`
- Create: `Sources/PDFCompressorCore/Models/CompressionModels.swift`
- Create: `Sources/PDFCompressorCore/Services/CompressionPlanner.swift`
- Create: `Sources/PDFCompressorCore/Support/FileSizeFormatter.swift`
- Test: `Tests/PDFCompressorCoreTests/CompressionPlannerTests.swift`

- [ ] Write failing tests for skip behavior, compression decision, worker limit, and output URL suffixing.
- [ ] Run `swift test` and confirm the tests fail because the module does not exist yet.
- [ ] Implement the package and minimal core types.
- [ ] Run `swift test` and confirm the core tests pass.

### Task 2: Compression Service

**Files:**
- Create: `Sources/PDFCompressorCore/Services/PDFCompressionService.swift`
- Test: extend `Tests/PDFCompressorCoreTests/CompressionPlannerTests.swift`

- [ ] Add a service that skips files at or under target size.
- [ ] Add iterative raster compression attempts for larger PDFs using PDFKit and CoreGraphics.
- [ ] Return structured results with skipped, compressed, and failed outcomes.
- [ ] Run `swift test`.

### Task 3: Desktop UI

**Files:**
- Create: `Sources/PDFCompressorApp/App/PDFCompressorApp.swift`
- Create: `Sources/PDFCompressorApp/Stores/CompressionQueueStore.swift`
- Create: `Sources/PDFCompressorApp/Views/ContentView.swift`
- Create: `Sources/PDFCompressorApp/Views/FileQueueView.swift`
- Create: `Sources/PDFCompressorApp/Views/ControlPanelView.swift`

- [ ] Build a native macOS window with queue, controls, and progress.
- [ ] Support file picking, drag and drop, row removal, and batch processing.
- [ ] Keep compression work asynchronous and bounded.

### Task 4: Run Loop

**Files:**
- Create: `script/build_and_run.sh`
- Create: `.codex/environments/environment.toml`

- [ ] Add a project-local build/run script that builds, bundles, and launches the SwiftUI app.
- [ ] Wire the Codex Run action to the script.
- [ ] Run `swift test`, `swift build`, and the script verify mode.
