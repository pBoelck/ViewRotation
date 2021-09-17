import SwiftUI
import Combine

extension View {
	/// A backwards compatible wrapper for iOS 14 `onChange`
	@ViewBuilder func valueChanged<T: Equatable>(value: T, onChange: @escaping (T) -> Void) -> some View {
		if #available(iOS 14.0, *) {
			self.onChange(of: value, perform: onChange)
		} else {
			self.onReceive(Just(value)) { onChange($0) }
		}
	}

	@ViewBuilder
   func `if`<Content: View>(_ conditional: Bool, content: (Self) -> Content) -> some View {
	   if conditional {
		   content(self)
	   } else {
		   self.edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
		   self
	   }
   }
}
