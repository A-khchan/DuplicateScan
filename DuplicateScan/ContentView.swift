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
    var fileName:String
    var fileSize:Int64 = 0
    var fileModificationDate: NSDate?
    var dupNumber:Int = 0 //0 means no duplication, 1 means first file in duplicated files, duplication means same file size and same creation date.
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
    
    @State private var selectedFolder: String = ""
    @State private var dScanFileManager: FileManager = FileManager()
    @State private var selectedFile: String? = nil
    @State private var selectedSize: Int64 = 0
    @State private var selectedDate: NSDate = Date() as NSDate
    @State private var selectedFileForProcess: String? = nil
    @State var listOfFileWithID = [
        FileWithID(fileName: "Empty")
    ]
    @State private var sortedListOfFileWithID: [FileWithID] = []
    @State private var isOn = false
    @State private var dup1:Int = 0
    @State private var dup2:Int = 0
    @State private var player: AVPlayer = AVPlayer()
    @State private var playerRHS: AVPlayer = AVPlayer()
    @State private var minSize: String = "0"
    @State private var progress: Double = 0
    @State private var totalCount: Double = 0
    @State private var progressPV: Double = 0
    @State private var totalCountPV: Double = 0
    @State private var fileCount: Double = 0
    @Environment(\.openURL) var openURL
    @State private var isLoading: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    VStack {
                        HStack {
                            Toggle(isOn: $isOn) {
                                Text("Show only files with duplication")
                                //.frame(minHeight: 32)
                            }
                            .toggleStyle(.checkbox)
                            //.frame(minWidth: 500)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Label("Min. size (MB)", systemImage: "line.3.horizontal.decrease.circle")
                            TextField("", text: $minSize)
                                .frame(maxWidth: 40)
                            
                        }
                        .frame(minHeight: 25)
                        
                        List(sortedListOfFileWithID.filter { $0.fileSize >= (Int(minSize) ?? 0)*1024*1024 && ($0.dupNumber < 2 && $0.dupNumber >= 0 && isOn == false || $0.dupNumber == 1 && isOn)
                        }, id: \.id, selection: $selectedFile) { fileWithID in
                            HStack {
                                
                                if fileWithID.dupNumber == 0 {
                                    Image(systemName: "doc")
                                        .imageScale(.large)
                                } else {
                                    Image(systemName: "doc.on.doc")
                                        .imageScale(.large)
                                }
                                //A file on left side list is clicked
                                Text(fileWithID.fileName)
                                    .onTapGesture {
                                        
                                        //Store selectedFile for adjusting color of selected row
                                        self.selectedFile = fileWithID.fileName
                                        self.selectedSize = fileWithID.fileSize
                                        self.selectedDate = fileWithID.fileModificationDate ?? Date() as NSDate
                                        
                                        //Example to convert string to path
                                        //print("Convert string to path: \(URL(fileURLWithPath: selectedFile!))")
                                        
                                        //Prepare player (AVPlayer) for PlayerView to display the video playback
                                        let asset = AVAsset(url: URL(fileURLWithPath: selectedFile!))
                                        let playerItem = AVPlayerItem(asset: asset)
                                        player.replaceCurrentItem(with: playerItem)
                                        
                                        selectedFileForProcess = nil
                                    }
                            }
                            .listRowBackground(self.selectedFile == fileWithID.fileName ? Color.blue : Color.white)
                            .foregroundColor(self.selectedFile == fileWithID.fileName ? Color.white : Color.black)
                        }
                        //Summary
                        Text("Number of file without duplication: \(sortedListOfFileWithID.filter { $0.dupNumber == 0 }.count)")
                        
                        Text("Number of file with duplication: \(sortedListOfFileWithID.filter { $0.dupNumber == 1 }.count)")
                        if let image = NSImage(contentsOf: URL(fileURLWithPath: selectedFile ?? ""))
                        {   //if loading an image is successful, display it
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFit()
                                //.frame(width: 300, height: 300, alignment:.center)
                                .frame(maxHeight: 300, alignment: .center)
                        } else {
                            
                            //Video player if it has ext. mov or mp4
                            /*
                             if selectedFile != nil && URL(fileURLWithPath: selectedFile!).pathExtension.lowercased() == "mov" {
                             PlayerView(player: $player)
                             */
                            if selectedFile != nil && ["mov", "mp4"].contains(URL(fileURLWithPath: selectedFile!).pathExtension.lowercased()) {
                                PlayerView(player: $player)
                            } else {
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 60, alignment:.center)
                            }
                        }
                        
                        Text("Selected file size: \(sortedListOfFileWithID.filter { $0.fileName == selectedFile }.reduce(0, { $0 + $1.fileSize}))")
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                    
                    //Right hand side column
                    VStack {
                        HStack {
                            Button("Swap files") {
                                //Button is clicked
                                if let index = sortedListOfFileWithID.firstIndex(where: {$0.fileName == selectedFile}) {
                                    dup1 = sortedListOfFileWithID[index].dupNumber
                                }
                                if let index = sortedListOfFileWithID.firstIndex(where: {$0.fileName == selectedFileForProcess}) {
                                    dup2 = sortedListOfFileWithID[index].dupNumber
                                }
                                //Update dupNumber in array
                                if let index = sortedListOfFileWithID.firstIndex(where: {$0.fileName == selectedFile}) {
                                    sortedListOfFileWithID[index].dupNumber = dup2
                                }
                                if let index = sortedListOfFileWithID.firstIndex(where: {$0.fileName == selectedFileForProcess}) {
                                    sortedListOfFileWithID[index].dupNumber = dup1
                                }
                                //After swap, list refreshed and result in no selection
                                selectedFile = nil
                                selectedFileForProcess = nil
                            }
                            .disabled(selectedFile == nil || selectedFileForProcess == nil)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("Duplicated files")
                            //.frame(minHeight: 32)
                                .frame(maxWidth: .infinity, alignment: .center)
                            Button("Delete the below selected file") {
                                
                                //Really delete the file upon button clicked
                                do {
                                    if dScanFileManager.fileExists(atPath: selectedFileForProcess!) {
                                        // Delete file
                                        try dScanFileManager.removeItem(atPath: selectedFileForProcess!)
                                        
                                        if let index = sortedListOfFileWithID.firstIndex(where: {$0.fileName == selectedFileForProcess}) {
                                            //Update dupNumber to -1 to hide the file from being displayed
                                            sortedListOfFileWithID[index].dupNumber = -1
                                        }
                                        selectedFileForProcess = nil
                                        
                                        //if all duplicated files are deleted, also update first file's dupNumber to 0 to indicate it has no more duplication.
                                        if sortedListOfFileWithID.filter({ $0.dupNumber >= 2 && $0.fileSize == selectedSize && $0.fileModificationDate?.timeIntervalSinceReferenceDate == selectedDate.timeIntervalSinceReferenceDate }).count == 0 {
                                            if let index = sortedListOfFileWithID.firstIndex(where: {$0.fileName == selectedFile}) {
                                                sortedListOfFileWithID[index].dupNumber = 0
                                                
                                                selectedFile = nil
                                            }
                                        }
                                    } else {
                                        print("File does not exist")
                                    }
                                } catch  let error as NSError  {
                                    print("Error when deleting the file: \(error)")
                                }
                                
                            }
                            .disabled(selectedFileForProcess == nil)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .frame(minHeight: 25)
                        
                        //Show the list of duplicated files
                        List(sortedListOfFileWithID.filter { $0.dupNumber >= 2 && $0.fileSize == selectedSize && $0.fileModificationDate?.timeIntervalSinceReferenceDate == selectedDate.timeIntervalSinceReferenceDate }, id: \.id, selection: $selectedFileForProcess) { fileWithID in
                            Text(fileWithID.fileName)
                                .onTapGesture {
                                    //
                                    self.selectedFileForProcess = fileWithID.fileName
                                    
                                    //Prepare playerRHS (AVPlayer) for PlayerView to display the video playback
                                    let asset = AVAsset(url: URL(fileURLWithPath: selectedFileForProcess!))
                                    let playerItem = AVPlayerItem(asset: asset)
                                    playerRHS.replaceCurrentItem(with: playerItem)
                                    
                                }
                                .listRowBackground(self.selectedFileForProcess == fileWithID.fileName ? Color.blue : Color.white)
                                .foregroundColor(self.selectedFileForProcess == fileWithID.fileName ? Color.white : Color.black)
                        }
                        Text("Number of duplicated files: \(sortedListOfFileWithID.filter { $0.dupNumber > 1 }.count)")
                        Text("Total size (in bytes) of duplicated files: \(sortedListOfFileWithID.filter { $0.dupNumber > 1 }.reduce(0, { $0 + $1.fileSize}))")
                        
                        if let image = NSImage(contentsOf: URL(fileURLWithPath: selectedFileForProcess ?? ""))
                        {
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFit()
                                //.frame(width: 300, height: 300, alignment:.center)
                                .frame(maxHeight: 300, alignment: .center)
                        } else {
                            
                            //Video player RHS
                            /*
                             if selectedFileForProcess != nil && URL(fileURLWithPath: selectedFileForProcess!).pathExtension.lowercased() == "mov" {
                             */
                            if selectedFileForProcess != nil && ["mov","mp4"].contains(URL(fileURLWithPath: selectedFileForProcess!).pathExtension.lowercased()) {
                                PlayerView(player: $playerRHS)
                            } else {
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 60, alignment:.center)
                            }
                        }
                        
                        Text("Selected file size: \(sortedListOfFileWithID.filter { $0.fileName == selectedFileForProcess }.reduce(0, { $0 + $1.fileSize}))")
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                }
                Picker(selection: .constant(1), label: Text("Folder")) {
                    Text(selectedFolder).tag(1)
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
                            
                            isLoading = true
                            
                            selectedFolder = panel.urls[0].path
                            
                            //The below has to cope with update of URL scheme in project DuplicateScan->(targets)DuplicateScan->Info->URL Scheme.
                            /* Open a new window example
                             if let url = URL(string: "DuplicateScanApp://Viewer") {
                             openURL(url)
                             }*/
                            
                            progress = 0.0
                            totalCount = 0.0
                            progressPV = 0.0
                            totalCountPV = 0.0
                            fileCount = 0.0
                            
                            Task.detached {
                                
                                listOfFileWithID = await getFileInfoArray(folder: panel.urls[0].path, portion: 0.6)
                                print("Complete loading all sub-folders: \(progress)")
                                
                                //With n items, number of sorting comparison need is (n-1)+(n-2)+...+1 = n(n-1)/2
                                //But since the complexity is lower due to smarter method used in Array.sorted. So, n*log(n) is used. Experiment shows multiply by 5 has better result.
                                let sortProgress = fileCount / (5.0*Double(listOfFileWithID.count)*log(Double(listOfFileWithID.count)))
                                
                                var sortCount = 0
                                    
                                sortedListOfFileWithID = listOfFileWithID.sorted(by: ) { (lhs, rhs) in
                                    
                                    sortCount += 1
                                    progress += sortProgress
                                    //print("In sort, progress is: \(progress)")
                                    //print("In sort, (progress - progressPV)/totalCountPV is: \((progress - progressPV)/totalCountPV)")
                                    //print("In sort, sortCount is: \(sortCount)")
                                    //print("In sort, progress - progressPV is: \(progress - progressPV)")
                                    //Limit the call to main.sync to have better performance
                                    if (progress - progressPV)/totalCountPV > 0.03 {
                                        DispatchQueue.main.sync {
                                            progressPV = progress
                                        }
                                    }
                                    
                                    if lhs.fileModificationDate == rhs.fileModificationDate {
                                        return lhs.fileSize < rhs.fileSize
                                    }
                                    
                                    let L = lhs.fileModificationDate ?? Date() as NSDate
                                    let R = rhs.fileModificationDate ?? Date() as NSDate
                                    
                                    return L.timeIntervalSinceReferenceDate
                                    < R.timeIntervalSinceReferenceDate
                                    
                                }
                                
                                //print("Complete sorting: \(progress)")
                                //print("sortCount: \(sortCount)")
                                //print("listOfFileWithID.count: \(listOfFileWithID.count)")
                                
                                //Check if any duplication, and then update dupNumber
                                var prevSize:Int64 = 0
                                var prevDate:NSDate = Date() as NSDate
                                var i = 0
                                let dupProgress = (totalCountPV - progressPV) / Double(sortedListOfFileWithID.count)
                                for item in sortedListOfFileWithID {
                                    //print("Name: \(item.fileName)")
                                    //print("Size: \(item.fileSize) ")
                                    //print("Create Date: \(String(describing: item.fileModificationDate))")
                                    if i > 0 {
                                        let thisDate = item.fileModificationDate ?? Date() as NSDate
                                        if prevSize == item.fileSize &&
                                            prevDate.timeIntervalSinceReferenceDate == thisDate.timeIntervalSinceReferenceDate {
                                            if sortedListOfFileWithID[i-1].dupNumber == 0 {
                                                sortedListOfFileWithID[i-1].dupNumber = 1
                                            }
                                            sortedListOfFileWithID[i].dupNumber = sortedListOfFileWithID[i-1].dupNumber + 1
                                        }
                                    }
                                    prevSize = item.fileSize
                                    prevDate = item.fileModificationDate ?? Date() as NSDate
                                    i += 1
                                    
                                    progress += dupProgress
                                    if (progress - progressPV)/totalCountPV > 0.03 {
                                        DispatchQueue.main.sync {
                                            progressPV = progress
                                        }
                                    }
                                }
                                //print("Complete assign dupNumber: \(progress)")
                                
                                DispatchQueue.main.async {
                                    progressPV = totalCountPV
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        isLoading = false
                                    }
                                }
                                
                                selectedFile = nil
                                selectedFileForProcess = nil
                                selectedSize = 0
                            }
                            
                            /*
                             print("****Sorted List is:")
                             for item in sortedListOfFileWithID {
                             print("Name: \(item.fileName)")
                             print("Size: \(item.fileSize) ")
                             print("Create Date: \(String(describing: item.fileModificationDate))")
                             print("dupNumber: \(item.dupNumber)")
                             }
                            */
                            //print(sortedListOfFileWithID)
                        }
                    }
                }
                
            }
            .padding()
            
            if isLoading {
                Rectangle()
                    .opacity(0.75)
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.white)
                    .opacity(1.0)
                    .frame(maxWidth: 500, maxHeight: 120)
                VStack {
                    //Text("Loading...")
                    ProgressView("Loading...", value: progressPV, total: totalCountPV)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(maxWidth: 400)
                    Text("\(Int(progressPV)) out of \(Int(totalCountPV))")
                }
            }
        }
    }


    func getFileInfoArray (folder: String, portion: Double) -> [FileWithID] {
        var ContentInDir: [String] = []
        let dScanFileManager: FileManager = FileManager()
        var listOfFileWithID = [
            FileWithID(fileName: "Empty")
        ]
        var retrievedBytes: Int64 = 0
        var retrievedModificationDateTime: NSDate?
        
        //First, get content of this folder
        do {
            try ContentInDir = dScanFileManager.contentsOfDirectory(atPath: folder)
        } catch {
            ContentInDir = []
        }
        
        var i = 0
        
        totalCount += Double(ContentInDir.count)
        
        //loop the content and fill up array
        listOfFileWithID = []
        for fileOrDir in ContentInDir {
            
            if let fileAttributes = try? FileManager.default.attributesOfItem(atPath: folder + "/" + fileOrDir) {
                
                if let fileType = fileAttributes[.type] as? FileAttributeType {
                    if fileType == .typeDirectory {
                        //print("Is Directory")
                        
                        listOfFileWithID += getFileInfoArray(folder: folder + "/" + fileOrDir, portion: portion/Double(ContentInDir.count))
                        
                    } else {
                        //print("Is not Directory")
                        fileCount += 1
                        
                        if let bytes = fileAttributes[.size] as? Int64 {
                            //print("(2)File size is: \(bytes)")
                            retrievedBytes = bytes
                        }
                        if let modificationDateTime = //fileAttributes[.creationDate] as? NSDate {
                            //Try using modification date instead
                            fileAttributes[.modificationDate] as? NSDate {
                                //print("modificationDateTime is: \(modificationDateTime)")
                            retrievedModificationDateTime = modificationDateTime
                        }
                        listOfFileWithID.append(FileWithID(fileName: folder + "/" + fileOrDir, fileSize: retrievedBytes, fileModificationDate: retrievedModificationDateTime))
                    }
                    
                    progress += 1.0
                    
                }
            }
            
            if (progress - progressPV)/totalCount > 0.06 {
                DispatchQueue.main.sync {
                    progressPV = progress
                    totalCountPV = totalCount + fileCount
                }
            }
            
            i += 1
        }
        
        return listOfFileWithID
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


struct Viewer: View {
    var body: some View {
        Text("Viewer")
            .frame(minWidth: 600, minHeight: 500)
    }
}


