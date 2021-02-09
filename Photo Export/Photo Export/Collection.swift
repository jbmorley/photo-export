//
//  Collection.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 04/02/2021.
//

import Foundation
import Photos

class Collection: NSObject, ObservableObject, Identifiable {

    var id: String { collection.id }

    @Published var assets: [PHAsset] = []

    weak var manager: Manager?
    var collection: PHAssetCollection

    var localizedTitle: String {
        collection.localizedTitle ?? "Untitled"
    }

    init(manager: Manager, collection: PHAssetCollection) {
        self.manager = manager
        self.collection = collection
        super.init()

        PHPhotoLibrary.shared().register(self)
        self.update()
    }

    func update() {

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
