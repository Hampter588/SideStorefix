//
//  CellularRefreshManager.swift
//  SideStore
//
//  Created by Magesh K on 4/9/26.
//  Copyright © 2026 SideStore. All rights reserved.
//

import Foundation
import UIKit
import Minimuxer

public final class CellularRefreshManager: @unchecked Sendable {
    public static let shared = CellularRefreshManager()

    private let lock = NSLock()
    private var cachedDidTurnOffData = false
    private var didTurnOffData: Bool {
        get { lock.withLock { cachedDidTurnOffData } }
        set { lock.withLock { cachedDidTurnOffData = newValue } }
    }

    private init() {}

    public var isSupported: Bool {
        #if os(tvOS)
        return false
        #else
        return true
        #endif
    }

    public var isEnabled: Bool {
        return UserDefaults.standard.isCellularRefreshEnabled
    }

    public func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.isCellularRefreshEnabled = enabled
    }

    @MainActor
    private func openShortcut(url: URL) async -> Bool {
        debugLog("[CellularRefreshManager] Opening shortcut URL: \(url.absoluteString)")
        let success = await UIApplication.shared.open(url)
        debugLog("[CellularRefreshManager] Shortcut URL open completed with success: \(success)")
        return success
    }

    @discardableResult
    private func turnOffData() async -> Bool {
        debugLog("[CellularRefreshManager] Executing TurnOffData shortcut...")
        let success = await openShortcut(url: AppConstants.Shortcuts.turnOffDataURL)
        debugLog("[CellularRefreshManager] TurnOffData shortcut finished execution.")
        return success
    }

    @discardableResult
    private func turnOnData() async -> Bool {
        debugLog("[CellularRefreshManager] Executing turnOnData shortcut...")
        let success = await openShortcut(url: AppConstants.Shortcuts.turnOnDataURL)
        debugLog("[CellularRefreshManager] turnOnData shortcut finished execution.")
        return success
    }

    private func sleep(baseDelay: TimeInterval, addOnDelay: TimeInterval = 0) async {
        let totalDelay = baseDelay + addOnDelay
        guard totalDelay > 0 else { return }
        try? await Task.sleep(nanoseconds: UInt64(totalDelay * 1_000_000_000))
    }

    // public apis
    @discardableResult
    public func turnOffDataIfNeeded(addOnDelay: TimeInterval = 0) async -> Bool {
        guard isSupported && isEnabled else { return false }
        guard !didTurnOffData else { return false }

        // If Wi-Fi is active, skip running cellular toggle shortcuts
        guard !minimuxer.network.isWifiSatisfied else {
            debugLog("[CellularRefreshManager] Wi-Fi is active, skipping turnOff shortcut.")
            return false
        }

        let success = await turnOffData()
        if success {
            didTurnOffData = true
            await sleep(baseDelay: 1.0, addOnDelay: addOnDelay)
        }
        return success
    }

    @discardableResult
    public func turnOnDataIfNeeded(addOnDelay: TimeInterval = 0) async -> Bool {
        guard didTurnOffData else { return false }

        let success = await turnOnData()
        if success {
            didTurnOffData = false
        }
        await sleep(baseDelay: 0.5, addOnDelay: addOnDelay)
        return success
    }
}
