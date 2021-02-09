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
                                print("Reveal in finder")
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
                .padding()
        }
        .toolbar {
            ToolbarItem {
                Button {

                } label: {
                    Text("Clear")
                }
                .foregroundColor(.primary)
            }
        }
    }

}
