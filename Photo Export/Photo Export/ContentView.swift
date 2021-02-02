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

struct CollectionView: View {

    @ObservedObject var manager: Manager // TODO: This probably doesn't require a manager.
    @ObservedObject var collection: Collection

    static let spacing: CGFloat = 8
    let columns = [GridItem(.adaptive(minimum: 200, maximum: 200), spacing: spacing)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Self.spacing) {
                ForEach(collection.photos) { photo in
                    Thumbnail(manager: manager, photo: photo)
                        .contextMenu(ContextMenu(menuItems: {
                            Button {
                                let picturesUrl = URL(fileURLWithPath: "/Users/jbmorley/Pictures")
                                let pictureUrl = picturesUrl.appendingPathComponent("example.jpeg")
                                _ = photo.export(to: pictureUrl) { result in
                                    switch result {
                                    case .success:
                                        print("successfully wrote file to \(pictureUrl)")
                                    case .failure(let error):
                                        print("failed to safe photo with error \(error)")
                                    }
                                }
                            } label: {
                                Text("Export...")
                            }
                        }))
                }
            }
            .padding()
        }
    }
}

struct ContentView: View {

    @ObservedObject var manager: Manager



    var body: some View {
        NavigationView {
            List {
                ForEach(manager.collections) { collection in
                    NavigationLink(collection.localizedTitle, destination: CollectionView(manager: manager, collection: collection))
                }
            }
            VStack {
                if manager.requiresAuthorization {
                    Button {
                        manager.authorize()
                    } label: {
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
