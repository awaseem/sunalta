import SwiftUI

struct AlarmExitPointOptionButton: View {
    let option: AlarmExitPoint
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: option.symbol).font(.title3).frame(width: 28)
                VStack(alignment: .leading) {
                    Text(option.title).font(.body.weight(.semibold))
                    Text(option.detail).font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.title3)
                    .accessibilityHidden(true)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
            .background(Color.primary.opacity(0.06), in: .rect(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.primary : .clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.title)
        .accessibilityHint(option.detail)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("exit-point-\(option.rawValue)")
    }
}
