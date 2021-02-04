//
//  CollectionView.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 04/02/2021.
//

import SwiftUI

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
                                manager.export([photo])
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
                    manager.export(photos)
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
