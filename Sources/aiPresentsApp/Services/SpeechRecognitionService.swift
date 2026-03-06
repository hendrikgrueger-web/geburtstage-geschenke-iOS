import Foundation
import Speech
import AVFoundation

/// On-Device Spracheingabe via SFSpeechRecognizer.
/// Bevorzugt On-Device-Erkennung (kein Datenabfluss).
@MainActor
@Observable
final class SpeechRecognitionService {
    var isAvailable = false
    var isTranscribing = false
    var transcript = ""

    private var audioEngine: AVAudioEngine?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

    /// Fordert Berechtigungen an und startet die Live-Transkription.
    func startTranscribing(onTranscript: @escaping @Sendable (String) -> Void) async throws {
        let authStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard authStatus == .authorized else {
            throw SpeechError.notAuthorized
        }

        let locale = Locale.current
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            throw SpeechError.notAvailable
        }

        // On-Device bevorzugen
        let request = SFSpeechAudioBufferRecognitionRequest()
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        request.shouldReportPartialResults = true

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        engine.prepare()
        try engine.start()

        self.audioEngine = engine
        self.recognitionRequest = request
        self.isTranscribing = true

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            if let result {
                let text = result.bestTranscription.formattedString
                Task { @MainActor in
                    self?.transcript = text
                    onTranscript(text)
                }
            }

            if error != nil || (result?.isFinal ?? false) {
                Task { @MainActor in
                    self?.stopTranscribing()
                }
            }
        }
    }

    func stopTranscribing() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        isTranscribing = false

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Fehler

    enum SpeechError: LocalizedError {
        case notAuthorized
        case notAvailable

        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return String(localized: "Spracheingabe nicht erlaubt. Bitte aktiviere die Berechtigung in den Einstellungen.")
            case .notAvailable:
                return String(localized: "Spracheingabe ist auf diesem Gerät nicht verfügbar.")
            }
        }
    }
}
