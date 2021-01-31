//
//  ContentView.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 30/01/2021.
//

import SwiftUI

struct Thumbnail: View {

    let manager: Manager
    let photo: Photo

    @State var image: NSImage? = nil

    var body: some View {
        HStack {
            if let image = image {
                Image(nsImage: image)
                    .fixedSize()
                    .frame(width: 200, height: 200)
            } else {
                Text("\(photo.asset.creationDate ?? Date.distantPast)")
            }
        }
        .onAppear(perform: {
            print("appear \(photo.id)")
            manager.imageManager.requestImage(for: photo.asset,
                                              targetSize: CGSize(width: 200, height: 200),
                                              contentMode: .aspectFit,
                                              options: nil,
                                              resultHandler: { image, _ in
                                                self.image = image
                                              })
        })
        .frame(width: 200, height: 200)
    }

}

struct ContentView: View {

    @ObservedObject var manager: Manager

    static let spacing: CGFloat = 8
    let columns = [GridItem(.adaptive(minimum: 200, maximum: 200), spacing: spacing)]

    var body: some View {
        VStack {
            if manager.requiresAuthorization {
                Button {
                    manager.authorize()
                } label: {
                    Text("Authorize")
                }
                .padding()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: Self.spacing) {
                        ForEach(manager.photos) { photo in
                            Thumbnail(manager: manager, photo: photo)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

