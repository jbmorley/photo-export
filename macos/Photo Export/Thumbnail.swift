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

import Photos
import SwiftUI

struct Thumbnail: View {

    let manager: Manager
    let asset: PHAsset

    @State var image: NSImage? = nil

    var body: some View {
        VStack {
            ZStack(alignment: Alignment(horizontal: .leading, vertical: .bottom)) {
                if let image = image {
                    Image(nsImage: image)
                        .fixedSize()
                }
                if asset.isFavorite {
                    Image(systemName: "heart.fill")
                        .shadow(radius: 16)
                        .padding(8)
                }
            }
            .frame(width: 200, height: 200)
        }
        .onAppear(perform: {
            manager.imageManager.requestImage(for: asset,
                                              targetSize: CGSize(width: 200, height: 200),
                                              contentMode: .aspectFit,
                                              options: nil,
                                              resultHandler: { image, _ in
                                                self.image = image
                                              })
        })
    }

}
