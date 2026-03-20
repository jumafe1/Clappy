import SwiftUI

struct PreferencesView: View {
    @ObservedObject var viewModel: PreferencesViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Trigger Mode
            VStack(alignment: .leading, spacing: 8) {
                Text("Trigger Mode")
                    .font(.headline)

                Picker("", selection: $viewModel.triggerMode) {
                    ForEach(NotchHoverMonitor.TriggerMode.allCases) { mode in
                        Text(mode.rawValue.capitalized).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                Text(triggerModeDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Slot Ordering
            VStack(alignment: .leading, spacing: 8) {
                Text("Feature Slots")
                    .font(.headline)

                List {
                    ForEach(viewModel.slots) { slot in
                        HStack {
                            Toggle(isOn: Binding(
                                get: { slot.isEnabled },
                                set: { _ in viewModel.toggleSlot(slot) }
                            )) {
                                Text(slot.type.displayName)
                            }
                        }
                    }
                    .onMove { source, destination in
                        viewModel.moveSlot(from: source, to: destination)
                    }
                }
                .frame(height: 100)
            }

            Divider()

            // Quit
            HStack {
                Spacer()
                Button("Quit Clappy") {
                    NSApp.terminate(nil)
                }
            }
        }
        .padding(20)
        .frame(width: 380)
    }

    private var triggerModeDescription: String {
        switch viewModel.triggerMode {
        case .hover:
            return "Panel expands when you hover near the notch area."
        case .click:
            return "Panel expands when you click the notch area."
        case .both:
            return "Panel expands on hover or click."
        }
    }
}
