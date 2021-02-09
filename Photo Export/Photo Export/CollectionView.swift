//
//  CollectionView.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 04/02/2021.
//

import Photos
import SwiftUI

struct CollectionView: View {

    @ObservedObject var manager: Manager // TODO: This probably doesn't require a manager.
    @ObservedObject var collection: Collection
    @State var showOnlyFavorites: Bool = false

    static let spacing: CGFloat = 8
    let columns = [GridItem(.adaptive(minimum: 200, maximum: 200), spacing: spacing)]

    var assets: [PHAsset] { collection.assets.filter { !showOnlyFavorites || $0.isFavorite } }

    var imageCount: Int { collection.assets.filter { $0.mediaType == .image }.count }
    var videoCount: Int { collection.assets.filter { $0.mediaType == .video }.count }
    var favoriteCount: Int { collection.assets.filter { $0.isFavorite }.count }

    var imageCountString: String {
        NSString.localizedStringWithFormat(NSLocalizedString("%lld images", comment: "Cheese") as NSString, imageCount) as String
    }

    var videoCountString: String {
        NSString.localizedStringWithFormat(NSLocalizedString("%lld videos", comment: "Cheese") as NSString, videoCount) as String
    }

    var favoriteCountString: String {
        NSString.localizedStringWithFormat(NSLocalizedString("%lld favorites", comment: "Cheese") as NSString, favoriteCount) as String
    }

    var summary: String {

        [imageCountString, videoCountString, favoriteCountString].joined(separator: NSLocalizedString("LIST_SEPARATOR", comment: "list separator"))

    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVGrid(columns: columns, spacing: Self.spacing) {
                    ForEach(assets) { asset in
                        Thumbnail(manager: manager, asset: asset)
                            .onTapGesture {
                                print(asset.databaseUUID)
                                print(asset.creationDate ?? "nil")
                                print(asset.modificationDate ?? "nil")
                            }
                            .contextMenu(ContextMenu(menuItems: {
                                Button {
                                    do {
                                        var options = ExportOptions()
                                        options.overwriteExisting = true
                                        try manager.export([asset], options: options)
                                    } catch {
                                        print("failed to export asset with error \(error)")
                                    }
                                } label: {
                                    Text("Export...")
                                }
                            }))
                    }
                }
                .padding()
            }
            Divider()
            Text(summary)
                .foregroundColor(.secondary)
                .padding()
        }
        .toolbar {
            ToolbarItem {
                Button {
                    do {
                        var options = ExportOptions()
                        options.overwriteExisting = true
                        try manager.export(assets, options: options)
                    } catch {
                        print("failed to export assets with error \(error)")
                    }
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
