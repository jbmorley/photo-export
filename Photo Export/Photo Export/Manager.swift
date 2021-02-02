//
//  Manager.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 02/02/2021.
//

import Combine
import Photos
import SwiftUI

struct ManagerKey: EnvironmentKey {
    static var defaultValue: Manager = Manager()
}

extension EnvironmentValues {
    var manager: Manager {
        get { self[ManagerKey.self] }
        set { self[ManagerKey.self] = newValue }
    }
}

enum ManagerError: Error {
    case unknown
}

class Manager: NSObject, ObservableObject {

    @Published var requiresAuthorization = true
    @Published var photos: [Photo] = []
    @Published var collections: [PHCollection] = []

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

        // Get all the collections.
        let collectionResult = PHAssetCollection.fetchTopLevelUserCollections(with: nil)
        collectionResult.enumerateObjects { collection, index, stop in
            dispatchPrecondition(condition: .onQueue(.main))
            self.collections.append(collection)
        }

        // TODO: Consider doing this on a different thread.
        var photos: [Photo] = []
        allPhotos.enumerateObjects { asset, index, stop in
            dispatchPrecondition(condition: .onQueue(.main))
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

    func metadata(for id: String) throws -> PhotoMetadata {
        // TODO: Consider making this a Promise.
        let libraryUrl = URL(fileURLWithPath: "/Users/jbmorley/Pictures/Photos Library.photoslibrary/database/Photos.sqlite")
        let library = PhotoLibrary(url: libraryUrl)
        return try library.metadata(for: id)
    }

    func image(for photo: Photo) -> Future<Data, Error> {
        return Future<Data, Error> { promise in
            DispatchQueue.global(qos: .background).async {
                let options = PHImageRequestOptions()
                options.version = .current
                options.isNetworkAccessAllowed = true
                options.resizeMode = .exact
                self.imageManager.requestImageDataAndOrientation(for: photo.asset, options: options) { data, filename, orientation, unknown in
                    guard let data = data else {
                        promise(.failure(ManagerError.unknown))
                        return
                    }
                    promise(.success(data))
                }

            }
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
