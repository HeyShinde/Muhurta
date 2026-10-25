//
//  SoundEngine.swift
//  Muhurta
//
//  Audio engine supporting authentic Vedic Mantras (Gayatri Mantra, Mahamrityunjaya, Ushas Sukta)
//  and acoustic 432Hz meditative soundscapes with asynchronous audio session management.
//

import Foundation
import AVFoundation
import Observation

public enum SacredSoundtrack: String, CaseIterable, Identifiable, Sendable {
    case gayatriMantra = "Gayatri Mantra (गायत्री मन्त्र)"
    case mahamrityunjaya = "Maha Mrityunjaya (महामृत्युंजय)"
    case ushasSukta = "Rigvedic Dawn Hymn (उषस् सूक्त)"
    case tanpura432 = "432Hz Acoustic Tanpura Drone"
    case templeConch = "Temple Shankha & Singing Bowl"
    
    public nonisolated var id: String { rawValue }
    
    public nonisolated var shortName: String {
        switch self {
        case .gayatriMantra: return "Gayatri Mantra"
        case .mahamrityunjaya: return "Maha Mrityunjaya"
        case .ushasSukta: return "Ushas Sukta"
        case .tanpura432: return "432Hz Tanpura"
        case .templeConch: return "Shankha & Bowl"
        }
    }
    
    public nonisolated var description: String {
        switch self {
        case .gayatriMantra:
            return "Rigveda 3.62.10. Solar invocation to Savitr awakening intellect (Dhiyo Yo Nah)."
        case .mahamrityunjaya:
            return "Rigveda 7.59.12. Healing, resonant restorative cadence for deep spiritual vitality."
        case .ushasSukta:
            return "Rigveda 1.48. The celestial dawn goddess awakening living beings into divine light."
        case .tanpura432:
            return "Concert pitch acoustic tanpura tuned to 432Hz fundamental meditative harmony."
        case .templeConch:
            return "Vedic Shankha resonance combined with multi-harmonic singing bowl chime."
        }
    }
    
    public nonisolated var resourceFilename: String {
        switch self {
        case .gayatriMantra: return "gayatri_mantra"
        case .mahamrityunjaya: return "mahamrityunjaya"
        case .ushasSukta: return "ushas_sukta"
        case .tanpura432: return "tanpura_432"
        case .templeConch: return "shankha_bowl"
        }
    }
    
    public nonisolated var iconName: String {
        switch self {
        case .gayatriMantra: return "sun.max.fill"
        case .mahamrityunjaya: return "flame.fill"
        case .ushasSukta: return "sunrise.fill"
        case .tanpura432: return "waveform.path"
        case .templeConch: return "bell.fill"
        }
    }
}

@Observable
public final class SoundEngine: @unchecked Sendable {
    public static let shared = SoundEngine()
    
    public var isPlaying: Bool = false
    public var currentSoundtrack: SacredSoundtrack = .gayatriMantra
    public var volume: Float = 0.7
    
    private var audioPlayer: AVAudioPlayer?
    private let audioEngine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private var phase: Double = 0.0
    private var phase2: Double = 0.0
    private var phase3: Double = 0.0
    private var sampleRate: Double = 44100.0
    private var fadeTimer: Timer?
    
    public init() {
        // Audio session is intentionally not activated on init to prevent UI hang warnings.
        // It is activated asynchronously on-demand when playback is requested.
    }
    
    public func togglePlay(soundtrack: SacredSoundtrack? = nil) {
        if let s = soundtrack, s != currentSoundtrack {
            currentSoundtrack = s
            if isPlaying {
                stop()
                start()
                return
            }
        }
        
        if isPlaying {
            stop()
        } else {
            start()
        }
    }
    
    public func start(withProgressiveFade: Bool = false, targetDurationMinutes: Double = 15.0) {
        stop()
        
        let targetVol = volume
        let currentSnd = currentSoundtrack
        
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            
            // 1. Configure and activate audio session asynchronously off main thread
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
                if #available(iOS 27.0, *) {
                    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                        session.activate(options: []) { _, _ in
                            continuation.resume()
                        }
                    }
                } else {
                    try session.setActive(true)
                }
            } catch {
                print("AVAudioSession configuration: \(error.localizedDescription)")
            }
            
            // 2. Check if an authentic external audio file exists in the bundle
            let filename = currentSnd.resourceFilename
            if let fileURL = Bundle.main.url(forResource: filename, withExtension: "caf") ??
                             Bundle.main.url(forResource: filename, withExtension: "m4a") ??
                             Bundle.main.url(forResource: filename, withExtension: "mp3") {
                do {
                    let player = try AVAudioPlayer(contentsOf: fileURL)
                    player.numberOfLoops = -1 // Infinite loop
                    let startVol: Float = withProgressiveFade ? 0.02 : targetVol
                    player.volume = startVol
                    player.prepareToPlay()
                    player.play()
                    
                    await MainActor.run {
                        self.audioPlayer = player
                        self.isPlaying = true
                        if withProgressiveFade {
                            self.volume = 0.02
                        }
                        self.setupFadeTimer(targetVol: targetVol, durationMinutes: targetDurationMinutes, withFade: withProgressiveFade)
                    }
                    return
                } catch {
                    print("Failed to play audio file: \(error.localizedDescription). Falling back to harmonic synthesis.")
                }
            }
            
            // 3. High-quality resonant harmonic synthesis fallback
            await MainActor.run {
                self.startSynthesizerFallback(targetVol: targetVol, durationMinutes: targetDurationMinutes, withFade: withProgressiveFade)
            }
        }
    }
    
    private func startSynthesizerFallback(targetVol: Float, durationMinutes: Double, withFade: Bool) {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        
        sourceNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let sRate = self.sampleRate
            let currentSound = self.currentSoundtrack
            let vol = Double(self.volume)
            
            for frame in 0..<Int(frameCount) {
                var sample: Float = 0.0
                
                switch currentSound {
                case .gayatriMantra, .tanpura432:
                    // 432Hz fundamental with pure tanpura fifth and octave partials
                    let f1 = 216.0
                    let f2 = 324.0
                    let f3 = 432.0
                    
                    self.phase += 2.0 * .pi * f1 / sRate
                    self.phase2 += 2.0 * .pi * f2 / sRate
                    self.phase3 += 2.0 * .pi * f3 / sRate
                    
                    let s1 = sin(self.phase) * 0.4
                    let s2 = sin(self.phase2) * 0.3
                    let s3 = sin(self.phase3) * 0.2
                    let lfo = 0.9 + 0.1 * sin(2.0 * .pi * 0.2 * Double(frame) / sRate)
                    sample = Float((s1 + s2 + s3) * vol * lfo * 0.45)
                    
                case .mahamrityunjaya, .templeConch:
                    // 136.1Hz Earth frequency + deep resonant temple bell overtones
                    let fBase = 136.1
                    self.phase += 2.0 * .pi * fBase / sRate
                    self.phase2 += 2.0 * .pi * (fBase * 2.0) / sRate
                    self.phase3 += 2.0 * .pi * (fBase * 3.5) / sRate
                    
                    let b1 = sin(self.phase) * 0.5
                    let b2 = sin(self.phase2) * 0.25
                    let b3 = sin(self.phase3) * 0.15
                    sample = Float((b1 + b2 + b3) * vol * 0.45)
                    
                case .ushasSukta:
                    // Soft morning dawn fifth harmony
                    let fFlute = 384.0
                    self.phase += 2.0 * .pi * fFlute / sRate
                    self.phase2 += 2.0 * .pi * (fFlute * 1.5) / sRate
                    
                    let flute = sin(self.phase) * 0.5 + sin(self.phase2) * 0.3
                    let vibrato = 1.0 + 0.04 * sin(2.0 * .pi * 4.0 * Double(frame) / sRate)
                    sample = Float(flute * vol * vibrato * 0.4)
                }
                
                for buffer in ablPointer {
                    let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                    buf[frame] = sample
                }
            }
            return noErr
        }
        
        guard let node = sourceNode else { return }
        audioEngine.attach(node)
        if #available(iOS 27.0, *) {
            try? audioEngine.connectNode(node, to: audioEngine.mainMixerNode, format: format)
        } else {
            audioEngine.connect(node, to: audioEngine.mainMixerNode, format: format)
        }
        
        do {
            try audioEngine.start()
            Task { @MainActor in
                self.isPlaying = true
                self.setupFadeTimer(targetVol: targetVol, durationMinutes: durationMinutes, withFade: withFade)
            }
        } catch {
            print("Audio engine failed to start: \(error.localizedDescription)")
        }
    }
    
    private func setupFadeTimer(targetVol: Float, durationMinutes: Double, withFade: Bool) {
        guard withFade else { return }
        let totalSteps = 60
        let interval = (durationMinutes * 60.0) / Double(totalSteps)
        let stepVolume = (targetVol - 0.02) / Float(totalSteps)
        
        fadeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] t in
            guard let self = self else { t.invalidate(); return }
            if self.volume < targetVol {
                self.volume += stepVolume
                self.audioPlayer?.volume = self.volume
            } else {
                self.volume = targetVol
                self.audioPlayer?.volume = targetVol
                t.invalidate()
            }
        }
    }
    
    public func setVolume(_ newVolume: Float) {
        let clamped = max(0.0, min(1.0, newVolume))
        self.volume = clamped
        self.audioPlayer?.volume = clamped
    }
    
    public func stop() {
        fadeTimer?.invalidate()
        fadeTimer = nil
        
        if let player = audioPlayer, player.isPlaying {
            player.stop()
            audioPlayer = nil
        }
        
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        if let node = sourceNode {
            audioEngine.detach(node)
            sourceNode = nil
        }
        
        isPlaying = false
        phase = 0.0
        phase2 = 0.0
        phase3 = 0.0
        
        Task.detached(priority: .utility) {
            let session = AVAudioSession.sharedInstance()
            if #available(iOS 27.0, *) {
                session.deactivate(options: []) { _, _ in }
            } else {
                try? session.setActive(false, options: .notifyOthersOnDeactivation)
            }
        }
    }
}
