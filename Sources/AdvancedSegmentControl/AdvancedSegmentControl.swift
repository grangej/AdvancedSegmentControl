import SwiftUI
import ViewExtractor

public struct AdvancedSegmentControl: View {

    private let inputViews: [AnyView]
    @Binding private var selectedIndex: Int
    @Binding private var secondarySelection: Int?
    
    @State private var highlightedIndex: Int?
    @State private var shouldHighlightSelectedIndex: Bool = false
    
    @State private var maxHeight: CGFloat = 0
    @State private var width: CGFloat = 0
    @Environment(\.segmentControlHighlightColor) var highlightColor: Color
    @Environment(\.segmentControlBackgroundColor) var backgroundColor: Color

    private var animationPoint: UnitPoint {
        
        if selectedIndex == 0 { return .center }
        if selectedIndex == inputViews.count - 1 { return .center }
        return UnitPoint.center
    }
    
    public init<Views>(selectedIndex: Binding<Int>, secondarySelection: Binding<Int?>?, @ViewBuilder content: TupleContent<Views>) {
        
        inputViews = ViewExtractor.getViews(from: content)
        self._selectedIndex = selectedIndex
        self._secondarySelection = secondarySelection ?? .constant(nil)
    }
    
    public init<Content: View>(selectedIndex: Binding<Int>, secondarySelection: Binding<Int?>?, @ViewBuilder content: NormalContent<Content>) {
        
        inputViews = ViewExtractor.getViews(from: content)
        self._selectedIndex = selectedIndex
        self._secondarySelection = secondarySelection ?? .constant(nil)
    }
    
    public init<Content: View & DynamicViewContentProvider>(selectedIndex: Binding<Int>, secondarySelection: Binding<Int?>?, content: ForEachContent<Content>) {
        
        inputViews = content().extractContent()
        self._selectedIndex = selectedIndex
        self._secondarySelection = secondarySelection ?? .constant(nil)

    }
    
    func indexSelected(index: Int) -> Bool { return selectedIndex == index }
    func shouldHighlight(index: Int) -> Bool { return highlightedIndex != nil && highlightedIndex == index }
    func showDivider(index: Int) -> Bool {
        
        if index == inputViews.count - 1 { return false }
        if indexSelected(index: index) { return false }
        if indexSelected(index: index + 1) { return false }
        return true
    }
    public var body: some View {
        ZStack(alignment: .leading) {
            HStack {
                Spacer()
                Color.clear
                Spacer()
            }
            RoundedRectangle(cornerRadius: 10).foregroundColor(backgroundColor).frame(maxHeight: maxHeight)
            RoundedRectangle(cornerRadius: 9).foregroundColor(highlightColor)
                .frame(width: self.width / 3, height: max(maxHeight - 2, 0))
                .alignmentGuide(HorizontalAlignment.leading) { d in
                
                var padding: CGFloat = 0
                switch selectedIndex {
                case inputViews.count - 1: padding = 1
                case 0: padding = -1
                default: padding = 0
                }
                                    
                return (-(self.width / 3) * CGFloat(selectedIndex) ) + padding
            }
            .scaleEffect(shouldHighlightSelectedIndex ? 0.93 : 1, anchor: animationPoint).animation(Animation.easeInOut, value: shouldHighlightSelectedIndex)
            .animation(.spring(), value: selectedIndex)
            HStack(alignment: .center, spacing: 0) {
                ForEach(inputViews.indices, id: \.self) { index in
                    HStack(spacing: 0) {
                        inputViews[index].padding(10)
                            .foregroundColor(indexSelected(index: index) ? backgroundColor : highlightColor ).animation(Animation.spring(), value: selectedIndex)
                            .opacity(shouldHighlight(index: index) ? 0.5 : 1.0).animation(Animation.linear, value: shouldHighlight(index: index))
                            .frame(maxWidth: .infinity, minHeight: maxHeight)
                        Divider().frame(maxHeight: max(maxHeight - 20, 0)).background(highlightColor).foregroundColor(highlightColor)
                            .opacity(showDivider(index: index) ? 1 : 0)
                    }
                    
                    .alignmentGuide(VerticalAlignment.center, computeValue: { d in
                        
                        DispatchQueue.main.async {
                            self.maxHeight = max(d.height, self.maxHeight)
                            self.width = max(( d.width * CGFloat(inputViews.count)), self.width)
                        }
                        
                        return d[VerticalAlignment.center]
                    }).simultaneousGesture(DragGesture(minimumDistance: 0).onChanged({ value in
                        
                        if indexSelected(index: index) {
                            shouldHighlightSelectedIndex = true
                        }
                        
                        highlightedIndex = index

                    }).onEnded({ value in
                        
                        shouldHighlightSelectedIndex = false
                        highlightedIndex = nil

                    })).simultaneousGesture(LongPressGesture(minimumDuration: 0.7).onEnded { value in
                        shouldHighlightSelectedIndex = false
                        highlightedIndex = nil
                        self.secondarySelection = index
                    }).simultaneousGesture(TapGesture(count: 1).onEnded({ _ in
                        self.selectedIndex = index
                    }))
                }
            }
        }

    }
}

struct MaximumHeightPreferenceKey: PreferenceKey
{
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat)
    {
        value = max(value, nextValue())
    }
}

struct AdvancedSegmentControl_Previews: PreviewProvider {
    
    static var previews: some View {
        
        AdvancedSegmentControl_PreviewView().padding(20).background(Color.accentColor).previewLayout(.sizeThatFits).preferredColorScheme(.dark)
    }
}

struct AdvancedSegmentControl_PreviewView: View {
    
    @State var selectedIndex: Int = 0
    
    var body: some View {
        VStack {
            Spacer()
            AdvancedSegmentControl(selectedIndex: $selectedIndex, secondarySelection: nil) {
                HStack {
                    Image(systemName: "square.and.arrow.down.on.square.fill")
                    Text("San Francisco")
                }
                Text("Test2")
                Text("Test3").bold()
            }.segmentControlHighlightColor(.orange).segmentControlBackgroundColor(.black)
        }.navigationTitle("test")

    }
}

extension String: Identifiable {
    public var id: String { return self }
}


struct AdvancedSegmentControlBackgroundColorKey: EnvironmentKey {
    static var defaultValue: Color = .secondary
}

struct AdvancedSegmentControlHighlightColorKey: EnvironmentKey {
    static var defaultValue: Color = .accentColor
}

extension EnvironmentValues {
   var segmentControlHighlightColor: Color {
       get { self[AdvancedSegmentControlHighlightColorKey.self] }
       set { self[AdvancedSegmentControlHighlightColorKey.self] = newValue }
   }
    
    var segmentControlBackgroundColor: Color {
        get { self[AdvancedSegmentControlBackgroundColorKey.self] }
        set { self[AdvancedSegmentControlBackgroundColorKey.self] = newValue }
    }
}

struct AdvancedSegmentControlBackgroundColorModifier: ViewModifier {
    
    var backgroundColor: Color
    
    func body(content: Content) -> some View {
        content.environment(\.segmentControlBackgroundColor, backgroundColor)
    }
}

struct AdvancedSegmentControlHighlightColorModifier: ViewModifier {
    
    var highlightColor: Color
    
    func body(content: Content) -> some View {
        content.environment(\.segmentControlHighlightColor, highlightColor)
    }
}

extension View {
    public func segmentControlHighlightColor(_ color: Color) -> some View {
        self.modifier(AdvancedSegmentControlHighlightColorModifier(highlightColor: color))
    }
    
    public func segmentControlBackgroundColor(_ color: Color) -> some View {
        self.modifier(AdvancedSegmentControlBackgroundColorModifier(backgroundColor: color))
    }
}
