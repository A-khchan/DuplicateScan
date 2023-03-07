//
//  ContentView.swift
//  DuplicateScan
//
//  Created by Albert Chan on 2/25/23.
//

import SwiftUI
import AVKit

struct FileWithID: Identifiable {
    var id = UUID()
    var FileName:String
    var FileSize:Int64 = 0
    var FileCreationDate: NSDate?
    var DupNumber:Int = 0 //0 means no duplication, 1 means first file in duplicated files, duplication means same file size and same creation date.
}

struct PlayerView: NSViewRepresentable {
    @Binding var player: AVPlayer

    func updateNSView(_ NSView: NSView, context: NSViewRepresentableContext<PlayerView>) {
        guard let view = NSView as? AVPlayerView else {
            debugPrint("unexpected view")
            return
        }

        view.player = player
    }

    func makeNSView(context: Context) -> NSView {
        return AVPlayerView(frame: .zero)
    }
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
    @State private var Dup1:Int = 0
    @State private var Dup2:Int = 0
    @State private var player: AVPlayer = AVPlayer()
    @State private var playerRHS: AVPlayer = AVPlayer()
    
    var body: some View {
        
        VStack {
            HStack {
                VStack {
                    Toggle(isOn: $isOn) {
                        Text("Show only files with duplication")
                            .frame(minHeight: 23)
                    }
                    .toggleStyle(.checkbox)
                    
                    List(sortedListOfFileWithID.filter { $0.DupNumber < 2 && $0.DupNumber >= 0 && isOn == false ||
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
                            //A file on left side list is clicked
                            Text(fileWithID.FileName)
                                .onTapGesture {
                                    
                                    //Store SelectedFile for adjusting color of selected row
                                    self.SelectedFile = fileWithID.FileName
                                    self.selectedSize = fileWithID.FileSize
                                    self.selectedDate = fileWithID.FileCreationDate ?? Date() as NSDate
                                    
                                    //Example to convert string to path
                                    //print("Convert string to path: \(URL(fileURLWithPath: SelectedFile!))")
                                    
                                    //print("filePath: \(fileWithID.FileName)")
                                    //print("filePath: \(fileWithID.FileSize)")
                                    //print("filePath: \(String(describing: fileWithID.FileCreationDate))")
                                    
                                    //Prepare player (AVPlayer) for PlayerView to display the video playback
                                    let asset = AVAsset(url: URL(fileURLWithPath: SelectedFile!))
                                    let playerItem = AVPlayerItem(asset: asset)
                                    player.replaceCurrentItem(with: playerItem)
                                    
                                    SelectedFileForProcess = nil
                                }
                        }
                        .listRowBackground(self.SelectedFile == fileWithID.FileName ? Color.blue : Color.white)
                        .foregroundColor(self.SelectedFile == fileWithID.FileName ? Color.white : Color.black)
                    }
                    //Summary
                    Text("Number of file without duplication: \(sortedListOfFileWithID.filter { $0.DupNumber == 0 }.count)")
                    
                    Text("Number of file with duplication: \(sortedListOfFileWithID.filter { $0.DupNumber == 1 }.count)")
                    if let image = NSImage(contentsOf: URL(fileURLWithPath: SelectedFile ?? ""))
                    {   //if loading an image is successful, display it
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 300, alignment:.center)
                    } else {
                        
                        //Video player if it has ext. mov
                        if SelectedFile != nil && URL(fileURLWithPath: SelectedFile!).pathExtension == "mov" {
                            PlayerView(player: $player)
                        } else {
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 100, alignment:.center)
                        }
                    }
                    
                    Text("Selected file size: \(sortedListOfFileWithID.filter { $0.FileName == SelectedFile }.reduce(0, { $0 + $1.FileSize}))")
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                
                //Right hand side column
                VStack {
                    HStack {
                        Button("Swap files") {
                            //Button is clicked
                            if let index = sortedListOfFileWithID.firstIndex(where: {$0.FileName == SelectedFile}) {
                                Dup1 = sortedListOfFileWithID[index].DupNumber
                            }
                            if let index = sortedListOfFileWithID.firstIndex(where: {$0.FileName == SelectedFileForProcess}) {
                                Dup2 = sortedListOfFileWithID[index].DupNumber
                            }
                            //Update DupNumber in array
                            if let index = sortedListOfFileWithID.firstIndex(where: {$0.FileName == SelectedFile}) {
                                sortedListOfFileWithID[index].DupNumber = Dup2
                            }
                            if let index = sortedListOfFileWithID.firstIndex(where: {$0.FileName == SelectedFileForProcess}) {
                                sortedListOfFileWithID[index].DupNumber = Dup1
                            }
                            //After swap, list refreshed and result in no selection
                            SelectedFile = nil
                            SelectedFileForProcess = nil
                        }
                        .disabled(SelectedFile == nil || SelectedFileForProcess == nil)
                        
                        Text("Duplicated files")
                            .frame(minHeight: 23)
                        Button("Delete the below selected file") {
                                
                            //Really delete the file upon button clicked
                            do {
                                if DScanFileManager.fileExists(atPath: SelectedFileForProcess!) {
                                    // Delete file
                                    try DScanFileManager.removeItem(atPath: SelectedFileForProcess!)
                                    
                                    if let index = sortedListOfFileWithID.firstIndex(where: {$0.FileName == SelectedFileForProcess}) {
                                        //Update DupNumber to -1 to hide the file from being displayed
                                        sortedListOfFileWithID[index].DupNumber = -1
                                    }
                                    SelectedFileForProcess = nil
                                    
                                    //if all duplicated files are deleted, also update first file's DupNumber to 0 to indicate it has no more duplication.
                                    if sortedListOfFileWithID.filter({ $0.DupNumber >= 2 && $0.FileSize == selectedSize && $0.FileCreationDate?.timeIntervalSinceReferenceDate == selectedDate.timeIntervalSinceReferenceDate }).count == 0 {
                                        if let index = sortedListOfFileWithID.firstIndex(where: {$0.FileName == SelectedFile}) {
                                            sortedListOfFileWithID[index].DupNumber = 0
                                            
                                         SelectedFile = nil
                                        }
                                    }
                                } else {
                                    print("File does not exist")
                                }
                            } catch  let error as NSError  {
                                print("Error when deleting the file: \(error)")
                            }
                            
                        }
                        .disabled(SelectedFileForProcess == nil)
                    }
                    
                    //Show the list of duplicated files
                    List(sortedListOfFileWithID.filter { $0.DupNumber >= 2 && $0.FileSize == selectedSize && $0.FileCreationDate?.timeIntervalSinceReferenceDate == selectedDate.timeIntervalSinceReferenceDate }, id: \.id, selection: $SelectedFileForProcess) { fileWithID in
                        Text(fileWithID.FileName)
                            .onTapGesture {
                                //
                                self.SelectedFileForProcess = fileWithID.FileName
                                
                                //Prepare playerRHS (AVPlayer) for PlayerView to display the video playback
                                let asset = AVAsset(url: URL(fileURLWithPath: SelectedFileForProcess!))
                                let playerItem = AVPlayerItem(asset: asset)
                                playerRHS.replaceCurrentItem(with: playerItem)
                                
                            }
                            .listRowBackground(self.SelectedFileForProcess == fileWithID.FileName ? Color.blue : Color.white)
                            .foregroundColor(self.SelectedFileForProcess == fileWithID.FileName ? Color.white : Color.black)
                    }
                    Text("Number of duplicated files: \(sortedListOfFileWithID.filter { $0.DupNumber > 1 }.count)")
                    Text("Total size (in bytes) of duplicated files: \(sortedListOfFileWithID.filter { $0.DupNumber > 1 }.reduce(0, { $0 + $1.FileSize}))")
                    
                    if let image = NSImage(contentsOf: URL(fileURLWithPath: SelectedFileForProcess ?? ""))
                    {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 300, alignment:.center)
                    } else {
                        
                        //Video player RHS
                        if SelectedFileForProcess != nil && URL(fileURLWithPath: SelectedFileForProcess!).pathExtension == "mov" {
                            PlayerView(player: $playerRHS)
                        } else {
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 100, alignment:.center)
                        }
                    }
                    
                    Text("Selected file size: \(sortedListOfFileWithID.filter { $0.FileName == SelectedFileForProcess }.reduce(0, { $0 + $1.FileSize}))")
                }
                .frame(minWidth: 0, maxWidth: .infinity)
            }
            Picker(selection: .constant(1), label: Text("Folder")) {
                Text(SelectedFolder).tag(1)
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
                        //print("panel.urls[0]: \(panel.urls[0])")
                        //path(percentEncoded:)' is only available in macOS 13.0 or newer
                        //print("panel.urls[0].path: \(panel.urls[0].path)")
                        
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
                        
                        //print(ContentInDir)
                        
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
                        
                        //Check if any duplication, and then update DupNumber
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
                        
                        SelectedFile = nil
                        SelectedFileForProcess = nil
                        selectedSize = 0
                        
                        /*
                        print("****Sorted List is:")
                        for item in sortedListOfFileWithID {
                            print("Name: \(item.FileName)")
                            print("Size: \(item.FileSize) ")
                            print("Create Date: \(String(describing: item.FileCreationDate))")
                            print("DupNumber: \(item.DupNumber)")
                        }
                         */
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
                    //print("Is Directory")
                    listOfFileWithID += getFileInfoArray(folder: folder + "/" + fileOrDir)
                } else {
                    //print("Is not Directory")
                    if let bytes = fileAttributes[.size] as? Int64 {
                        //print("(2)File size is: \(bytes)")
                        retrievedBytes = bytes
                    }
                    if let createDateTime = fileAttributes[.creationDate] as? NSDate {
                        //print("createDateTime is: \(createDateTime)")
                        retrievedCreateDateTime = createDateTime
                    }
                    listOfFileWithID.append(FileWithID(FileName: folder + "/" + fileOrDir, FileSize: retrievedBytes, FileCreationDate: retrievedCreateDateTime))
                }
            }
        }
    }
    
    return listOfFileWithID
}
