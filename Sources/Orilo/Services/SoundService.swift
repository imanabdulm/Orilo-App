import AppKit
import Foundation

struct SoundService {
    func playSessionStart() { play("Blow") }
    func playSessionComplete() { play("Glass") }
    func playBreakStart() { play("Ping") }
    func playBreakEnd() { play("Pop") }
    func playTick() { play("Tink") }
    func playPause() { play("Morse") }
    func playResume() { play("Pop") }

    private func play(_ name: String) {
        NSSound(named: NSSound.Name(name))?.play()
    }
}
