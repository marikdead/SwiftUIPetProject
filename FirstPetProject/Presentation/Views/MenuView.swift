// MARK: - PRESENTATION LAYER → View
// MenuView — экран выбора позиций из меню.
// Структура:
//   MenuView                  ← главный экран
//     CategoryFilterBar       ← горизонтальный скролл категорий
//     MenuItemRow             ← строка одной позиции
//     OrderSummaryBar         ← нижняя плашка с итогом и кнопкой перехода

import SwiftUI

struct MenuView: View {
    @State private var viewModel = MenuViewModel()
    @Environment(AppRouter.self) private var router
    @Environment(AppSettings.self) private var settings

    var body: some View {
        let palette = settings.palette

        ZStack(alignment: .bottom) {
            palette.background.ignoresSafeArea()

            VStack(spacing: 0) {
                MenuHeaderView(totalQuantity: viewModel.totalQuantity, palette: palette)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                CategoryFilterBar(
                    selected: viewModel.selectedCategory,
                    palette: palette,
                    onSelect: { viewModel.selectCategory($0) }
                )
                .padding(.bottom, 12)

                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.filteredItems) { item in
                            MenuItemRow(
                                item: item,
                                quantity: viewModel.quantity(for: item),
                                format: { viewModel.formatCurrency($0) },
                                palette: palette,
                                onAdd: { viewModel.add(item) },
                                onRemove: { viewModel.remove(item) }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, viewModel.hasOrder ? 100 : 32)
                }
            }

            if viewModel.hasOrder {
                OrderSummaryBar(
                    total: viewModel.formatCurrency(viewModel.totalAmount),
                    quantity: viewModel.totalQuantity,
                    palette: palette,
                    onClear: { viewModel.clearOrder() },
                    onContinue: {
                        router.push(.summary(
                            items: viewModel.orderedItems,
                            total: viewModel.totalAmount
                        ))
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.hasOrder)
        .animation(.spring(response: 0.3), value: viewModel.selectedCategory)
        .navigationTitle("")
        .navigationBarHidden(true)
    }
}

private struct MenuHeaderView: View {
    let totalQuantity: Int
    let palette: AppPalette

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Меню")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(palette.textPrimary)
                Text("Собери свой заказ")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(palette.textMuted)
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(palette.secondarySurface)
                    .frame(width: 52, height: 52)

                Image(systemName: "fork.knife")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [palette.accentStart, palette.accentEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                if totalQuantity > 0 {
                    Text("\(totalQuantity)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(palette.accentStart)
                        .clipShape(Capsule())
                        .offset(x: 18, y: -18)
                }
            }
            .animation(.spring(response: 0.3), value: totalQuantity)
        }
    }
}

private struct CategoryFilterBar: View {
    let selected: MenuCategory?
    let palette: AppPalette
    let onSelect: (MenuCategory) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MenuCategory.allCases, id: \.self) { category in
                    let isSelected = selected == category
                    Button {
                        onSelect(category)
                    } label: {
                        Text(category.rawValue)
                            .font(.system(size: 14, weight: isSelected ? .semibold : .regular, design: .rounded))
                            .foregroundStyle(isSelected ? palette.textPrimary : palette.textMuted)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Group {
                                    if isSelected {
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [palette.accentStart, palette.accentEnd],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    } else {
                                        Capsule()
                                            .fill(palette.secondarySurface)
                                            .overlay(Capsule().stroke(palette.border, lineWidth: 1))
                                    }
                                }
                            )
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

private struct MenuItemRow: View {
    let item: MenuItem
    let quantity: Int
    let format: (Double) -> String
    let palette: AppPalette
    let onAdd: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text(item.emoji)
                .font(.system(size: 36))
                .frame(width: 56, height: 56)
                .background(palette.secondarySurface)
                .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.textPrimary)
                Text(item.description)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(palette.textMuted)
                    .lineLimit(1)
                Text(format(item.price))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.accentStart)
                    .padding(.top, 2)
            }

            Spacer()

            if quantity > 0 {
                HStack(spacing: 10) {
                    Button(action: onRemove) {
                        Image(systemName: "minus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(palette.accentStart)
                            .frame(width: 28, height: 28)
                            .background(palette.secondarySurface)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(palette.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    Text("\(quantity)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(palette.textPrimary)
                        .frame(minWidth: 18)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: quantity)

                    Button(action: onAdd) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
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
                .transition(.scale.combined(with: .opacity))
            } else {
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(
                            LinearGradient(
                                colors: [palette.accentStart, palette.accentEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: palette.accentStart.opacity(0.4), radius: 8, y: 3)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(14)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    quantity > 0
                        ? palette.accentStart.opacity(0.4)
                        : palette.border,
                    lineWidth: 1
                )
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: quantity)
    }
}

private struct OrderSummaryBar: View {
    let total: String
    let quantity: Int
    let palette: AppPalette
    let onClear: () -> Void
    let onContinue: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onClear) {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(palette.textMuted)
                    .frame(width: 48, height: 52)
                    .background(palette.secondarySurface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(palette.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Button(action: onContinue) {
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(quantity) позиц.")
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundStyle(palette.accentSoft)
                        Text(total)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Text("Далее →")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 18)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: [palette.accentStart, palette.accentEnd],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: palette.accentStart.opacity(0.4), radius: 12, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
        .padding(.top, 12)
        .background(
            LinearGradient(
                colors: [palette.background.opacity(0), palette.background],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

#Preview {
    NavigationStack {
        MenuView()
    }
    .environment(AppRouter())
    .environment(AppSettings())
}
