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
    var FileSize:Int64 = 0
    var FileCreationDate: NSDate?
}


struct ContentView: View {
    
    @State private var SelectedFolder: String = ""
    @State private var DScanFileManager: FileManager = FileManager()
    @State private var ContentInDir: [String] = []
    @State private var SelectedFile: String? = nil
    @State var listOfFileWithID = [
        FileWithID(FileName: "Empty")
    ]
    
    var body: some View {
        
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
            HStack {
                
                VStack {
                    List(listOfFileWithID, id: \.id, selection: $SelectedFile) { fileWithID in
                        Text(fileWithID.FileName)
                            .onTapGesture {
                                //Store it to adjust color of selected row
                                self.SelectedFile = fileWithID.FileName
                                
                                print("filePath: \(fileWithID.FileName)")
                                print("filePath: \(fileWithID.FileSize)")
                                print("filePath: \(String(describing: fileWithID.FileCreationDate))")
                            }
                            .listRowBackground(self.SelectedFile == fileWithID.FileName ? Color.blue : Color.white)
                            .foregroundColor(self.SelectedFile == fileWithID.FileName ? Color.white : Color.black)
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
                panel.canChooseFiles = false
                panel.canChooseDirectories = true
                panel.allowsMultipleSelection = false
                panel.isFloatingPanel = true
                panel.beginSheetModal(for: window) { (result) in
                    if result == NSApplication.ModalResponse.OK {
                        print("panel.urls[0]: \(panel.urls[0])")
                        //path(percentEncoded:)' is only available in macOS 13.0 or newer
                        print("panel.urls[0].path: \(panel.urls[0].path)")
                        
                        if let fileAttributes = try? FileManager.default.attributesOfItem(atPath: panel.urls[0].path) {
                        
                            if let bytes = fileAttributes[.size] as? Int64 {
                                print("File size is: \(bytes)")
                            }
                        }
                        
                        SelectedFolder = panel.urls[0].path
                            
                        do {
                            try ContentInDir = DScanFileManager.contentsOfDirectory(atPath: panel.urls[0].path)
                        } catch {
                            ContentInDir = []
                        }
                        listOfFileWithID = []
                        for fileOrDir in ContentInDir {
                            listOfFileWithID.append(FileWithID(FileName: fileOrDir))
                        }
                        
                        print(ContentInDir)
                        
                        listOfFileWithID = getFileInfoArray(folder: panel.urls[0].path)
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

func getFileInfoArray (folder: String) -> [FileWithID] {
    var ContentInDir: [String] = []
    let DScanFileManager: FileManager = FileManager()
    var listOfFileWithID = [
        FileWithID(FileName: "Empty")
    ]
    var retrievedBytes: Int64 = 0
    var retrievedCreateDateTime: NSDate?
    
    //First, get content of this folder
    do {
        try ContentInDir = DScanFileManager.contentsOfDirectory(atPath: folder)
    } catch {
        ContentInDir = []
    }
    
    //loop the content and fill up array
    listOfFileWithID = []
    for fileOrDir in ContentInDir {
        if let fileAttributes = try? FileManager.default.attributesOfItem(atPath: folder + "/" + fileOrDir) {
            
            if let fileType = fileAttributes[.type] as? FileAttributeType {
                if fileType == .typeDirectory {
                    print("Is Directory")
                    listOfFileWithID += getFileInfoArray(folder: folder + "/" + fileOrDir)
                } else {
                    print("Is not Directory")
                    if let bytes = fileAttributes[.size] as? Int64 {
                        print("(2)File size is: \(bytes)")
                        retrievedBytes = bytes
                    }
                    if let createDateTime = fileAttributes[.creationDate] as? NSDate {
                        print("createDateTime is: \(createDateTime)")
                        retrievedCreateDateTime = createDateTime
                    }
                    listOfFileWithID.append(FileWithID(FileName: folder + "/" + fileOrDir, FileSize: retrievedBytes, FileCreationDate: retrievedCreateDateTime))
                }
            }
        }
    }
    
    return listOfFileWithID
}
