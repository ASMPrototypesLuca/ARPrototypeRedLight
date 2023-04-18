import SwiftUI

struct ContentView: View {
    @StateObject private var recognizedObject = RecognizedObject()
    
    var body: some View {
        ZStack {
            DetectorViewControllerRepresentable(recognizedObject: recognizedObject)
            
            if recognizedObject.recognized {
                VStack {
                    Spacer()
                    Text("Recognized: \(recognizedObject.objectName) \nConfidence: \(String(format: "%.0f", recognizedObject.confidence * 100))%")
                        .frame(maxWidth: .infinity, minHeight: 100)
                        .padding()
                        .multilineTextAlignment(.center)
                        .background(Color.white)
                        .opacity(0.8)
                        .foregroundColor(.black)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .transition(.move(edge: .bottom))
                        .animation(.spring())
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

