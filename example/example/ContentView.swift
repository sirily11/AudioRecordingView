//
//  ContentView.swift
//  example
//
//  Created by Qiwei Li on 3/20/24.
//

import AudioRecorder
import Charts
import Combine
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Spacer()
            RecordingView(recordingConfiguration: .init(numberOfBars: 30), visulizationConfiguration: .init(waveformHeight: 50)) { audioData in
                print("Audio data: \(audioData.count)")
            }
        }
    }
}
