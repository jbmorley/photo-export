//
//  ContentView.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 30/01/2021.
//

import SwiftUI
import ImageIO
import Photos

extension PHObject: Identifiable {
    public var id: String { localIdentifier }
}

struct ContentView: View {

    @ObservedObject var manager: Manager

    var body: some View {
        NavigationView {
            VStack {
                List(manager.collections, children: \.collections) { collection in
                    NavigationLink(destination: CollectionView(manager: manager, collection: collection)) {
                        switch collection.collectionType {
                        case .album:
                            Label(collection.localizedTitle, systemImage: "rectangle.stack")
                        case .folder:
                            Label(collection.localizedTitle, systemImage: "folder")
                        }
                    }
                }
            }
            VStack {
                if manager.requiresAuthorization {
                    Button {
                        manager.authorize()
                    } label: {
                        // TODO: Don't use a button for this.
                        Text("Authorize")
                    }
                    .padding()
                } else {
                    EmptyView()
                }
            }
        }
    }
}
