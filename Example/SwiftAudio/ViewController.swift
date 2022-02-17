//
//  ViewController.swift
//  SwiftAudio
//
//  Created by Jørgen Henrichsen on 03/11/2018.
//  Copyright (c) 2018 Jørgen Henrichsen. All rights reserved.
//

import UIKit
import SwiftAudioEx
import AVFoundation
import MediaPlayer


class ViewController: UIViewController {

    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var remainingTimeLabel: UILabel!
    @IBOutlet weak var elapsedTimeLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var loadIndicator: UIActivityIndicatorView!
    @IBOutlet weak var errorLabel: UILabel!
    
    private var isScrubbing: Bool = false
    private let controller = AudioController.shared
    private var lastLoadFailed: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        controller.player.event.stateChange.addListener(self, handleAudioPlayerStateChange)
        controller.player.event.playbackEnd.addListener(self, handleAudioPlayerPlaybackEnd(data:))
        controller.player.event.secondElapse.addListener(self, handleAudioPlayerSecondElapsed)
        controller.player.event.seek.addListener(self, handleAudioPlayerDidSeek)
        controller.player.event.updateDuration.addListener(self, handleAudioPlayerUpdateDuration)
        controller.player.event.didRecreateAVPlayer.addListener(self, handleAVPlayerRecreated)
        controller.player.event.fail.addListener(self, handlePlayerFailure)
        updateMetaData()
        handleAudioPlayerStateChange(data: controller.player.playerState)
    }
    
    @IBAction func togglePlay(_ sender: Any) {
        if !controller.audioSessionController.audioSessionIsActive {
            try? controller.audioSessionController.activateSession()
        }
        if lastLoadFailed, let item = controller.player.currentItem {
            lastLoadFailed = false
            errorLabel.isHidden = true
            try? controller.player.load(item: item, playWhenReady: true)
        }
        else {
            controller.player.togglePlaying()
        }
    }
    
    @IBAction func download(_ sender: Any) {
        print("download")
        let url = "http://ec2-13-53-83-250.eu-north-1.compute.amazonaws.com/vods3/_definst_/mp3:amazons3/audio-books-staging-private/76/8d/768d79dcea8ae1e9fa0fa1e7e9b48df7_1.mp3/playlist.m3u8?wowzatokenendtime=1645027700&wowzatokenstarttime=1645024100&wowzatokenhash=itr5wF_k_cGrKSO9SOoLHalI4Z6rRqnnbST9x4Imykofl8NhUeCAv8alCd-az6YU";
        let urlAsset = AVURLAsset(url: URL(string: url)!)
        let stream = Stream(nm: "hello", playlist: url)
        let asset = Asset(stream: stream, urlAsset:urlAsset)
        AssetPersistenceManager.sharedManager.downloadStream(for: asset)
    }
    
    @IBAction func previous(_ sender: Any) {
        try? controller.player.previous()
    }
    
    @IBAction func next(_ sender: Any) {
        try? controller.player.next()
    }
    
    @IBAction func startScrubbing(_ sender: UISlider) {
        isScrubbing = true
    }
    
    @IBAction func scrubbing(_ sender: UISlider) {
        controller.player.seek(to: Double(slider.value))
    }
    
    @IBAction func scrubbingValueChanged(_ sender: UISlider) {
        let value = Double(slider.value)
        elapsedTimeLabel.text = value.secondsToString()
        remainingTimeLabel.text = (controller.player.duration - value).secondsToString()
    }
    
    func updateTimeValues() {
        self.slider.maximumValue = Float(self.controller.player.duration)
        self.slider.setValue(Float(self.controller.player.currentTime), animated: true)
        self.elapsedTimeLabel.text = self.controller.player.currentTime.secondsToString()
        self.remainingTimeLabel.text = (self.controller.player.duration - self.controller.player.currentTime).secondsToString()
    }
    
    func updateMetaData() {
        if let item = controller.player.currentItem {
            titleLabel.text = item.getTitle()
            artistLabel.text = item.getArtist()
            item.getArtwork({ (image) in
                self.imageView.image = image
            })
        }
    }
    
    func setPlayButtonState(forAudioPlayerState state: AudioPlayerState) {
        playButton.setTitle(state == .playing ? "Pause" : "Play", for: .normal)
    }
    
    func setErrorMessage(_ message: String) {
        self.loadIndicator.stopAnimating()
        errorLabel.isHidden = false
        errorLabel.text = message
    }
    
    // MARK: - AudioPlayer Event Handlers
    
    func handleAudioPlayerStateChange(data: AudioPlayer.StateChangeEventData) {
        print("state=\(data)")
        DispatchQueue.main.async {
            self.setPlayButtonState(forAudioPlayerState: data)
            switch data {
            case .loading:
                self.loadIndicator.startAnimating()
                self.updateMetaData()
                self.updateTimeValues()
            case .buffering:
                self.loadIndicator.startAnimating()
            case .ready:
                self.loadIndicator.stopAnimating()
                self.updateMetaData()
                self.updateTimeValues()
            case .playing, .paused, .idle:
                self.loadIndicator.stopAnimating()
                self.updateTimeValues()
            }
        }
    }

    func handleAudioPlayerPlaybackEnd(data: AudioPlayer.PlaybackEndEventData) {
        print("playEndReason=\(data)")
    }
    
    func handleAudioPlayerSecondElapsed(data: AudioPlayer.SecondElapseEventData) {
        if !isScrubbing {
            DispatchQueue.main.async {
                self.updateTimeValues()
            }
        }
    }
    
    func handleAudioPlayerDidSeek(data: AudioPlayer.SeekEventData) {
        isScrubbing = false
    }
    
    func handleAudioPlayerUpdateDuration(data: AudioPlayer.UpdateDurationEventData) {
        DispatchQueue.main.async {
            self.updateTimeValues()
        }
    }
    
    func handleAVPlayerRecreated() {
        try? controller.audioSessionController.set(category: .playback)
    }
    
    func handlePlayerFailure(data: AudioPlayer.FailEventData) {
        if let error = data as NSError? {
            if error.code == -1009 {
                lastLoadFailed = true
                DispatchQueue.main.async {
                    self.setErrorMessage("Network disconnected. Please try again...")
                }
            }
        }
    }
    
}
