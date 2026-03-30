//
//  ServerSettingsVM+Computed.swift
//  AevonX
//
//  Computed properties for service filtering and categorization.
//

import Foundation

extension ServerSettingsViewModel {

    var filteredServices: [ServiceInfo] {
        var result = allServices
        if !serviceSearchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(serviceSearchText) }
        }
        switch serviceFilter {
        case .all: break
        case .active: result = result.filter { $0.activeState == .active }
        case .inactive: result = result.filter { $0.activeState == .inactive }
        case .failed: result = result.filter { $0.activeState == .failed }
        case .enabled: result = result.filter { $0.enabledState == .enabled }
        case .disabled: result = result.filter { $0.enabledState == .disabled }
        }
        return result
    }

    var categorizedServices: [(category: ServiceCategory, services: [ServiceInfo])] {
        let filtered = filteredServices
        let grouped = Dictionary(grouping: filtered) { svc -> ServiceCategory in
            svc.activeState == .failed ? .failed : svc.category
        }
        return ServiceCategory.allCases.compactMap { cat in
            guard let svcs = grouped[cat], !svcs.isEmpty else { return nil }
            return (category: cat, services: svcs.sorted { $0.name < $1.name })
        }
    }

    /// Validates password meets complexity requirements.
    func validatePassword(_ pwd: String, _ confirm: String, setMsg: @escaping ((String, Bool)?) -> Void) -> Bool {
        guard !pwd.isEmpty, pwd == confirm else {
            setMsg(("Passwords do not match", false))
            clearMsg(after: 4) { setMsg(nil) }
            return false
        }
        guard pwd.count >= 8 else {
            setMsg(("Minimum 8 characters", false))
            clearMsg(after: 4) { setMsg(nil) }
            return false
        }
        let hasUpper = pwd.contains(where: { $0.isUppercase })
        let hasLower = pwd.contains(where: { $0.isLowercase })
        let hasDigit = pwd.contains(where: { $0.isNumber })
        guard hasUpper && hasLower && hasDigit else {
            setMsg(("Must include uppercase, lowercase, and number", false))
            clearMsg(after: 4) { setMsg(nil) }
            return false
        }
        return true
    }
}
