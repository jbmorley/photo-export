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

class Collection: ObservableObject, Identifiable {

    var id: String { collection.id }

    @Published var photos: [Photo] = []

    // TODO: This should probably be weak??
    var manager: Manager
    var collection: PHAssetCollection

    var localizedTitle: String {
        collection.localizedTitle ?? "Untitled"
    }

    init(manager: Manager, collection: PHAssetCollection) {
        self.manager = manager
        self.collection = collection

        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        let result = PHAsset.fetchAssets(in: collection, options: options)
        result.enumerateObjects { asset, index, stop in
            dispatchPrecondition(condition: .onQueue(.main))
            self.photos.append(Photo(manager: manager, asset: asset))
        }
    }

}

class ExportTask: Operation {

    override var isAsynchronous: Bool { false }
    override var isExecuting: Bool { running }
    override var isFinished: Bool { complete }

    let photo: Photo
    let url: URL
    var cancelleable: Cancellable?
    var running = false
    var complete = false

    init(photo: Photo, url: URL) {
        self.photo = photo
        self.url = url
    }

    override func start() {
        running = true
        print("starting export")
        let sem = DispatchSemaphore(value: 0)
        cancelleable = photo.export(to: url) { result in
            switch result {
            case .success:
                print("successfully wrote file to \(self.url)")
            case .failure(let error):
                print("failed to safe photo with error \(error)")
            }
            // TODO: How do I know which thread to dispatch this to?

            sem.signal()
        }
        print("waiting for export to finish")
        sem.wait()
        print("finishing export")
        complete = true
        running = false
    }

    override func cancel() {
        cancelleable?.cancel()
    }

}

class TaskManager: ObservableObject {

    let queue = OperationQueue()

    init() {
        queue.maxConcurrentOperationCount = 1
    }

    func add(task: ExportTask) {
        queue.addOperation(task)
    }

}

struct AssetDetails {
    let data: Data
    let filename: String
    let orientation: CGImagePropertyOrientation
}

class Manager: NSObject, ObservableObject {

    @Published var requiresAuthorization = true
    @Published var photos: [Photo] = []
    @Published var collections: [Collection] = []

    let imageManager = PHCachingImageManager()
    let taskManager = TaskManager()

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

        // Get all the collections.
        let collectionResult = PHAssetCollection.fetchTopLevelUserCollections(with: nil)
        collectionResult.enumerateObjects { collection, index, stop in
            dispatchPrecondition(condition: .onQueue(.main))
            guard let assetCollection = collection as? PHAssetCollection else {
                return
            }
            self.collections.append(Collection(manager: self, collection: assetCollection))
        }

        // TODO: Consider doing this on a different thread.
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
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

    func image(for photo: Photo) -> Future<AssetDetails, Error> {
        return Future<AssetDetails, Error> { promise in
            DispatchQueue.global(qos: .background).async {
                let options = PHImageRequestOptions()
                options.version = .current
                options.isNetworkAccessAllowed = true
                options.resizeMode = .exact
                self.imageManager.requestImageDataAndOrientation(for: photo.asset, options: options) { data, filename, orientation, unknown in
                    guard let data = data,
                          let filename = filename else {
                        promise(.failure(ManagerError.unknown))
                        return
                    }
                    promise(.success(AssetDetails(data: data, filename: filename, orientation: orientation)))
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
