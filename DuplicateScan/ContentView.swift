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
    var DupNumber:Int = 0 //0 means no duplication, 1 means first file in duplicated files, duplication means same file size and same creation date.
}


struct ContentView: View {
    
    @State private var SelectedFolder: String = ""
    @State private var DScanFileManager: FileManager = FileManager()
    @State private var ContentInDir: [String] = []
    @State private var SelectedFile: String? = nil
    @State private var selectedSize: Int64 = 0
    @State private var selectedDate: NSDate = Date() as NSDate
    @State private var SelectedFileForProcess: String? = nil
    @State var listOfFileWithID = [
        FileWithID(FileName: "Empty")
    ]
    @State var sortedListOfFileWithID: [FileWithID] = []
    @State private var isOn = false
    
    var body: some View {
        
        VStack {
            HStack {
                VStack {
                    Toggle(isOn: $isOn) {
                        Text("Show only files with duplication")
                    }
                    .toggleStyle(.checkbox)
                    
                    List(sortedListOfFileWithID.filter { $0.DupNumber < 2 && isOn == false ||
                        $0.DupNumber == 1 && isOn
                    }, id: \.id, selection: $SelectedFile) { fileWithID in
                        HStack {
                            if fileWithID.DupNumber == 0 {
                                Image(systemName: "doc")
                                    .imageScale(.large)
                            } else {
                                Image(systemName: "doc.on.doc")
                                    .imageScale(.large)
                            }
                            Text(fileWithID.FileName)
                                .onTapGesture {
                                    //Store it to adjust color of selected row
                                    self.SelectedFile = fileWithID.FileName
                                    self.selectedSize = fileWithID.FileSize
                                    self.selectedDate = fileWithID.FileCreationDate ?? Date() as NSDate
                                    
                                    print("filePath: \(fileWithID.FileName)")
                                    print("filePath: \(fileWithID.FileSize)")
                                    print("filePath: \(String(describing: fileWithID.FileCreationDate))")
                                }
                                
                        }
                        .listRowBackground(self.SelectedFile == fileWithID.FileName ? Color.blue : Color.white)
                        .foregroundColor(self.SelectedFile == fileWithID.FileName ? Color.white : Color.black)
                    }
                    //Summary
                    Text("Number of file without duplication: \(sortedListOfFileWithID.filter { $0.DupNumber == 0 }.count)")
                    Text("Number of file with duplication: \(sortedListOfFileWithID.filter { $0.DupNumber == 1 }.count)")
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                
                VStack {
                    //Text("\(SelectedFile ?? "N/A")")
                    List(sortedListOfFileWithID.filter { $0.DupNumber >= 2 && $0.FileSize == selectedSize && $0.FileCreationDate?.timeIntervalSinceReferenceDate == selectedDate.timeIntervalSinceReferenceDate }, id: \.id, selection: $SelectedFileForProcess) { fileWithID in
                        Text(fileWithID.FileName)
                            .onTapGesture {
                                //
                                self.SelectedFileForProcess = fileWithID.FileName
                            }
                            .listRowBackground(self.SelectedFileForProcess == fileWithID.FileName ? Color.blue : Color.white)
                            .foregroundColor(self.SelectedFileForProcess == fileWithID.FileName ? Color.white : Color.black)
                    }
                    Text("Number of duplicated files: \(sortedListOfFileWithID.filter { $0.DupNumber > 1 }.count)")
                    Text("Total size (in bytes) of duplicated files: \(sortedListOfFileWithID.filter { $0.DupNumber > 1 }.reduce(0, { $0 + $1.FileSize}))")
                    
                }
                .frame(minWidth: 0, maxWidth: .infinity)
            }
            Picker(selection: .constant(1), label: Text("Folder")) {
                Text(SelectedFolder ).tag(1)
            }
            Button("Choose folder") {
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
                        sortedListOfFileWithID = listOfFileWithID.sorted(by: ) { (lhs, rhs) in
                            if lhs.FileCreationDate == rhs.FileCreationDate {
                                return lhs.FileSize < rhs.FileSize
                            }
                            
                            let L = lhs.FileCreationDate ?? Date() as NSDate
                            let R = rhs.FileCreationDate ?? Date() as NSDate
                            
                            return L.timeIntervalSinceReferenceDate
                            < R.timeIntervalSinceReferenceDate
                            
                        }
                        
                        var prevSize:Int64 = 0
                        var prevDate:NSDate = Date() as NSDate
                        var i = 0
                        for item in sortedListOfFileWithID {
                            //print("Name: \(item.FileName)")
                            //print("Size: \(item.FileSize) ")
                            //print("Create Date: \(String(describing: item.FileCreationDate))")
                            if i > 0 {
                                let thisDate = item.FileCreationDate ?? Date() as NSDate
                                if prevSize == item.FileSize &&
                                    prevDate.timeIntervalSinceReferenceDate == thisDate.timeIntervalSinceReferenceDate {
                                    if sortedListOfFileWithID[i-1].DupNumber == 0 {
                                        sortedListOfFileWithID[i-1].DupNumber = 1
                                    }
                                    sortedListOfFileWithID[i].DupNumber = sortedListOfFileWithID[i-1].DupNumber + 1
                                }
                            }
                            prevSize = item.FileSize
                            prevDate = item.FileCreationDate ?? Date() as NSDate
                            i += 1
                        }
                        
                        print("****Sorted List is:")
                        for item in sortedListOfFileWithID {
                            print("Name: \(item.FileName)")
                            print("Size: \(item.FileSize) ")
                            print("Create Date: \(String(describing: item.FileCreationDate))")
                            print("DupNumber: \(item.DupNumber)")
                        }
                        //print(sortedListOfFileWithID)
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
