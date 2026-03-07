// TB3 iOS — GoogleCast SDK Bridge
// Adapts GCKSessionManager events to CastService and wraps GCKCastChannel
// as CastSessionProtocol for message sending.

import Foundation
import UIKit

/// Bridges GoogleCast SDK (Obj-C) to the Swift CastService / CastSessionProtocol.
@MainActor
final class GCKCastSessionAdapter: NSObject {
    private let castService: CastService
    private let castState: CastState
    private let namespace = AppConfig.castNamespace
    private var channel: TB3CastChannel?
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
        // Remove old channel from previous session if any
        if let oldChannel = channel {
            oldChannel.onConnected = nil
        }

        // Create channel that notifies us when it's actually connected
        let ch = TB3CastChannel(namespace: namespace)
        ch.onConnected = { [weak self] in
            Task { @MainActor [weak self] in
                self?.onChannelReady(ch)
            }
        }
        session.add(ch)
        channel = ch

        castService.updateDeviceName(session.device.friendlyName)
    }

    private func onChannelReady(_ ch: TB3CastChannel) {
        let adapter = GCKChannelAdapter(channel: ch)
        castService.onSessionConnected(adapter)

        // Send state immediately + retry at 500ms and 1500ms
        notifyCurrentState()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.notifyCurrentState()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.notifyCurrentState()
        }
    }

    private func handleSessionEnded() {
        if let oldChannel = channel {
            oldChannel.onConnected = nil
        }
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

// MARK: - TB3CastChannel (subclass to get didConnect/didDisconnect callbacks)

/// Custom GCKCastChannel subclass that provides connection lifecycle callbacks.
/// GCKGenericChannel's delegate only exposes message reception, not connect/disconnect.
final class TB3CastChannel: GCKCastChannel, @unchecked Sendable {
    /// Fires on main thread when channel connects (ready to send messages).
    var onConnected: (@Sendable () -> Void)?

    override func didConnect() {
        super.didConnect()
        let callback = onConnected
        DispatchQueue.main.async {
            callback?()
        }
    }

    override func didDisconnect() {
        super.didDisconnect()
    }
}

// MARK: - GCKChannelAdapter (CastSessionProtocol)

/// Wraps GCKCastChannel to implement CastSessionProtocol.
final class GCKChannelAdapter: CastSessionProtocol {
    private let channel: GCKCastChannel

    init(channel: GCKCastChannel) {
        self.channel = channel
    }

    func sendMessage(_ message: String, namespace: String) throws {
        var error: GCKError?
        channel.sendTextMessage(message, error: &error)
        if let error { throw error }
    }
}
