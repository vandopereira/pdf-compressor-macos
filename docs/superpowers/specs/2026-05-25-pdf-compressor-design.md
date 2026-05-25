# PDF Compressor Desktop App Design

## Goal
Build a native macOS desktop app that compresses one or many PDF files toward a user-selected target size in MB, applying compression only when a file is larger than the target.

## Users
The app is for people who need to shrink PDFs for upload limits, email attachments, portals, and administrative workflows. They need quick batch processing, clear status, and confidence that already-small files are not modified.

## UX
The first screen is the working app: a file queue, a target MB control, output location, and a primary compress action. Users can add PDFs with a file picker or drag and drop. Each row shows original size, target, status, output size, and savings. Rows can be removed or retried.

## Behavior
- A PDF smaller than or equal to the target is marked skipped and is not rewritten.
- A PDF larger than the target is compressed through iterative quality and resolution attempts.
- Multiple files are processed concurrently with a bounded worker count so the UI stays responsive.
- Output files are written with a stable suffix beside the original unless the user chooses a destination folder.
- Failed files keep their original untouched and show a concise error.

## Architecture
The app is a SwiftPM macOS SwiftUI app. The core compression logic lives in `PDFCompressorCore` and is independent from the SwiftUI views. The app target owns selection, drag and drop, queue state, and progress.

## Performance
The compression service runs off the main actor. Batch work is bounded by `ProcessInfo.processInfo.activeProcessorCount - 1`, with a minimum of 1 and a conservative maximum of 4 workers. PDF rendering uses autorelease pools per page and per attempt to reduce memory spikes.

## Testing
Unit tests cover target-size skip behavior, attempt planning, worker limit calculation, and output URL generation. The app is then built with SwiftPM and launched through a project-local run script.
