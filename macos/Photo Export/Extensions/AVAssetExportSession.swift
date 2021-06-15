//
//  AVAssetExportSession.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 16/02/2021.
//

import Combine
import Foundation
import Photos

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
