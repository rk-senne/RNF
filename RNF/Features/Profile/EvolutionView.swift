import SwiftUI

struct EvolutionView: View {

    var statChanges: [String: Int]

    var body: some View {

        VStack(spacing: 20) {

            Text("EVOLUTION")
                .font(.title2)
                .fontWeight(.bold)

            Text("This Week")
                .font(.caption)
                .foregroundColor(.gray)

            VStack(spacing: 12) {

                ForEach(statChanges.keys.sorted(), id: \.self) { stat in

                    HStack {

                        Text(stat)
                            .font(.headline)

                        Spacer()

                        Text("+\(statChanges[stat] ?? 0)")
                            .foregroundColor(.green)
                            .fontWeight(.bold)

                    }

                }

            }
            .padding()

            Spacer()

        }
        .padding()

    }

}
