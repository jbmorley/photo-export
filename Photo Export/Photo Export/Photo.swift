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

    var id: String {
        asset.localIdentifier
    }

    let asset: PHAsset

    init(asset: PHAsset) {
        self.asset = asset
    }

}
