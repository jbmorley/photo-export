//
//  Photo_ExportApp.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 30/01/2021.
//

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

    func export(to url: URL, completion: @escaping (Result<Bool, Error>) -> Void) {

        let completion: (Result<Bool, Error>) -> Void = { result in
            DispatchQueue.global(qos: .background).async {
                completion(result)
            }
        }

        var metadata: PhotoMetadata?
        do {
            metadata = try manager.metadata(for: databaseUUID)  // TODO: This can almost certainly error too!
        } catch {
            completion(.failure(error))
            return
        }
        let safeMetadata = metadata!

        let options = PHImageRequestOptions()
        options.version = .current
        options.isNetworkAccessAllowed = true
        options.resizeMode = .exact

        manager.image(for: asset) { result in
            switch result {
            case .success(let data):
                guard let image = data.set(title: safeMetadata.title) else {
                    print("failed to set title")
                    // TODO: Completion with error.
                    return
                }
                try! image.write(to: url)
                completion(.success(true))
            case .failure(let error):
                completion(.failure(error))
            }
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
