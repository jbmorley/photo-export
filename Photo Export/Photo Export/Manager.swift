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
    case invalidExtension
    case missingProperties
    case unknownImageType
    case invalidData
    case fileExists(url: URL)
}

struct ExportOptions {

    var overwriteExisting = false

}

class Manager: NSObject, ObservableObject {

    // TODO: Support setting the photo library.

    @Published var requiresAuthorization = true
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

    func metadata(for asset: PHAsset) -> Future<Metadata, Error> {
        return Future<Metadata, Error>.init { promise in
            DispatchQueue.main.async {
                do {
                    let libraryUrl = URL(fileURLWithPath: "/Users/jbmorley/Pictures/Photos Library.photoslibrary")
                    let library = PhotoLibrary(url: libraryUrl)
                    let metadata = try library.metadata(for: asset.databaseUUID)
                    promise(.success(metadata))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }

    func image(for asset: PHAsset) -> Future<AssetDetails, Error> {
        return Future<AssetDetails, Error> { promise in
            DispatchQueue.global(qos: .background).async {

                let options = PHImageRequestOptions()
                options.version = .current
                options.isNetworkAccessAllowed = true
                options.resizeMode = .exact
                options.deliveryMode = .highQualityFormat

                // TODO: Consider moving this to PHCachingImageManager?
                self.imageManager.requestImageDataAndOrientation(for: asset, options: options) {
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

    func export(video asset: PHAsset, directoryUrl: URL, options: ExportOptions) -> AnyPublisher<Bool, Error> {

        let availablePresets = AVAssetExportSession.allExportPresets()

        let videoRequestOptions = PHVideoRequestOptions()
        return self.imageManager.requestExportSession(video: asset,
                                                      options: videoRequestOptions,
                                                      exportPreset: availablePresets[0])
            .map { $0.session }
            .tryMap({ session -> AVAssetExportSession in

                // Configure the output destination.

                let outputFileType = session.supportedFileTypes[0]
                let outputPathExtension = outputFileType.pathExtension
                let destinationUrl = directoryUrl
                    .appendingPathComponent(asset.originalFilename.deletingPathExtension)
                    .appendingPathExtension(outputPathExtension)

                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: destinationUrl.path) {
                    if options.overwriteExisting {
                        try fileManager.removeItem(at: destinationUrl)
                    } else {
                        throw ManagerError.fileExists(url: destinationUrl)
                    }
                }

                session.outputFileType = outputFileType
                session.outputURL = destinationUrl

                return session
            })
            .zip(metadata(for: asset))
            .flatMap { session, metadata -> Future<Bool, Error> in

                // Set the metadata and start the export.

                var metadataItems: [AVMetadataItem] = []
                if let title = metadata.title {
                    metadataItems.append(self.makeMetadataItem(.commonIdentifierTitle,
                                                               value: title))
                }
                if let caption = metadata.caption {
                    metadataItems.append(self.makeMetadataItem(.commonIdentifierDescription,
                                                               value: caption))
                }
                if let creationDate = asset.creationDate {
                    metadataItems.append(self.makeMetadataItem(.commonIdentifierCreationDate,
                                                               value: creationDate))
                    metadataItems.append(self.makeMetadataItem(.quickTimeMetadataCreationDate,
                                                               value: creationDate))
                }
                if let modificationDate = asset.modificationDate {
                    metadataItems.append(self.makeMetadataItem(.commonIdentifierLastModifiedDate,
                                                               value: modificationDate))
                }
                if let location = asset.location {
                    print(location.iso6809Representation)
                    metadataItems.append(self.makeMetadataItem(.commonIdentifierLocation,
                                                               value: location.iso6809Representation))
                    metadataItems.append(self.makeMetadataItem(.quickTimeMetadataLocationISO6709,
                                                               value: location.iso6809Representation))
                }
                session.metadata = metadataItems

                return session.export()
            }
            .eraseToAnyPublisher()

    }

    func export(image asset: PHAsset, directoryUrl: URL, options: ExportOptions) -> AnyPublisher<Bool, Error> {
        return image(for: asset)
            .receive(on: DispatchQueue.global(qos: .background))
            .zip(metadata(for: asset))
            .tryMap { details, metadata -> AssetDetails in
                return details.set(data: try details.data.set(metadata: metadata))
            }
            .tryMap { details in
                guard let pathExtension = details.fileExtension else {
                    throw ManagerError.invalidExtension
                }
                let destinationUrl = directoryUrl
                    .appendingPathComponent(asset.originalFilename.deletingPathExtension)
                    .appendingPathExtension(pathExtension)

                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: destinationUrl.path) {
                    if options.overwriteExisting {
                        try fileManager.removeItem(at: destinationUrl)
                    } else {
                        throw ManagerError.fileExists(url: destinationUrl)
                    }
                }

                try details.data.write(to: destinationUrl)
                return true
            }
            .eraseToAnyPublisher()
    }

    func export(_ assets: [PHAsset], options: ExportOptions) throws {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        guard openPanel.runModal() == NSApplication.ModalResponse.OK,
              let url = openPanel.url else {
            print("export cancelled")
            return
        }
        let tasks = try assets
            .map { asset -> FutureOperation in
                let title = asset.originalFilename.deletingPathExtension
                switch asset.mediaType {
                case .image:
                    return FutureOperation(title: title) { self.export(image: asset,
                                                                       directoryUrl: url,
                                                                       options: options) }
                case .video:
                    return FutureOperation(title: title) { self.export(video: asset,
                                                                       directoryUrl: url,
                                                                       options: options) }
                default:
                    throw ManagerError.unsupportedMediaType
                }
        }
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
