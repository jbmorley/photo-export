//
//  TaskManager.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 07/02/2021.
//

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
