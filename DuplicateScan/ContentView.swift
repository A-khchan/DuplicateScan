//
//  ContentView.swift
//  DuplicateScan
//
//  Created by Albert Chan on 2/25/23.
//

import SwiftUI


struct FileWithID: Identifiable {
    var id = UUID()
    var FileName:String
}


struct ContentView: View {
    
    @State private var SelectedFolder: String = ""
    @State private var DScanFileManager: FileManager = FileManager()
    @State private var ContentInDir: [String] = []
    //@State private var FileName: String = ""
    @State private var SelectedFile: String? = nil
    //@State private var multiSelection = Set<UUID>()
    @State var listOfFileWithID = [
        FileWithID(FileName: "Empty")
    ]
    //@State var orgPanelURL: URL
    
    var body: some View {
        
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
            HStack {
                
                VStack {
                    List(listOfFileWithID, id: \.id, selection: $SelectedFile) { movie in
                        Text(movie.FileName)
                            .onTapGesture {
                                self.SelectedFile = movie.FileName
                                print("file:/" + SelectedFolder + "/" +  movie.FileName)
                                //var urlwithFilename: URL = URL(string: orgPanelURL + movie.FileName)!
                                //do {
                                //    let resource = try urlwithFilename.resourceValues(forKeys: [.fileSizeKey])
                                //    let fileSize = resource.fileSize!
                                //    SelectedFile = fileSize.codingKey.stringValue
                                //} catch {
                                //    print("error in getting file size")
                                //}
                            }
                            .listRowBackground(self.SelectedFile == movie.FileName ? Color.blue : Color.white)
                            .foregroundColor(self.SelectedFile == movie.FileName ? Color.white : Color.black)
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                
                VStack {
                    Text("\(SelectedFile ?? "N/A")")
                }
                .frame(minWidth: 0, maxWidth: .infinity)
            }
            Picker(selection: .constant(1), label: Text("Folder")) {
                Text(SelectedFolder ).tag(1)
            }
            Button("Button") {
                let window: NSWindow = NSApp.mainWindow ?? NSWindow()
                
                let panel = NSOpenPanel()
                panel.canChooseFiles = true
                panel.canChooseDirectories = true
                panel.allowsMultipleSelection = false
                panel.isFloatingPanel = true
                panel.beginSheetModal(for: window) { (result) in
                    if result == NSApplication.ModalResponse.OK {
                        print("panel.urls[0]: \(panel.urls[0])")
                        print("panel.urls[0].path: \(panel.urls[0].path)")
                        
                        if let fileAttributes = try? FileManager.default.attributesOfItem(atPath: panel.urls[0].path) {
                        
                            if let bytes = fileAttributes[.size] as? Int64 {
                                print("File size is: \(bytes)")
                            }
                        }
                        
                        //SelectedFolder = panel.urls[0].path
                        //var orgPanelURL = panel.urls[0]
                            
                        //do {
                        //    try ContentInDir = DScanFileManager.contentsOfDirectory(atPath: panel.urls[0].path)
                        //} catch {
                        //    ContentInDir = []
                        //}
                        //listOfFileWithID = []
                        //for fileOrDir in ContentInDir {
                        //    listOfFileWithID.append(FileWithID(FileName: fileOrDir))
                        //}
                        
                        //print(ContentInDir)
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
