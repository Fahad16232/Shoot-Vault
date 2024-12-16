import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false

    var body: some View {
        if isActive {
            ContentView() // Navigate to main content
        } else {
            VStack {
                Image("icon1") // Replace with your app icon name
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150) // Adjust as needed
                Text("Shoot Vault")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white) // Splash screen background color
            .ignoresSafeArea()
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // Splash screen duration
                    withAnimation {
                        isActive = true
                    }
                }
            }
        }
    }
}
