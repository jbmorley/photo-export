//
//  Photo_ExportApp.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 30/01/2021.
//

import Combine
import SwiftUI
import Photos


class Photo: Identifiable {

    let manager: Manager

    var id: String {
        asset.localIdentifier
    }

    var databaseUUID: String {
        return String(asset.localIdentifier.prefix(36))
    }

    let asset: PHAsset

    init(manager: Manager, asset: PHAsset) {
        self.manager = manager
        self.asset = asset
    }

    // TODO: Rename url
    func export(to url: URL, completion: @escaping (Result<Bool, Error>) -> Void) -> Cancellable {
        return manager.image(for: self)
            .receive(on: DispatchQueue.global(qos: .background))
            .tryMap { details -> AssetDetails in

                let metadata = try self.manager.metadata(for: self.databaseUUID)
                guard let title = metadata.title else {
                    return details
                }

                return AssetDetails(data: details.data.set(title: title)!,
                                    filename: details.filename,
                                    orientation: details.orientation)

            }
            .tryMap { details in

                let resources = PHAssetResource.assetResources(for: self.asset)
                let originalFilename = resources[0].originalFilename
                let basename = (originalFilename as NSString).deletingPathExtension  // TODO: Add convenience
                let pathExtension = (details.filename as NSString).pathExtension  // TODO: Add convenience
                let destinationUrl = url.appendingPathComponent(basename).appendingPathExtension(pathExtension)
                try details.data.write(to: destinationUrl)

            }
            .sink(receiveCompletion: { result in

                switch result {
                case .finished:
                    completion(.success(true))
                case .failure(let error):
                    completion(.failure(error))
                }

            }, receiveValue: { _ in })
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
