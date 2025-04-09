import SwiftUI

struct PremiumView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                // Background color matching the app
                Color(red: 0.86, green: 0.75, blue: 0.6)
                    .ignoresSafeArea()
                    .overlay(
                        Image(systemName: "circle.grid.cross.fill")
                            .foregroundColor(.brown.opacity(0.1))
                            .font(.system(size: 20))
                    )

                ScrollView {
                    VStack(spacing: 30) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 60))
                            .foregroundColor(.brown)
                            .padding(.top, 40)

                        Text("Unlock Word Locker Premium")
                            .font(.custom("Marker Felt", size: 24))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)

                        Text("Gain unlimited access to store all the words and phrases you want!")
                            .font(.custom("Marker Felt", size: 16))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        // Subscription Options
                        VStack(spacing: 20) {
                            SubscriptionOptionView(
                                title: "Monthly",
                                price: "$1",
                                duration: "/ month",
                                color: Color.blue.opacity(0.7)
                            )
                            SubscriptionOptionView(
                                title: "Annual",
                                price: "$10",
                                duration: "/ year",
                                color: Color.green.opacity(0.7)
                            )
                            SubscriptionOptionView(
                                title: "Lifetime",
                                price: "$15",
                                duration: "one-time",
                                color: Color.purple.opacity(0.7)
                            )
                        }
                        .padding(.horizontal)

                        Text("Payment processing will be handled through the App Store.")
                            .font(.custom("Marker Felt", size: 12))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.top, 10)

                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Premium Options")
                        .font(.custom("Marker Felt", size: 20))
                        .foregroundColor(.black)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.custom("Marker Felt", size: 16))
                    .foregroundColor(.black)
                }
            }
        }
        .accentColor(.black) // Consistent accent color
    }
}

struct SubscriptionOptionView: View {
    let title: String
    let price: String
    let duration: String
    let color: Color

    var body: some View {
        Button(action: {
            // TODO: Implement purchase logic here (e.g., using StoreKit)
            print("Selected \(title) option")
        }) {
            HStack {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.custom("Marker Felt", size: 20))
                    Text("\(price) \(duration)")
                        .font(.custom("Marker Felt", size: 16))
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(color)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 2)
                    )
            )
            .foregroundColor(.white)
        }
    }
}

#Preview {
    PremiumView()
}
