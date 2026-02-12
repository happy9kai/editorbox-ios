//
//  PurchaseService.swift
//  EditorBox
//
//  Created by Codex on 2026/02/12.
//

import Foundation
import Observation
import StoreKit

@MainActor
@Observable
final class PurchaseService {
    enum ProductID {
        static let premiumMonthly = "editorbox.premium.monthly"
    }

    private(set) var premiumProduct: Product?
    private(set) var isPremiumActive: Bool = false
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?

    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    deinit {
        updatesTask?.cancel()
    }

    func start() {
        if updatesTask == nil {
            updatesTask = Task { [weak self] in
                guard let self else { return }
                for await _ in Transaction.updates {
                    _ = await self.refreshEntitlementStatus()
                }
            }
        }

        Task { [weak self] in
            guard let self else { return }
            await self.loadProductsIfNeeded()
            _ = await self.refreshEntitlementStatus()
        }
    }

    func loadProductsIfNeeded() async {
        guard premiumProduct == nil else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let products = try await Product.products(for: [ProductID.premiumMonthly])
            premiumProduct = products.first(where: { $0.id == ProductID.premiumMonthly })
        } catch {
            errorMessage = "商品情報の取得に失敗しました。"
        }
    }

    @discardableResult
    func refreshEntitlementStatus() async -> Bool {
        var active = false

        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement else { continue }
            guard transaction.productID == ProductID.premiumMonthly else { continue }
            guard transaction.revocationDate == nil else { continue }

            if let expirationDate = transaction.expirationDate, expirationDate <= .now {
                continue
            }

            active = true
            break
        }

        isPremiumActive = active
        return active
    }

    func purchasePremium() async -> Bool {
        await loadProductsIfNeeded()

        guard let premiumProduct else {
            errorMessage = "購入可能な商品が見つかりません。"
            return false
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await premiumProduct.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    errorMessage = "購入検証に失敗しました。"
                    return false
                }

                await transaction.finish()
                return await refreshEntitlementStatus()

            case .userCancelled:
                return false

            case .pending:
                errorMessage = "購入処理が保留中です。"
                return false

            @unknown default:
                errorMessage = "購入結果の判定に失敗しました。"
                return false
            }
        } catch {
            errorMessage = "購入処理に失敗しました。"
            return false
        }
    }

    func restorePurchases() async -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            return await refreshEntitlementStatus()
        } catch {
            errorMessage = "復元に失敗しました。"
            return false
        }
    }

    var premiumPriceText: String {
        premiumProduct?.displayPrice ?? "-"
    }
}
