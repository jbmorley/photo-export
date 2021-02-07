//
//  PHAsset.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 04/02/2021.
//

import Foundation
import Photos

extension PHAsset {

    var originalFilename: String {
        let resources = PHAssetResource.assetResources(for: self)
        return resources[0].originalFilename
    }

}
