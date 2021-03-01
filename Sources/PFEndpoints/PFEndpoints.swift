/*
 MIT License

 Copyright (c) 2021 Lewis Shaw

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import UIKit

public protocol PFEndpointsDelegate: AnyObject {
    
    func endpoints(_ endpoints: PFEndpoints, didSelectEndpoint endpoint: PFEndpoint)
    
    func endpoints(_ endpoints: PFEndpoints, didTapAction action: PFAction)
}

public extension PFEndpointsDelegate {
    
    func endpoints(_ endpoints: PFEndpoints, didTapAction action: PFAction) { }
}

public class PFEndpoints {
    
    private var configuration: PFConfiguration
    
    public weak var delegate: PFEndpointsDelegate?
    
    private lazy var textFieldCompleteButton: UIAlertAction = UIAlertAction()
    
    private var showAlert: (() -> Void)?
    
    public private (set) var currentEndpoint: PFEndpoint? {
        get {
            if let data = UserDefaults.standard.data(forKey: configuration.userDefaultsKey) {
                let endpoint = try? JSONDecoder().decode(PFEndpoint.self, from: data)
                
                return endpoint
            }
            
            return nil
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: configuration.userDefaultsKey)
            }
        }
    }
    
    public var isDefaultEndpointCurrent: Bool {
        currentEndpoint == configuration.endpoints[configuration.defaultEndpointIndex]
    }
    
    public var defaultEndpoint: PFEndpoint {
        configuration.endpoints[configuration.defaultEndpointIndex]
    }
    
    public init(configuration: PFConfiguration) {
        guard !configuration.endpoints.isEmpty else {
            fatalError("PFConfiguration.Endpoints must contain at least one endpoint.")
        }
        
        self.configuration = configuration
        
        if !configuration.endpoints.indices.contains(configuration.defaultEndpointIndex) {
            debugPrint("PFConfiguration.defaultEndpointIndex is out of range, defaulting to index 0.")
            self.configuration.defaultEndpointIndex = 0
        }
        
        if currentEndpoint == nil {
            selected(self.configuration.endpoints[self.configuration.defaultEndpointIndex])
        }
    }
    
    public func attach(to viewController: UIViewController, gestureView: UIView? = nil, gestureRecognizer: UIGestureRecognizer? = nil) {
        guard let view = gestureView ?? viewController.view else {
            fatalError("Called `attach` without a valid view.")
        }
        
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(gestureRecognizer ?? buildDefaultGestureRecognizer(for: viewController))
        
        if let currentEndpoint = currentEndpoint {
            selected(currentEndpoint)
        }
    }
}

private extension PFEndpoints {
    
    func selected(_ endpoint: PFEndpoint) {
        self.currentEndpoint = endpoint
        NotificationCenter.default.post(name: .PFDidSelectEnpoint, object: self, userInfo: [Notification.PFKey.Endpoint: endpoint])
        delegate?.endpoints(self, didSelectEndpoint: endpoint)
    }
    
    func tapped(_ action: PFAction) {
        delegate?.endpoints(self, didTapAction: action)
    }
    
    func canOpenUrl(_ stringUrl: String) -> Bool {
        guard let url = URL(string: stringUrl), UIApplication.shared.canOpenURL(url) else {
            return false
        }
        
        let regEx = "((https|http)://)((\\w|-)+)(([.]|[/])((\\w|-)+))+(:[0-9]+)?"
        let predicate = NSPredicate(format: "SELF MATCHES %@", argumentArray: [regEx])
        return predicate.evaluate(with: stringUrl)
    }
}

private extension PFEndpoints {
    
    func attachShakeDetector(for viewController: UIViewController) {
        
    }
    
    func buildDefaultGestureRecognizer(for viewController: UIViewController) -> UITapGestureRecognizer {
        showAlert = { [weak viewController] in
            if let viewController = viewController {
                self.display(on: viewController)
            }
        }
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleGesture))
        
        let isSimulator = TARGET_OS_SIMULATOR != 0
        gesture.numberOfTapsRequired = isSimulator ? 1 : 2
        gesture.numberOfTouchesRequired =  isSimulator ? 1 : 2
        
        return gesture
    }
}

private extension PFEndpoints {
    
    func presentRestartAlert(on viewController: UIViewController) {
        let alert = UIAlertController(title: "App Restart Required", message: "For the change to take affect, you must restart the app.", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Don't restart", style: .cancel)
        let restartAction = UIAlertAction(title: "Restart", style: .destructive) { _ in
            fatalError("Restart app for changes to take affect.")
        }
        
        alert.addAction(cancelAction)
        alert.addAction(restartAction)
        
        viewController.present(alert, animated: true)
    }
}

private extension PFEndpoints {
    
    @objc func textFieldChanged(_ sender: UITextField) {
        guard var text = sender.text else {
            textFieldCompleteButton.isEnabled = false
            return
        }
        
        if !text.contains("http://") && !text.contains("https://") {
            text = "https://" + text
        }
        
        textFieldCompleteButton.isEnabled = canOpenUrl(text)
    }
    
    @objc func handleGesture(_ sender: UITapGestureRecognizer) {
        showAlert?()
    }
}

public extension PFEndpoints {
    
    func display(on viewController: UIViewController) {
        
        func handleDismissal() {
            if configuration.changeRequiresRestart {
                presentRestartAlert(on: viewController)
            } else {
                viewController.dismiss(animated: true)
            }
        }
        
        let alert = UIAlertController(title: configuration.alertTitle, message: configuration.alertMessage, preferredStyle: configuration.allowCustom ? .alert : .actionSheet)
        
        for endpoint in configuration.endpoints {
            let endpointAction = UIAlertAction(title: endpoint.title, style: .default) { [weak self] _ in
                self?.selected(endpoint)
                handleDismissal()
            }
            
            if endpoint == currentEndpoint {
                if #available(iOS 13.0, *) {
                    endpointAction.setValue(UIImage(systemName: "checkmark.circle.fill"), forKey: "image")
                } else {
                    endpointAction.setValue(UIImage(named: "Check"), forKey: "image")
                }
            }
            
            alert.addAction(endpointAction)
        }
        
        if configuration.allowCustom {
            textFieldCompleteButton = UIAlertAction(title: configuration.textFieldCompleteButtonTitle, style: .default, handler: { _ in
                guard let textField = alert.textFields?.first,
                      let text = textField.text,
                      let url = URL(string: text) else {
                    return
                }
                
                self.selected(PFEndpoint(title: "Custom", url: url))
                handleDismissal()
            })
        }
        alert.addAction(textFieldCompleteButton)
        
        alert.addTextField { textField in
            textField.placeholder = self.configuration.textFieldPlaceholder
            textField.addTarget(self, action: #selector(self.textFieldChanged), for: .editingChanged)
            textField.text = self.currentEndpoint?.url.absoluteString
        }
        
        for action in configuration.actions {
            let alertAction = UIAlertAction(title: action.title, style: .default) { [weak self] _ in
                self?.tapped(action)
                viewController.dismiss(animated: true)
            }
            
            alert.addAction(alertAction)
        }
        
        let cancelAction = UIAlertAction(title: configuration.cancelTitle, style: .cancel)
        
        alert.addAction(cancelAction)
        
        viewController.present(alert, animated: true)
    }
}
