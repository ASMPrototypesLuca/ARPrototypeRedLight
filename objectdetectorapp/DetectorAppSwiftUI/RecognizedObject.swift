import Combine

class RecognizedObject: ObservableObject {
    @Published var recognized: Bool = false
    @Published var objectName: String = ""
    @Published var confidence: Double = 0.0
}

