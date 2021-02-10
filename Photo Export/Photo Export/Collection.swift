//
//  Collection.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 04/02/2021.
//

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
