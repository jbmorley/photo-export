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

import Foundation

// TODO: Rename this to ExportManager.
class TaskManager: NSObject, ObservableObject {

    @objc let queue = OperationQueue()

    var observation: NSKeyValueObservation?
    @Published var tasks: [Task] = []

    override init() {
        queue.maxConcurrentOperationCount = 3
        super.init()
        dispatchPrecondition(condition: .onQueue(.main))
        observation = observe(\.queue.operationCount, options: [.new]) { object, change in
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }

    func run(_ task: Task) {
        dispatchPrecondition(condition: .onQueue(.main))
        tasks.append(task)
        queue.addOperation(task)
    }

    func run(_ tasks: [Task]) {
        dispatchPrecondition(condition: .onQueue(.main))
        self.tasks.append(contentsOf: tasks)
        queue.addOperations(tasks, waitUntilFinished: false)
    }

    func clear() {
        dispatchPrecondition(condition: .onQueue(.main))
        self.tasks.removeAll { !$0.isExecuting && ( $0.isFinished || $0.isCancelled ) }
    }

}
