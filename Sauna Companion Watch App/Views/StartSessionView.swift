//
//  StartSessionView.swift
//  Sauna Companion Watch App
//

import SwiftUI

struct StartSessionView: View {
    @Bindable var store: SessionStore

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "timer")
                .font(.system(size: 32))
                .foregroundStyle(.orange)

            Text("RoundPulse")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                // The name has to survive a 40 mm case, where 17pt can run
                // past the edge. Scaling down beats clipping the app's own
                // name.
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Button {
                Task { await store.startSession() }
            } label: {
                Text("Start Round")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}
