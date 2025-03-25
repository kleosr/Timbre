import UIKit
import Speech
import SnapKit

class MainViewController: UIViewController {
    
    // MARK: - Properties
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // UI Components
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let recognizedTextView = UITextView()
    private let statusLabel = UILabel()
    private let startListeningButton = UIButton(type: .system)
    private let processedCommandTextView = UITextView()
    private let viewServicesButton = UIButton(type: .system)
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        requestSpeechAuthorization()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .white
        title = "VoiceVibe"
        
        // Title Label
        titleLabel.text = "VoiceVibe"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 28)
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        
        // Description Label
        descriptionLabel.text = "Create voice-activated micro-services on the fly"
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        view.addSubview(descriptionLabel)
        
        // Status Label
        statusLabel.text = "Ready"
        statusLabel.font = UIFont.systemFont(ofSize: 14)
        statusLabel.textColor = .systemGreen
        statusLabel.textAlignment = .right
        view.addSubview(statusLabel)
        
        // Recognized Text View
        recognizedTextView.layer.cornerRadius = 8
        recognizedTextView.layer.borderWidth = 1
        recognizedTextView.layer.borderColor = UIColor.lightGray.cgColor
        recognizedTextView.font = UIFont.systemFont(ofSize: 16)
        recognizedTextView.isEditable = false
        recognizedTextView.backgroundColor = UIColor(white: 0.95, alpha: 1)
        view.addSubview(recognizedTextView)
        
        // Start Listening Button
        startListeningButton.setTitle("Start Listening", for: .normal)
        startListeningButton.backgroundColor = .systemBlue
        startListeningButton.setTitleColor(.white, for: .normal)
        startListeningButton.layer.cornerRadius = 8
        startListeningButton.addTarget(self, action: #selector(startListeningButtonTapped), for: .touchUpInside)
        view.addSubview(startListeningButton)
        
        // Processed Command Text View
        processedCommandTextView.layer.cornerRadius = 8
        processedCommandTextView.layer.borderWidth = 1
        processedCommandTextView.layer.borderColor = UIColor.lightGray.cgColor
        processedCommandTextView.font = UIFont.systemFont(ofSize: 16)
        processedCommandTextView.isEditable = false
        processedCommandTextView.backgroundColor = UIColor(white: 0.95, alpha: 1)
        view.addSubview(processedCommandTextView)
        
        // View Services Button
        viewServicesButton.setTitle("View My Services", for: .normal)
        viewServicesButton.backgroundColor = .clear
        viewServicesButton.setTitleColor(.systemBlue, for: .normal)
        viewServicesButton.layer.cornerRadius = 8
        viewServicesButton.layer.borderWidth = 1
        viewServicesButton.layer.borderColor = UIColor.systemBlue.cgColor
        viewServicesButton.addTarget(self, action: #selector(viewServicesButtonTapped), for: .touchUpInside)
        view.addSubview(viewServicesButton)
    }
    
    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
            make.centerX.equalToSuperview()
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
        
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(24)
            make.right.equalToSuperview().offset(-20)
        }
        
        recognizedTextView.snp.makeConstraints { make in
            make.top.equalTo(statusLabel.snp.bottom).offset(16)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(100)
        }
        
        startListeningButton.snp.makeConstraints { make in
            make.top.equalTo(recognizedTextView.snp.bottom).offset(16)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(44)
        }
        
        processedCommandTextView.snp.makeConstraints { make in
            make.top.equalTo(startListeningButton.snp.bottom).offset(24)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(100)
        }
        
        viewServicesButton.snp.makeConstraints { make in
            make.top.equalTo(processedCommandTextView.snp.bottom).offset(24)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(44)
        }
    }
    
    // MARK: - Actions
    
    @objc private func startListeningButtonTapped() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            startListeningButton.setTitle("Start Listening", for: .normal)
            startListeningButton.backgroundColor = .systemBlue
        } else {
            startRecording()
            startListeningButton.setTitle("Stop Listening", for: .normal)
            startListeningButton.backgroundColor = .systemRed
        }
    }
    
    @objc private func viewServicesButtonTapped() {
        // TODO: Implement navigation to services list
    }
    
    // MARK: - Speech Recognition
    
    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self?.startListeningButton.isEnabled = true
                case .denied, .restricted, .notDetermined:
                    self?.startListeningButton.isEnabled = false
                    self?.showAlert(title: "Speech Recognition Disabled", message: "To use voice commands, please enable speech recognition in Settings.")
                @unknown default:
                    self?.startListeningButton.isEnabled = false
                }
            }
        }
    }
    
    private func startRecording() {
        // Cancel any existing recognition task
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            showAlert(title: "Audio Session Error", message: "Could not configure audio session: \(error.localizedDescription)")
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            showAlert(title: "Recognition Error", message: "Could not create speech recognition request.")
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Get input node
        let inputNode = audioEngine.inputNode
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            var isFinal = false
            
            if let result = result {
                self?.recognizedTextView.text = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self?.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self?.recognitionRequest = nil
                self?.recognitionTask = nil
                
                self?.startListeningButton.isEnabled = true
                self?.startListeningButton.setTitle("Start Listening", for: .normal)
                self?.startListeningButton.backgroundColor = .systemBlue
                
                if let recognizedText = self?.recognizedTextView.text, !recognizedText.isEmpty {
                    self?.processVoiceCommand(recognizedText)
                }
            }
        }
        
        // Configure audio input
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
            statusLabel.text = "Listening..."
            statusLabel.textColor = .systemBlue
        } catch {
            showAlert(title: "Audio Engine Error", message: "Could not start audio engine: \(error.localizedDescription)")
        }
    }
    
    private func processVoiceCommand(_ command: String) {
        // Update UI
        statusLabel.text = "Processing..."
        statusLabel.textColor = .systemOrange
        
        // For now, just display the command
        processedCommandTextView.text = "Processing command: \(command)"
        
        // TODO: Implement NLP and service creation logic
        
        // Reset status after processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.statusLabel.text = "Ready"
            self?.statusLabel.textColor = .systemGreen
        }
    }
    
    // MARK: - Helpers
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
} 