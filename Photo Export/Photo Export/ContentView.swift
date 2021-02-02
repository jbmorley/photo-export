//
//  ContentView.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 30/01/2021.
//

import SwiftUI
import ImageIO
import Photos
import SQLite3


func read_title(id: String) -> String? {

    let libraryUrl = URL(fileURLWithPath: "/Users/jbmorley/Pictures/Photos Library.photoslibrary/database/Photos.sqlite")

    // open database

    print("opening Photos.sqlite...")
    var db: OpaquePointer?
    guard sqlite3_open(libraryUrl.path, &db) == SQLITE_OK else {
        print("error opening database")
        sqlite3_close(db)
        db = nil
        return nil
    }

    var statement: OpaquePointer?

    if sqlite3_prepare_v2(db, "select ZADDITIONALASSETATTRIBUTES.ZTITLE from ZASSET JOIN ZADDITIONALASSETATTRIBUTES ON ZADDITIONALASSETATTRIBUTES.ZASSET = ZASSET.Z_PK where ZUUID = ?", -1, &statement, nil) != SQLITE_OK {
        let errmsg = String(cString: sqlite3_errmsg(db)!)
        print("error preparing select: \(errmsg)")
    }

    let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    print("binding ...")
    if sqlite3_bind_text(statement, 1, id, -1, SQLITE_TRANSIENT) != SQLITE_OK {
        let errmsg = String(cString: sqlite3_errmsg(db)!)
        print("failure binding foo: \(errmsg)")
    }

    var name: String?

    print("checking data...")
    while sqlite3_step(statement) == SQLITE_ROW {
        if let cString = sqlite3_column_text(statement, 0) {
            name = String(cString: cString)
            print("name = \(name ?? "?")")
        } else {
            print("name not found")
        }
    }

    print("finalizing statement...")
    if sqlite3_finalize(statement) != SQLITE_OK {
        let errmsg = String(cString: sqlite3_errmsg(db)!)
        print("error finalizing prepared statement: \(errmsg)")
    }

    statement = nil

    print("closing database...")
    if sqlite3_close(db) != SQLITE_OK {
        print("error closing database")
    }

    print("closed!!")

    db = nil

    return name
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
                                        print(photo.asset.localIdentifier)
                                        print(photo.asset.localIdentifier.prefix(36))

                                        let title = read_title(id: String(photo.asset.localIdentifier.prefix(36))) ?? ""

                                        photo.asset.requestContentEditingInput(with: nil) { contentEditingInput, something in

                                            let picturesUrl = URL(fileURLWithPath: "/Users/jbmorley/Pictures")
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

                                            // TODO: Consider exporting the original and final versions.
                                            let options = PHImageRequestOptions()
                                            options.version = .current
                                            options.isNetworkAccessAllowed = true
                                            options.resizeMode = .exact

                                            manager.imageManager.requestImageDataAndOrientation(for: photo.asset, options: options) { data, filename, orientation, unknown in
                                                guard let data = data,
                                                      let filename = filename,
                                                      let unknown = unknown else {
                                                    print("Unable to fetch data")
                                                    return
                                                }

                                                print(data.imageProperties ?? "No image properties")
                                                try! data.write(to: picturesUrl.appendingPathComponent(filename))

                                                guard let image = data.set(title: title) else {
                                                    print("failed to set title")
                                                    return
                                                }
                                                print(image.imageProperties ?? "no image properties")
                                                try! image.write(to: picturesUrl.appendingPathComponent("foo.jpeg"))

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

