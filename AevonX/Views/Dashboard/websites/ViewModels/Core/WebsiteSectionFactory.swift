//
//  WebsiteSectionFactory.swift
//  AevonX
//
//  Lazy ViewModel factory for website sections.
//  Creates ViewModels on-demand and caches them for the session.
//  This ensures ViewModels survive sidebar navigation without re-creation.
//

import SwiftUI
import Combine
import AevonXCoreBridge

@MainActor
class WebsiteSectionFactory: ObservableObject {
    let serverId: String
    let domain: String
    let docRoot: String
    let runtime: RuntimeType
    let engine: String

    init(serverId: String, domain: String, docRoot: String, runtime: RuntimeType, engine: String = "nginx") {
        self.serverId = serverId
        self.domain = domain
        self.docRoot = docRoot
        self.runtime = runtime
        self.engine = engine
    }

    // MARK: - Lazy ViewModels
    // Each ViewModel is created on first access and cached

    private var _siteConfigVM: SiteConfigViewModel?
    var siteConfigVM: SiteConfigViewModel {
        if let vm = _siteConfigVM { return vm }
        let vm = SiteConfigViewModel(serverId: serverId, domain: domain, engine: engine)
        _siteConfigVM = vm
        return vm
    }

    private var _cacheVM: CacheViewModel?
    var cacheVM: CacheViewModel {
        if let vm = _cacheVM { return vm }
        let vm = CacheViewModel(serverId: serverId, domain: domain, engine: engine)
        _cacheVM = vm
        return vm
    }

    private var _backupVM: BackupViewModel?
    var backupVM: BackupViewModel {
        if let vm = _backupVM { return vm }
        let vm = BackupViewModel(serverId: serverId, domain: domain, docRoot: docRoot)
        _backupVM = vm
        return vm
    }

    private var _monitoringVM: MonitoringViewModel?
    var monitoringVM: MonitoringViewModel {
        if let vm = _monitoringVM { return vm }
        let vm = MonitoringViewModel(serverId: serverId, domain: domain)
        _monitoringVM = vm
        return vm
    }

    private var _securityVM: SiteSecurityViewModel?
    var securityVM: SiteSecurityViewModel {
        if let vm = _securityVM { return vm }
        let vm = SiteSecurityViewModel(serverId: serverId, domain: domain, docRoot: docRoot, engine: engine)
        _securityVM = vm
        return vm
    }

    private var _headersVM: HeadersViewModel?
    var headersVM: HeadersViewModel {
        if let vm = _headersVM { return vm }
        let vm = HeadersViewModel(serverId: serverId, domain: domain, engine: engine)
        _headersVM = vm
        return vm
    }

    private var _logsVM: EnhancedLogsViewModel?
    var logsVM: EnhancedLogsViewModel {
        if let vm = _logsVM { return vm }
        let vm = EnhancedLogsViewModel(serverId: serverId, domain: domain, engine: engine)
        _logsVM = vm
        return vm
    }

    private var _quickActionsVM: QuickActionsViewModel?
    var quickActionsVM: QuickActionsViewModel {
        if let vm = _quickActionsVM { return vm }
        let vm = QuickActionsViewModel(serverId: serverId, domain: domain, docRoot: docRoot, runtime: runtime, engine: engine)
        _quickActionsVM = vm
        return vm
    }

    private var _advancedDomainVM: AdvancedDomainViewModel?
    var advancedDomainVM: AdvancedDomainViewModel {
        if let vm = _advancedDomainVM { return vm }
        let vm = AdvancedDomainViewModel(serverId: serverId, domain: domain, docRoot: docRoot, engine: engine)
        _advancedDomainVM = vm
        return vm
    }

    private var _performanceTuningVM: PerformanceTuningViewModel?
    var performanceTuningVM: PerformanceTuningViewModel {
        if let vm = _performanceTuningVM { return vm }
        let vm = PerformanceTuningViewModel(serverId: serverId, domain: domain, engine: engine)
        _performanceTuningVM = vm
        return vm
    }

    private var _siteCloningVM: SiteCloningViewModel?
    var siteCloningVM: SiteCloningViewModel {
        if let vm = _siteCloningVM { return vm }
        let vm = SiteCloningViewModel(serverId: serverId, domain: domain, docRoot: docRoot, engine: engine)
        _siteCloningVM = vm
        return vm
    }

    private var _scheduledBackupVM: ScheduledBackupViewModel?
    var scheduledBackupVM: ScheduledBackupViewModel {
        if let vm = _scheduledBackupVM { return vm }
        let vm = ScheduledBackupViewModel(serverId: serverId, domain: domain, docRoot: docRoot)
        _scheduledBackupVM = vm
        return vm
    }

    // MARK: - Reset

    /// Call when website changes to invalidate all cached VMs
    func invalidateAll() {
        _siteConfigVM = nil
        _cacheVM = nil
        _backupVM = nil
        _monitoringVM = nil
        _securityVM = nil
        _headersVM = nil
        _logsVM = nil
        _quickActionsVM = nil
        _advancedDomainVM = nil
        _performanceTuningVM = nil
        _siteCloningVM = nil
        _scheduledBackupVM = nil
    }
}
