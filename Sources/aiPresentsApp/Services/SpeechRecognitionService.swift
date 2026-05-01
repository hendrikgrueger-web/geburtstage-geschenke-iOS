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
    private var timeoutTask: Task<Void, Never>?

    /// Maximale Aufnahmedauer in Sekunden.
    static let maxDuration: TimeInterval = 30

    /// Fordert Berechtigungen an und startet die Live-Transkription.
    func startTranscribing(onTranscript: @escaping @Sendable (String) -> Void) async throws {
        // Vorherige Session bereinigen, falls noch aktiv
        if isTranscribing {
            stopTranscribing()
        }

        let authStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard authStatus == .authorized else {
            throw SpeechError.notAuthorized
        }

        // Mikrofon-Berechtigung anfragen (separate Berechtigung!)
        let micAllowed = await AVAudioApplication.requestRecordPermission()
        guard micAllowed else {
            throw SpeechError.notAuthorized
        }

        // Direkt nach Permission-Grant kann AVAudioSession kurz noch nicht
        // initialisiert sein — kurze Pause verhindert 0-Channel-Format und
        // installTap-Crashes auf iOS 26 beim ersten Mic-Aktivieren.
        try? await Task.sleep(for: .milliseconds(150))

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
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            // Audio-Session konnte nicht aktiviert werden — sauber zurueck
            try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            throw SpeechError.notAvailable
        }

        let engine = AVAudioEngine()
        // prepare() VOR installTap — sonst kann inputNode bei Race-Conditions
        // mit einem Format ankommen, das installTap mit NSException sprengt.
        engine.prepare()

        let inputNode = engine.inputNode
        // inputFormat ist robuster als outputFormat direkt nach Permission-Grant.
        let recordingFormat = inputNode.inputFormat(forBus: 0)

        guard recordingFormat.channelCount > 0,
              recordingFormat.sampleRate > 0,
              recordingFormat.commonFormat != .otherFormat else {
            try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            throw SpeechError.notAvailable
        }

        do {
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                request.append(buffer)
            }
            try engine.start()
        } catch {
            inputNode.removeTap(onBus: 0)
            try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            throw SpeechError.notAvailable
        }

        self.audioEngine = engine
        self.recognitionRequest = request
        self.isTranscribing = true

        // 30-Sekunden Auto-Stop
        timeoutTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(SpeechRecognitionService.maxDuration))
            guard !Task.isCancelled else { return }
            self?.stopTranscribing()
        }

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
        guard isTranscribing else { return }

        timeoutTask?.cancel()
        timeoutTask = nil

        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        isTranscribing = false

        // Session deaktivieren UND Category zuruecksetzen, sonst kollidiert
        // unser .record/.measurement-State mit System-Diktat im Search-Bar
        // und anderen Audio-Sessions.
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
        try? session.setCategory(.ambient, mode: .default)
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
