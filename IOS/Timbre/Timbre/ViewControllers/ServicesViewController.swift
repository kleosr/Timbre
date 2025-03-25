import UIKit
import SnapKit

class ServicesViewController: UIViewController {
    
    // MARK: - Properties
    
    private var services: [MicroService] = []
    private var tableView = UITableView()
    private let emptyStateLabel = UILabel()
    private let createServiceButton = UIButton(type: .system)
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchServices()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .white
        title = "My Services"
        
        // Add a back button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        
        // Table View
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ServiceTableViewCell.self, forCellReuseIdentifier: "ServiceCell")
        tableView.tableFooterView = UIView() // Remove empty cell separators
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.backgroundColor = .white
        view.addSubview(tableView)
        
        // Empty State Label
        emptyStateLabel.text = "You don't have any active services yet.\nUse voice commands to create one."
        emptyStateLabel.font = UIFont.systemFont(ofSize: 16)
        emptyStateLabel.textColor = .gray
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.isHidden = true
        view.addSubview(emptyStateLabel)
        
        // Create Service Button
        createServiceButton.setTitle("Create New Service", for: .normal)
        createServiceButton.backgroundColor = .systemBlue
        createServiceButton.setTitleColor(.white, for: .normal)
        createServiceButton.layer.cornerRadius = 8
        createServiceButton.addTarget(self, action: #selector(createServiceButtonTapped), for: .touchUpInside)
        view.addSubview(createServiceButton)
    }
    
    private func setupConstraints() {
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(createServiceButton.snp.top).offset(-16)
        }
        
        emptyStateLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.equalToSuperview().offset(32)
            make.right.equalToSuperview().offset(-32)
        }
        
        createServiceButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-16)
            make.height.equalTo(44)
        }
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func createServiceButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Data Loading
    
    private func fetchServices() {
        // Get services from MicroServiceManager
        services = Array(MicroServiceManager.shared.activeServices.values)
        
        // Update UI based on services availability
        tableView.reloadData()
        emptyStateLabel.isHidden = !services.isEmpty
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension ServicesViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return services.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ServiceCell", for: indexPath) as? ServiceTableViewCell else {
            return UITableViewCell()
        }
        
        let service = services[indexPath.row]
        cell.configure(with: service)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 110
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let service = services[indexPath.row]
        let serviceDetailVC = ServiceDetailViewController(service: service)
        navigationController?.pushViewController(serviceDetailVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let service = services[indexPath.row]
            
            // Stop and remove the service
            MicroServiceManager.shared.stopService(serviceId: service.id) { success in
                if success {
                    DispatchQueue.main.async {
                        self.services.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                        self.emptyStateLabel.isHidden = !self.services.isEmpty
                    }
                }
            }
        }
    }
}

// MARK: - ServiceTableViewCell

class ServiceTableViewCell: UITableViewCell {
    
    // MARK: - Properties
    
    private let serviceNameLabel = UILabel()
    private let serviceDescriptionLabel = UILabel()
    private let statusLabel = UILabel()
    private let statusIndicator = UIView()
    private let controlButton = UIButton(type: .system)
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        serviceNameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        contentView.addSubview(serviceNameLabel)
        
        serviceDescriptionLabel.font = UIFont.systemFont(ofSize: 14)
        serviceDescriptionLabel.textColor = .darkGray
        serviceDescriptionLabel.numberOfLines = 2
        contentView.addSubview(serviceDescriptionLabel)
        
        statusLabel.font = UIFont.systemFont(ofSize: 12)
        statusLabel.textAlignment = .right
        contentView.addSubview(statusLabel)
        
        statusIndicator.layer.cornerRadius = 5
        contentView.addSubview(statusIndicator)
        
        controlButton.backgroundColor = .systemBlue
        controlButton.setTitleColor(.white, for: .normal)
        controlButton.layer.cornerRadius = 5
        controlButton.addTarget(self, action: #selector(controlButtonTapped), for: .touchUpInside)
        contentView.addSubview(controlButton)
    }
    
    private func setupConstraints() {
        serviceNameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.left.equalToSuperview().offset(16)
            make.right.equalTo(statusIndicator.snp.left).offset(-8)
        }
        
        serviceDescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(serviceNameLabel.snp.bottom).offset(4)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }
        
        statusIndicator.snp.makeConstraints { make in
            make.centerY.equalTo(serviceNameLabel)
            make.right.equalToSuperview().offset(-16)
            make.width.height.equalTo(10)
        }
        
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(serviceDescriptionLabel.snp.bottom).offset(8)
            make.left.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-12)
        }
        
        controlButton.snp.makeConstraints { make in
            make.centerY.equalTo(statusLabel)
            make.right.equalToSuperview().offset(-16)
            make.width.equalTo(80)
            make.height.equalTo(30)
        }
    }
    
    // MARK: - Configuration
    
    func configure(with service: MicroService) {
        serviceNameLabel.text = service.name
        serviceDescriptionLabel.text = service.description
        
        // Set status indicator color and label
        switch service.status {
        case .running:
            statusIndicator.backgroundColor = .systemGreen
            statusLabel.text = "Running"
            controlButton.setTitle("Stop", for: .normal)
            controlButton.backgroundColor = .systemRed
        case .paused:
            statusIndicator.backgroundColor = .systemYellow
            statusLabel.text = "Paused"
            controlButton.setTitle("Resume", for: .normal)
            controlButton.backgroundColor = .systemGreen
        case .stopped:
            statusIndicator.backgroundColor = .systemGray
            statusLabel.text = "Stopped"
            controlButton.setTitle("Start", for: .normal)
            controlButton.backgroundColor = .systemGreen
        case .starting:
            statusIndicator.backgroundColor = .systemBlue
            statusLabel.text = "Starting..."
            controlButton.setTitle("Cancel", for: .normal)
            controlButton.backgroundColor = .systemRed
        case .stopping:
            statusIndicator.backgroundColor = .systemOrange
            statusLabel.text = "Stopping..."
            controlButton.isEnabled = false
            controlButton.backgroundColor = .systemGray
        case .created:
            statusIndicator.backgroundColor = .systemPurple
            statusLabel.text = "Created"
            controlButton.setTitle("Start", for: .normal)
            controlButton.backgroundColor = .systemGreen
        case .error:
            statusIndicator.backgroundColor = .systemRed
            statusLabel.text = "Error"
            controlButton.setTitle("Restart", for: .normal)
            controlButton.backgroundColor = .systemBlue
        }
        
        // Tag the button with service ID hash value for identification
        controlButton.tag = service.id.hashValue
    }
    
    // MARK: - Actions
    
    @objc private func controlButtonTapped() {
        // This tag should be set during configure to identify the service
        let serviceHash = controlButton.tag
        
        // Find the service with this hash
        if let serviceId = MicroServiceManager.shared.activeServices.keys.first(where: { $0.hashValue == serviceHash }) {
            let service = MicroServiceManager.shared.activeServices[serviceId]
            
            switch service?.status {
            case .running:
                MicroServiceManager.shared.stopService(serviceId: serviceId) { _ in }
            case .paused, .stopped, .created, .error:
                MicroServiceManager.shared.startService(serviceId: serviceId) { _ in }
            case .starting:
                MicroServiceManager.shared.stopService(serviceId: serviceId) { _ in }
            default:
                break
            }
        }
    }
}

// MARK: - ServiceDetailViewController

class ServiceDetailViewController: UIViewController {
    
    // MARK: - Properties
    
    private let service: MicroService
    private let statusView = UIView()
    private let serviceNameLabel = UILabel()
    private let serviceDescriptionLabel = UILabel()
    private let statusLabel = UILabel()
    private let controlButton = UIButton(type: .system)
    private let commandTextField = UITextField()
    private let executeButton = UIButton(type: .system)
    private let responseTextView = UITextView()
    
    // MARK: - Initialization
    
    init(service: MicroService) {
        self.service = service
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        updateStatusUI()
        
        // Register for status updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(serviceStatusChanged(_:)),
            name: .serviceStatusChanged,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .white
        title = "Service Details"
        
        // Add a back button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        
        // Status View (colored box at the top)
        statusView.backgroundColor = .systemGreen
        view.addSubview(statusView)
        
        // Service Name Label
        serviceNameLabel.text = service.name
        serviceNameLabel.font = UIFont.boldSystemFont(ofSize: 24)
        serviceNameLabel.textColor = .white
        statusView.addSubview(serviceNameLabel)
        
        // Service Description Label
        serviceDescriptionLabel.text = service.description
        serviceDescriptionLabel.font = UIFont.systemFont(ofSize: 16)
        serviceDescriptionLabel.textColor = .white
        serviceDescriptionLabel.numberOfLines = 0
        statusView.addSubview(serviceDescriptionLabel)
        
        // Status Label
        statusLabel.text = "Status: Running"
        statusLabel.font = UIFont.systemFont(ofSize: 14)
        statusLabel.textColor = .white
        statusView.addSubview(statusLabel)
        
        // Control Button (Start/Stop/Pause)
        controlButton.setTitle("Stop Service", for: .normal)
        controlButton.backgroundColor = .white
        controlButton.setTitleColor(.systemRed, for: .normal)
        controlButton.layer.cornerRadius = 8
        controlButton.addTarget(self, action: #selector(controlButtonTapped), for: .touchUpInside)
        statusView.addSubview(controlButton)
        
        // Command Text Field
        commandTextField.placeholder = "Enter command"
        commandTextField.borderStyle = .roundedRect
        commandTextField.returnKeyType = .send
        commandTextField.delegate = self
        view.addSubview(commandTextField)
        
        // Execute Button
        executeButton.setTitle("Execute", for: .normal)
        executeButton.backgroundColor = .systemBlue
        executeButton.setTitleColor(.white, for: .normal)
        executeButton.layer.cornerRadius = 8
        executeButton.addTarget(self, action: #selector(executeButtonTapped), for: .touchUpInside)
        view.addSubview(executeButton)
        
        // Response Text View
        responseTextView.font = UIFont.systemFont(ofSize: 14)
        responseTextView.isEditable = false
        responseTextView.layer.borderWidth = 1
        responseTextView.layer.borderColor = UIColor.lightGray.cgColor
        responseTextView.layer.cornerRadius = 8
        responseTextView.text = "Enter a command and tap Execute to see the response."
        view.addSubview(responseTextView)
    }
    
    private func setupConstraints() {
        statusView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(180)
        }
        
        serviceNameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(60)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
        
        serviceDescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(serviceNameLabel.snp.bottom).offset(8)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
        
        statusLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.bottom.equalToSuperview().offset(-20)
        }
        
        controlButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-20)
            make.width.equalTo(120)
            make.height.equalTo(36)
        }
        
        commandTextField.snp.makeConstraints { make in
            make.top.equalTo(statusView.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(20)
            make.right.equalTo(executeButton.snp.left).offset(-8)
            make.height.equalTo(36)
        }
        
        executeButton.snp.makeConstraints { make in
            make.top.equalTo(statusView.snp.bottom).offset(20)
            make.right.equalToSuperview().offset(-20)
            make.width.equalTo(100)
            make.height.equalTo(36)
        }
        
        responseTextView.snp.makeConstraints { make in
            make.top.equalTo(commandTextField.snp.bottom).offset(16)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-16)
        }
    }
    
    // MARK: - Status Update
    
    private func updateStatusUI() {
        // Update status label
        statusLabel.text = "Status: \(service.status.rawValue.capitalized)"
        
        // Update status view background color
        switch service.status {
        case .running:
            statusView.backgroundColor = .systemGreen
            controlButton.setTitle("Stop Service", for: .normal)
            controlButton.setTitleColor(.systemRed, for: .normal)
        case .paused:
            statusView.backgroundColor = .systemYellow
            controlButton.setTitle("Resume Service", for: .normal)
            controlButton.setTitleColor(.systemGreen, for: .normal)
        case .stopped:
            statusView.backgroundColor = .systemGray
            controlButton.setTitle("Start Service", for: .normal)
            controlButton.setTitleColor(.systemGreen, for: .normal)
        case .starting:
            statusView.backgroundColor = .systemBlue
            controlButton.setTitle("Cancel", for: .normal)
            controlButton.setTitleColor(.systemRed, for: .normal)
        case .stopping:
            statusView.backgroundColor = .systemOrange
            controlButton.setTitle("Stopping...", for: .normal)
            controlButton.isEnabled = false
        case .created:
            statusView.backgroundColor = .systemPurple
            controlButton.setTitle("Start Service", for: .normal)
            controlButton.setTitleColor(.systemGreen, for: .normal)
        case .error:
            statusView.backgroundColor = .systemRed
            controlButton.setTitle("Restart Service", for: .normal)
            controlButton.setTitleColor(.systemBlue, for: .normal)
        }
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func controlButtonTapped() {
        switch service.status {
        case .running:
            MicroServiceManager.shared.stopService(serviceId: service.id) { _ in }
        case .paused, .stopped, .created, .error:
            MicroServiceManager.shared.startService(serviceId: service.id) { _ in }
        case .starting:
            MicroServiceManager.shared.stopService(serviceId: service.id) { _ in }
        default:
            break
        }
    }
    
    @objc private func executeButtonTapped() {
        guard let command = commandTextField.text, !command.isEmpty else {
            responseTextView.text = "Please enter a command."
            return
        }
        
        // Execute the command on the service
        let result = service.executeCommand(command)
        
        // Display the result
        responseTextView.text = "Command: \(command)\n\nResult: \(result.success ? "Success" : "Failed")\nMessage: \(result.message)"
        
        if let data = result.data {
            responseTextView.text?.append("\n\nData: \(data)")
        }
        
        // Clear the command field
        commandTextField.text = ""
    }
    
    @objc private func serviceStatusChanged(_ notification: Notification) {
        if let serviceId = notification.userInfo?["serviceId"] as? String, serviceId == service.id {
            DispatchQueue.main.async {
                self.updateStatusUI()
            }
        }
    }
}

// MARK: - UITextFieldDelegate

extension ServiceDetailViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        executeButtonTapped()
        return true
    }
} 