//
//  TaskManager.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 07/02/2021.
//

import Foundation

class TaskManager: NSObject, ObservableObject {

    @objc let queue = OperationQueue()

    var observation: NSKeyValueObservation?

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

    func run(_ task: Operation) {
        queue.addOperation(task)
    }

    func run(_ tasks: [Operation]) {
        queue.addOperations(tasks, waitUntilFinished: false)
    }

}
