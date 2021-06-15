//
//  AVAsset.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 07/02/2021.
//

import Foundation
import Photos

extension AVFileType {

    var utType: UTType { UTType(rawValue)! }
    var pathExtension: String { utType.preferredFilenameExtension! }  // TODO: This should be able to fail

}
