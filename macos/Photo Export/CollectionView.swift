// Copyright (c) 2021 InSeven Limited
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
