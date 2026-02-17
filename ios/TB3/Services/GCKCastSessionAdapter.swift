// TB3 iOS — GoogleCast SDK Bridge
// Adapts GCKSessionManager events to CastService and wraps GCKGenericChannel
// as CastSessionProtocol for message sending.

import Foundation
import UIKit

/// Bridges GoogleCast SDK (Obj-C) to the Swift CastService / CastSessionProtocol.
@MainActor
final class GCKCastSessionAdapter: NSObject {
    private let castService: CastService
    private let castState: CastState
    private let namespace = AppConfig.castNamespace
    private var channel: GCKGenericChannel?
    private var sessionManager: GCKSessionManager?

    /// Called to request sending current workout state (set by RootView wiring).
    var onRequestSendState: (() -> Void)?

    init(castService: CastService, castState: CastState) {
        self.castService = castService
        self.castState = castState
        super.init()
    }

    func start() {
        let context = GCKCastContext.sharedInstance()
        sessionManager = context.sessionManager
        sessionManager?.add(self)

        // Track device discovery via notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(castStateDidChange(_:)),
            name: NSNotification.Name.gckCastStateDidChange,
            object: nil
        )

        // Set initial availability
        let gckState = context.castState
        castService.setAvailable(gckState != .noDevicesAvailable)
    }

    @objc private func castStateDidChange(_ notification: Notification) {
        let gckState = GCKCastContext.sharedInstance().castState
        castService.setAvailable(gckState != .noDevicesAvailable)
        castState.isLoading = (gckState == .connecting)
    }

    // MARK: - Private Handlers

    private func handleSessionStarted(_ session: GCKCastSession) {
        let ch = GCKGenericChannel(namespace: namespace)
        session.add(ch)
        channel = ch

        let adapter = GCKChannelAdapter(channel: ch)
        castService.onSessionConnected(adapter)
        castService.updateDeviceName(session.device.friendlyName)

        // Send state immediately + retry at 500ms and 1500ms
        // (matches web app's connection race handling)
        notifyCurrentState()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.notifyCurrentState()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.notifyCurrentState()
        }
    }

    private func handleSessionEnded() {
        channel = nil
        castService.onSessionDisconnected()
    }

    private func notifyCurrentState() {
        onRequestSendState?()
    }
}

// MARK: - GCKSessionManagerListener

extension GCKCastSessionAdapter: GCKSessionManagerListener {
    nonisolated func sessionManager(
        _ sessionManager: GCKSessionManager,
        didStart session: GCKCastSession
    ) {
        nonisolated(unsafe) let s = session
        DispatchQueue.main.async { [weak self] in
            self?.handleSessionStarted(s)
        }
    }

    nonisolated func sessionManager(
        _ sessionManager: GCKSessionManager,
        didResumeCastSession session: GCKCastSession
    ) {
        nonisolated(unsafe) let s = session
        DispatchQueue.main.async { [weak self] in
            self?.handleSessionStarted(s)
        }
    }

    nonisolated func sessionManager(
        _ sessionManager: GCKSessionManager,
        didEnd session: GCKSession,
        withError error: (any Error)?
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.handleSessionEnded()
        }
    }

    nonisolated func sessionManager(
        _ sessionManager: GCKSessionManager,
        didFailToStart session: GCKSession,
        withError error: any Error
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.handleSessionEnded()
        }
    }
}

// MARK: - GCKChannelAdapter (CastSessionProtocol)

/// Wraps GCKGenericChannel to implement CastSessionProtocol.
final class GCKChannelAdapter: CastSessionProtocol {
    private let channel: GCKGenericChannel

    init(channel: GCKGenericChannel) {
        self.channel = channel
    }

    func sendMessage(_ message: String, namespace: String) throws {
        var error: GCKError?
        channel.sendTextMessage(message, error: &error)
        if let error { throw error }
    }
}
