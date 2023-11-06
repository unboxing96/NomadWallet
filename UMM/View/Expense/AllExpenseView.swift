//
//  AllExpenseView.swift
//  UMM
//
//  Created by 김태현 on 10/11/23.
//

import SwiftUI

struct AllExpenseView: View {
    @ObservedObject var expenseViewModel: ExpenseViewModel
    @State private var selectedPaymentMethod: Int = -2
    @Binding var selectedTab: Int
    let namespace: Namespace.ID
    let exchangeRatehandler = ExchangeRateHandler.shared
    let currencyInfoModel = CurrencyInfoModel.shared.currencyResult
    @EnvironmentObject var mainVM: MainViewModel
    
    init(expenseViewModel: ExpenseViewModel, selectedTab: Binding<Int>, namespace: Namespace.ID) {
        self.expenseViewModel = expenseViewModel
        self._selectedTab = selectedTab
        self.namespace = namespace
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if expenseViewModel.filteredAllExpenses.count == 0 {
                noDataView
            } else {
                countryPicker
                allExpenseSummaryTotal
                allExpenseSummaryByCurrency
                allExpenseBarGraph
                Divider()
                ScrollView(showsIndicators: false) {
                    drawExpensesByCategory
                }
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            print("AllExpenseView | selctedTravel: \(String(describing: mainVM.selectedTravel?.name))")
            print("AllExpenseView | selctedCountry: \(expenseViewModel.selectedCountry)")
            expenseViewModel.fetchExpense()
            expenseViewModel.fetchTravel()
            expenseViewModel.fetchCountryForAllExpense(country: expenseViewModel.selectedCountry)
        }
    }
    
    // MARK: - 뷰
    
    var allExpenseSummaryTotal: some View {
        let totalSum = expenseViewModel.filteredAllExpensesByCountry.reduce(0) { total, expense in
            let isoCode = currencyInfoModel[Int(expense.currency)]?.isoCodeNm ?? "Unknown"
            let rate = exchangeRatehandler.getExchangeRateFromKRW(currencyCode: isoCode)
            let amount = (expense.payAmount != -1) ? expense.payAmount : 0
            return total + amount * (rate ?? -100)
        }
        return NavigationLink {
            AllExpenseDetailView(
                selectedTravel: mainVM.selectedTravel,
                selectedCategory: -2,
                selectedCountry: expenseViewModel.selectedCountry,
                selectedPaymentMethod: -2,
                sumPaymentMethod: totalSum
            )
        } label: {
            HStack(spacing: 0) {
                Text("\(expenseViewModel.formatSum(from: totalSum, to: 0))원")
                    .font(.display4)
                    .foregroundStyle(.black)
                Image(systemName: "chevron.right")
                    .font(.system(size: 24))
                    .foregroundStyle(.gray200)
                    .padding(.leading, 16)
            }
            .padding(.top, 32)
        }
    }
    
    var allExpenseSummaryByCurrency: some View {
        let currencies = Array(Set(expenseViewModel.filteredAllExpensesByCountry.map { $0.currency })).sorted { $0 < $1 }
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(currencies.indices, id: \.self) { idx in
                    let currency = currencies[idx]
                    let sum = expenseViewModel.filteredAllExpenses.filter({ $0.currency == currency }).reduce(0) { total, expense in
                        let amount = (expense.payAmount != -1) ? expense.payAmount : 0
                        return total + amount
                    }
                    
                    Text("\(Currency.getSymbol(of: Int(currency)))\(expenseViewModel.formatSum(from: sum, to: 2))")
                        .font(.caption2)
                        .foregroundStyle(.gray300)
                    if idx != currencies.count - 1 {
                        Circle()
                            .frame(width: 3, height: 3)
                            .foregroundStyle(.gray300)
                            .padding(.horizontal, 3)
                    }
                }
            }
            .padding(.top, 10)
        }
    }
    
    var allExpenseBarGraph: some View {
        let indexedSumArrayInPayAmountOrder = expenseViewModel.getPayAmountOrderedIndicesOfCategory(categoryArray: expenseViewModel.categoryArray, expenseArray: expenseViewModel.filteredAllExpensesByCountry)
        return BarGraph(data: indexedSumArrayInPayAmountOrder)
            .padding(.top, 22)
            .padding(.bottom, 20)
    }
    
    private var countryPicker: some View {
        let allExpensesInSelectedTravel = expenseViewModel.filteredAllExpenses
        let countries = [-2] + Array(Set(allExpensesInSelectedTravel.compactMap { $0.country })).sorted { $0 < $1 } // 중복 제거
        
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(countries, id: \.self) { country in
                    Button(action: {
                        DispatchQueue.main.async {
                            expenseViewModel.selectedCountry = Int64(country)
                            expenseViewModel.fetchCountryForAllExpense(country: expenseViewModel.selectedCountry)
                        }
                    }, label: {
                        Text("\(Country.titleFor(rawValue: Int(country)))")
                            .padding(.leading, 4)
                            .font(.caption2)
                            .frame(width: 61) // 폰트 개수가 다르고, 크기는 고정되어 있어서 상수 값을 주었습니다.
                            .padding(.vertical, 7)
                            .background(expenseViewModel.selectedCountry == country ? Color.black: Color.gray100)
                            .foregroundColor(expenseViewModel.selectedCountry == country ? Color.white: Color.gray300)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    })
                }
            }
            .padding(.top, 16)
        }
    }
    
    private func getExpenseArray(for country: Int64) -> [Expense] {
        if country == expenseViewModel.selectedCountry {
            return expenseViewModel.filteredAllExpensesByCountry
        } else {
            return expenseViewModel.filteredAllExpenses
        }
    }
    
    private var drawExpensesByCategory: some View {
        drawExpenseContent(for: expenseViewModel.selectedCountry, with: getExpenseArray(for: expenseViewModel.selectedCountry))
    }
    
    // 1. 나라별
    // 1-1. 항목별
    private func drawExpenseContent(for country: Int64, with expenses: [Expense]) -> some View {
        let indexedSumArrayInPayAmountOrder = expenseViewModel.getPayAmountOrderedIndicesOfCategory(categoryArray: expenseViewModel.categoryArray, expenseArray: expenses)
        
        return VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(0..<expenseViewModel.categoryArray.count, id: \.self) { index in
                    let categoryName = indexedSumArrayInPayAmountOrder[index].0
                    let categorySum = indexedSumArrayInPayAmountOrder[index].1
                    let totalSum = indexedSumArrayInPayAmountOrder.map { $0.1 }.reduce(0, +)
                    
                    NavigationLink {
                        AllExpenseDetailView(
                            selectedTravel: mainVM.selectedTravel,
                            selectedCategory: indexedSumArrayInPayAmountOrder[index].0,
                            selectedCountry: expenseViewModel.selectedCountry,
                            selectedPaymentMethod: -2,
                            sumPaymentMethod: totalSum
                        )
                    } label: {
                        HStack(alignment: .center, spacing: 0) {
                            Image(ExpenseInfoCategory(rawValue: Int(categoryName))?.modalImageString ?? "nil")
                                .font(.system(size: 36))
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text("\(ExpenseInfoCategory.descriptionFor(rawValue: Int(categoryName)))")
                                    .font(.subhead2_1)
                                    .foregroundStyle(.black)
                                HStack(alignment: .center, spacing: 0) {
                                    Text("\(expenseViewModel.formatSum(from: categorySum <= -1 ? 0 : categorySum / totalSum * 100, to: 1))%")
                                        .font(.caption2)
                                        .foregroundStyle(.gray300)
                                }
                                .padding(.top, 4)
                            }
                            .padding(.leading, 10)
                            
                            Spacer()
                            
                            HStack(alignment: .center, spacing: 0) {
                                Text("\(expenseViewModel.formatSum(from: categorySum <= -1 ? 0 : categorySum, to: 0))원")
                                    .font(.subhead3_1)
                                    .foregroundStyle(.black)
                                    .padding(.leading, 3)
                                    .padding(.trailing, 12)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.gray300)
                                
                            }
                        }
                    }
                    .padding(.top, 20)
                }
                .padding(.bottom, 24)
            }
        }
    }
    
    private var noDataView: some View {
        VStack(spacing: 0) {
            Text("아직 지출 기록이 없어요")
                .font(.subhead3_2)
                .foregroundStyle(.gray300)
                .padding(.top, 130)
            Spacer()
        }
    }
}

struct CurrencyForChart: Identifiable, Hashable {
    let id = UUID()
    let currency: Int64
    let sum: Double
    
    init(currency: Int64, sum: Double) {
        self.currency = currency
        self.sum = sum
    }
}

struct ExpenseForChart: Identifiable, Hashable {
    let id = UUID()
    let name: Int64
    let value: Double
    
    init(_ tuple: (Int64, Double)) {
        self.name = tuple.0
        self.value = tuple.1
    }
}

struct BarGraph: View {
    var data: [(Int64, Double)]
    private var totalSum: Double {
        return data.map { $0.1 }.reduce(0, +)
    }
    private var validDataCount: Int {
        return data.filter { $0.1 != 0 }.count
    }
    private var deviceWidthWithoutSpacing: Double {
        return Double(UIScreen.main.bounds.width) - 40 - Double(validDataCount - 1) * 2  // 요소 사이의 공간을 고려
    }
    private var lessthanZeroDataCount: Double {
        return Double(data.filter { $0.1 > 0 && $0.1 / totalSum * deviceWidthWithoutSpacing < 5 }.count)
    }
    
    var body: some View {
        let minElementWidth = 5.0
        let totalMinWidth = minElementWidth * Double(validDataCount)
        
        HStack(spacing: 2) {
            ForEach(0..<validDataCount, id: \.self) { index in
                let item = data[index]
                let elementWidth = (item.1 / totalSum) * max(0, (deviceWidthWithoutSpacing - totalMinWidth)) + minElementWidth
                
                BarElement(
                    color: ExpenseInfoCategory(rawValue: Int(item.0))?.color ?? Color.gray,
                    width: (item.1 != 0 ? elementWidth : 0),
                    isFirstElement: index == 0,
                    isLastElement: index == validDataCount - 1
                )
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct BarElement: View {
    let color: Color
    let width: CGFloat
    let isFirstElement: Bool
    let isLastElement: Bool
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: max(0, width), height: 24)
            .modifier(RoundedModifier(isFirstElement: isFirstElement, isLastElement: isLastElement))
    }
}

struct RoundedModifier: ViewModifier {
    let isFirstElement: Bool
    let isLastElement: Bool
    
    func body(content: Content) -> some View {
        if isFirstElement && isLastElement {
            return AnyView(content.cornerRadius(6))
        } else if isFirstElement {
            return AnyView(content.cornerRadius(6, corners: [.topLeft, .bottomLeft]))
        } else if isLastElement {
            return AnyView(content.cornerRadius(6, corners: [.topRight, .bottomRight]))
        } else {
            return AnyView(content)
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

//  #Preview {
//      AllExpenseView(selectedTab: .constant(1), namespace: Namespace.ID)
//  }
