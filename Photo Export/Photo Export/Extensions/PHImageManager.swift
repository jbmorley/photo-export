//
//  PHImageManager.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 07/02/2021.
//

import Combine
import Photos

struct ExportSession {

    let session: AVAssetExportSession
    let info: [AnyHashable : Any]

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
