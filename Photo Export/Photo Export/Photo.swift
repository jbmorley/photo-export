//
//  Photo.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 04/02/2021.
//

import Combine
import Foundation
import Photos

enum PhotoError: Error {
    case invalidExtension
}

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

                return details.set(data: details.data.set(title: title)!)
            }
            .tryMap { details in

                guard let pathExtension = details.fileExtension else {
                    throw PhotoError.invalidExtension
                }

                let destinationUrl = url
                    .appendingPathComponent(self.asset.originalFilename.deletingPathExtension)
                    .appendingPathExtension(pathExtension)
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
