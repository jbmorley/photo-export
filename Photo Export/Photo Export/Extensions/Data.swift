//
//  Data.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 02/02/2021.
//

import Foundation

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

    func set(title: String) -> Data? {

        guard let imageSource = imageSource else {
            return nil
        }

        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [AnyHashable: Any] else {
            print("unable to get properties")
            return nil
        }

        var mutableProperties = properties
        if var mutableExif = (properties[(kCGImagePropertyExifDictionary as String)]) as? [AnyHashable: Any] {
            mutableExif[kCGImagePropertyExifUserComment as String] = title
            print(kCGImagePropertyExifUserComment)
            mutableProperties[kCGImagePropertyExifDictionary] = mutableExif
        }
        if var mutableIPTC = (properties[(kCGImagePropertyIPTCDictionary as String)]) as? [AnyHashable: Any] {
            mutableIPTC[kCGImagePropertyIPTCObjectName as String] = title
            print(kCGImagePropertyIPTCObjectName);
            mutableIPTC[kCGImagePropertyIPTCCaptionAbstract as String] = title
            mutableProperties[kCGImagePropertyIPTCDictionary] = mutableIPTC
        } else {
            var mutableIPTC: [AnyHashable: String] = [:]
            mutableIPTC[kCGImagePropertyIPTCObjectName as String] = title
            print(kCGImagePropertyIPTCObjectName);
            mutableIPTC[kCGImagePropertyIPTCCaptionAbstract as String] = title
            mutableProperties[kCGImagePropertyIPTCDictionary] = mutableIPTC
        }
        if var mutableTIFF = (properties[(kCGImagePropertyTIFFDictionary as String)]) as? [AnyHashable: Any] {
            mutableTIFF[kCGImagePropertyTIFFImageDescription as String] = title
            mutableProperties[kCGImagePropertyTIFFDictionary] = mutableTIFF
        }

        guard let uti = CGImageSourceGetType(imageSource) else {
            print("Unable to determine image source type")
            return nil
        }

        let data = NSMutableData()
        let destination: CGImageDestination = CGImageDestinationCreateWithData(data as CFMutableData, uti, 1, nil)!
        CGImageDestinationAddImageFromSource(destination, imageSource, 0, mutableProperties as CFDictionary)
        CGImageDestinationFinalize(destination)

        return data as Data
    }

}
