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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Update status based on active services
        updateActiveServicesCount()
        
        // Listen for changes in services
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(serviceStatusChanged(_:)),
            name: .serviceStatusChanged,
            object: nil
        )
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .serviceStatusChanged, object: nil)
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .white
        title = "Timbre"
        
        // Title Label
        titleLabel.text = "Timbre"
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
        let servicesVC = ServicesViewController()
        navigationController?.pushViewController(servicesVC, animated: true)
    }
    
    @objc private func serviceStatusChanged(_ notification: Notification) {
        updateActiveServicesCount()
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
        
        // Display the command
        processedCommandTextView.text = "Processing command: \(command)"
        
        // Simple NLP processing
        if command.lowercased().contains("create") && command.lowercased().contains("service") {
            // Extract service name (simple approach - would need more sophisticated NLP in real app)
            var serviceName = "Unnamed Service"
            var serviceDescription = "Service created by voice command"
            
            // Try to extract name after "called" or "named"
            if let calledRange = command.lowercased().range(of: "called "),
               calledRange.upperBound < command.endIndex {
                let nameStartIndex = calledRange.upperBound
                if let endRange = command[nameStartIndex...].firstIndex(where: { $0 == "." || $0 == "," }) {
                    serviceName = String(command[nameStartIndex..<endRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                } else {
                    serviceName = String(command[nameStartIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            } else if let namedRange = command.lowercased().range(of: "named "),
                      namedRange.upperBound < command.endIndex {
                let nameStartIndex = namedRange.upperBound
                if let endRange = command[nameStartIndex...].firstIndex(where: { $0 == "." || $0 == "," }) {
                    serviceName = String(command[nameStartIndex..<endRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                } else {
                    serviceName = String(command[nameStartIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            
            // Try to extract description after "that" or "which"
            if let thatRange = command.lowercased().range(of: "that "),
               thatRange.upperBound < command.endIndex {
                serviceDescription = String(command[thatRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if let whichRange = command.lowercased().range(of: "which "),
                      whichRange.upperBound < command.endIndex {
                serviceDescription = String(command[whichRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            // Create dummy service with extracted name
            createDummyService(name: serviceName, description: serviceDescription)
            
        } else if command.lowercased().contains("list") && command.lowercased().contains("service") {
            // Navigate to services list
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.viewServicesButtonTapped()
            }
        } else if command.lowercased().contains("help") || command.lowercased().contains("what can you do") {
            // Show help
            processedCommandTextView.text = """
            I can help you with the following:
            - "Create a service called [name]" - Creates a new micro-service
            - "List my services" - Shows all your active services
            - "Help" - Shows this help message
            """
        } else {
            // Unknown command
            processedCommandTextView.text = "I'm not sure how to process: \"\(command)\"\n\nTry saying \"Create a service called [name]\" or \"List my services\""
        }
        
        // Reset status after processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.updateActiveServicesCount()
        }
    }
    
    // MARK: - Service Management
    
    private func createDummyService(name: String, description: String) {
        // Create configuration JSON
        let config = """
        {
            "name": "\(name)",
            "description": "\(description)"
        }
        """
        
        // Create and start the service
        MicroServiceManager.shared.createService(type: "dummy", configuration: config) { [weak self] success, serviceId in
            if success, let serviceId = serviceId {
                MicroServiceManager.shared.startService(serviceId: serviceId) { success in
                    DispatchQueue.main.async {
                        if success {
                            self?.processedCommandTextView.text = "Created and started service: \(name)"
                        } else {
                            self?.processedCommandTextView.text = "Created service but failed to start it: \(name)"
                        }
                        self?.updateActiveServicesCount()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self?.processedCommandTextView.text = "Failed to create service: \(name)"
                }
            }
        }
    }
    
    private func updateActiveServicesCount() {
        let serviceCount = MicroServiceManager.shared.activeServices.count
        
        DispatchQueue.main.async { [weak self] in
            if serviceCount > 0 {
                self?.statusLabel.text = "\(serviceCount) active service\(serviceCount > 1 ? "s" : "")"
                
                // Update view services button title with count
                self?.viewServicesButton.setTitle("View My Services (\(serviceCount))", for: .normal)
            } else {
                self?.statusLabel.text = "Ready"
                self?.viewServicesButton.setTitle("View My Services", for: .normal)
            }
            
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