//
//  ContentView.swift
//  example
//
//  Created by Qiwei Li on 3/20/24.
//

import Charts
import Combine
import SwiftUI

/**
 Builder for building wave form visualization view
 */
public typealias WaveformViewBuilder<T> = (_ data: [Float], _ configuration: AudioManagerConfiguration) -> T

/**
 Callback function when recorded is finished
 */
public typealias OnRecorded = (_ audioData: [Float]) -> Void

public struct VisulizationConfiguration {
    public let waveformHeight: CGFloat
    public let waveformWidth: CGFloat

    public init(waveformHeight: CGFloat = 50, waveformWidth: CGFloat = 300) {
        self.waveformHeight = waveformHeight
        self.waveformWidth = waveformWidth
    }
}

/**
    A view that allows you to record audio and visualize the waveform
 */
public struct RecordingView<VisulizationView: View>: View {
    @StateObject var recorder: AudioManager = .init()
    @State var isRecording = false
    @State var showVisulization = false

    let timer: Publishers.Autoconnect<Timer.TimerPublisher>

    let recordingConfiguration: AudioManagerConfiguration
    let visulizationConfiguration: VisulizationConfiguration

    let buildAudioWavefromView: WaveformViewBuilder<VisulizationView>?
    let onRecorded: OnRecorded?

    public init(recordingConfiguration: AudioManagerConfiguration = .init(), visulizationConfiguration: VisulizationConfiguration = .init(), onRecorded: OnRecorded? = nil, buildAudioWavefromView:
        @escaping WaveformViewBuilder<VisulizationView>)
    {
        self.buildAudioWavefromView = buildAudioWavefromView
        self.recordingConfiguration = recordingConfiguration
        self.visulizationConfiguration = visulizationConfiguration
        self.timer = Timer.publish(
            every: recordingConfiguration.updateInterval,
            on: .main,
            in: .common
        ).autoconnect()
        self.onRecorded = onRecorded
    }

    public init(recordingConfiguration: AudioManagerConfiguration = .init(), visulizationConfiguration: VisulizationConfiguration = .init(), onRecorded: OnRecorded? = nil) {
        self.buildAudioWavefromView = nil
        self.timer = Timer.publish(
            every: recordingConfiguration.updateInterval,
            on: .main,
            in: .common
        ).autoconnect()
        self.recordingConfiguration = recordingConfiguration
        self.visulizationConfiguration = visulizationConfiguration
        self.onRecorded = onRecorded
    }

    var defaultVisulizationView: some View {
        Chart(Array(recorder.amplitudes.enumerated()), id: \.0) { index, magnitude in
            BarMark(
                x: .value("Frequency", String(index)),
                y: .value("Magnitude", magnitude)
            )
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: recorder.configuration.waveformLowerLimit ... recorder.configuration.waveformUpperLimit)
        .padding()
        .frame(width: visulizationConfiguration.waveformWidth, height: visulizationConfiguration.waveformHeight)
        .background(
            .black
                .opacity(0.3)
                .shadow(.inner(radius: 20))
        )
        .cornerRadius(10)
    }

    public var body: some View {
        VStack {
            Spacer()
            Group {
                if showVisulization {
                    if let buildAudioWavefromView = buildAudioWavefromView {
                        buildAudioWavefromView(recorder.amplitudes, recorder.configuration)
                    } else {
                        defaultVisulizationView
                    }
                }
            }
            .opacity(showVisulization ? 1 : 0)
            Button(isRecording ? "Stop" : "Start") {
                if isRecording {
                    recorder.stopRecording()
                } else {
                    recorder.startRecording()
                }
                withAnimation {
                    showVisulization.toggle()
                    isRecording.toggle()
                }
            }
        }
        .onChange(of: isRecording) { oldValue, newValue in
            if oldValue, !newValue {
                if let onRecorded = onRecorded {
                    onRecorded(recorder.pcmWaveData)
                }
            }
        }
        .onReceive(timer, perform: { _ in
            recorder.refreshAmplitudes()
        })
        .onAppear {
            recorder.configuration = recordingConfiguration
        }
        .padding()
        .onAppear {
            recorder.startEngine()
        }
        .onDisappear {
            recorder.stopEngine()
        }
    }
}

public extension RecordingView where VisulizationView == EmptyView {
    init(recordingConfiguration: AudioManagerConfiguration = .init(), visulizationConfiguration: VisulizationConfiguration = .init(), onRecorded: OnRecorded? = nil) {
        self.buildAudioWavefromView = nil
        self.recordingConfiguration = recordingConfiguration
        self.timer = Timer.publish(
            every: recordingConfiguration.updateInterval,
            on: .main,
            in: .common
        ).autoconnect()
        self.visulizationConfiguration = visulizationConfiguration
        self.onRecorded = onRecorded
    }
}
