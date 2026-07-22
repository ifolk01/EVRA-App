import Foundation
import ActivityKit
import AppIntents

// Esta struct precisa de estar aqui para que tanto a App quanto o Widget a vejam
public struct TrackingAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var currentDistance: Double
        public var currentDuration: TimeInterval
        public var co2Avoided: Double
        public var isPaused: Bool
        public var isFinishing: Bool
    }
    public var startTime: Date
}

// Os Intents também precisam de ser visíveis para ambos
@available(iOS 17.0, *)
public struct ToggleRideIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Pausar/Retomar"
    public init() {}
    public func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: Notification.Name("ToggleRideStatus"), object: nil)
        return .result()
    }
}

@available(iOS 17.0, *)
public struct FinishRideIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Finalizar Trajeto"
    public init() {}
    public func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: Notification.Name("FinishRideSignal"), object: nil)
        return .result()
    }
}
