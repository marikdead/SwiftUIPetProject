// MARK: - PRESENTATION LAYER → View
// SummaryView — итоговый экран.
// Показывает список позиций из заказа, позволяет выбрать чаевые и количество людей,
// переиспользует TipCalculatorViewModel для расчётов.

import SwiftUI
import SwiftData

struct SummaryView: View {
    let orderItems: [MenuOrderItem]
    let orderTotal: Double

    @State private var viewModel: TipCalculatorViewModel
    @Environment(AppRouter.self) private var router
    @Environment(AppSettings.self) private var settings
    @Environment(AppShellState.self) private var shellState
    @Environment(\.modelContext) private var modelContext
    @State private var isSaved = false
    private let saveUseCase = SaveCheckUseCase()

    init(orderItems: [MenuOrderItem], orderTotal: Double) {
        self.orderItems = orderItems
        self.orderTotal = orderTotal
        // Передаём сумму заказа напрямую в ViewModel через billAmountText
        let vm = TipCalculatorViewModel()
        vm.updateBillAmount(String(orderTotal))
        _viewModel = State(initialValue: vm)
    }

    var body: some View {
        let palette = settings.palette

        ZStack {
            palette.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    SummaryHeaderView(onBack: { router.pop() }, palette: palette)
                    
                    OrderItemsCard(
                        items: orderItems,
                        format: { viewModel.formatCurrency($0) },
                        palette: palette
                    )

                    PeopleSummarySection(
                        count: viewModel.numberOfPeople,
                        palette: palette,
                        onDecrement: { viewModel.changePeople(by: -1) },
                        onIncrement: { viewModel.changePeople(by: 1) }
                    )

                    TipSummarySection(
                        options: viewModel.tipOptions,
                        selected: viewModel.selectedTipPercentage,
                        palette: palette,
                        labelFor: { viewModel.formattedPercentage($0) },
                        onSelect: { viewModel.selectTip($0) }
                    )

                    if let calc = viewModel.calculation {
                        SummaryResultCard(
                            calculation: calc,
                            format: { viewModel.formatCurrency($0) },
                            palette: palette
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    if viewModel.calculation != nil {
                        SaveCheckButton(isSaved: isSaved, palette: palette) {
                            guard let calc = viewModel.calculation else { return }
                            let record = CheckRecord(
                                billAmount: calc.billAmount,
                                tipPercentage: calc.tipPercentage,
                                tipAmount: calc.tipAmount,
                                totalAmount: calc.totalAmount,
                                numberOfPeople: viewModel.numberOfPeople,
                                itemNames: orderItems.map { $0.menuItem.name }
                            )
                            saveUseCase.execute(record, context: modelContext)
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                isSaved = true
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.calculation?.amountPerPerson)
        .navigationBarHidden(true)
    }
}

private struct SummaryHeaderView: View {
    let onBack: () -> Void
    let palette: AppPalette

    var body: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Меню")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                }
                .foregroundStyle(palette.accentStart)
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Итог")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(palette.textPrimary)
                Text("Разделим честно")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(palette.textMuted)
            }
        }
        .padding(.top, 8)
    }
}

private struct OrderItemsCard: View {
    let items: [MenuOrderItem]
    let format: (Double) -> String
    let palette: AppPalette

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Label("Ваш заказ", systemImage: "list.bullet.rectangle")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(palette.textMuted)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

            ForEach(items) { orderItem in
                HStack(spacing: 10) {
                    Text(orderItem.menuItem.emoji)
                        .font(.system(size: 22))
                        .frame(width: 36, height: 36)
                        .background(palette.secondarySurface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    Text(orderItem.menuItem.name)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(palette.textSecondary)

                    if orderItem.quantity > 1 {
                        Text("×\(orderItem.quantity)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(palette.accentStart)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(palette.accentSoft)
                            .clipShape(Capsule())
                    }

                    Spacer()

                    Text(format(orderItem.subtotal))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(palette.textPrimary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)

                if orderItem.id != items.last?.id {
                    Divider()
                        .background(palette.border)
                        .padding(.horizontal, 20)
                }
            }

            Divider()
                .background(palette.border)
                .padding(.horizontal, 20)

            HStack {
                Text("Сумма заказа")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.textSecondary)
                Spacer()
                Text(format(items.reduce(0) { $0 + $1.subtotal }))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.textPrimary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(palette.border, lineWidth: 1)
        )
    }
}

private struct PeopleSummarySection: View {
    let count: Int
    let palette: AppPalette
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Количество людей", systemImage: "person.2")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(palette.textMuted)

            HStack {
                Button(action: onDecrement) {
                    Image(systemName: "minus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(palette.accentStart)
                        .frame(width: 44, height: 44)
                        .background(palette.secondarySurface)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(palette.border, lineWidth: 1))
                }
                .buttonStyle(.plain)

                Spacer()

                Text("\(count)")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(palette.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: count)

                Spacer()

                Button(action: onIncrement) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            LinearGradient(
                                colors: [palette.accentStart, palette.accentEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(palette.border, lineWidth: 1)
        )
    }
}

private struct TipSummarySection: View {
    let options: [Double]
    let selected: Double
    let palette: AppPalette
    let labelFor: (Double) -> String
    let onSelect: (Double) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Чаевые", systemImage: "star")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(palette.textMuted)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(options, id: \.self) { option in
                    let isSelected = selected == option
                    Button { onSelect(option) } label: {
                        Text(labelFor(option))
                            .font(.system(size: 15, weight: isSelected ? .bold : .medium, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(isSelected ? .white : palette.textMuted)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                Group {
                                    if isSelected {
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(LinearGradient(
                                                colors: [palette.accentStart, palette.accentEnd],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ))
                                    } else {
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(palette.secondarySurface)
                                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(palette.border, lineWidth: 1))
                                    }
                                }
                            )
                            .shadow(color: isSelected ? palette.accentStart.opacity(0.4) : .clear, radius: 8, y: 4)
                            .scaleEffect(isSelected ? 1.03 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(palette.border, lineWidth: 1)
        )
    }
}

private struct SummaryResultCard: View {
    let calculation: TipCalculation
    let format: (Double) -> String
    let palette: AppPalette

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("Каждый платит")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.textMuted)
                Text(format(calculation.amountPerPerson))
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(palette.textPrimary)
                    .contentTransition(.numericText(value: calculation.amountPerPerson))
                    .animation(.spring(response: 0.4), value: calculation.amountPerPerson)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(LinearGradient(
                colors: [palette.accentStart.opacity(0.35), palette.accentEnd.opacity(0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))

            Divider().background(palette.border)

            VStack(spacing: 0) {
                SummaryRow(icon: "doc.text", title: "Счёт", value: format(calculation.billAmount), palette: palette)
                Divider().background(palette.border).padding(.horizontal, 20)
                SummaryRow(icon: "star", title: "Чаевые (\(Int(calculation.tipPercentage * 100))%)", value: format(calculation.tipAmount), palette: palette, valueColor: palette.accentStart)
                Divider().background(palette.border).padding(.horizontal, 20)
                SummaryRow(icon: "sum", title: "Итого", value: format(calculation.totalAmount), palette: palette, isBold: true)
                Divider().background(palette.border).padding(.horizontal, 20)
                SummaryRow(icon: "person.2", title: "Чаевые на чел.", value: format(calculation.tipPerPerson), palette: palette, valueColor: palette.accentStart)
            }
            .padding(.vertical, 8)
            .background(palette.surface)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(palette.border, lineWidth: 1))
        .shadow(color: palette.accentStart.opacity(0.15), radius: 20, y: 8)
    }
}

private struct SummaryRow: View {
    let icon: String
    let title: String
    let value: String
    let palette: AppPalette
    var valueColor: Color? = nil
    var isBold: Bool = false

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(palette.textMuted)
                .frame(width: 20)
            Text(title)
                .font(.system(size: 14, weight: isBold ? .semibold : .regular, design: .rounded))
                .foregroundStyle(isBold ? palette.textSecondary : palette.textMuted)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: isBold ? .bold : .medium, design: .rounded))
                .foregroundStyle(valueColor ?? palette.textPrimary)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

private struct SaveCheckButton: View {
    let isSaved: Bool
    let palette: AppPalette
    let onSave: () -> Void

    var body: some View {
        Button(action: onSave) {
            HStack(spacing: 10) {
                Image(systemName: isSaved ? "checkmark.circle.fill" : "square.and.arrow.down")
                    .font(.system(size: 16, weight: .semibold))
                Text(isSaved ? "Чек сохранён" : "Сохранить чек")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(isSaved ? palette.accentStart : .white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                Group {
                    if isSaved {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(palette.accentSoft)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(palette.accentStart.opacity(0.4), lineWidth: 1))
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(
                                colors: [palette.accentStart, palette.accentEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                    }
                }
            )
            .shadow(color: isSaved ? .clear : palette.accentStart.opacity(0.35), radius: 12, y: 5)
            .scaleEffect(isSaved ? 1.0 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSaved)
        }
        .buttonStyle(.plain)
        .disabled(isSaved)
    }
}

#Preview {
    let sampleItems = [
        MenuOrderItem(menuItem: MenuRepository.items[0], quantity: 2),
        MenuOrderItem(menuItem: MenuRepository.items[4], quantity: 1),
        MenuOrderItem(menuItem: MenuRepository.items[8], quantity: 3),
    ]
    NavigationStack {
        SummaryView(orderItems: sampleItems, orderTotal: sampleItems.reduce(0) { $0 + $1.subtotal })
    }
    .environment(AppRouter())
    .environment(AppSettings())
    .environment(AppShellState())
}
