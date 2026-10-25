//
//  SoundscapePlayerView.swift
//  Muhurta
//
//  Redesigned Vedic Resonance Sanctuary featuring:
//  1. Sacred Chants & Soundscapes with breathing harmonic visualizer, sleep timers, and volume slider.
//  2. Śrīmad Bhagavad Gītā sanctuary with Daily Divine Shloka and an interactive 18-Adhyāya chapter explorer.
//

import SwiftUI

public struct SoundscapePlayerView: View {
    @State private var soundEngine = SoundEngine.shared
    @State private var gitaEngine = BhagavadGitaEngine.shared
    @State private var locationService = LocationService.shared
    
    // Segmented Mode: 0 = Sacred Chants, 1 = Bhagavad Gītā
    @State private var activeResonanceMode: Int = 0
    @State private var isBreathing = false
    @State private var selectedGitaChapter: GitaChapter? = nil
    @State private var copiedShlokaNotice = false
    
    // Sleep Timer States
    @State private var selectedTimerMinutes: Int? = nil
    @State private var timerRemainingSeconds: Int = 0
    @State private var timerTask: Task<Void, Never>? = nil
    
    private let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
    private let deepGold = Color(red: 0.88, green: 0.64, blue: 0.28)
    
    public init() {}
    
    private var currentVara: VedicVara {
        let vDate = PanchangaEngine.vedicDate(for: Date(), coordinate: locationService.currentCoordinate)
        if let panchanga = PanchangaEngine.calculatePanchanga(for: vDate, coordinate: locationService.currentCoordinate) {
            return panchanga.vara
        }
        return VedicVara(weekdayNumber: 1, nameSanskrit: "रविवार", nameEnglish: "Ravivāra", rulingGraha: "Sūrya (Sun)", element: "Tejas (Fire)", deity: "Sūrya Nārāyaṇa", essence: "Vitality, courage, and spiritual radiance")
    }
    
    public var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.06, blue: 0.08).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    sanctuaryHeader
                    
                    // Segmented Sanctuary Selector
                    resonanceModePicker
                    
                    if activeResonanceMode == 0 {
                        // MARK: - Chants & Soundscapes Mode
                        chantsContent
                    } else {
                        // MARK: - Śrīmad Bhagavad Gītā Mode
                        gitaContent
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 110)
            }
        }
        .sheet(item: $selectedGitaChapter) { chapter in
            GitaChapterDetailView(chapter: chapter)
        }
    }
    
    // MARK: - 1. Sanctuary Header
    
    private var sanctuaryHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("RESONANCE & WISDOM")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(2.0)
                    .foregroundColor(gold)
                
                Text(activeResonanceMode == 0 ? "Vedic Soundscapes" : "Śrīmad Bhagavad Gītā")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundColor(.white)
            }
            Spacer()
            
            // Audio Indicator Pill
            if soundEngine.isPlaying {
                HStack(spacing: 5) {
                    Image(systemName: "waveform")
                        .font(.system(size: 12))
                        .foregroundColor(gold)
                    Text("PLAYING")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(gold)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(gold.opacity(0.12))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(gold.opacity(0.3), lineWidth: 1))
            }
        }
        .padding(.top, 14)
    }
    
    // MARK: - 2. Mode Picker
    
    private var resonanceModePicker: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    activeResonanceMode = 0
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 13))
                    Text("Sacred Chants")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .foregroundColor(activeResonanceMode == 0 ? .black : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(activeResonanceMode == 0 ? gold : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            }
            
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    activeResonanceMode = 1
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 13))
                    Text("Bhagavad Gītā")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .foregroundColor(activeResonanceMode == 1 ? .black : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(activeResonanceMode == 1 ? gold : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
    
    // MARK: - 3. Sacred Chants View
    
    private var chantsContent: some View {
        VStack(spacing: 20) {
            // Vedic Day Acoustic Alignment Badge
            vedicDayBadge
            
            // Audio Player Hero Card
            audioPlayerCard
            
            // Sleep Timer & Ambient Drone Bar
            timerAndControlsBar
            
            // Sound Library Cards
            soundtrackLibrary
        }
    }
    
    // MARK: - 4. Audio Player Hero Card
    
    private var audioPlayerCard: some View {
        VStack(spacing: 16) {
            // Visualizer Mandala
            ZStack {
                // Outer Pulse
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [gold.opacity(soundEngine.isPlaying ? 0.22 : 0.05), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 110
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(isBreathing ? 1.08 : 0.94)
                
                // Rotating Ring
                Circle()
                    .stroke(
                        gold.opacity(soundEngine.isPlaying ? 0.45 : 0.15),
                        style: StrokeStyle(lineWidth: 1.5, dash: [4, 7])
                    )
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(isBreathing ? 360 : 0))
                    .animation(.linear(duration: 35).repeatForever(autoreverses: false), value: isBreathing)
                
                // Center Play/Pause Disc
                Button {
                    soundEngine.togglePlay()
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [gold, deepGold],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 72, height: 72)
                            .shadow(color: gold.opacity(soundEngine.isPlaying ? 0.45 : 0.15), radius: 14)
                        
                        Image(systemName: soundEngine.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 26))
                            .foregroundColor(Color(red: 0.08, green: 0.06, blue: 0.02))
                    }
                }
            }
            .frame(height: 190)
            .onAppear {
                withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                    isBreathing = true
                }
            }
            
            // Track Info
            VStack(spacing: 4) {
                Text(soundEngine.currentSoundtrack.rawValue)
                    .font(.system(size: 17, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(soundEngine.currentSoundtrack.description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            // Quick Volume Slider
            HStack(spacing: 12) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Slider(value: Binding(
                    get: { soundEngine.volume },
                    set: { soundEngine.setVolume($0) }
                ), in: 0...1)
                .tint(gold)
                
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.13))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(gold.opacity(0.18), lineWidth: 1)
                )
        )
    }
    
    // MARK: - 5. Timer & Controls Bar
    
    private var timerAndControlsBar: some View {
        VStack(spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .font(.system(size: 12))
                        .foregroundColor(gold)
                    Text("SLEEP & MEDITATION TIMER")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundColor(gold)
                }
                
                Spacer()
                
                if timerRemainingSeconds > 0 {
                    Text(formatSeconds(timerRemainingSeconds))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(gold)
                }
            }
            
            HStack(spacing: 8) {
                timerButton(minutes: 10, label: "10m")
                timerButton(minutes: 20, label: "20m")
                timerButton(minutes: 30, label: "30m")
                timerButton(minutes: 60, label: "1h")
                
                Button {
                    cancelTimer()
                } label: {
                    Text("Off")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(selectedTimerMinutes == nil ? gold : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(selectedTimerMinutes == nil ? gold.opacity(0.15) : Color.white.opacity(0.03))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(selectedTimerMinutes == nil ? gold.opacity(0.4) : Color.clear, lineWidth: 1))
                }
            }
        }
        .padding(14)
        .background(Color(red: 0.08, green: 0.09, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
    
    private func timerButton(minutes: Int, label: String) -> some View {
        let isSelected = selectedTimerMinutes == minutes
        return Button {
            setTimer(minutes: minutes)
        } label: {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isSelected ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(isSelected ? gold : Color.white.opacity(0.04))
                .clipShape(Capsule())
        }
    }
    
    // MARK: - 6. Soundtrack Library
    
    private var soundtrackLibrary: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SACRED AUDIO REPOSITORY")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.4)
                .foregroundColor(gold)
                .padding(.horizontal, 4)
            
            VStack(spacing: 8) {
                ForEach(SacredSoundtrack.allCases) { soundtrack in
                    let isCurrent = soundEngine.currentSoundtrack == soundtrack
                    
                    Button {
                        soundEngine.togglePlay(soundtrack: soundtrack)
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(isCurrent ? gold.opacity(0.2) : Color.white.opacity(0.04))
                                    .frame(width: 38, height: 38)
                                
                                Image(systemName: soundtrack.iconName)
                                    .font(.system(size: 16))
                                    .foregroundColor(isCurrent ? gold : .secondary)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(soundtrack.rawValue)
                                    .font(.system(size: 13, weight: isCurrent ? .bold : .medium, design: .serif))
                                    .foregroundColor(isCurrent ? .white : Color.white.opacity(0.85))
                                
                                Text(soundtrack.description)
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            if isCurrent && soundEngine.isPlaying {
                                Image(systemName: "waveform")
                                    .font(.system(size: 14))
                                    .foregroundColor(gold)
                            } else {
                                Image(systemName: "play.circle")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(12)
                        .background(isCurrent ? gold.opacity(0.07) : Color.white.opacity(0.02))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(isCurrent ? gold.opacity(0.3) : Color.white.opacity(0.04), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - 7. Bhagavad Gītā Content
    
    private var gitaContent: some View {
        VStack(spacing: 20) {
            // Daily Shloka Hero Card
            dailyShlokaHero
            
            // 18 Chapters Directory
            chaptersDirectory
        }
    }
    
    // MARK: - 8. Daily Shloka Hero
    
    private var dailyShlokaHero: some View {
        let shloka = gitaEngine.dailyShloka()
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundColor(gold)
                    Text("DAILY DIVINE SHLOKA • दैनिक श्लोक")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.4)
                        .foregroundColor(gold)
                }
                
                Spacer()
                
                Text("BG \(shloka.chapter).\(shloka.verse)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(gold)
                    .clipShape(Capsule())
            }
            
            // Devanagari Sanskrit
            Text(shloka.sanskrit)
                .font(.system(size: 17, weight: .bold, design: .serif))
                .foregroundColor(.white)
                .lineSpacing(6)
            
            // Transliteration
            Text(shloka.transliteration)
                .font(.system(size: 13, weight: .regular, design: .serif))
                .italic()
                .foregroundColor(Color.white.opacity(0.75))
                .lineSpacing(3)
            
            Divider()
                .background(Color.white.opacity(0.08))
            
            // Translation
            VStack(alignment: .leading, spacing: 4) {
                Text("ENGLISH TRANSLATION")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(gold.opacity(0.85))
                
                Text("\"\(shloka.englishTranslation)\"")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .lineSpacing(4)
            }
            
            // Purport
            VStack(alignment: .leading, spacing: 4) {
                Text("CONTEMPLATION FOR TODAY")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(.secondary)
                
                Text(shloka.purport)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(3)
            }
            .padding(12)
            .background(Color.white.opacity(0.025))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            // Shloka Action Buttons
            HStack(spacing: 12) {
                Button {
                    let shareText = "\(shloka.sanskrit)\n\n\(shloka.transliteration)\n\n\"\(shloka.englishTranslation)\"\n— Śrīmad Bhagavad Gītā \(shloka.chapter).\(shloka.verse)"
                    UIPasteboard.general.string = shareText
                    withAnimation {
                        copiedShlokaNotice = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copiedShlokaNotice = false
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: copiedShlokaNotice ? "checkmark" : "square.and.arrow.up")
                        Text(copiedShlokaNotice ? "Copied" : "Share Verse")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(gold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(gold.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(gold.opacity(0.35), lineWidth: 1))
                }
                
                Button {
                    soundEngine.togglePlay(soundtrack: .tanpura432)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: soundEngine.isPlaying ? "pause.fill" : "waveform")
                        Text(soundEngine.isPlaying ? "Pause Drone" : "432Hz Drone")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(gold)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.10, green: 0.11, blue: 0.16), Color(red: 0.07, green: 0.08, blue: 0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(gold.opacity(0.25), lineWidth: 1)
                )
        )
    }
    
    // MARK: - 9. 18 Chapters Directory
    
    private var chaptersDirectory: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("THE 18 ADHYĀYAS (अष्टादश अध्यायाः)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.4)
                        .foregroundColor(gold)
                    Text("Complete Cosmic Discourse of Lord Kṛṣṇa")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                }
                Spacer()
                Text("700 Verses")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 8) {
                ForEach(gitaEngine.chapters) { chapter in
                    Button {
                        selectedGitaChapter = chapter
                    } label: {
                        HStack(spacing: 14) {
                            // Chapter Number Badge
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(gold.opacity(0.12))
                                    .frame(width: 38, height: 38)
                                Text("\(chapter.number)")
                                    .font(.system(size: 14, weight: .bold, design: .serif))
                                    .foregroundColor(gold)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(chapter.sanskritName)
                                        .font(.system(size: 14, weight: .bold, design: .serif))
                                        .foregroundColor(.white)
                                    
                                    Text("• \(chapter.verseCount)v")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                
                                Text("\(chapter.transliteratedName) — \(chapter.englishTitle)")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color.white.opacity(0.3))
                        }
                        .padding(12)
                        .background(Color(red: 0.08, green: 0.09, blue: 0.13))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - 10. Vedic Day Acoustic Alignment Badge
    
    private var vedicDayBadge: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(gold.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "tuningfork")
                    .font(.system(size: 15))
                    .foregroundColor(gold)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("NĀDA BRAHMA • \(currentVara.nameSanskrit)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundColor(gold)
                
                Text("\(currentVara.rulingGraha) • Sacred Acoustic Resonance")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("\(currentVara.essence)")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(12)
        .background(Color(red: 0.08, green: 0.09, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(gold.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Helpers
    
    private func setTimer(minutes: Int) {
        selectedTimerMinutes = minutes
        timerRemainingSeconds = minutes * 60
        timerTask?.cancel()
        timerTask = Task {
            while timerRemainingSeconds > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { break }
                await MainActor.run {
                    timerRemainingSeconds -= 1
                    if timerRemainingSeconds == 0 {
                        soundEngine.stop()
                        selectedTimerMinutes = nil
                    }
                }
            }
        }
    }
    
    private func cancelTimer() {
        selectedTimerMinutes = nil
        timerRemainingSeconds = 0
        timerTask?.cancel()
        timerTask = nil
    }
    
    private func formatSeconds(_ total: Int) -> String {
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}
