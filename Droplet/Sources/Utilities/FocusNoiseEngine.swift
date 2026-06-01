import AVFoundation
import Foundation

final class FocusNoiseEngine {
    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private var leftChannel = NoiseChannel(seed: 0xD20C_AFE1)
    private var rightChannel = NoiseChannel(seed: 0xF0C0_5EED)

    var volume: Float = 0.5 {
        didSet {
            engine.mainMixerNode.outputVolume = generatedOutputVolume
        }
    }

    private var generatedOutputVolume: Float {
        min(max(volume, 0), 1) * 0.075
    }

    func start(noise: GeneratedNoise, volume: Float) throws {
        stop()

        self.volume = volume
        leftChannel = NoiseChannel(seed: 0xD20C_AFE1, noise: noise)
        rightChannel = NoiseChannel(seed: 0xF0C0_5EED, noise: noise)

        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!
        let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self else { return noErr }
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            guard buffers.count >= 2,
                  let left = buffers[0].mData?.assumingMemoryBound(to: Float.self),
                  let right = buffers[1].mData?.assumingMemoryBound(to: Float.self) else {
                return noErr
            }

            for frame in 0..<Int(frameCount) {
                left[frame] = self.leftChannel.nextSample()
                right[frame] = self.rightChannel.nextSample()
            }

            return noErr
        }

        sourceNode = node
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = generatedOutputVolume
        try engine.start()
    }

    func stop() {
        engine.stop()
        if let sourceNode {
            engine.detach(sourceNode)
        }
        sourceNode = nil
    }
}

private struct NoiseChannel {
    private var random: SeededNoiseRandom
    private let noise: GeneratedNoise
    private var pink = PinkFilter()
    private var brown = BrownFilter()
    private var blue = DifferenceFilter(gain: 0.46)
    private var violet = SecondDifferenceFilter(gain: 0.16)
    private var green = GreenFilter()
    private let outputGain: Float

    init(seed: UInt64, noise: GeneratedNoise = .white) {
        random = SeededNoiseRandom(seed: seed)
        self.noise = noise
        outputGain = noise.outputGain
    }

    mutating func nextSample() -> Float {
        let white = random.nextSample()
        let sample: Float

        switch noise {
        case .white:
            sample = white
        case .pink:
            sample = pink.process(white)
        case .brown:
            sample = brown.process(white)
        case .green:
            sample = green.process(white)
        case .blue:
            sample = blue.process(white)
        case .violet:
            sample = violet.process(white)
        }

        return softLimit(sample * outputGain)
    }

    private func softLimit(_ sample: Float) -> Float {
        let squared = sample * sample
        return sample / (1 + squared)
    }
}

private struct SeededNoiseRandom {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func nextSample() -> Float {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        let value = UInt32(truncatingIfNeeded: state >> 32)
        return (Float(value) / Float(UInt32.max)) * 2 - 1
    }
}

private struct PinkFilter {
    private var b0: Float = 0
    private var b1: Float = 0
    private var b2: Float = 0
    private var b3: Float = 0
    private var b4: Float = 0
    private var b5: Float = 0
    private var b6: Float = 0

    mutating func process(_ white: Float) -> Float {
        b0 = 0.99886 * b0 + white * 0.0555179
        b1 = 0.99332 * b1 + white * 0.0750759
        b2 = 0.96900 * b2 + white * 0.1538520
        b3 = 0.86650 * b3 + white * 0.3104856
        b4 = 0.55000 * b4 + white * 0.5329522
        b5 = -0.7616 * b5 - white * 0.0168980
        let output = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362
        b6 = white * 0.115926
        return output
    }
}

private struct BrownFilter {
    private var value: Float = 0

    mutating func process(_ white: Float) -> Float {
        value = (value + white * 0.024) / 1.024
        return value * 3.0
    }
}

private struct DifferenceFilter {
    private var previous: Float = 0
    private let gain: Float

    init(gain: Float) {
        self.gain = gain
    }

    mutating func process(_ white: Float) -> Float {
        let output = (white - previous) * gain
        previous = white
        return output
    }
}

private struct SecondDifferenceFilter {
    private var previousWhite: Float = 0
    private var previousDifference: Float = 0
    private let gain: Float

    init(gain: Float) {
        self.gain = gain
    }

    mutating func process(_ white: Float) -> Float {
        let difference = white - previousWhite
        let output = (difference - previousDifference) * gain
        previousWhite = white
        previousDifference = difference
        return output
    }
}

private struct GreenFilter {
    private var slowLowPass: Float = 0
    private var fastLowPass: Float = 0

    mutating func process(_ white: Float) -> Float {
        slowLowPass += 0.018 * (white - slowLowPass)
        fastLowPass += 0.16 * (white - fastLowPass)
        return (fastLowPass - slowLowPass) * 1.5
    }
}
