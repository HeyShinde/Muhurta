//
//  SupportSanctuaryView.swift
//  Muhurta
//
//  Sacred Seva & Contribution Sanctuary.
//  Enables seekers to support the project via:
//  1. Open-Source code contributions on GitHub (https://github.com/heyshinde/Muhurta)
//  2. Voluntary sacred Dakṣiṇā offerings (StoreKit 2 tips & annual patronage)
//

import SwiftUI
import StoreKit

public struct DakshinaTier: Identifiable, Sendable {
    public let id: String
    public let emoji: String
    public let title: String
    public let sanskritTitle: String
    public let priceString: String
    public let cadence: String
    public let description: String
    public let isPopular: Bool
    
    public init(id: String, emoji: String, title: String, sanskritTitle: String, priceString: String, cadence: String, description: String, isPopular: Bool = false) {
        self.id = id
        self.emoji = emoji
        self.title = title
        self.sanskritTitle = sanskritTitle
        self.priceString = priceString
        self.cadence = cadence
        self.description = description
        self.isPopular = isPopular
    }
}

public struct SupportSanctuaryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @ObservedObject var storeManager = StoreKitManager.shared
    
    @State private var selectedTier: DakshinaTier? = nil
    @State private var showingThankYouAlert = false
    @State private var thankYouMessage = ""
    @State private var isProcessing = false
    
    private let gold = Color(red: 0.94, green: 0.76, blue: 0.42)
    private let deepGold = Color(red: 0.88, green: 0.64, blue: 0.28)
    
    public static let tiers: [DakshinaTier] = [
        DakshinaTier(
            id: StoreKitManager.dipaID,
            emoji: "🪔",
            title: "Dīpa Offering",
            sanskritTitle: "दीप समर्पण",
            priceString: "$4.99",
            cadence: "One-time",
            description: "A gentle flame honoring daily sacred solar calculations."
        ),
        DakshinaTier(
            id: StoreKitManager.pushpaID,
            emoji: "🌸",
            title: "Puṣpa Offering",
            sanskritTitle: "पुष्प समर्पण",
            priceString: "$9.99",
            cadence: "One-time",
            description: "A fragrant floral offering supporting sacred audio & mantra preservation.",
            isPopular: true
        ),
        DakshinaTier(
            id: StoreKitManager.annualID,
            emoji: "✨",
            title: "Annual Seeker Patron",
            sanskritTitle: "वार्षिक सेवा",
            priceString: "$9.99 / yr",
            cadence: "Yearly Patronage",
            description: "Continuous year-round patronage sustaining open Vedic research."
        ),
        DakshinaTier(
            id: StoreKitManager.archanaID,
            emoji: "🥥",
            title: "Archana Patron",
            sanskritTitle: "अर्चना सेवा",
            priceString: "$24.99",
            cadence: "One-time",
            description: "A profound traditional Vedic offering powering astronomical precision."
        ),
        DakshinaTier(
            id: StoreKitManager.benefactorID,
            emoji: "🛕",
            title: "Temple Benefactor",
            sanskritTitle: "महा संरक्षक",
            priceString: "$99.99",
            cadence: "One-time",
            description: "Enduring patronage honoring the eternal preservation of Vedic sciences."
        )
    ]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    // Hero Banner
                    heroBanner
                    
                    // Pillar 1: Support with Code (Open Source)
                    codeContributionCard
                    
                    // Pillar 2: Support with Funds (Sacred Dakṣiṇā)
                    fundsSection
                    
                    // Restore Purchases & Apple Compliance Note
                    footerCompliance
                        .padding(.bottom, 36)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
            }
            .background(Color(red: 0.05, green: 0.06, blue: 0.08).ignoresSafeArea())
            .toolbarBackground(Color(red: 0.05, green: 0.06, blue: 0.08), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationTitle("Contribute & Seva")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(gold)
                    .fontWeight(.bold)
                }
            }
            .alert("कृतज्ञता • Gratitude", isPresented: $showingThankYouAlert) {
                Button("ॐ तत्सत्", role: .cancel) {}
            } message: {
                Text(thankYouMessage)
            }
            .task {
                await storeManager.loadProducts()
            }
        }
    }
    
    // MARK: - 1. Hero Banner
    
    private var heroBanner: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(gold.opacity(0.12))
                    .frame(width: 56, height: 56)
                Text("ॐ")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundColor(gold)
            }
            
            Text("Free, Open & Without Ads Forever")
                .font(.system(size: 19, weight: .bold, design: .serif))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Muhūrta is crafted as a non-commercial sacred offering. We never track your personal data, never sell ads, and never gate sacred wisdom behind paywalls.")
                .font(.system(size: 12.5, weight: .regular))
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 8)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color(red: 0.10, green: 0.11, blue: 0.16), Color(red: 0.07, green: 0.08, blue: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(gold.opacity(0.22), lineWidth: 1)
        )
    }
    
    // MARK: - 2. Code Contribution Card
    
    private var codeContributionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(gold)
                    Text("SUPPORT WITH CODE (मुक्त स्रोत)")
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .tracking(1.4)
                        .foregroundColor(gold)
                }
                
                Spacer()
                
                Text("GPLv3")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Open-Source on GitHub")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                
                Text("Our astronomical ephemeris algorithms, solar calculations, and SwiftUI components are fully open for review, improvements, and scholar verification.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(3)
            }
            
            // Link Button
            Button {
                if let url = URL(string: "https://github.com/heyshinde/Muhurta") {
                    openURL(url)
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.up.right.square.fill")
                    Text(" GitHub Muhurta")
                        .font(.system(size: 12.5, weight: .bold, design: .monospaced))
                    Spacer()
                    Image(systemName: "star.fill")
                        .foregroundColor(gold)
                        .font(.system(size: 11))
                    Text("Star & Fork")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(12)
                .background(Color.black.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(gold.opacity(0.35), lineWidth: 1)
                )
            }
        }
        .padding(18)
        .background(Color(red: 0.08, green: 0.09, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }
    
    // MARK: - 3. Funds Section (Sacred Dakṣiṇā)
    
    private var fundsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(gold)
                    Text("SUPPORT WITH FUNDS (दक्षिणा समर्पण)")
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .tracking(1.4)
                        .foregroundColor(gold)
                }
                
                Spacer()
                
                Text("Voluntary")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            
            Text("If Muhūrta enriches your daily Sādhana, you are warmly invited to offer a voluntary Dakṣiṇā. All funds sustain server ephemeris feeds, audio production, and indie development.")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(3)
            
            // Tier Cards List
            VStack(spacing: 10) {
                ForEach(Self.tiers) { tier in
                    tierCard(tier: tier)
                }
            }
        }
        .padding(18)
        .background(Color(red: 0.08, green: 0.09, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }
    
    // MARK: - 4. Tier Card
    
    private func tierCard(tier: DakshinaTier) -> some View {
        Button {
            makeOffering(for: tier)
        } label: {
            HStack(spacing: 14) {
                Text(tier.emoji)
                    .font(.system(size: 26))
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.04))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(tier.title)
                            .font(.system(size: 14, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                        
                        if tier.isPopular {
                            Text("POPULAR")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(gold)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text("\(tier.sanskritTitle) • \(tier.description)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    if isProcessing && selectedTier?.id == tier.id {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: gold))
                            .scaleEffect(0.8)
                            .frame(height: 24)
                    } else {
                        Text(displayPrice(for: tier))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(gold)
                        Text(tier.cadence)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(minWidth: 72, alignment: .trailing)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(gold.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .padding(12)
            .background(Color.white.opacity(0.025))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(tier.isPopular ? gold.opacity(0.35) : Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isProcessing)
    }
    
    // MARK: - 5. Footer & Compliance
    
    private var footerCompliance: some View {
        VStack(spacing: 8) {
            Button {
                Task {
                    do {
                        try await storeManager.restorePurchases()
                        await MainActor.run {
                            thankYouMessage = "Your previous voluntary offerings and subscriptions have been refreshed."
                            showingThankYouAlert = true
                        }
                    } catch {
                        await MainActor.run {
                            thankYouMessage = "Could not restore purchases: \(error.localizedDescription)"
                            showingThankYouAlert = true
                        }
                    }
                }
            } label: {
                Text("Restore Purchases")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(gold.opacity(0.8))
            }
            
            Text("Voluntary patronage gifts are processed securely via Apple In-App Purchase. No core astrological calculations are restricted based on offerings.")
                .font(.system(size: 10.5))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            
            // App Store Review Guideline 3.1.2 Subscription Compliance Links
            HStack(spacing: 12) {
                Link("Privacy Policy", destination: URL(string: "https://muhurta.shindeaditya.com/privacy")!)
                Text("•").foregroundColor(.secondary.opacity(0.6))
                Link("Terms of Use (EULA)", destination: URL(string: "https://muhurta.shindeaditya.com/terms")!)
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(gold.opacity(0.85))
            .padding(.top, 4)
        }
    }
    
    // MARK: - Action Handler & Price Helper
    
    private func displayPrice(for tier: DakshinaTier) -> String {
        if let product = storeManager.products.first(where: { $0.id == tier.id }) {
            if product.type == .autoRenewable {
                return "\(product.displayPrice)/yr"
            }
            return product.displayPrice
        }
        return tier.priceString
    }
    
    private func makeOffering(for tier: DakshinaTier) {
        selectedTier = tier
        Task {
            isProcessing = true
            defer { isProcessing = false }
            
            do {
                let purchased = try await storeManager.purchase(productID: tier.id)
                if purchased {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                    thankYouMessage = """
                    ॐ तत्सत्। धन्यवादः 🙏
                    
                    Thank you for your sacred offering of \(tier.title) (\(displayPrice(for: tier))).
                    Your support preserves open Vedic ephemeris algorithms and keeps Muhūrta 100% free and ad-free.
                    """
                    showingThankYouAlert = true
                }
            } catch {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
                thankYouMessage = "Unable to process offering: \(error.localizedDescription)"
                showingThankYouAlert = true
            }
        }
    }
}
