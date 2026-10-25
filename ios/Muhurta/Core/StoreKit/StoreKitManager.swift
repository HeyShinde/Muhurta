//
//  StoreKitManager.swift
//  Muhurta
//
//  Modern StoreKit 2 Purchase & Voluntary Offering Manager.
//  Handles product fetching, In-App Purchase execution, Transaction Verification,
//  and transaction updates stream with Swift 6 concurrency compliance.
//

import Foundation
import StoreKit
import Combine

@MainActor
public final class StoreKitManager: ObservableObject {
    public static let shared = StoreKitManager()
    
    // Consecrated Product IDs
    public static let dipaID = "com.shindeaditya.Muhurta.tip.dipa"
    public static let pushpaID = "com.shindeaditya.Muhurta.tip.pushpa"
    public static let annualID = "com.shindeaditya.Muhurta.tip.annual"
    public static let archanaID = "com.shindeaditya.Muhurta.tip.archana"
    public static let benefactorID = "com.shindeaditya.Muhurta.tip.benefactor"
    
    public static let allProductIDs: Set<String> = [
        dipaID,
        pushpaID,
        annualID,
        archanaID,
        benefactorID
    ]
    
    @Published public private(set) var products: [Product] = []
    @Published public private(set) var purchasedProductIDs: Set<String> = []
    @Published public var isPurchasing: Bool = false
    @Published public var errorMessage: String? = nil
    
    private var updatesTask: Task<Void, Never>? = nil
    
    private init() {
        updatesTask = listenForTransactions()
        Task {
            await loadProducts()
            await updatePurchasedStatus()
        }
    }
    
    deinit {
        updatesTask?.cancel()
    }
    
    // MARK: - 1. Fetch Products
    
    public func loadProducts() async {
        do {
            let fetched = try await Product.products(for: Self.allProductIDs)
            self.products = fetched.sorted { $0.price < $1.price }
            print("StoreKit: Successfully loaded \(fetched.count) products: \(fetched.map { "\($0.id) -> \($0.displayPrice)" })")
        } catch {
            print("StoreKit: Failed to load products: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - 2. Purchase Flow
    
    public func purchase(product: Product) async throws -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedStatus()
            await transaction.finish()
            return true
            
        case .userCancelled:
            return false
            
        case .pending:
            return false
            
        @unknown default:
            return false
        }
    }
    
    public func purchase(productID: String) async throws -> Bool {
        if let product = products.first(where: { $0.id == productID }) {
            return try await purchase(product: product)
        }
        
        // If products weren't cached yet, fetch on-demand
        let fetched = try await Product.products(for: [productID])
        if let product = fetched.first {
            return try await purchase(product: product)
        }
        
        throw StoreKitError.productNotFound
    }
    
    // MARK: - 3. Restore Purchases
    
    public func restorePurchases() async throws {
        try await AppStore.sync()
        await updatePurchasedStatus()
    }
    
    // MARK: - 4. Verification & Updates Listener
    
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updatePurchasedStatus()
                    await transaction.finish()
                } catch {
                    print("StoreKit: Transaction verification failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func updatePurchasedStatus() async {
        var purchased = Set<String>()
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                purchased.insert(transaction.productID)
            }
        }
        self.purchasedProductIDs = purchased
    }
    
    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
    
    public enum StoreKitError: LocalizedError {
        case productNotFound
        case verificationFailed
        
        public var errorDescription: String? {
            switch self {
            case .productNotFound:
                return "The requested offering was not found on the App Store."
            case .verificationFailed:
                return "Apple transaction verification failed."
            }
        }
    }
}
