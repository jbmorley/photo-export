//
//  Photo_ExportApp.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 30/01/2021.
//

import Combine
import SwiftUI
import Photos

@main
struct Photo_ExportApp: App {

    var manager = Manager()

    var body: some Scene {
        WindowGroup {
            ContentView(manager: manager)
                .preferredColorScheme(.dark)
        }
        WindowGroup("Exports") {
            ExportsView(manager: manager, taskManager: manager.taskManager)
                .preferredColorScheme(.dark)
        }
        Settings {
            SettingsView()
                .environment(\.manager, manager)
                .preferredColorScheme(.dark)
        }
    }
}
