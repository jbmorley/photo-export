//
//  PHImageManager.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 07/02/2021.
//

import Combine
import Photos


// TODO: A cancellable future would be great. Is this just a single yielding promise?


struct ExportSession {

    let session: AVAssetExportSession
    let info: [AnyHashable : Any]

}

extension AVAssetExportSession {

    func export() -> Future<URL, Error> {
        return Future<URL, Error>.init { promise in
            self.exportAsynchronously {
                switch self.status {
                case .completed:
                    guard let url = self.outputURL else {
                        promise(.failure(ManagerError.unknown))  // TODO: Process this better.
                        return
                    }
                    promise(.success(url))
                default:
                    promise(.failure(self.error ?? ManagerError.unknown))
                }
            }
        }
    }

}

extension PHImageManager {

    // Result called on an arbitrary queue.
    func requestExportSession(video: PHAsset, options: PHVideoRequestOptions, exportPreset: String) -> Future<ExportSession, Error> {
        return Future<ExportSession, Error>.init { promise in
            self.requestExportSession(forVideo: video, options: options, exportPreset: exportPreset) { session, info in
                guard let session = session,
                      let info = info else {
                    promise(.failure(ManagerError.unknown))  // TODO: Better error reporting?
                    return
                }
                promise(.success(ExportSession(session: session, info: info)))
            }
        }
    }

}


