//
//  ViewController.swift
//  demoOfflineVideo
//
//  Created by Ventuno Technologies on 15/11/19.
//  Copyright © 2019 Ventuno Technologies. All rights reserved.
//

import UIKit
import Photos
import AVKit

class ViewController: UIViewController{
    
    @IBOutlet var mPlayerView: UIView!
    var mPlayer:AVPlayer?
    @IBOutlet var percentageLabel: UILabel!
    var dwUrl:URL!
    let urlString = "https://ventuno.contentbridge.tv/DUV19794V_Sobresali/DUV19794V_Sobresali_1280_720_2400.mp4"
    var delegate:URLSessionDownloadDelegate?
    
    private var destinationURL:URL?
    private var playerItemContext = 0
    
    private var currAsset:AVAsset?
    
    private var mediaSelectionMap = [AVAssetDownloadTask : AVMediaSelection]()
    
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "MySession")
        //        config.isDiscretionary = true
        config.sessionSendsLaunchEvents = true
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    
    // HLS Vars
    
    private var hlsDownloadSession:AVAssetDownloadURLSession?
    private var configuration:URLSessionConfiguration?
    //End of HLS Vars
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //        downloadVideoLink("http://techslides.com/demos/sample-videos/small.mp4")
        let item = AVPlayerItem(url: URL(string: "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8")!)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                        self.setUpPlayer(item)
//        }
        
        print("viewDidLoad")
        //        setupHlsDownload()
    }
    
    @available(iOS 10.0, *)
    @IBAction func mOnPlayClicked(_ sender: Any) {
        //        mPlayer?.play()
        
        guard let assetPath = UserDefaults.standard.value(forKey: "assetPath") as? String else {
            // Present Error: No offline version of this asset available
            setupHlsDownload()
            return
        }
        
        
        let baseURL = URL(fileURLWithPath: NSHomeDirectory())
        let assetURL = baseURL.appendingPathComponent(assetPath)
        let asset = AVURLAsset(url: assetURL)
        
        
        
        
        
        if let cache = asset.assetCache, cache.isPlayableOffline {
            // Set up player item and player and begin playback
            print("playable asset")
            findSubtitle(asset)
        }
         
       createVtnPlayer(asset)
        
       
        
        //        nextMediaSelection(asset)
//        listDirectory(assetURL)
        
        
    }
    
    @IBAction func mOnPauseClicked(_ sender: Any) {
        mPlayer?.pause()
        
    }
    
    
    @IBAction func mOnDeleteClicked(_ sender: Any) {
        
        let userDefaults = UserDefaults.standard
        
        if let assetPath = userDefaults.value(forKey: "assetPath") as? String{
            let baseURL = URL(fileURLWithPath: NSHomeDirectory())
            let assetURL = baseURL.appendingPathComponent(assetPath)
            do {
                try FileManager.default.removeItem(at: assetURL)
                percentageLabel?.text = "Deleted"
            } catch let error as NSError {
                print("Error: \(error.domain)")
                percentageLabel?.text = "Delete Failed: \(error.domain)"
            }
            
            userDefaults.removeObject(forKey: "assetPath")
        }
        
    }
    
    
    @IBAction func mOpenDownload(_ sender: Any) {
        if let dwUrl = dwUrl{
            playVideo(dwUrl)
        }
        else{
            print("NIL")
        }
    }
}

extension ViewController{
    
    func playVideo(_ url:URL){
        
        let mPlayerItem = AVPlayerItem(url: url)
        
        mPlayerItem.addObserver(self,forKeyPath: #keyPath(AVPlayerItem.status),options: [.old, .new],context: &playerItemContext)
        
        self.mPlayer = AVPlayer(playerItem: mPlayerItem)
        
        //            self.mPlayer?.rate = 0.0
        //            self.mPlayer?.replaceCurrentItem(with: mPlayerItem)
        
        let layer: AVPlayerLayer = AVPlayerLayer(player: self.mPlayer)
        layer.frame = self.mPlayerView.bounds
        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.mPlayerView.layer.addSublayer(layer)
        self.mPlayer?.play()
        
        print("PATH: ", getVideoUrl() as Any)
        
        
    }
    func getVideoUrl() -> URL? {
        let asset = self.mPlayer?.currentItem?.asset
        if asset == nil {
            return nil
        }
        if let urlAsset = asset as? AVURLAsset {
            return urlAsset.url
        }
        return nil
    }
    
    
    func downloadVideoLinkAndCreateAsset(_ urlString:String) {
        guard let videoURL = URL(string: urlString) else { return }
        
        // let documentsURL = try FileManager.default.url(for: .documentDirectory,in: .userDomainMask,appropriateFor: nil,create: true)
        
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let savedURL = documentsURL.appendingPathComponent(videoURL.lastPathComponent)
        
        print("Path:\(documentsURL.appendingPathComponent(videoURL.lastPathComponent).path)")
        
        if !FileManager.default.fileExists(atPath: documentsURL.appendingPathComponent(videoURL.lastPathComponent).path) {
            
            URLSession.shared.downloadTask(with: videoURL) { (location, response, error) -> Void in
                guard let location = location else { return  }
                
                print("Location \(location)")
                let destinationURL = documentsURL.appendingPathComponent(response?.suggestedFilename ?? videoURL.lastPathComponent)
                do {
                    try FileManager.default.moveItem(at: location, to: destinationURL)
                    //                    try FileManager.default.removeItem(at: location)
                    self.dwUrl = savedURL
                    print("DownloadedURl :\(self.dwUrl)")
                } catch {
                    print ("file error: \(error)")
                }
            }.resume()
            
        }else{
            print("File exists")
        }
        
    }
    
    func startDownload(_ url:URL){
        
        //        let urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        
        let backgroundTask = urlSession.downloadTask(with: url)
        backgroundTask.resume()
    }
    
}

extension ViewController {
    
    
    @available(iOS 10.0, *)
    func nextMediaSelection(_ asset: AVURLAsset) -> (mediaSelectionGroup: AVMediaSelectionGroup?,
        mediaSelectionOption: AVMediaSelectionOption?) {
            
            // If the specified asset has not associated asset cache, return nil tuple
            guard let assetCache = asset.assetCache else {
                return (nil, nil)
            }
            
            // Iterate through audible and legible characteristics to find associated groups for asset
            for characteristic in [AVMediaCharacteristic.audible, AVMediaCharacteristic.legible] {
                
                if let mediaSelectionGroup = asset.mediaSelectionGroup(forMediaCharacteristic: characteristic) {
                    
                    // Determine which offline media selection options exist for this asset
                    let savedOptions = assetCache.mediaSelectionOptions(in: mediaSelectionGroup)
                    
                    // If there are still media options to download...
                    if savedOptions.count < mediaSelectionGroup.options.count {
                        for option in mediaSelectionGroup.options {
                           
                            if !savedOptions.contains(option) {
                                // This option hasn't been downloaded. Return it so it can be.
                                print("Available Media:",mediaSelectionGroup,option.displayName,option.availableMetadataFormats )
                                
                                return (mediaSelectionGroup, option)
                            }
                        }
                    }
                }
            }
            // At this point all media options have been downloaded.
            return (nil, nil)
    }
    
    
    
    private func findSubtitle(_ asset: AVURLAsset) -> (mediaSelectionGroup: AVMediaSelectionGroup?,
    mediaSelectionOption: AVMediaSelectionOption?){

        if let mediaSelectionGroup = asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristic.legible) {

            let locale = Locale(identifier: "en")
            let options = AVMediaSelectionGroup.mediaSelectionOptions(from: mediaSelectionGroup.options, with: locale)
            
          
            print("Subtitle Selected:  \(options.first?.displayName ?? "No Subtitle Selected") ")
            
            for option in mediaSelectionGroup.options {
                print("Subtitle Selected:  \(option.displayName) ")
                
//                if(option.displayName == "English"){
//                    return (mediaSelectionGroup, option)
//                }
                 
            }
            return (mediaSelectionGroup, options.first)
        
        }
        
        return (nil, nil)
    }
    
    //HLS Downloader
    
    
    @available(iOS 10.0, *)
    private func setupHlsDownload(){
        
        configuration = URLSessionConfiguration.background(withIdentifier: "VtnHlsDownlaoder")
        configuration?.sessionSendsLaunchEvents = true
        
        guard let configuration = configuration else{
            return
        }
        
        hlsDownloadSession = AVAssetDownloadURLSession(configuration: configuration,
                                                       assetDownloadDelegate: self,
                                                       delegateQueue: OperationQueue.main)
        
        //https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8
        guard let url = URL(string: "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8")else{
            return
        }
        
        let asset = AVURLAsset(url: url)
        
        let assetTitle = url.lastPathComponent
        
        print("Download Title: ",assetTitle)
        
        guard let hlsDownloadSession = hlsDownloadSession else{
            return
        }
      
        // Create new AVAssetDownloadTask for the desired asset
        if let downloadTask = hlsDownloadSession.makeAssetDownloadTask(asset: asset,
                                                                       assetTitle: "samplevid",
                                                                       assetArtworkData: nil,
                                                                       options: [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: 200000]){
            downloadTask.resume()
            
            currAsset = downloadTask.urlAsset
        }
            
    }
    
    private func restorePendingDownloads() {
        // Create session configuration with ORIGINAL download identifier
        configuration = URLSessionConfiguration.background(withIdentifier: "VtnHlsDownlaoder")
        
        guard let configuration = configuration else{
            return
        }
        
        // Create a new AVAssetDownloadURLSession
        hlsDownloadSession = AVAssetDownloadURLSession(configuration: configuration,
                                                       assetDownloadDelegate: self,
                                                       delegateQueue: OperationQueue.main)
        
        // Grab all the pending tasks associated with the downloadSession
        hlsDownloadSession?.getAllTasks { tasksArray in
            // For each task, restore the state in the app
            for task in tasksArray {
                guard let downloadTask = task as? AVAssetDownloadTask else { break }
                // Restore asset, progress indicators, state, etc...
                let asset = downloadTask.urlAsset
                print("Pending Tasks # ", asset.url)
            }
        }
    }
    
    private func playOfflineAsset(_ mAVAssetDownloadTask:AVAssetDownloadTask, _ location:URL) {
        guard let assetPath = UserDefaults.standard.value(forKey: "assetPath") as? String else {
            // Present Error: No offline version of this asset available
            return
        }
        let baseURL = URL(fileURLWithPath: NSHomeDirectory())
        let assetURL = baseURL.appendingPathComponent(assetPath)
        
        print("Asset Path:", assetURL)
        //        let assetURL = URL(fileURLWithPath: assetPath)
        
        let asset = AVURLAsset(url: assetURL)
        
        
        if #available(iOS 10.0, *) {
            if let cache = asset.assetCache, cache.isPlayableOffline {
                // Set up player item and player and begin playback
                
                //                let playerItem = AVPlayerItem(asset: asset)
                //                setUpPlayer(playerItem)
                currAsset = mAVAssetDownloadTask.urlAsset
                //                let avAssest = AVAsset(url: assetURL)
                let avAssest  = mAVAssetDownloadTask.urlAsset
                let playerItem = AVPlayerItem(asset: avAssest)
                let player = AVPlayer(playerItem: playerItem)  // video path coming from above function
                
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                self.present(playerViewController, animated: true, completion: {
                    player.play()
                })
                //                createVtnPlayer(asset)
                
            } else {
                // Present Error: No playable version of this asset exists offline
                print("No playable version of this asset exists offline")
            }
        } else {
            // Fallback on earlier versions
            print("Cant be player below iOS 10")
        }
    }
    
    private func setUpPlayer(_ mAVPlayerItem:AVPlayerItem){
        
        mAVPlayerItem.addObserver(self,forKeyPath: #keyPath(AVPlayerItem.status),options: [.old, .new],context: &playerItemContext)
        
        if let mPlayer = mPlayer{
            self.mPlayer?.replaceCurrentItem(with: mAVPlayerItem)
        }else{
            self.mPlayer = AVPlayer(playerItem: mAVPlayerItem)
        }
        
        
        let playerViewController = AVPlayerViewController()
        playerViewController.player = mPlayer
        self.present(playerViewController, animated: true, completion: {
            self.mPlayer?.play()
        })
        
        /*
         
         let layer: AVPlayerLayer = AVPlayerLayer(player: self.mPlayer)
         layer.frame = self.mPlayerView.bounds
         layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
         self.mPlayerView.layer.addSublayer(layer)*/
        
        
        
        print("PATH: ", getVideoUrl() as Any)
        
        
    }
    
    func createVtnPlayer(_ asset:AVURLAsset){
        
        let keys: [String] = ["playable"]
        
        asset.loadValuesAsynchronously(forKeys: keys, completionHandler: {
            var error: NSError? = nil
            let status = asset.statusOfValue(forKey: "playable", error: &error)
            switch status {
            case .loaded:
                DispatchQueue.main.async {
                    let mAVPlayerItem = AVPlayerItem(asset: asset)
                    self.setUpPlayer(mAVPlayerItem)
                }
                break
            case .failed:
                DispatchQueue.main.async {
                    //do something, show alert, put a placeholder image etc.
                    print("Asset error")
                }
                break
            case .cancelled:
                DispatchQueue.main.async {
                    //do something, show alert, put a placeholder image etc.
                }
                break
            default:
                break
            }
        })
        
        
    }
    
    private func listDirectory(_ documentsURL: URL){
        
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            // process files
            print(fileURLs)
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }
        
        
    }
    
    
    
    
}



extension ViewController : AVAssetDownloadDelegate{
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        var percentComplete = 0.0
        // Iterate through the loaded time ranges
        for value in loadedTimeRanges {
            // Unwrap the CMTimeRange from the NSValue
            let loadedTimeRange = value.timeRangeValue
            // Calculate the percentage of the total expected asset duration
            percentComplete += loadedTimeRange.duration.seconds / timeRangeExpectedToLoad.duration.seconds
        }
        percentComplete *= 100
        // Update UI state: post notification, update KVO state, invoke callback, etc.
        
        print("Download Percentage: ", percentComplete)
        self.percentageLabel.text = "\(percentComplete)%"
        
    }
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        // Do not move the asset from the download location
        UserDefaults.standard.set(location.relativePath, forKey: "assetPath")
        print("Download Complete",location)
        playOfflineAsset(assetDownloadTask,location)
        
        
        //        listDirectory(location)
    }
    
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("Download Error", error.debugDescription)
        
      
    // Determine the next available AVMediaSelectionOption to download
        if #available(iOS 10.0, *) {
            
            guard error == nil else { return }
            guard let task = task as? AVAssetDownloadTask else { return }
            
            let mediaSelectionPair = nextMediaSelection(task.urlAsset)
            
            // If an undownloaded media selection option exists in the group...
            if let group = mediaSelectionPair.mediaSelectionGroup,
                let option = mediaSelectionPair.mediaSelectionOption {
                
                // Exit early if no corresponding AVMediaSelection exists for the current task
                guard let originalMediaSelection = mediaSelectionMap[task] else { return }
                
                // Create a mutable copy and select the media selection option in the media selection group
                let mediaSelection = originalMediaSelection.mutableCopy() as! AVMutableMediaSelection
                mediaSelection.select(option, in: group)
                
                
                
                // Create a new download task with this media selection in its options
                let options = [AVAssetDownloadTaskMediaSelectionKey: mediaSelection]
                 let task = hlsDownloadSession?.makeAssetDownloadTask(asset: task.urlAsset,
                                                                 assetTitle: "samplevid",
                                                                 assetArtworkData: nil,
                                                                 options: options)
                    // Start media selection download
                task?.resume()
                
                
               
                
            } else {
                // All media selection downloads complete
            }
            
        }
           
        

    }
    
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didResolve resolvedMediaSelection: AVMediaSelection) {
        print("Available Media", resolvedMediaSelection)
        mediaSelectionMap[assetDownloadTask] = resolvedMediaSelection
       
    }
    
    
}




extension ViewController : URLSessionDownloadDelegate{
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        let bytesWritten = Float(totalBytesWritten/1000)
        let bytesExpectedToWrite = Float(totalBytesExpectedToWrite/1000)
        
        print("totalBytesWritten \(bytesWritten),totalBytesExpectedToWrite \(bytesExpectedToWrite)")
        
        let percentDownloaded:Float =  (bytesWritten / bytesExpectedToWrite)*100
        let percent = Int(percentDownloaded)
        
        DispatchQueue.main.async {
            self.percentageLabel.text = "\(percent)%"
            print("Percentage :\(percent)")
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("location \(location)")
        
        guard let destinationURL = destinationURL else {
            print("destinationURL not found")
            return
        }
        
        
        do {
            try FileManager.default.moveItem(at: location, to: destinationURL)
            print("DownloadedURl: \(destinationURL)")
            dwUrl = destinationURL
            DispatchQueue.main.async {
                // Update UI after background thread
                self.playVideo(destinationURL)
            }
            
            
        } catch {
            print ("file error: \(error)")
        }
        
    }
    
}

extension ViewController {
    
    override func observeValue(forKeyPath keyPath: String?,of object: Any?,change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        
        // Only handle observations for the playerItemContext
        guard context == &playerItemContext else {
            super.observeValue(forKeyPath: keyPath,of: object,change: change,context: context)
            return
        }
        
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItem.Status
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItem.Status(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            
            // Switch over status value
            switch status {
            case .readyToPlay:
                print("Ready")
                self.mPlayer?.play()
                break;
            case .failed:
                print(mPlayer?.currentItem?.error?.localizedDescription ?? "Reason Unknown")
                print("Failed")
                break;
            case .unknown:
                print("Unknown")
                break;
            default:
                print("Undetermined")
                break;
            }
        }
    }
    
}


extension ViewController {
    
    
    
    func downloadVideoLink(_ urlString:String){
        if let url = URL(string: urlString){
            
            guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            
            
            destinationURL = documentsURL.appendingPathComponent(url.lastPathComponent)
            
            print("Path: ", destinationURL!.path)
            
            if !FileManager.default.fileExists(atPath: documentsURL.appendingPathComponent(url.lastPathComponent).path) {
                print("New File Creation")
                startDownload(url)
            }else{
                print("File exists")
                print("Playing from local media")
                if let destinationURL = destinationURL {playVideo(destinationURL)}
            }
            
        }
    }
    
    
    @available(iOS 10.0, *)
    private func configureSubtitleDownload(_ task:AVAssetDownloadTask) {

        let mediaSelectionPair = findSubtitle(task.urlAsset)
        
        if let group = mediaSelectionPair.mediaSelectionGroup,
            let option = mediaSelectionPair.mediaSelectionOption {
        
               // Exit early if no corresponding AVMediaSelection exists for the current task
               guard let originalMediaSelection = mediaSelectionMap[task] else { return }
            guard let hlsDownloadSession = hlsDownloadSession else{
                       return
                   }
        
               // Create a mutable copy and select the media selection option in the media selection group
               let mediaSelection = originalMediaSelection.mutableCopy() as! AVMutableMediaSelection
            mediaSelection.select(option, in: group)
            
        
               // Create a new download task with this media selection in its options
            let options = [AVAssetDownloadTaskMediaSelectionKey: mediaSelection]
            let task = hlsDownloadSession.makeAssetDownloadTask(asset: task.urlAsset,
                                                                    assetTitle: "sample",
                                                                    assetArtworkData: nil,
                                                                    options: options)
            
                   // Start media selection download
                   task?.resume()
        }
        
        
    }
    
    
    
}


