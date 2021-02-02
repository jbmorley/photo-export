//
//  ContentView.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 30/01/2021.
//

import SwiftUI
import ImageIO
import Photos


struct Thumbnail: View {

    let manager: Manager
    let photo: Photo

    @State var image: NSImage? = nil

    var heart: String {
        photo.asset.isFavorite ? "❤️" : ""
    }

    var body: some View {
        VStack {
            HStack {
                if let image = image {
                    Image(nsImage: image)
                        .fixedSize()
                        .frame(width: 200, height: 200)
                }
            }
            .frame(width: 200, height: 200)
            Text("\(heart)")
                .lineLimit(1)
        }
        .onAppear(perform: {
            manager.imageManager.requestImage(for: photo.asset,
                                              targetSize: CGSize(width: 200, height: 200),
                                              contentMode: .aspectFit,
                                              options: nil,
                                              resultHandler: { image, _ in
                                                self.image = image
                                              })
        })
    }

}

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

struct ContentView: View {

    @ObservedObject var manager: Manager

    static let spacing: CGFloat = 8
    let columns = [GridItem(.adaptive(minimum: 200, maximum: 200), spacing: spacing)]

    var body: some View {
        VStack {
            if manager.requiresAuthorization {
                Button {
                    manager.authorize()
                } label: {
                    Text("Authorize")
                }
                .padding()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: Self.spacing) {
                        ForEach(manager.photos) { photo in
                            Thumbnail(manager: manager, photo: photo)
                                .contextMenu(ContextMenu(menuItems: {
                                    Button {
                                        let picturesUrl = URL(fileURLWithPath: "/Users/jbmorley/Pictures")
                                        let pictureUrl = picturesUrl.appendingPathComponent("example.jpeg")
                                        photo.export(to: pictureUrl) { result in
                                            switch result {
                                            case .success:
                                                print("successfully wrote file to \(pictureUrl)")
                                            case .failure(let error):
                                                print("failed to safe photo with error \(error)")
                                            }
                                        }

                                        // TODO: This call is probably not required if we're only doing read-only work.
//                                        photo.asset.requestContentEditingInput(with: nil) { contentEditingInput, something in
//
//
//                                            let resourceManager = PHAssetResourceManager()
//                                            let resources = PHAssetResource.assetResources(for: photo.asset)
//                                            print(resources)
//                                            for resource in resources {
//                                                var resourceData = Data()
//                                                let options = PHAssetResourceRequestOptions()
//                                                resourceManager.requestData(for: resource, options: options) { data in
//                                                    resourceData.append(data)
//                                                } completionHandler: { error in
//                                                    if let error = error {
//                                                        print("failed to get resource with error \(error)")
//                                                        return
//                                                    }
//                                                    print(resourceData.imageProperties ?? "No image properties")
//                                                    try! resourceData.write(to: picturesUrl.appendingPathComponent(resource.originalFilename))
//                                                }
//                                            }

//                                        }
                                    } label: {
                                        Text("Export...")
                                    }
                                }))
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

