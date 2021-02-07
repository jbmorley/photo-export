//
//  AssetDetails.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 04/02/2021.
//

import Foundation

struct AssetDetails {
    let data: Data
    let uti: String
    let orientation: CGImagePropertyOrientation

    // TODO: Should this be optional?
    var fileExtension: String? {
        guard let fileExtension = UTTypeCopyPreferredTagWithClass(uti as CFString, kUTTagClassFilenameExtension) else {
            return nil
        }
        return String(fileExtension.takeRetainedValue())
    }

    func set(data: Data) -> AssetDetails {
        return AssetDetails(data: data,
                            uti: uti,
                            orientation: orientation)
    }
}
