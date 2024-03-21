import Accelerate
import AudioKit
import AudioKitEX
import AVFoundation
import SoundpipeAudioKit
import SwiftUI

public struct AudioManagerConfiguration {
    public var numberOfBars: Int
    public var maxAmplitude: Float
    public var minAmplitude: Float
    public var referenceValueForFFT: Float
    public var waveformLowerLimit: Float
    public var waveformUpperLimit: Float
    public var updateInterval: Double

    public init(numberOfBars: Int = 50, maxAmplitude: Float = 0.0, minAmplitude: Float = -70, referenceValueForFFT: Float = 12, waveformLowerLimit: Float = 0.15, waveformUpperLimit: Float = 0.3, updateInterval: Double = 0.08) {
        self.numberOfBars = numberOfBars
        self.maxAmplitude = maxAmplitude
        self.minAmplitude = minAmplitude
        self.referenceValueForFFT = referenceValueForFFT
        self.waveformLowerLimit = waveformLowerLimit
        self.waveformUpperLimit = waveformUpperLimit
        self.updateInterval = updateInterval
    }
}

public class AudioManager: ObservableObject {
    let engine = AudioEngine()
    let engine2 = AudioEngine()
    let recorder: NodeRecorder
    let player = AudioPlayer()
    let mixer = Mixer()
    var ffttap: FFTTap?

    let tapnodeA: Fader

    public var configuration: AudioManagerConfiguration
    @Published public var amplitudes: [Float] = []

    public init(configuration: AudioManagerConfiguration = .init()) {
        guard let input = engine.input else {
            fatalError()
        }

        recorder = try! NodeRecorder(node: input, shouldCleanupRecordings: false)
        let mic = input
        tapnodeA = Fader(mic)
        let silencer = Fader(tapnodeA, gain: 0)

        engine.output = silencer
        self.configuration = configuration
    }

    /**
     Start the audio engine
     */
    public func startEngine() {
        try? engine.start()
    }

    /**
     Stop the audio engine
     */
    public func stopEngine() {
        engine.stop()
    }

    /**
     Start recording process
     */
    @MainActor
    public func startRecording() {
        do {
            Task {
                ffttap = FFTTap(tapnodeA, callbackQueue: .global()) { _ in }
                ffttap?.isNormalized = false
                ffttap?.start()
            }
            try recorder.record()
        } catch let err {
            fatalError("\(err)")
        }
    }

    /**
     Stop recording process
     */
    public func stopRecording() {
        guard let audioFile = recorder.audioFile else {
            return
        }
        recorder.stop()
        ffttap?.stop()
    }

    /**
     Get pcm wave data array
     */
    public var pcmWaveData: [Float] {
        guard let audioFile = recorder.audioFile else {
            return []
        }
        return audioFile.toFloatChannelData()?.first ?? []
    }

    /**
     Get the latest amplitudes and update the state
     */
    public func refreshAmplitudes() {
        if let ffttap = ffttap {
            updateAmplitudes(ffttap.fftData)
        }
    }
}

// MARK: FFT Helper method

extension AudioManager {
    func updateAmplitudes(_ fftFloats: [Float]) {
        var maxAmplitude = configuration.maxAmplitude
        var minAmplitude = configuration.minAmplitude
        var referenceValueForFFT = configuration.referenceValueForFFT

        var fftData = fftFloats
        for index in 0 ..< fftData.count {
            if fftData[index].isNaN { fftData[index] = 0.0 }
        }

        var one = Float(1.0)
        var zero = Float(0.0)
        var decibelNormalizationFactor = Float(1.0 / (maxAmplitude - minAmplitude))
        var decibelNormalizationOffset = Float(-minAmplitude / (maxAmplitude - minAmplitude))

        var decibels = [Float](repeating: 0, count: fftData.count)
        vDSP_vdbcon(fftData, 1, &referenceValueForFFT, &decibels, 1, vDSP_Length(fftData.count), 0)

        vDSP_vsmsa(decibels,
                   1,
                   &decibelNormalizationFactor,
                   &decibelNormalizationOffset,
                   &decibels,
                   1,
                   vDSP_Length(decibels.count))

        vDSP_vclip(decibels, 1, &zero, &one, &decibels, 1, vDSP_Length(decibels.count))

        DispatchQueue.main.async {
            let filteredDecibels = decibels.map { $0 > self.configuration.waveformLowerLimit ? $0 : 0 }
            var amplitues = Array(repeating: Float(0), count: self.configuration.numberOfBars)
            for index in 0 ..< self.configuration.numberOfBars {
                if index < filteredDecibels.count { amplitues[index] = filteredDecibels[index] }
            }
            withAnimation(.easeInOut(duration: 0.2)) {
                self.amplitudes = amplitues
            }
        }
    }
}
