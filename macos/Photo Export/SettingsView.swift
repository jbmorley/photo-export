//
//  SettingsView.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 13/02/2021.
//

import SwiftUI

struct GeneralSettingsView: View {

    var manager: Manager

    @State var content: String = ""

    var body: some View {
        HStack {
            List {
                Text("Hello, World!")
            }
            VStack {
                TextField("Content", text: $content)

            }
        }
    }

}

struct SettingsView: View {

    @Environment(\.manager) var manager;

    private enum Tabs: Hashable {
        case general
    }

    var body: some View {
        TabView {
            GeneralSettingsView(manager: manager)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tabs.general)
        }
        .padding()
        .frame(minWidth: 400, maxWidth: .infinity, minHeight: 460, maxHeight: .infinity)
    }

}
