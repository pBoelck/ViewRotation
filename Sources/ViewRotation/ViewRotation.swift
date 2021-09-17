import SwiftUI

struct PagingScrollView: View {
	// MARK: - Private variable
	
	/// index of current page 0..N-1
	@Binding private var selectedIndex: Int
	
	/// current offset of all items
	@State private var currentScrollOffset = CGFloat.zero
	
	/// drag offset during drag gesture
	@State private var dragOffset = CGFloat.zero
	
	/// offset to scroll on the first item
	@State private var leadingOffset: CGFloat
	
	/// since the hstack is centered by default this offset actualy moves it entirely to the left
	@State private var stackOffset: CGFloat // to fix center alignment
	
	/// width of item / tile
	@State private var tileWidth: CGFloat
	
	private var views: [AnyView]
	
	/// total width of conatiner
	private let contentWidth: CGFloat
	
	/// number of items; I did not come with the soluion of extracting the right count in initializer
	private let itemsCount: Int
	
	/// padding between items
	private let tilePadding: CGFloat
	
	private let viewPuffer: Int
	
	// MARK: - Initializer
	
	init<A: View>(selectedIndex:Binding<Int>, views: [A], pageWidth: CGFloat, tileWidth: CGFloat, tilePadding: CGFloat, activateCarousel: Bool = false) {
		viewPuffer = activateCarousel ? 2 : 0
		
		self._selectedIndex = selectedIndex
		
		if activateCarousel {
			self.views = [AnyView]()
			for index in (0 ..< viewPuffer).reversed() {
				self.views.append(AnyView(views[views.count - 1 - index]))
			}
			
			for view in views {
				self.views.append(AnyView(view))
			}
			
			for index in 0 ..< viewPuffer {
				self.views.append(AnyView(views[index]))
			}
		}
		else {
			self.views = views.map{ AnyView($0) }
		}
		
		itemsCount = self.views.count
		
		self.tileWidth = tileWidth
		self.tilePadding = tilePadding
		
		contentWidth = (tileWidth + tilePadding) * CGFloat(itemsCount)
		
		leadingOffset = (pageWidth - tileWidth - tilePadding * 2) / 2 + tilePadding
		stackOffset = (contentWidth - pageWidth - tilePadding) / 2
	}
	
	// MARK: - Internal View
	
	var body: some View {
		VStack(spacing: 10) {
			HStack(alignment: .center, spacing: tilePadding) {
				ForEach(0 ..< itemsCount) {  index in
					views[index]
						.offset(x: currentScrollOffset, y: 0)
						.frame(width: tileWidth)
				}
			}
			.onAppear {
				selectedIndex += viewPuffer
				currentScrollOffset = offsetForIndex(selectedIndex)
			}
			.offset(x: stackOffset, y: 0)
			.background(Color.black.opacity(0.0001)) // this allows gesture recognizing even when background is transparent
			.frame(width: contentWidth)
			// Reespond to swipe gestur
			.simultaneousGesture(DragGesture(minimumDistance: 1, coordinateSpace: .local)
									.onChanged {
										dragOffset = $0.translation.width
										currentScrollOffset = computeCurrentScrollOffset()
									}
									.onEnded {
										let velocityDiff = ($0.predictedEndTranslation.width - dragOffset) * 0.66
										let newPageIndex = indexForOffset(currentScrollOffset + velocityDiff)
										dragOffset = 0
										selectedIndex = newPageIndex
									}
			)
			.valueChanged(value: selectedIndex) { index in
				if viewPuffer > 0 {
					if selectedIndex < viewPuffer {
						setIndex(itemsCount - viewPuffer - 1)
					} else if selectedIndex >= itemsCount - viewPuffer {
						setIndex(viewPuffer)
					} else {
						withAnimation(.linear)  { setIndex(selectedIndex) }
					}
				} else {
					withAnimation(.linear) { setIndex(selectedIndex) }
				}
			}
			
			// Added Indicator
			
			HStack {
				ForEach(viewPuffer ..< itemsCount - viewPuffer) { index in
					Button(action: { setIndex(index) },
						   label: {
							Rectangle()
								.frame(width: 10.0, height: 10.0)
								.cornerRadius(10.0)
								.foregroundColor(selectedIndex == index ? Color.red : Color.gray)
						   })
				}
			}
		}
	}
	
	private func offsetForIndex(_ index: Int) -> CGFloat {
		leadingOffset - CGFloat(index) * (tileWidth + tilePadding)
	}
	
	private func indexForOffset(_ offset: CGFloat) -> Int {
		guard itemsCount > 0 else { return 0 }
		
		let offset = logicalScrollOffset(trueOffset: offset)
		let floatIndex = offset / (tileWidth + tilePadding)
		return min(max(Int(round(floatIndex)), 0), itemsCount - 1)
	}
	
	private func computeCurrentScrollOffset() -> CGFloat {
		offsetForIndex(selectedIndex) + dragOffset
	}
	
	private func logicalScrollOffset(trueOffset: CGFloat) -> CGFloat {
		(trueOffset - leadingOffset) *  -1.0
	}
	
	private func setIndex(_ index: Int) {
		selectedIndex = index
		currentScrollOffset = computeCurrentScrollOffset()
	}
}
