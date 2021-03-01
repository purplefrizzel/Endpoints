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

import Foundation

public struct PFConfiguration {
    
    public var userDefaultsKey: String
    
    public var alertTitle: String = "Select an Endpoint"
    
    public var alertMessage: String? {
        guard let info = Bundle.main.infoDictionary,
            let displayName = (info["CFBundleDisplayName"] as? String) ?? (info["CFBundleName"] as? String),
            let versionString = info["CFBundleShortVersionString"] as? String,
            let buildNumber = info["CFBundleVersion"] as? String else {
            return "Choose an endpoint and then the magic happens."
        }
        
        return "\(displayName) \(versionString)(\(buildNumber))"
    }
    
    public var textFieldPlaceholder: String = "Enter a URL (https://apple.com)"
    
    public var textFieldCompleteButtonTitle: String = "Use Custom"
    
    public var cancelTitle: String = "Cancel"
    
    public var allowCustom: Bool = false
    
    public var actions: [PFAction] = []
    
    public var endpoints: [PFEndpoint] = []
    
    public var defaultEndpointIndex: Int = 0
    
    public var changeRequiresRestart: Bool = false
    
    public var shakeToActivate: Bool = true
    
    public init(userDefaultsKey: String, endpoints: [PFEndpoint], actions: [PFAction], allowCustom: Bool = false) {
        self.userDefaultsKey = userDefaultsKey
        self.endpoints = endpoints
        self.actions = actions
        self.allowCustom = allowCustom
    }
}
