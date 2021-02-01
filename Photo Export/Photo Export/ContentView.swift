//
//  ContentView.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 30/01/2021.
//

import SwiftUI
import ImageIO
import Photos


extension NSImage {

//    func getExifData() -> CFDictionary? {
//        var exifData: CFDictionary? = nil
//        if let data = self.jpegData(compressionQuality: 1.0) {
//            data.withUnsafeBytes {
//                let bytes = $0.baseAddress?.assumingMemoryBound(to: UInt8.self)
//                if let cfData = CFDataCreate(kCFAllocatorDefault, bytes, data.count),
//                    let source = CGImageSourceCreateWithData(cfData, nil) {
//                    exifData = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
//                }
//            }
//        }
//        return exifData
//    }
}


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

    var imageProperties: [String: Any]? {
        if let imageSource = CGImageSourceCreateWithData(self as CFData, nil) {
            return CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any]
        }
        return nil
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
                                        print("EXPORTING!")
                                        photo.asset.requestContentEditingInput(with: nil) { contentEditingInput, something in

                                            // TODO: Consider exporting the original and final versions.
                                            let options = PHImageRequestOptions()
                                            options.version = .current
                                            options.isNetworkAccessAllowed = true
                                            options.resizeMode = .exact

                                            let picturesUrl = URL(fileURLWithPath: "/Users/jbmorley/Pictures")

                                            let resourceManager = PHAssetResourceManager()
                                            let resources = PHAssetResource.assetResources(for: photo.asset)
                                            print(resources)
                                            for resource in resources {
                                                var resourceData = Data()
                                                let options = PHAssetResourceRequestOptions()
                                                resourceManager.requestData(for: resource, options: options) { data in
                                                    resourceData.append(data)
                                                } completionHandler: { error in
                                                    if let error = error {
                                                        print("failed to get resource with error \(error)")
                                                        return
                                                    }
                                                    print(resourceData.imageProperties ?? "No image properties")
                                                    try! resourceData.write(to: picturesUrl.appendingPathComponent(resource.originalFilename))
                                                }
                                            }


                                            manager.imageManager.requestImageDataAndOrientation(for: photo.asset, options: options) { data, filename, orientation, unknown in
                                                guard let data = data,
                                                      let filename = filename,
                                                      let unknown = unknown else {
                                                    print("Unable to fetch data")
                                                    return
                                                }

                                                print(data.imageProperties ?? "No image properties")
                                                try! data.write(to: picturesUrl.appendingPathComponent(filename))

                                                print(filename)
                                                print(orientation)
                                                for (key, _) in unknown {
                                                    print(key)
                                                }

                                            }

                                        }
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

