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
    case unsupportedMediaType
}



// TODO: Move this out.
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


class FutureOperation: Operation {

    override var isAsynchronous: Bool { false }
    override var isExecuting: Bool { running }
    override var isFinished: Bool { complete }

    var block: () -> AnyPublisher<Bool, Error>
    var cancellable: Cancellable?
    var running = false
    var complete = false

    init(block: @escaping () -> AnyPublisher<Bool, Error>) {
        self.block = block
    }

    override func start() {
        running = true
        print("starting export")
        let sem = DispatchSemaphore(value: 0)
        cancellable = block().sink(receiveCompletion: { result in
            switch result {
            case .finished:
                print("future operation success")
            case .failure(let error):
                print("future operation failure with error \(error)")
            }
            sem.signal()
        }, receiveValue: { _ in })

        sem.wait()
        complete = true
        running = false
    }

    override func cancel() {
        cancellable?.cancel()
    }

}


// TODO: Move this out.
class TaskManager: NSObject, ObservableObject {

    @objc let queue = OperationQueue()

    var observation: NSKeyValueObservation?

    override init() {
        queue.maxConcurrentOperationCount = 3
        super.init()
        dispatchPrecondition(condition: .onQueue(.main))
        observation = observe(\.queue.operationCount, options: [.new]) { object, change in
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }

    func run(_ task: Operation) {
        queue.addOperation(task)
    }

    func run(_ tasks: [Operation]) {
        queue.addOperations(tasks, waitUntilFinished: false)
    }

}

extension AVFileType {
    var utType: UTType { UTType(rawValue)! }
    var pathExtension: String { utType.preferredFilenameExtension! }  // TODO: This should be able to fail
}

class Manager: NSObject, ObservableObject {

    // TODO: Support setting the photo library.

    @Published var requiresAuthorization = true
    @Published var photos: [Photo] = []
    @Published var collections: [Collection] = []

    let imageManager = PHCachingImageManager()
    let taskManager = TaskManager()

    var cancellable: Cancellable?

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

        // TODO: Do something with these.
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

        cancellable = taskManager.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }

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

                // TODO: Do I need to normalize the crop rect?
                options.deliveryMode = .highQualityFormat

                // TODO: Consider moving this to PHCachingImageManager?
                self.imageManager.requestImageDataAndOrientation(for: photo.asset, options: options) {
                    data, uti, orientation, unknown in
                    guard let data = data,
                          let uti = uti else {
                        promise(.failure(ManagerError.unknown))
                        return
                    }
                    promise(.success(AssetDetails(data: data, uti: uti, orientation: orientation)))
                }

            }
        }
    }

    func makeMetadataItem(_ identifier: AVMetadataIdentifier, value: Any) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.identifier = identifier
        item.value = value as? NSCopying & NSObjectProtocol
        item.extendedLanguageTag = "und"
        return item.copy() as! AVMetadataItem
    }

    // TODO: Perhaps this could be moved to the image manager?
    // TODO: Rename this.
    func exportVideo(asset: PHAsset, directoryUrl: URL) -> AnyPublisher<Bool, Error> {

        let availablePresets = AVAssetExportSession.allExportPresets()
        print(availablePresets)

        let options = PHVideoRequestOptions()
        return self.imageManager.requestExportSession(video: asset,
                                                      options: options,
                                                      exportPreset: availablePresets[0])
            .map { $0.session }
            .flatMap { session -> Future<Bool, Error> in

                print("\(session)")
                print("\(asset.originalFilename)")
                print("\(session.supportedFileTypes)")
                print(session.metadata ?? "nil")

                let titleItem = self.makeMetadataItem(.commonIdentifierTitle, value: "My Movie Title")
                let descItem = self.makeMetadataItem(.commonIdentifierDescription, value: "My Movie Description")
                session.metadata = [titleItem, descItem]

                let outputFileType = session.supportedFileTypes[0]
                let outputPathExtension = outputFileType.pathExtension

                session.outputFileType = outputFileType
                session.outputURL = directoryUrl
                    .appendingPathComponent(asset.originalFilename.deletingPathExtension)
                    .appendingPathExtension(outputPathExtension)

                return session.export()
            }
            .eraseToAnyPublisher()

    }

    // TODO: Switch this to assets.
    func exportOperation(photo: Photo, directoryUrl: URL) throws -> Operation {
        switch photo.asset.mediaType {
        case .image:
            return ExportTask(photo: photo, url: directoryUrl)
        case .video:
            return FutureOperation { self.exportVideo(asset: photo.asset, directoryUrl: directoryUrl) }
        default:
            throw ManagerError.unsupportedMediaType
        }
    }

    func export(_ photos: [Photo]) throws {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        guard openPanel.runModal() == NSApplication.ModalResponse.OK,
              let url = openPanel.url else {
            print("export cancelled")
            return
        }
        let tasks = try photos.map { try self.exportOperation(photo: $0, directoryUrl: url) }
        taskManager.run(tasks)
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
