import XCTest
@testable import DropletCore

final class GeneratedNoiseRendererTests: XCTestCase {
    func testRendererProducesDeterministicBoundedSamples() {
        var first = GeneratedNoiseRenderer(noise: .pink, seed: 0xD0C0_1E7)
        var second = GeneratedNoiseRenderer(noise: .pink, seed: 0xD0C0_1E7)

        let firstSamples = (0..<128).map { _ in first.nextSample() }
        let secondSamples = (0..<128).map { _ in second.nextSample() }

        XCTAssertEqual(firstSamples, secondSamples)
        XCTAssertTrue(firstSamples.allSatisfy { (-1...1).contains($0) })
        XCTAssertGreaterThan(firstSamples.reduce(0) { $0 + abs($1) }, 0)
    }

    func testNoiseColorsUseDifferentFilterResponses() {
        var white = GeneratedNoiseRenderer(noise: .white, seed: 0xD0C0_1E7)
        var brown = GeneratedNoiseRenderer(noise: .brown, seed: 0xD0C0_1E7)
        var blue = GeneratedNoiseRenderer(noise: .blue, seed: 0xD0C0_1E7)

        let whiteSamples = (0..<64).map { _ in white.nextSample() }
        let brownSamples = (0..<64).map { _ in brown.nextSample() }
        let blueSamples = (0..<64).map { _ in blue.nextSample() }

        XCTAssertNotEqual(whiteSamples, brownSamples)
        XCTAssertNotEqual(whiteSamples, blueSamples)
        XCTAssertNotEqual(brownSamples, blueSamples)
    }
}
