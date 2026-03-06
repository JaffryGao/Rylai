// LaunchAtLoginManager.swift
// Rylai ❄️ — Launch at Login (macOS 13+ SMAppService)

import Foundation
import ServiceManagement

@available(macOS 13.0, *)
class LaunchAtLoginManager: ObservableObject {
    
    @Published var isEnabled: Bool = false
    
    private let service = SMAppService.mainApp
    
    init() {
        refresh()
    }
    
    func refresh() {
        isEnabled = service.status == .enabled
    }
    
    func toggle() {
        do {
            if isEnabled {
                try service.unregister()
            } else {
                try service.register()
            }
            isEnabled.toggle()
        } catch {
            print("LaunchAtLogin error: \(error.localizedDescription)")
        }
    }
}
