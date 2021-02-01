//
//  Photo_ExportApp.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 30/01/2021.
//

import SwiftUI
import Photos


class Photo: Identifiable {

    var id: String {
        asset.localIdentifier
    }

    let asset: PHAsset

    init(asset: PHAsset) {
        self.asset = asset
    }

}


class Manager: NSObject, ObservableObject, PHPhotoLibraryChangeObserver, PHPhotoLibraryAvailabilityObserver {

    @Published var requiresAuthorization = true
    @Published var photos: [Photo] = []

    let imageManager = PHCachingImageManager()

    func photoLibraryDidBecomeUnavailable(_ photoLibrary: PHPhotoLibrary) {
        print("photo library did become unavailable")
    }


    func photoLibraryDidChange(_ changeInstance: PHChange) {
        print("photo library did change")
    }

    override init() {
        super.init()
        print(PHPhotoLibrary.authorizationStatus(for: .readWrite))

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
        print(allPhotos)
        print(allPhotos.count)

        var photos: [Photo] = []
        allPhotos.enumerateObjects { asset, index, stop in
            photos.append(Photo(asset: asset))
        }
        self.photos = photos

        // TODO: Do we need to do this, see https://developer.apple.com/documentation/photokit/browsing_and_modifying_photo_albums.
//        imageManager.startCachingImages(for: addedAssets,
//                                        targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
//        imageManager.stopCachingImages(for: removedAssets,
//                                       targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)


//
//        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
//        print(smartAlbums)
//
//        let userCollections = PHCollectionList.fetchTopLevelUserCollections(with: nil)
//        print(userCollections)

    }

    func authorize() {
        print("Request authorization")

        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            print(status)
        }
    }

}

struct ManagerKey: EnvironmentKey {
    static var defaultValue: Manager = Manager()
}

extension EnvironmentValues {
    var manager: Manager {
        get { self[ManagerKey.self] }
        set { self[ManagerKey.self] = newValue }
    }
}

@main
struct Photo_ExportApp: App {

    var manager = Manager()

    var body: some Scene {
        WindowGroup {
            ContentView(manager: manager)
                .preferredColorScheme(.dark)
        }
    }
}
