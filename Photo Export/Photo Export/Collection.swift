//
//  Collection.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 04/02/2021.
//

import Foundation
import Photos

class Collection: ObservableObject, Identifiable {

    var id: String { collection.id }

    @Published var photos: [PHAsset] = []

    weak var manager: Manager?
    var collection: PHAssetCollection

    var localizedTitle: String {
        collection.localizedTitle ?? "Untitled"
    }

    init(manager: Manager, collection: PHAssetCollection) {
        self.manager = manager
        self.collection = collection

        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        let result = PHAsset.fetchAssets(in: collection, options: options)
        result.enumerateObjects { asset, index, stop in
            dispatchPrecondition(condition: .onQueue(.main))
            self.photos.append(asset)
        }
    }

}
