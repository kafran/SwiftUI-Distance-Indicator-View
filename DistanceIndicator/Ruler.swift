//
//  DistanceIndicator.swift
//  DistanceIndicator
//
//  Created by Kolmar Kafran on 13/05/23.

import SwiftUI

struct DistanceIndicator: View {
    @Binding var distanceState: DistanceState
    private let rulerMarks = 13 // This can be exposed to create different ruler sizes.

    var body: some View {
        HStack(spacing: 0) {
            Text("Too Close")
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundColor(.white)
            Ruler(marksCount: rulerMarks, distanceState: $distanceState)
            Text("Too Far")
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundColor(.white)
        }
    }
}

struct Ruler: View {
    let marksCount: Int // The number of ticks/marks in the ruler
    @Binding var distanceState: DistanceState

    @State private var spacerSize: CGSize = .zero
    @State private var rulerSize: CGSize = .zero // The size occupied by the ruler
    @State private var highlightOffset: Double = .zero
    @State private var arrowOffset: Double = .zero

    var body: some View {
        ZStack {
            LowerLayerRulerMarks(
                marksCount: marksCount,
                spacerSize: $spacerSize,
                rulerSize: $rulerSize,
                highlightOffset: $highlightOffset
            )
            UpperLayerRulerMarks(
                marksCount: marksCount,
                spacerSize: spacerSize,
                highlightOffset: highlightOffset
            )
            Image(systemName: "triangle.fill")
                .foregroundColor(.brown)
                .offset(x: arrowOffset, y: 26)
                .animation(.easeInOut(duration: Ruler.Constants.animationDuration), value: arrowOffset)
                .onChange(of: distanceState) { newState in
                    switch newState {
                    case .ok,
                         .unknown:
                        arrowOffset = 0
                    case .tooClose:
                        arrowOffset = (-rulerSize.width / 2) + (spacerSize.width + Ruler.Constants.markWidth / 2)
                    case .tooFar:
                        arrowOffset = (rulerSize.width / 2) - (spacerSize.width + Ruler.Constants.markWidth / 2)
                    }
                }
        }
        .onChange(of: distanceState) { newState in
            let highlight = (spacerSize.width + 3) * 5
            let offsetMax = rulerSize.width - highlight
            switch newState {
            case .ok,
                 .unknown:
                highlightOffset = 0
            case .tooClose:
                highlightOffset = -offsetMax / 2
            case .tooFar:
                highlightOffset = offsetMax / 2
            }
        }
    }
}

struct LowerLayerRulerMarks: View {
    // This layer is also responsible for passing upward important screen sizes
    // Reference: https://fivestars.blog/articles/swiftui-share-layout-information/

    struct SizePreferenceKey: PreferenceKey {
        static var defaultValue: CGSize = .zero
        static func reduce(value _: inout CGSize, nextValue _: () -> CGSize) {}
    }

    let marksCount: Int
    @Binding var spacerSize: CGSize
    @Binding var rulerSize: CGSize
    @Binding var highlightOffset: Double

    var body: some View {
        HStack(spacing: 0) {
            let rulerRange = 0..<marksCount
            ForEach(rulerRange, id: \.self) { idx in
                Spacer()
                    .background {
                        GeometryReader { reader in
                            Color.clear
                                .preference(key: SizePreferenceKey.self, value: reader.size)
                        }
                    }
                    .onPreferenceChange(SizePreferenceKey.self) { newSize in
                        self.spacerSize = newSize
                    }
                RoundedRectangle(cornerRadius: 3)
                    .fill(.white)
                    .frame(width: Ruler.Constants.markWidth, height: Ruler.Constants.markHeight)
                if idx == rulerRange.upperBound - 1 {
                    Spacer()
                }
            }
        }
        .background(alignment: .center) {
            GeometryReader { reader in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: reader.size)
            }
        }
        .onPreferenceChange(SizePreferenceKey.self) { newSize in
            self.rulerSize = newSize
        }
        .reverseMask {
            Color.white
                .frame(width: (spacerSize.width + Ruler.Constants.markWidth) * Ruler.Constants.markHighlightCount)
                .opacity(Ruler.Constants.maskOpacity)
                .offset(x: highlightOffset)
                .animation(.easeInOut(duration: Ruler.Constants.animationDuration), value: highlightOffset)
        }
    }
}

struct UpperLayerRulerMarks: View {
    let marksCount: Int
    let spacerSize: CGSize
    let highlightOffset: Double
    var body: some View {
        HStack(spacing: 0) {
            let rulerRange = 0..<marksCount
            ForEach(rulerRange, id: \.self) { idx in
                Spacer()
                RoundedRectangle(cornerRadius: 3)
                    .foregroundColor(.brown)
                    .frame(width: Ruler.Constants.markWidth, height: Ruler.Constants.markHighlightHeight)
                if idx == rulerRange.upperBound - 1 {
                    Spacer()
                }
            }
        }
        .mask {
            Color.white
                .frame(width: (spacerSize.width + Ruler.Constants.markWidth) * Ruler.Constants.markHighlightCount)
                .opacity(Ruler.Constants.maskOpacity)
                .offset(x: highlightOffset)
                .animation(.easeInOut(duration: Ruler.Constants.animationDuration), value: highlightOffset)
        }
    }
}

extension Ruler {
    enum Constants {
        static let maskOpacity: Double = 0.99 // I don't know why opacity 1.0 is not working.
        static let animationDuration: Double = 0.95
        static let markWidth: CGFloat = 3
        static let markHeight: CGFloat = 20
        static let markHighlightHeight: CGFloat = 26
        static let markHighlightCount: CGFloat = 5
    }
}

/// Reference: https://www.fivestars.blog/articles/reverse-masks-how-to/
public extension View {
    @inlinable
    func reverseMask<Mask: View>(
        alignment: Alignment = .center,
        @ViewBuilder _ mask: () -> Mask
    ) -> some View {
        self.mask {
            Rectangle()
                .overlay(alignment: alignment) {
                    mask()
                        .blendMode(.destinationOut)
                }
        }
    }
}

enum DistanceState: CaseIterable {
    case ok
    case tooFar
    case tooClose
    case unknown
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        DistanceIndicator(distanceState: .constant(.unknown))
            .padding(.vertical, 30)
            .padding(.horizontal, 10)
            .background(Color.black)
            .opacity(0.6)
            .previewLayout(.fixed(width: 400, height: 100))
    }
}
