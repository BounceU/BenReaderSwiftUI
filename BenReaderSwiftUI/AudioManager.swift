//
//  AudioManager.swift
//  BenReaderSwiftUI
//
//  Created by Ben Liebkemann on 6/11/25.
//

import Foundation
import SwiftUI
import AVFoundation
import MediaPlayer

enum PlayerScrubState {
    case reset;
    case scrubStarted;
    case scrubEnded(Double);
}

class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    var player: AVPlayer?
    var book: Book?
    
    var chapters: [Chapter]
    var currentChapter: Chapter?
    
    var isPlaying: Bool = false;
    
    var timerValue: TimeInterval?;
    
    var info: [String: Any] = [:];
    
    var scrubState: PlayerScrubState = .reset {
        didSet {
            switch scrubState {
            case .reset: return
            case .scrubStarted: return
            case .scrubEnded(let seekTime):
                player?.seek(to: CMTimeMakeWithSeconds(seekTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero)
            }
        }
    }
    
    init() {
        chapters = []
    }
    
    func getPlayer() -> AVPlayer? {
        return player
    }
    
    func nextChapter() {
        guard let player = self.player, let currentChapter = self.currentChapter else {
            return;
        }
        if let chapterNum = chapters.firstIndex(where: {
            otherChap in
            return otherChap.chapterPath == currentChapter.chapterPath
        }) {
            if (chapterNum != chapters.count - 1) {
                player.seek(to: .init(seconds: chapters[chapterNum + 1].startTime + 0.01, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero)
            } else {
                player.seek(to: .init(seconds: currentChapter.endTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero)
            }
        } else {
            player.seek(to: .init(seconds: currentChapter.endTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero)
        }
        trackUpdate();
    }
    
    func prevChapter() {
        guard let player = self.player, let currentChapter = self.currentChapter else {
            return;
        }
        if let chapterNum = chapters.firstIndex(where: {
            otherChap in
            return otherChap.chapterPath == currentChapter.chapterPath
        }) {
           
            if(abs(player.currentTime().seconds.distance(to: currentChapter.startTime)) < 3.0 && chapterNum != 0) {
                player.seek(to: .init(seconds: chapters[chapterNum - 1].startTime + 0.01, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero)
            } else {
                player.seek(to: .init(seconds: currentChapter.startTime + 0.01, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero)
            }
        } else {
            player.seek(to: .init(seconds: currentChapter.startTime + 0.01, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero)
        }
        trackUpdate();
    }
    
    func trackUpdate() {
        switch self.scrubState {
        case .reset:
            break;
        case .scrubStarted:
            break;
        case .scrubEnded(_):
            self.scrubState = .reset;
            break;
        }
        if let seconds = player?.currentTime().seconds {
           
            if let st = currentChapter?.startTime, let et = currentChapter?.endTime {
                if(seconds < st || seconds > et) {
                    updateNowPlayingInfo();
                }
                info[MPNowPlayingInfoPropertyPlaybackProgress] = (seconds - st) / (et - st) / Double(book?.rate ?? 1)
                info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = (seconds - st) / Double(book?.rate ?? 1)
               
                MPNowPlayingInfoCenter.default().nowPlayingInfo = info
            }
            
            if let timerSeconds = timerValue {
                let systemSeconds = Date().timeIntervalSince1970;
                
                if systemSeconds >= timerSeconds {
                    pause()
                } else {
                    if timerSeconds - systemSeconds <= 5 {
                        player?.volume = Float((timerSeconds - systemSeconds) / 5.0);
                    }
                }
            }
        }
    }
    
    func skip(_ amount: Double) {
        guard let player = self.player else {
            return;
        }
        player.seek(to: .init(seconds: player.currentTime().seconds + amount * Double((book?.rate ?? 1)), preferredTimescale: 1), toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    func togglePlayer() {
        guard self.player != nil else {
            return;
        }
        
        if(getIsPlaying()) {
            pause()
            
        } else {
            play()
        }
        
    }
    
    func getIsPlaying() -> Bool {
        guard let aPlayer = self.player else {
            isPlaying = false;
            return false;
        }
        if aPlayer.rate != 0 {
            isPlaying = true;
            return true
        } else {
            isPlaying = false;
            return false;
        }
      
    }
    
    func play() {
        
        if let timerSeconds = timerValue {
            if Date().timeIntervalSince1970 >= timerSeconds {
                timerValue = nil
            }
        }
        player?.volume = 1.0;
        player?.play();
        player?.rate = book?.rate ?? 1.0;
    }
    
    func pause() {
        player?.pause();
    }
    
    func play(book: Book) {
        timerValue = nil
        print("STARTING PLAY OF BOOK")
        guard let url = Utils.getAudioURL(book.fileName) else { return }
        print("URL: \(url)")
        self.book = book;
        
        
        chapters = Utils.loadChaptersFromBook(book);
        player = AVPlayer(playerItem: AVPlayerItem(url: url))
        player?.seek(to: CMTime(seconds: book.location, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
        
        
        
        player?.play()
        player?.rate = book.rate;
        updateNowPlayingInfo()
    }
    
    
    
    func updateNowPlayingInfo() {
        
        guard let player = player, let currentItem = player.currentItem, let book = book else { return }
        
        
        for chapter in chapters.reversed() {
            if(book.location >= chapter.startTime) {
                currentChapter = chapter
                break;
            }
        }
        
        var image: UIImage;
        
        if let coverURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(book.image).path {
            image = UIImage(contentsOfFile: coverURL) ?? UIImage(named: "default_cover")!
        } else {
            image = UIImage(named: "default_cover")!
        }
        
        
        
        info = [
            MPMediaItemPropertyTitle: currentChapter?.title ?? "No chapter",
            
            MPMediaItemPropertyArtist: book.author,
            
            MPMediaItemPropertyArtwork: MPMediaItemArtwork(boundsSize: CGSize(width: image.size.width, height: image.size.height)) { _ in
                image
            },
            
            MPMediaItemPropertyAlbumTitle: book.title,
            
            MPMediaItemPropertyPlaybackDuration: ((currentChapter?.endTime ?? currentItem.duration.seconds) - (currentChapter?.startTime ?? 0)) / Double(book.rate),
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime().seconds - (currentChapter?.startTime ?? 0) / Double(book.rate),
            MPNowPlayingInfoPropertyPlaybackRate: player.rate,
        ]
      
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        MPNowPlayingInfoCenter.default().playbackState = .playing
      
        
        
    }
    
    
}
