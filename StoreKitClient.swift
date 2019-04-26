//
//  StoreKitClient.swift
//  https://github.com/persiogv/StoreKitClient
//
//  Created by Pérsio on 26/01/17.
//  Copyright © 2017 Persio Vieira. All rights reserved.
//

import StoreKit

// purchasing   - Transaction is being added to the server queue.
// purchased    - Transaction is in queue, user has been charged.  Client should complete the transaction.
// failed       - Transaction was cancelled or failed before being added to the server queue.
// restored     - Transaction was restored from user's purchase history.  Client should complete the transaction.
// deferred     - The transaction is in the queue, but its final status is pending external action.

protocol StoreKitClientDelegate {
    
    /// Calls delegate when transactions are updated
    ///
    /// - Parameters:
    ///   - storeKitClient: A reference to caller
    ///   - transactions: An array containing the updated transactions
    func storeKitClient(_ storeKitClient: StoreKitClient, didUpdateTransactions transactions: [SKPaymentTransaction])
    
    /// Calls delegate when products request finishes
    ///
    /// - Parameters:
    ///   - storeKitClient: A reference to caller
    ///   - products: An array containing the requestes products
    func storeKitClient(_ storeKitClient: StoreKitClient, didFinishProductsRequestWithProducts products: [SKProduct])
}

class StoreKitClient: NSObject {
    
    private let delegate: StoreKitClientDelegate
    private let productsRequest: SKProductsRequest
    private let productIdentifiers: Set<String>
    
    // MARK: - Initializer
    
    /// Instantiates the StoreKitClient
    ///
    /// - Parameters:
    ///   - delegate: A reference to an delegate
    ///   - identifiers: The products' identifiers
    required init(delegate: StoreKitClientDelegate, productIdentifiers identifiers: Set<String>) {
        self.delegate = delegate
        self.productIdentifiers = identifiers
        self.productsRequest = SKProductsRequest(productIdentifiers: identifiers)
    }

    // MARK: - Public statements
    
    /// Returns the payments availability
    static var isPaymentsAvalilable: Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    /// Starts the products request
    func startProductsRequest() {
        productsRequest.delegate = self
        productsRequest.start()
    }
    
    /// Performs payment request
    ///
    /// - Parameters:
    ///   - product: The product to be bought
    ///   - quantity: The quantity of products
    ///   - username: The buyer's username (sha256 encrypted)
    func performPaymentRequest(with product: SKProduct, quantity: Int, username: String) {
        let payment = SKMutablePayment(product: product)
        payment.quantity = quantity
        payment.applicationUsername = username
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().add(payment)
    }
    
    /// Call this every time your transactions are done
    func finishTransactions() {
        SKPaymentQueue.default().remove(self)
    }
    
    // MARK: - User review
    
    /// Calls the App Store Rating Alert Controller
    static func requestReview() {
        SKStoreReviewController.requestReview()
    }
}

// MARK: - Payment transaction observer
extension StoreKitClient: SKPaymentTransactionObserver {
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .failed, .restored:
                SKPaymentQueue.default().finishTransaction(transaction)
            default:
                break
            }
        }
        delegate.storeKitClient(self, didUpdateTransactions: transactions)
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        delegate.storeKitClient(self, didUpdateTransactions: queue.transactions)
    }
}

// MARK: - Products request delegate
extension StoreKitClient: SKProductsRequestDelegate {
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let validProducts = response.products.filter { productIdentifiers.contains($0.productIdentifier) }
        delegate.storeKitClient(self, didFinishProductsRequestWithProducts: validProducts)
    }
}
