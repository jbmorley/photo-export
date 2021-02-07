//
//  Thumbnail.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 02/02/2021.
//

import Photos
import SwiftUI

struct Thumbnail: View {

    let manager: Manager
    let asset: PHAsset

    @State var image: NSImage? = nil

    var heart: String {
        asset.isFavorite ? "❤️" : "..."
    }

    var body: some View {
        VStack {
            HStack {
                if let image = image {
                    Image(nsImage: image)
                        .fixedSize()
                        .frame(width: 200, height: 200)
                }
            }
            .frame(width: 200, height: 200)
            Text("\(heart)")
                .lineLimit(1)
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
