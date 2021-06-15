//
//  FutureOperation.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 07/02/2021.
//

import Combine
import Foundation

class Task: Operation, Identifiable {

    let title: String
    var url: URL? = nil

    init(title: String) {
        self.title = title
    }

}

class FutureOperation: Task {

    override var isAsynchronous: Bool { false }
    override var isExecuting: Bool { running }
    override var isFinished: Bool { complete }

    var block: () -> AnyPublisher<URL, Error>
    var cancellable: Cancellable?
    var running = false
    var complete = false

    init(title: String, block: @escaping () -> AnyPublisher<URL, Error>) {
        self.block = block
        super.init(title: title)
    }

    override func start() {
        running = true
        let sem = DispatchSemaphore(value: 0)
        var url: URL?
        cancellable = block().sink(receiveCompletion: { result in
            sem.signal()
        }, receiveValue: { result in
            url = result
        })
        sem.wait()
        self.url = url
        complete = true
        running = false
    }

    override func cancel() {
        cancellable?.cancel()
    }

}
