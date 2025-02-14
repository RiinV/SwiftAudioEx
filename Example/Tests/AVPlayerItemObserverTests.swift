import Quick
import Nimble
import AVFoundation

@testable import SwiftAudioEx

class AVPlayerItemObserverTests: QuickSpec {
    
    override func spec() {
        
        describe("An AVPlayerItemObserver") {
            var observer: AVPlayerItemObserver!
            beforeEach {
                observer = AVPlayerItemObserver()
            }
            describe("observed item") {
                context("when observing") {
                    var item: AVPlayerItem!
                    beforeEach {
                        item = AVPlayerItem(url: URL(fileURLWithPath: Source.path))
                        observer.startObserving(item: item)
                    }
                    
                    it("should exist") {
                        expect(observer.observingItem).toEventuallyNot(beNil())
                    }
                }
            }
            
            describe("observing status") {
                it("should not be observing") {
                    expect(observer.isObserving).toEventuallyNot(beTrue())
                }
                context("when observing") {
                    var item: AVPlayerItem!
                    beforeEach {
                        item = AVPlayerItem(url: URL(fileURLWithPath: Source.path))
                        observer.startObserving(item: item)
                    }
                    it("should be observing") {
                        expect(observer.isObserving).toEventually(beTrue())
                    }
                }
            }
        }
    }
}

class AVPlayerItemObserverDelegateHolder: AVPlayerItemObserverDelegate {
    var receivedMetadata: ((_ metadata: [AVMetadataItem]) -> Void)?

    func item(didReceiveMetadata metadata: [AVMetadataItem]) {
        receivedMetadata?(metadata)
    }

    
    var updateDuration: ((_ duration: Double) -> Void)?
    
    func item(didUpdateDuration duration: Double) {
        updateDuration?(duration)
    }
}
