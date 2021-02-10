//
//  ExportsView.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 09/02/2021.
//

import SwiftUI

struct ExportsView: View {

    @ObservedObject var manager: Manager
    @ObservedObject var taskManager: TaskManager

    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach(manager.taskManager.tasks) { task in
                    HStack {
                        Text(task.title)
                        Spacer()
                        if (task.isExecuting) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .controlSize(.small)
                        } else if (task.isFinished) {
                            Button {
                                guard let url = task.url else {
                                    return
                                }
                                NSWorkspace.shared.activateFileViewerSelecting([url])
                            } label: {
                                Image(systemName: "magnifyingglass.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                    .padding()
                    Divider()
                }
            }
            Divider()
            Text("\(taskManager.tasks.count) Pending")
                .foregroundColor(.secondary)
                .padding()
        }
        .toolbar {
            ToolbarItem {
                Button {
                    taskManager.clear()
                } label: {
                    Text("Clear")
                }
                .foregroundColor(.primary)
            }
        }
    }

}
