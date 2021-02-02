//
//  Manager.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 02/02/2021.
//

import Photos
import SwiftUI
import SQLite3


struct PhotoMetadata {

    let title: String
    let caption: String

}

let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)


enum PhotoLibraryError: Error {
    case notFound
}

class PhotoLibrary {

    let url: URL

    init(url: URL) {
        self.url = url
    }

    func metadata(for id: String) throws -> PhotoMetadata? {

        guard FileManager.default.fileExists(atPath: self.url.path) else {
            throw PhotoLibraryError.notFound
        }

        var db: OpaquePointer?
        guard sqlite3_open(url.path, &db) == SQLITE_OK else {
            print("error opening database")
            sqlite3_close(db)
            db = nil
            return nil
        }

        defer {
            print("closing the database")
            if sqlite3_close(db) != SQLITE_OK {
                print("error closing database")
            }
            db = nil
        }

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, "SELECT ZADDITIONALASSETATTRIBUTES.ZTITLE FROM ZASSET JOIN ZADDITIONALASSETATTRIBUTES ON ZADDITIONALASSETATTRIBUTES.ZASSET = ZASSET.Z_PK where ZUUID = ?", -1, &statement, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error preparing select: \(errmsg)")
        }

        if sqlite3_bind_text(statement, 1, id, -1, SQLITE_TRANSIENT) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("failure binding foo: \(errmsg)")
        }

        var name: String?

        defer {
            print("finalizing the statement")
            if sqlite3_finalize(statement) != SQLITE_OK {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                print("error finalizing prepared statement: \(errmsg)")
            }
            statement = nil
        }

        while sqlite3_step(statement) == SQLITE_ROW {
            if let cString = sqlite3_column_text(statement, 0) {
                name = String(cString: cString)
                print("name = \(name ?? "?")")
            } else {
                print("name not found")
            }
        }

        guard let safeName = name else {
            return nil
        }

        return PhotoMetadata(title: safeName, caption: safeName)
    }

}


enum ManagerError: Error {

    case unknown

}


class Manager: NSObject, ObservableObject {

    @Published var requiresAuthorization = true
    @Published var photos: [Photo] = []

    let imageManager = PHCachingImageManager()

    override init() {
        super.init()

        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized, .restricted, .limited:
            print("authorized")
            requiresAuthorization = false
        case .notDetermined, .denied:
            requiresAuthorization = true
        @unknown default:
            requiresAuthorization = true
        }

        PHPhotoLibrary.shared().register(self as PHPhotoLibraryChangeObserver)
        PHPhotoLibrary.shared().register(self as PHPhotoLibraryAvailabilityObserver)

        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)


        // TODO: Consider doing this on a different thread.
        var photos: [Photo] = []
        allPhotos.enumerateObjects { asset, index, stop in
            photos.append(Photo(manager: self, asset: asset))
        }
        self.photos = photos

        // TODO: Do we need to do this, see https://developer.apple.com/documentation/photokit/browsing_and_modifying_photo_albums.
//        imageManager.startCachingImages(for: addedAssets,
//                                        targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
//        imageManager.stopCachingImages(for: removedAssets,
//                                       targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)

    }

    func authorize() {
        print("Request authorization")

        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            print(status)
        }
    }

    func metadata(for id: String) throws -> PhotoMetadata? {
        // TODO: Consider making this a Promise.
        let libraryUrl = URL(fileURLWithPath: "/Users/jbmorley/Pictures/Photos Library.photoslibrary/database/Photos.sqlite")
        let library = PhotoLibrary(url: libraryUrl)
        return try library.metadata(for: id)
    }

    func image(for asset: PHAsset, completion: @escaping (Result<Data, Error>) -> Void) {

        let completion: (Result<Data, Error>) -> Void = { result in
            DispatchQueue.global(qos: .background).async {
                completion(result)
            }
        }

        let options = PHImageRequestOptions()
        options.version = .current
        options.isNetworkAccessAllowed = true
        options.resizeMode = .exact

        imageManager.requestImageDataAndOrientation(for: asset, options: options) { data, filename, orientation, unknown in
            guard let data = data else {
                completion(.failure(ManagerError.unknown))
                return
            }
            completion(.success(data))
        }

    }

}


extension Manager: PHPhotoLibraryChangeObserver {

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        print("photo library did change")
    }

}

extension Manager: PHPhotoLibraryAvailabilityObserver {

    func photoLibraryDidBecomeUnavailable(_ photoLibrary: PHPhotoLibrary) {
        print("photo library did become unavailable")
    }

}
