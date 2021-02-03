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
    @State var showOnlyFavorites: Bool = false

    static let spacing: CGFloat = 8
    let columns = [GridItem(.adaptive(minimum: 200, maximum: 200), spacing: spacing)]

    var photos: [Photo] { collection.photos.filter { !showOnlyFavorites || $0.asset.isFavorite } }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Self.spacing) {
                ForEach(photos) { photo in
                    Thumbnail(manager: manager, photo: photo)
                        .contextMenu(ContextMenu(menuItems: {
                            Button {
                                let picturesUrl = URL(fileURLWithPath: "/Users/jbmorley/Pictures")
                                let pictureUrl = picturesUrl.appendingPathComponent("example.jpeg")
                                let export = ExportTask(photo: photo, url: pictureUrl)
                                manager.taskManager.add(task: export)
                            } label: {
                                Text("Export...")
                            }
                        }))
                }
            }
            .padding()
        }
        .toolbar {
            ToolbarItem {
                Button {

                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(.primary)
                }
            }
            ToolbarItem {
                Button {
                    showOnlyFavorites = !showOnlyFavorites
                } label: {
                    if showOnlyFavorites {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.primary)
                    } else {
                        Image(systemName: "heart")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .navigationTitle(collection.localizedTitle)
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
