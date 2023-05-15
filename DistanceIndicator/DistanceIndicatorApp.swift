//
//  DistanceIndicatorApp.swift
//  DistanceIndicator
//
//  Created by Kolmar Kafran on 13/05/23.
//

import SwiftUI

@main
struct DistanceIndicatorApp: App {
    private let timer = Timer.publish(every: 1.5, on: .main, in: .default).autoconnect()
    @State private var distance: DistanceState = .unknown
    var body: some Scene {
        WindowGroup {
            DistanceIndicator(distanceState: $distance)
                .padding(.vertical, 30)
                .padding(.horizontal, 10)
                .background(Color.black)
                .opacity(0.6)
                .onReceive(timer) { _ in
                    if let distance = DistanceState.allCases.randomElement(), distance != .unknown {
                        self.distance = distance
                    }
                }
        }
    }
}
