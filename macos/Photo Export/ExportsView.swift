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
