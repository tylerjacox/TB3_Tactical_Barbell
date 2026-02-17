// TB3 iOS — Profile View (settings, 1RM entry, sync, data management)

import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) var appState
    @Bindable var vm: ProfileViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScreenHeader(title: "Profile")

                Form {
                    // 1RM Entry
                    liftEntrySection

                    // Settings
                    settingsSection

                    // Plate Inventory
                    plateInventorySection

                    // Sync
                    syncSection

                    // Data Management
                    dataSection

                    // About
                    aboutSection
                }
                .scrollContentBackground(.hidden)
            }
            .background(Color.tb3Background)
            .navigationBarHidden(true)
            .confirmDialog(isPresented: $vm.showDeleteConfirm, config: ConfirmDialogConfig(
                title: "Delete All Data?",
                message: "This will permanently delete all your training data, maxes, and settings. This cannot be undone.",
                confirmLabel: "Delete Everything",
                isDanger: true,
                onConfirm: { vm.deleteAllData() }
            ))
        }
    }

    // MARK: - Lift Entry

    private var liftEntrySection: some View {
        Section("Your Lifts") {
            ForEach(LiftName.allCases, id: \.rawValue) { lift in
                liftRow(lift)
            }
        }
    }

    private func liftRow(_ lift: LiftName) -> some View {
        let current = appState.currentLifts.first { $0.name == lift.rawValue }

        return VStack(alignment: .leading, spacing: 8) {
            Button {
                vm.toggleLift(lift.rawValue)
            } label: {
                HStack {
                    Text(lift.displayName)
                        .font(.body)
                        .foregroundStyle(Color.tb3Text)

                    Spacer()

                    if let current {
                        Text("\(Int(current.workingMax)) lb")
                            .font(.subheadline.monospaced())
                            .foregroundStyle(Color.tb3Muted)
                    } else {
                        Text("Not set")
                            .font(.subheadline)
                            .foregroundStyle(Color.tb3Disabled)
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.tb3Disabled)
                        .rotationEffect(.degrees(vm.expandedLift == lift.rawValue ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            if vm.expandedLift == lift.rawValue {
                HStack(spacing: 12) {
                    TextField("Weight", text: $vm.liftWeight)
                        .keyboardType(.decimalPad)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)

                    Text("lb \u{00D7}")
                        .foregroundStyle(Color.tb3Muted)

                    TextField("Reps", text: $vm.liftReps)
                        .keyboardType(.numberPad)
                        .frame(width: 60)
                        .textFieldStyle(.roundedBorder)

                    Text("reps")
                        .foregroundStyle(Color.tb3Muted)

                    Spacer()

                    Button("Save") {
                        vm.save1RM(liftName: lift.rawValue)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(vm.liftWeight.isEmpty || vm.liftReps.isEmpty)
                }

                // Percentage table
                if let current {
                    percentageTable(workingMax: current.workingMax)
                }
            }
        }
    }

    private func percentageTable(workingMax: Double) -> some View {
        let rounding = appState.profile.roundingIncrement
        let percentages = [100, 95, 90, 85, 80, 75, 70, 65]

        return VStack(alignment: .leading, spacing: 4) {
            ForEach(percentages, id: \.self) { pct in
                let weight = OneRepMaxCalculator.roundWeight(workingMax * Double(pct) / 100.0, increment: rounding)
                HStack {
                    Text("\(pct)%")
                        .font(.caption.monospaced())
                        .foregroundStyle(Color.tb3Muted)
                        .frame(width: 40, alignment: .trailing)
                    Text("\(Int(weight)) lb")
                        .font(.caption.monospaced())
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Settings

    private var settingsSection: some View {
        Section("Settings") {
            // Max Type
            Picker("Max Type", selection: Binding(
                get: { appState.profile.maxType },
                set: { vm.updateMaxType($0) }
            )) {
                Text("Training (90%)").tag("training")
                Text("True 1RM").tag("true")
            }

            // Rounding
            Picker("Rounding", selection: Binding(
                get: { appState.profile.roundingIncrement },
                set: { vm.updateRounding($0) }
            )) {
                Text("2.5 lb").tag(2.5)
                Text("5 lb").tag(5.0)
            }

            // Barbell Weight
            HStack {
                Text("Barbell Weight")
                Spacer()
                TextField("45", text: Binding(
                    get: { "\(Int(appState.profile.barbellWeight))" },
                    set: { vm.updateBarbellWeight($0) }
                ))
                .keyboardType(.numberPad)
                .frame(width: 60)
                .multilineTextAlignment(.trailing)
                Text("lb")
                    .foregroundStyle(Color.tb3Muted)
            }

            // Rest Timer
            HStack {
                Text("Rest Timer Default")
                Spacer()
                TextField("120", text: Binding(
                    get: { "\(appState.profile.restTimerDefault)" },
                    set: { vm.updateRestTimer($0) }
                ))
                .keyboardType(.numberPad)
                .frame(width: 60)
                .multilineTextAlignment(.trailing)
                Text("sec")
                    .foregroundStyle(Color.tb3Muted)
            }

            // Sound Mode
            Picker("Sound", selection: Binding(
                get: { appState.profile.soundMode },
                set: { vm.updateSoundMode($0) }
            )) {
                Text("On").tag("on")
                Text("Vibrate").tag("vibrate")
                Text("Off").tag("off")
            }

            // Voice
            Toggle("Voice Countdown", isOn: Binding(
                get: { appState.profile.voiceAnnouncements },
                set: { vm.updateVoice($0) }
            ))
        }
    }

    // MARK: - Plate Inventory

    private var plateInventorySection: some View {
        Section("Plate Inventory") {
            NavigationLink("Barbell Plates") {
                PlateInventoryEditorView(
                    inventory: Binding(
                        get: { appState.profile.plateInventoryBarbell },
                        set: { newValue in
                            appState.profile.plateInventoryBarbell = newValue
                            let profile = vm.dataStore.loadProfile()
                            profile.apply(from: appState.profile)
                            vm.dataStore.saveProfile(profile)
                            appState.regenerateScheduleIfNeeded()
                        }
                    ),
                    title: "Barbell Plates"
                )
            }

            NavigationLink("Belt Plates") {
                PlateInventoryEditorView(
                    inventory: Binding(
                        get: { appState.profile.plateInventoryBelt },
                        set: { newValue in
                            appState.profile.plateInventoryBelt = newValue
                            let profile = vm.dataStore.loadProfile()
                            profile.apply(from: appState.profile)
                            vm.dataStore.saveProfile(profile)
                            appState.regenerateScheduleIfNeeded()
                        }
                    ),
                    title: "Belt Plates"
                )
            }
        }
    }

    // MARK: - Sync

    private var syncSection: some View {
        Section("Sync") {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if appState.syncState.isSyncing {
                        Label("Syncing...", systemImage: "arrow.triangle.2.circlepath")
                            .font(.subheadline)
                    } else if let lastSync = appState.syncState.lastSyncedAt {
                        Label("Last synced", systemImage: "checkmark.circle")
                            .font(.subheadline)
                        Text(lastSync)
                            .font(.caption)
                            .foregroundStyle(Color.tb3Muted)
                    } else {
                        Label("Not synced", systemImage: "xmark.circle")
                            .font(.subheadline)
                            .foregroundStyle(Color.tb3Muted)
                    }

                    if let error = appState.syncState.error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Color.tb3Error)
                    }
                }

                Spacer()

                Button("Sync Now") {
                    vm.syncNow()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(appState.syncState.isSyncing)
            }

            HStack {
                Text("Sessions")
                Spacer()
                Text("\(appState.sessionHistory.count)")
                    .foregroundStyle(Color.tb3Muted)
            }

            HStack {
                Text("Max Tests")
                Spacer()
                Text("\(appState.maxTestHistory.count)")
                    .foregroundStyle(Color.tb3Muted)
            }
        }
    }

    // MARK: - Data Management

    private var dataSection: some View {
        Section("Data") {
            Button("Export Data") {
                // TODO: Phase 6 — ExportImportService
            }

            Button("Import Data") {
                // TODO: Phase 6 — ExportImportService
            }

            if appState.authState.isAuthenticated {
                Button("Sign Out") {
                    Task { await vm.signOut() }
                }
            }

            Button("Delete All Data", role: .destructive) {
                vm.showDeleteConfirm = true
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(Color.tb3Muted)
            }

            if let email = appState.authState.email {
                HStack {
                    Text("Account")
                    Spacer()
                    Text(email)
                        .foregroundStyle(Color.tb3Muted)
                }
            }
        }
    }
}

