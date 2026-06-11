import AVFoundation
import DropletCore
import Foundation

final class FocusNoiseEngine {
    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private var leftRenderer = GeneratedNoiseRenderer(noise: .white, seed: 0xD20C_AFE1)
    private var rightRenderer = GeneratedNoiseRenderer(noise: .white, seed: 0xF0C0_5EED)

    var volume: Float = 0.5 {
        didSet {
            engine.mainMixerNode.outputVolume = generatedOutputVolume
        }
    }

    private var generatedOutputVolume: Float {
        min(max(volume, 0), 1)
    }

    func start(noise: GeneratedNoise, volume: Float) throws {
        stop()

        self.volume = volume
        leftRenderer = GeneratedNoiseRenderer(noise: noise, seed: 0xD20C_AFE1)
        rightRenderer = GeneratedNoiseRenderer(noise: noise, seed: 0xF0C0_5EED)

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
                left[frame] = self.leftRenderer.nextSample()
                right[frame] = self.rightRenderer.nextSample()
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
