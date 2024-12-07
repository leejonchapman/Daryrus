//
//  SleepTimerView.swift
//  Papyrus
//

import SwiftUI

struct SleepTimerView: View {
    @Binding var showSheet: Bool
    @Binding var sleepTimerDuration: TimeInterval
    let startSleepTimer: (TimeInterval) -> Void
    let resetSleepTimer: () -> Void

    // State variables for hours and minutes
    @State private var selectedHours: Int = 0
    @State private var selectedMinutes: Int = 0

    var body: some View {
        NavigationView {
            VStack {
                Text("Set Sleep Timer")
                    .font(.headline)
                    .padding(.top, 20)

                Spacer()

                HStack {
                    Picker("Hours", selection: $selectedHours) {
                        ForEach(0..<24) { hour in
                            Text("\(hour) h").tag(hour)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(maxWidth: .infinity)

                    Picker("Minutes", selection: $selectedMinutes) {
                        ForEach(0..<60) { minute in
                            Text("\(minute) m").tag(minute)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 200)

                Spacer()

                HStack {
                    Button(action: {
                        resetSleepTimer() // Reset the timer
                        showSheet = false // Close the sheet
                    }) {
                        Text("Reset")
                            .bold()
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button(action: {
                        let duration = TimeInterval((selectedHours * 3600) + (selectedMinutes * 60))
                        sleepTimerDuration = duration // Update the sleep timer duration
                        startSleepTimer(duration) // Start the timer
                        showSheet = false // Close the sheet
                    }) {
                        Text("Set Timer")
                            .bold()
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding([.leading, .trailing, .bottom], 20)
            }
            .navigationTitle("Sleep Timer")
            .navigationBarItems(trailing: Button("Cancel") {
                showSheet = false
            })
        }
    }
}
