//
//  Photo.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 04/02/2021.
//

import Combine
import Foundation
import Photos

class Photo: Identifiable {

    let manager: Manager

    var id: String {
        asset.localIdentifier
    }

    let asset: PHAsset

    init(manager: Manager, asset: PHAsset) {
        self.manager = manager
        self.asset = asset
    }

}
