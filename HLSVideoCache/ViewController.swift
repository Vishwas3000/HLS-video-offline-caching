//
//  ViewController.swift
//  HLSVideoCache
//
//  Created by Gary Newby on 24/08/2021.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet private var playerView: UIView!
    @IBOutlet private var video1: UIButton!
    @IBOutlet private var video2: UIButton!
    
    @IBOutlet weak var seekForwardButton: UIButton!
    @IBOutlet weak var seekBackwardButton: UIButton!
    
    @IBOutlet weak var downloadSpeedLabel: UILabel!

    @IBOutlet weak var clrAllCache: UIButton!
    
    private let player = AVPlayer()
    private var playerLayer: AVPlayerLayer?
    private var downloadSpeedTimer: Timer?

    // Test streams
    private let videos = [
        "https://zingcam.cdn.flamapp.com/stream/6697c5a3938beaac6dc241ed_1721395630/hls/master.m3u8",
        "https://zingcam.cdn.flamapp.com/stream/6698c2ea938beaac6dc2476f_1721373841/hls/master.m3u8"
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = playerView.bounds
        playerView.layer.addSublayer(playerLayer)
        self.playerLayer = playerLayer

        video1.addAction(UIAction { _ in self.playVideo(at: 0) }, for: .touchUpInside)
        video2.addAction(UIAction { _ in self.playVideo(at: 1) }, for: .touchUpInside)
        
        // Add actions for seek buttons
        seekForwardButton.addAction(UIAction { _ in self.seekForward() }, for: .touchUpInside)
        seekBackwardButton.addAction(UIAction { _ in self.seekBackward() }, for: .touchUpInside)
        clrAllCache.addAction(UIAction{ _ in self.clearAllCache() }, for: .touchUpInside)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapPlayerView(_:)))
        playerView.addGestureRecognizer(tapGestureRecognizer)
        
    }
    
    private func clearAllCache(){
        do {
            try HLSVideoCache.shared.clearCache()
        } catch {
            print("Failed to clear cache: \(error)")
        }
    }
    
    deinit {
        downloadSpeedTimer?.invalidate()
    }

    private func playVideo(at index: Int) {
        let url = URL(string: self.videos[index])!
        let videoURL = HLSVideoCache.shared.reverseProxyURL(from: url)!
        let playerItem = AVPlayerItem(url: videoURL)
        player.replaceCurrentItem(with: playerItem)
        playerLayer?.frame = playerView.bounds
        player.play()
        
        startMonitoringDownloadSpeed()
    }
    
    @objc private func updateDownloadSpeed() {
        guard let accessLog = player.currentItem?.accessLog(),
              let lastEvent = accessLog.events.last else {
            downloadSpeedLabel.text = "DSpeed: N/A"
            return
        }
        
        let transferDuration = lastEvent.transferDuration // in seconds
           let numberOfBytesTransferred = lastEvent.numberOfBytesTransferred // in bytes
           let downloadSpeedBps = Double(numberOfBytesTransferred) / transferDuration // bytes per second
           let downloadSpeedMBps = downloadSpeedBps / 1_000_000 // megabytes per second
        
        DispatchQueue.main.async {
            self.downloadSpeedLabel.text = String(format: "Download Speed: %.2f MBps", downloadSpeedMBps)
        }
    }
    
    private func startMonitoringDownloadSpeed() {
           downloadSpeedTimer?.invalidate()
        downloadSpeedTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateDownloadSpeed), userInfo: nil, repeats: true)
       }
    
    private func seekForward() {
        let currentTime = player.currentTime()
        let newTime = CMTimeAdd(currentTime, CMTimeMake(value: 5, timescale: 1))
        player.seek(to: newTime)
        player.play()
    }
    
    private func seekBackward() {
        let currentTime = player.currentTime()
        let newTime = CMTimeSubtract(currentTime, CMTimeMake(value: 5, timescale: 1))
        player.seek(to: newTime)
        player.play()
    }

    @objc private func didTapPlayerView(_ sender: UITapGestureRecognizer) {
        if player.rate > 0 {
            player.pause()
        } else {
            player.play()
        }
    }
}

