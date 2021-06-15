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

import Foundation
import Photos

enum CollectionType {
    case album
    case folder
}

class Collection: NSObject, ObservableObject, Identifiable {

    var id: String { collection.id }
    var collectionType: CollectionType { collection.canContainAssets ? .album : .folder }

    @Published var assets: [PHAsset] = []
    @Published var collections: [Collection]?

    var localizedTitle: String { collection.localizedTitle ?? "Untitled" }

    fileprivate weak var manager: Manager?
    fileprivate var collection: PHCollection

    init(manager: Manager, collection: PHCollection) {
        self.manager = manager
        self.collection = collection
        super.init()
        PHPhotoLibrary.shared().register(self)
        update()
    }

    func update() {
        updateAssets()
        updateCollections()
    }

    func updateAssets() {
        guard let collection = self.collection as? PHAssetCollection else {
            return
        }
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        var assets: [PHAsset] = []
        let result = PHAsset.fetchAssets(in: collection, options: options)
        result.enumerateObjects { asset, index, stop in
            dispatchPrecondition(condition: .onQueue(.main))
            assets.append(asset)
        }
        self.assets = assets
    }

    func updateCollections() {
        guard let collection = self.collection as? PHCollectionList,
              let manager = manager else {
            return
        }
        var collections: [Collection] = []
        let result = PHAssetCollection.fetchCollections(in: collection, options: nil)
        result.enumerateObjects { collection, index, stop in
            dispatchPrecondition(condition: .onQueue(.main))
            collections.append(Collection(manager: manager, collection: collection))
        }
        self.collections = collections
    }

}

extension Collection: PHPhotoLibraryChangeObserver {

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async {
            var contentDidChange = false
            if let change = changeInstance.changeDetails(for: self.collection) {
                contentDidChange = change.assetContentChanged
            }
            for asset in self.assets {
                if changeInstance.changeDetails(for: asset) != nil {
                    contentDidChange = true
                    break
                }
            }
            if contentDidChange {
                self.update()
            }
        }
    }

}
