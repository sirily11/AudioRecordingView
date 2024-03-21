//
//  exampleApp.swift
//  example
//
//  Created by Qiwei Li on 3/20/24.
//

import AudioRecorder
import SwiftUI

@main
struct exampleApp: App {
    @StateObject var recorder = AudioManager(configuration: .init())

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(recorder)
        }
    }
}
