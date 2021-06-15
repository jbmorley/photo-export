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
