//
//  RootView.swift
//  MySelf
//
//  Created by Yumin Chu on 3/14/24.
//

import SwiftUI

import ComposableArchitecture

@Reducer
struct RootCore {
  struct State: Equatable {
    let id = UUID()
    let numberOfPages = 3
    let cardWidth: CGFloat = 260
    let cardPadding: CGFloat = 20
    @BindingState var currentPage = 0
    @BindingState var currentScrollOffset: CGFloat = 0
    @BindingState var dragOffset: CGFloat = 0
    var pagingView = PagingScrollCore.State()
    var initialOffset: CGFloat = 0
  }
  
  enum Action: BindableAction, Equatable {
    case binding(BindingAction<State>)
    case pagingView(PagingScrollCore.Action)
    case setupOffset(CGFloat)
  }
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    Scope(state: \.pagingView, action: \.pagingView) {
      PagingScrollCore()
    }
    Reduce { state, action in
      switch action {
      case .binding:
        break
        
      case let .setupOffset(cardWidth):
        state.initialOffset = ((
          cardWidth - state.cardWidth - 2 * state.cardPadding
        ) / 2) + state.cardPadding
        state.currentScrollOffset = countOffset(state: &state)
      }
      
      return .none
    }
  }
  
  private func setupOffset() {
    
  }
  
  private func countOffset(state: inout State) -> CGFloat {
    CGFloat(state.currentPage) * (state.cardWidth + state.cardPadding)
  }
}

struct RootView: View {
  private let store: StoreOf<RootCore>
  @ObservedObject private var viewStore: ViewStoreOf<RootCore>
  
  init(store: StoreOf<RootCore>) {
    self.store = store
    self.viewStore = .init(store, observe: { $0 })
  }
  
  var body: some View {
    ZStack {
      VStack(alignment: .center, spacing: 25) {
        pageControl
        pagingView
      }
    }
  }
}

#Preview {
  RootView(store: .init(initialState: RootCore.State()) {
    RootCore()
  })
}

extension RootView {
  private var pageControl: some View {
    HStack(spacing: 0) {
      RepresentedPageControl(
        numberOfPage: viewStore.numberOfPages,
        currentPage: viewStore.$currentPage
      )
      .foregroundColor(.blue)
      .aspectRatio(3 / 2, contentMode: .fit)
      .frame(width: 165, height: 42)
      Spacer()
    }
  }
  
  private var pagingView: some View {
    GeometryReader { geometry in
      HStack(alignment: .center, spacing: viewStore.cardPadding) {
        cardsView
      }
      .onAppear {
        store.send(.setupOffset(geometry.size.width))
      }
    }
  }
  
  private var cardsView: some View {
    ForEach(Card.dummy) { card in
      GeometryReader { geometry in
        CardItem(cardInfo: card)
          .rotation3DEffect(
            Angle(degrees: (
              Double(geometry.frame(in: .global).minX) - 20
            ) - 15),
            axis: (x: 0, y: 90, z: 0)
          )
          .scaleEffect(
            viewStore.currentPage == Card.dummy.firstIndex(of: card) ?? 0 ? 1.05 : 1
          )
      }
      .frame(width: viewStore.cardWidth, height: 600)
    }
  }
}
