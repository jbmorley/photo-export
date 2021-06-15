// Copyright (c) 2021 InSeven Limited
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
