import XCTest
@testable import PDFCompressorCore

final class CompressionPlannerTests: XCTestCase {
    func testSkipsWhenSourceSizeIsAtOrBelowTarget() {
        let plan = CompressionPlanner.plan(sourceBytes: 1_000_000, targetMegabytes: 1.0)

        XCTAssertEqual(plan.action, .skip)
        XCTAssertEqual(plan.targetBytes, 1_000_000)
    }

    func testCompressesWhenSourceSizeIsAboveTarget() {
        let plan = CompressionPlanner.plan(sourceBytes: 2_500_000, targetMegabytes: 1.0)

        XCTAssertEqual(plan.action, .compress)
        XCTAssertEqual(plan.targetBytes, 1_000_000)
    }

    func testWorkerLimitLeavesCapacityForTheUI() {
        XCTAssertEqual(CompressionPlanner.workerLimit(activeProcessorCount: 1), 1)
        XCTAssertEqual(CompressionPlanner.workerLimit(activeProcessorCount: 2), 1)
        XCTAssertEqual(CompressionPlanner.workerLimit(activeProcessorCount: 8), 4)
    }

    func testOutputURLAddsCompressedSuffixBeforeExtension() {
        let input = URL(fileURLWithPath: "/tmp/contracts/report.final.pdf")

        let output = CompressionPlanner.defaultOutputURL(for: input)

        XCTAssertEqual(output.path, "/tmp/contracts/report.final-compressed.pdf")
    }

    func testByteFormatterUsesMegabytes() {
        XCTAssertEqual(FileSizeFormatter.megabytesString(bytes: 1_500_000), "1.5 MB")
    }

    func testCompressionServiceDoesNotRewriteFilesBelowTarget() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }

        let source = folder.appendingPathComponent("small.pdf")
        try Data("small file".utf8).write(to: source)

        let result = await PDFCompressionService().compress(sourceURL: source, targetMegabytes: 1)

        XCTAssertEqual(result.status, .skipped)
        XCTAssertNil(result.outputURL)
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.appendingPathComponent("small-compressed.pdf").path))
    }

    func testAspectFitPreservesOriginalRatioWhenContainerIsDifferent() {
        let rect = AspectRatio.fit(
            contentSize: CGSize(width: 800, height: 400),
            in: CGRect(x: 0, y: 0, width: 300, height: 300)
        )

        XCTAssertEqual(rect.width, 300, accuracy: 0.001)
        XCTAssertEqual(rect.height, 150, accuracy: 0.001)
        XCTAssertEqual(rect.origin.y, 75, accuracy: 0.001)
    }
}
