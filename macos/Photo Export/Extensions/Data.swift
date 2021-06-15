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

extension Data {

    var imageSource: CGImageSource? {
        return CGImageSourceCreateWithData(self as CFData, nil)
    }

    var imageProperties: [String: Any]? {
        guard let imageSource = imageSource else {
            return nil
        }
        return CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any]
    }

    func set(asset: PHAsset, metadata: Metadata) throws -> Data {

        guard let imageSource = imageSource else {
            throw ManagerError.invalidData
        }

        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [AnyHashable: Any] else {
            throw ManagerError.missingProperties
        }

        var mutableProperties = properties

        var iptc = (properties[(kCGImagePropertyIPTCDictionary as String)]) as? [AnyHashable: Any] ?? [:]
        if let title = metadata.title {
            iptc[kCGImagePropertyIPTCObjectName as String] = title
        }
        if let caption = metadata.caption {
            iptc[kCGImagePropertyIPTCCaptionAbstract as String] = caption
        }
        mutableProperties[kCGImagePropertyIPTCDictionary] = iptc

//        var exif = (properties[(kCGImagePropertyExifDictionary as String)]) as? [AnyHashable: Any] ?? [:]
//        exif[kCGImagePropertyExifDateTimeOriginal] = asset.creationDate
//        mutableProperties[kCGImagePropertyExifDictionary] = exif


//        if var mutableIPTC = (properties[(kCGImagePropertyIPTCDictionary as String)]) as? [AnyHashable: Any] {
//            if let title = metadata.title {
//                iptc[kCGImagePropertyIPTCObjectName as String] = title
//            }
//            if let caption = metadata.caption {
//                iptc[kCGImagePropertyIPTCCaptionAbstract as String] = caption
//            }
//            mutableProperties[kCGImagePropertyIPTCDictionary] = mutableIPTC
//        } else {
//            var mutableIPTC: [AnyHashable: String] = [:]
//            if let title = metadata.title {
//                mutableIPTC[kCGImagePropertyIPTCObjectName as String] = title
//            }
//            if let caption = metadata.caption {
//                mutableIPTC[kCGImagePropertyIPTCCaptionAbstract as String] = caption
//            }
//            mutableProperties[kCGImagePropertyIPTCDictionary] = mutableIPTC
//        }
//        mutableProperties[kCGImagePropertyIPTCDictionary] = iptc


        guard let uti = CGImageSourceGetType(imageSource) else {
            throw ManagerError.unknownImageType
        }

        let data = NSMutableData()
        let destination: CGImageDestination = CGImageDestinationCreateWithData(data as CFMutableData, uti, 1, nil)!
        CGImageDestinationAddImageFromSource(destination, imageSource, 0, mutableProperties as CFDictionary)
        CGImageDestinationFinalize(destination)

        return data as Data
    }

}
