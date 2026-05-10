import SwiftUI

struct AudioInputSettingsView: View {
    @ObservedObject var audioDeviceManager = AudioDeviceManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                mainContent
            }
        }
        .background(DreamersAtmosphere().ignoresSafeArea())
        .foregroundStyle(DreamersTheme.primaryText(for: colorScheme))
        .tint(DreamersTheme.accentText(for: colorScheme))
    }
    
    private var mainContent: some View {
        VStack(spacing: 40) {
            inputModeSection

            switch audioDeviceManager.inputMode {
            case .systemDefault:
                systemDefaultSection
            case .custom:
                customDeviceSection
            case .prioritized:
                prioritizedDevicesSection
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
    }
    
    private var heroSection: some View {
        CompactHeroSection(
            icon: "waveform",
            title: "Audio Input",
            description: "Configure your microphone preferences"
        )
    }
    
    private var inputModeSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Input Mode")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(DreamersTheme.primaryText(for: colorScheme))
            
            HStack(spacing: 20) {
                ForEach(AudioInputMode.allCases, id: \.self) { mode in
                    InputModeCard(
                        mode: mode,
                        isSelected: audioDeviceManager.inputMode == mode,
                        action: { audioDeviceManager.selectInputMode(mode) }
                    )
                }
            }
        }
    }
    
    private var systemDefaultSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Current Device")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(DreamersTheme.primaryText(for: colorScheme))

            HStack {
                Image(systemName: "display")
                    .foregroundStyle(DreamersTheme.secondaryText(for: colorScheme))

                Text(audioDeviceManager.getSystemDefaultDeviceName() ?? "No device available")
                    .foregroundStyle(DreamersTheme.primaryText(for: colorScheme))

                Spacer()

                Label("Active", systemImage: "wave.3.right")
                    .font(.caption)
                    .foregroundStyle(DreamersTheme.success(for: colorScheme))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(DreamersTheme.success(for: colorScheme).opacity(0.14))
                    )
            }
            .padding()
            .background(CardBackground(isSelected: false))
        }
    }

    private var customDeviceSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Available Devices")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(DreamersTheme.primaryText(for: colorScheme))

                Spacer()

                Button(action: { audioDeviceManager.loadAvailableDevices() }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(ChromeIconButtonStyle())
            }

            VStack(spacing: 12) {
                ForEach(audioDeviceManager.availableDevices, id: \.id) { device in
                    DeviceSelectionCard(
                        name: device.name,
                        isSelected: audioDeviceManager.selectedDeviceID == device.id,
                        isActive: audioDeviceManager.getCurrentDevice() == device.id
                    ) {
                        audioDeviceManager.selectDevice(id: device.id)
                    }
                }
            }
        }
    }
    
    private var prioritizedDevicesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            if audioDeviceManager.availableDevices.isEmpty {
                emptyDevicesState
            } else {
                prioritizedDevicesContent
                Divider().padding(.vertical, 8)
                availableDevicesContent
            }
        }
    }
    
    private var prioritizedDevicesContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Prioritized Devices")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Devices will be used in order of priority. If a device is unavailable, the next one will be tried. If no prioritized device is available, the built-in microphone will be used.")
                    .font(.subheadline)
                    .foregroundStyle(DreamersTheme.secondaryText(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if audioDeviceManager.prioritizedDevices.isEmpty {
                Text("No prioritized devices")
                    .foregroundStyle(DreamersTheme.secondaryText(for: colorScheme))
                    .padding(.vertical, 8)
            } else {
                prioritizedDevicesList
            }
        }
    }
    
    private var availableDevicesContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Devices")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(DreamersTheme.primaryText(for: colorScheme))
            
            availableDevicesList
        }
    }
    
    private var emptyDevicesState: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.slash.circle.fill")
                .font(.system(size: 48))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(DreamersTheme.secondaryText(for: colorScheme))
            
            VStack(spacing: 8) {
                Text("No Audio Devices")
                    .font(.headline)
                    .foregroundStyle(DreamersTheme.primaryText(for: colorScheme))
                Text("Connect an audio input device to get started")
                    .font(.subheadline)
                    .foregroundStyle(DreamersTheme.secondaryText(for: colorScheme))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(CardBackground(isSelected: false))
    }
    
    private var prioritizedDevicesList: some View {
        VStack(spacing: 12) {
            ForEach(audioDeviceManager.prioritizedDevices.sorted(by: { $0.priority < $1.priority })) { device in
                devicePriorityCard(for: device)
            }
        }
    }
    
    private func devicePriorityCard(for prioritizedDevice: PrioritizedDevice) -> some View {
        let device = audioDeviceManager.availableDevices.first(where: { $0.uid == prioritizedDevice.id })
        return DevicePriorityCard(
            name: prioritizedDevice.name,
            priority: prioritizedDevice.priority,
            isActive: device.map { audioDeviceManager.getCurrentDevice() == $0.id } ?? false,
            isPrioritized: true,
            isAvailable: device != nil,
            canMoveUp: prioritizedDevice.priority > 0,
            canMoveDown: prioritizedDevice.priority < audioDeviceManager.prioritizedDevices.count - 1,
            onTogglePriority: { audioDeviceManager.removePrioritizedDevice(id: prioritizedDevice.id) },
            onMoveUp: { moveDeviceUp(prioritizedDevice) },
            onMoveDown: { moveDeviceDown(prioritizedDevice) }
        )
    }
    
    private var availableDevicesList: some View {
        let unprioritizedDevices = audioDeviceManager.availableDevices.filter { device in
            !audioDeviceManager.prioritizedDevices.contains { $0.id == device.uid }
        }
        
        return Group {
            if unprioritizedDevices.isEmpty {
                Text("No additional devices available")
                    .foregroundStyle(DreamersTheme.secondaryText(for: colorScheme))
                    .padding(.vertical, 8)
            } else {
                ForEach(unprioritizedDevices, id: \.id) { device in
                    DevicePriorityCard(
                        name: device.name,
                        priority: nil,
                        isActive: audioDeviceManager.getCurrentDevice() == device.id,
                        isPrioritized: false,
                        isAvailable: true,
                        canMoveUp: false,
                        canMoveDown: false,
                        onTogglePriority: { audioDeviceManager.addPrioritizedDevice(uid: device.uid, name: device.name) },
                        onMoveUp: {},
                        onMoveDown: {}
                    )
                }
            }
        }
    }
    
    private func moveDeviceUp(_ device: PrioritizedDevice) {
        guard device.priority > 0,
              let currentIndex = audioDeviceManager.prioritizedDevices.firstIndex(where: { $0.id == device.id })
        else { return }
        
        var devices = audioDeviceManager.prioritizedDevices
        devices.swapAt(currentIndex, currentIndex - 1)
        updatePriorities(devices)
    }
    
    private func moveDeviceDown(_ device: PrioritizedDevice) {
        guard device.priority < audioDeviceManager.prioritizedDevices.count - 1,
              let currentIndex = audioDeviceManager.prioritizedDevices.firstIndex(where: { $0.id == device.id })
        else { return }
        
        var devices = audioDeviceManager.prioritizedDevices
        devices.swapAt(currentIndex, currentIndex + 1)
        updatePriorities(devices)
    }
    
    private func updatePriorities(_ devices: [PrioritizedDevice]) {
        let updatedDevices = devices.enumerated().map { index, device in
            PrioritizedDevice(id: device.id, name: device.name, priority: index)
        }
        audioDeviceManager.updatePriorities(devices: updatedDevices)
    }
}

struct InputModeCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let mode: AudioInputMode
    let isSelected: Bool
    let action: () -> Void

    private var icon: String {
        switch mode {
        case .systemDefault: return "display"
        case .custom: return "mic.circle.fill"
        case .prioritized: return "list.number"
        }
    }

    private var description: String {
        switch mode {
        case .systemDefault: return "Use your Mac's default input"
        case .custom: return "Select a specific input device"
        case .prioritized: return "Set up device priority order"
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isSelected ? DreamersTheme.accentText(for: colorScheme) : DreamersTheme.secondaryText(for: colorScheme))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.rawValue)
                        .font(.headline)
                        .foregroundStyle(DreamersTheme.primaryText(for: colorScheme))
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(DreamersTheme.secondaryText(for: colorScheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(CardBackground(isSelected: isSelected))
        }
        .buttonStyle(.plain)
    }
}

struct DeviceSelectionCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let name: String
    let isSelected: Bool
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isSelected ? DreamersTheme.accentText(for: colorScheme) : DreamersTheme.secondaryText(for: colorScheme))
                    .font(.system(size: 18))
                
                Text(name)
                    .foregroundStyle(DreamersTheme.primaryText(for: colorScheme))
                
                Spacer()
                
                if isActive {
                    Label("Active", systemImage: "wave.3.right")
                        .font(.caption)
                        .foregroundStyle(DreamersTheme.success(for: colorScheme))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(DreamersTheme.success(for: colorScheme).opacity(0.14))
                        )
                }
            }
            .padding()
            .background(CardBackground(isSelected: isSelected))
        }
        .buttonStyle(.plain)
    }
}

struct DevicePriorityCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let name: String
    let priority: Int?
    let isActive: Bool
    let isPrioritized: Bool
    let isAvailable: Bool
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onTogglePriority: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    
    var body: some View {
        HStack {
            // Priority number or dash
            if let priority = priority {
                Text("\(priority + 1)")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(DreamersTheme.secondaryText(for: colorScheme))
                    .frame(width: 24)
            } else {
                Text("-")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(DreamersTheme.secondaryText(for: colorScheme))
                    .frame(width: 24)
            }
            
            // Device name
            Text(name)
                .foregroundStyle(isAvailable ? DreamersTheme.primaryText(for: colorScheme) : DreamersTheme.secondaryText(for: colorScheme))
            
            Spacer()
            
            // Status and Controls
            HStack(spacing: 12) {
                // Active status
                if isActive {
                    Label("Active", systemImage: "wave.3.right")
                        .font(.caption)
                        .foregroundStyle(DreamersTheme.success(for: colorScheme))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(DreamersTheme.success(for: colorScheme).opacity(0.14))
                        )
                } else if !isAvailable && isPrioritized {
                    Label("Unavailable", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(DreamersTheme.warning(for: colorScheme))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(DreamersTheme.warning(for: colorScheme).opacity(0.14))
                        )
                }
                
                // Priority controls (only show if prioritized)
                if isPrioritized {
                    HStack(spacing: 2) {
                        Button(action: onMoveUp) {
                            Image(systemName: "chevron.up")
                        .foregroundStyle(canMoveUp ? DreamersTheme.accentText(for: colorScheme) : DreamersTheme.tertiaryText(for: colorScheme).opacity(0.5))
                        }
                        .disabled(!canMoveUp)
                        
                        Button(action: onMoveDown) {
                            Image(systemName: "chevron.down")
                        .foregroundStyle(canMoveDown ? DreamersTheme.accentText(for: colorScheme) : DreamersTheme.tertiaryText(for: colorScheme).opacity(0.5))
                        }
                        .disabled(!canMoveDown)
                    }
                }
                
                // Toggle priority button
                Button(action: onTogglePriority) {
                    Image(systemName: isPrioritized ? "minus.circle.fill" : "plus.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(isPrioritized ? DreamersTheme.danger(for: colorScheme) : DreamersTheme.accentText(for: colorScheme))
                }
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(CardBackground(isSelected: false))
    }
} 
