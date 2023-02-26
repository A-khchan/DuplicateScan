//
//  ContentView.swift
//  DuplicateScan
//
//  Created by Albert Chan on 2/25/23.
//

import SwiftUI

struct ContentView: View {
    
    @State private var SelectedFolder: String = ""
    @State private var DScanFileManager: FileManager = FileManager()
    @State private var ContentInDir: [String] = []
    @State private var FileName: String = ""
    
    var body: some View {
        
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
            HStack {
                List(ContentInDir, id: \.self) {
                    FileName in
                    Text(FileName)
            	}
                List {
                    
                }
            }
            Picker(selection: .constant(1), label: Text("Folder")) {
                Text(SelectedFolder).tag(1)
                //Text("2").tag(2)
            }
            Button("Button") {
                let window: NSWindow = NSApp.mainWindow ?? NSWindow()
                
                let panel = NSOpenPanel()
                panel.canChooseFiles = false
                panel.canChooseDirectories = true
                panel.allowsMultipleSelection = false
                panel.isFloatingPanel = false
                panel.beginSheetModal(for: window) { (result) in
                    if result == NSApplication.ModalResponse.OK {
                        SelectedFolder = panel.urls[0].path
                        print(panel.urls[0])
                            
                        do {
                            try ContentInDir = DScanFileManager.contentsOfDirectory(atPath: panel.urls[0].path)
                        } catch {
                            ContentInDir = []
                        }
                        print(ContentInDir)
                    }
                }
            }
            
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
