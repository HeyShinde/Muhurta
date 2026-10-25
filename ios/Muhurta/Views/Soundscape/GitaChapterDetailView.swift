//
//  GitaChapterDetailView.swift
//  Muhurta
//
//  Immersive sacred reader for Śrīmad Bhagavad Gītā chapters.
//  Presents Sanskrit Devanagari verses, transliterations, English translations,
//  and purports, complemented by background ambient tanpura drone resonance.
//

import SwiftUI

public struct GitaChapterDetailView: View {
    public let chapter: GitaChapter
    @Environment(\.dismiss) private var dismiss
    @State private var soundEngine = SoundEngine.shared
    @State private var selectedVerseIndex: Int = 0
    @State private var copiedVerseId: String? = nil
    
    private let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
    
    public init(chapter: GitaChapter) {
        self.chapter = chapter
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.06, blue: 0.08).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Chapter Header Hero
                        chapterHeroBanner
                        
                        // Chapter Key Verses List
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("FEATURED SACRED SHLOKAS")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .tracking(1.5)
                                    .foregroundColor(gold)
                                Spacer()
                                Text("\(chapter.keyVerses.count) Verses Included")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 4)
                            
                            ForEach(chapter.keyVerses) { verse in
                                verseCard(verse: verse)
                            }
                        }
                        
                        // Full Adhyāya Reading Note
                        HStack(spacing: 12) {
                            Image(systemName: "book.pages")
                                .font(.system(size: 18))
                                .foregroundColor(gold)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Complete Adhyāya • \(chapter.verseCount) Verses")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Reflect upon these cardinal verses during Brahma Muhūrta and Sandhyā for supreme mental poise.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                        .padding(.bottom, 90)
                    }
                    .padding(20)
                }
                
                // Floating Ambient Drone Bar at bottom
                VStack {
                    Spacer()
                    ambientReadingDock
                }
            }
            .navigationTitle("Adhyāya \(chapter.number)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Chapter Hero Banner
    
    private var chapterHeroBanner: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(gold.opacity(0.12))
                    .frame(width: 56, height: 56)
                Image(systemName: chapter.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(gold)
            }
            
            VStack(spacing: 4) {
                Text("अध्याय \(chapter.number) • \(chapter.sanskritName)")
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundColor(gold)
                
                Text(chapter.transliteratedName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(chapter.englishTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Text(chapter.essence)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color(red: 0.10, green: 0.11, blue: 0.16), Color(red: 0.07, green: 0.08, blue: 0.11)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(gold.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Verse Card
    
    private func verseCard(verse: GitaVerse) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Verse Number & Copy action
            HStack {
                Text("BG \(verse.chapter).\(verse.verse)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(gold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(gold.opacity(0.12))
                    .clipShape(Capsule())
                
                Spacer()
                
                Button {
                    let text = "\(verse.sanskrit)\n\n\(verse.transliteration)\n\n\"\(verse.englishTranslation)\"\n— Bhagavad Gītā \(verse.chapter).\(verse.verse)"
                    UIPasteboard.general.string = text
                    withAnimation {
                        copiedVerseId = verse.id
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copiedVerseId = nil
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: copiedVerseId == verse.id ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 12))
                        Text(copiedVerseId == verse.id ? "Copied" : "Share")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(copiedVerseId == verse.id ? .green : .secondary)
                }
            }
            
            // Devanagari Sanskrit
            Text(verse.sanskrit)
                .font(.system(size: 17, weight: .bold, design: .serif))
                .foregroundColor(.white)
                .lineSpacing(6)
            
            // Transliteration
            Text(verse.transliteration)
                .font(.system(size: 13, weight: .regular, design: .serif))
                .italic()
                .foregroundColor(Color.white.opacity(0.75))
                .lineSpacing(4)
            
            Divider()
                .background(Color.white.opacity(0.08))
            
            // English Translation
            VStack(alignment: .leading, spacing: 6) {
                Text("TRANSLATION")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(gold.opacity(0.8))
                
                Text("\"\(verse.englishTranslation)\"")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .lineSpacing(4)
            }
            
            // Purport / Contemplation
            VStack(alignment: .leading, spacing: 4) {
                Text("MEDITATIVE CONTEMPLATION")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(.secondary)
                
                Text(verse.purport)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(3)
            }
            .padding(12)
            .background(Color.white.opacity(0.02))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(16)
        .background(Color(red: 0.08, green: 0.09, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
    
    // MARK: - Ambient Reading Dock
    
    private var ambientReadingDock: some View {
        HStack(spacing: 12) {
            Image(systemName: "waveform")
                .font(.system(size: 15))
                .foregroundColor(soundEngine.isPlaying ? gold : .secondary)
            
            VStack(alignment: .leading, spacing: 1) {
                Text("Meditative Drone (432Hz Tanpura)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                Text(soundEngine.isPlaying ? "Playing sacred ambient background" : "Tap to listen while reading")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                soundEngine.togglePlay(soundtrack: .tanpura432)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: soundEngine.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 11))
                    Text(soundEngine.isPlaying ? "Pause" : "Play")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(gold)
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Material.ultraThinMaterial
        )
        .clipShape(Capsule())
        .overlay(Capsule().stroke(gold.opacity(0.3), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.5), radius: 10, y: 5)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}
