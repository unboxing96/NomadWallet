//
//  ExpenseView.swift
//  UMM
//
//  Created by 김태현 on 10/11/23.
//

import SwiftUI

struct ExpenseView: View {
    @State var selectedTab = 0
    @Namespace var namespace
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                TodayExpenseView(selectedTab: $selectedTab, namespace: namespace)
                    .tag(0)
                AllExpenseView(selectedTab: $selectedTab, namespace: namespace)
                    .tag(1)
            }
        }
    }
}

struct TabBarItem: View {
    @Binding var selectedTab: Int
    let namespace: Namespace.ID
    
    var title: String
    var tab: Int
    
    var body: some View {
        Button {
            selectedTab = tab
        } label: {
            VStack {
                Text(title)
                    .font(.subhead3_1)
                    .foregroundStyle(selectedTab == tab ? .black : .gray300)

                ZStack {
                    Divider()
                        .padding(.top, 12)
                        .frame(height: 2)
                    if selectedTab == tab {
                        Color.black
                            .frame(height: 2)
                            .matchedGeometryEffect(id: "underline", in: namespace.self)
                            .padding(.top, 11)
                            .padding(.horizontal)
                    } else {
                        Color.gray300
                            .frame(height: 2)
                            .padding(.top, 11)
                            .padding(.horizontal)
                    }
                }
            }
            .animation(.spring(), value: selectedTab)
        }
        .buttonStyle(.plain)
    }
}

enum TabbedItems: Int, CaseIterable {
    case todayExpense
    case allExpense
    
    var title: String {
        switch self {
        case .todayExpense:
            return "일별 지출"
        case .allExpense:
            return "전체 지출"
        }
    }
}

#Preview {
   ExpenseView()
}
