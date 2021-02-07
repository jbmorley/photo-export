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

    func run(_ task: ExportTask) {
        queue.addOperation(task)
    }

    func run(_ tasks: [ExportTask]) {
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

//
    // TODO: Perhaps this could be moved to the image manager?
    func exportVideo(_ photo: Photo) {

        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        guard openPanel.runModal() == NSApplication.ModalResponse.OK,
              let url = openPanel.url else {
            print("export cancelled")
            return
        }

        let options = PHVideoRequestOptions()

        // Get the presets.
        let availablePresets = AVAssetExportSession.allExportPresets()
        print(availablePresets)

        self.imageManager.requestExportSession(forVideo: photo.asset,
                                               options: options,
                                               exportPreset: availablePresets[0]) { session, info in
            print("Doing some export??")
            guard let session = session,
                  let info = info else {
                print("unable to get export session")
                return
            }
            print("\(session)")
            print("\(info)")
            print("\(photo.asset.originalFilename)")
            print("\(session.supportedFileTypes)")
            print(session.metadata)

            let titleItem = self.makeMetadataItem(.commonIdentifierTitle, value: "My Movie Title")
            let descItem = self.makeMetadataItem(.commonIdentifierDescription, value: "My Movie Description")
            session.metadata = [titleItem, descItem]


            let outputFileType = session.supportedFileTypes[0]
            let outputPathExtension = outputFileType.pathExtension

            session.outputFileType = outputFileType
            session.outputURL = url.appendingPathComponent(photo.asset.originalFilename.deletingPathExtension).appendingPathExtension(outputPathExtension)
            session.exportAsynchronously {
                print("done!")
            }
        }
    }

    func export(_ photos: [Photo]) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        guard openPanel.runModal() == NSApplication.ModalResponse.OK,
              let url = openPanel.url else {
            print("export cancelled")
            return
        }
        let tasks = photos.map { ExportTask(photo: $0, url: url) }
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
