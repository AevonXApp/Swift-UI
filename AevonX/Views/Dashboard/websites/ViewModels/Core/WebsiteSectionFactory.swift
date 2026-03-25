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
        if _siteConfigVM == nil {
            _siteConfigVM = SiteConfigViewModel(serverId: serverId, domain: domain, engine: engine)
        }
        return _siteConfigVM!
    }

    private var _cacheVM: CacheViewModel?
    var cacheVM: CacheViewModel {
        if _cacheVM == nil {
            _cacheVM = CacheViewModel(serverId: serverId, domain: domain, engine: engine)
        }
        return _cacheVM!
    }

    private var _backupVM: BackupViewModel?
    var backupVM: BackupViewModel {
        if _backupVM == nil {
            _backupVM = BackupViewModel(serverId: serverId, domain: domain, docRoot: docRoot)
        }
        return _backupVM!
    }

    private var _monitoringVM: MonitoringViewModel?
    var monitoringVM: MonitoringViewModel {
        if _monitoringVM == nil {
            _monitoringVM = MonitoringViewModel(serverId: serverId, domain: domain)
        }
        return _monitoringVM!
    }

    private var _securityVM: SiteSecurityViewModel?
    var securityVM: SiteSecurityViewModel {
        if _securityVM == nil {
            _securityVM = SiteSecurityViewModel(serverId: serverId, domain: domain, docRoot: docRoot, engine: engine)
        }
        return _securityVM!
    }

    private var _headersVM: HeadersViewModel?
    var headersVM: HeadersViewModel {
        if _headersVM == nil {
            _headersVM = HeadersViewModel(serverId: serverId, domain: domain, engine: engine)
        }
        return _headersVM!
    }

    private var _logsVM: EnhancedLogsViewModel?
    var logsVM: EnhancedLogsViewModel {
        if _logsVM == nil {
            _logsVM = EnhancedLogsViewModel(serverId: serverId, domain: domain, engine: engine)
        }
        return _logsVM!
    }

    private var _quickActionsVM: QuickActionsViewModel?
    var quickActionsVM: QuickActionsViewModel {
        if _quickActionsVM == nil {
            _quickActionsVM = QuickActionsViewModel(serverId: serverId, domain: domain, docRoot: docRoot, runtime: runtime, engine: engine)
        }
        return _quickActionsVM!
    }

    private var _advancedDomainVM: AdvancedDomainViewModel?
    var advancedDomainVM: AdvancedDomainViewModel {
        if _advancedDomainVM == nil {
            _advancedDomainVM = AdvancedDomainViewModel(serverId: serverId, domain: domain, docRoot: docRoot, engine: engine)
        }
        return _advancedDomainVM!
    }

    private var _performanceTuningVM: PerformanceTuningViewModel?
    var performanceTuningVM: PerformanceTuningViewModel {
        if _performanceTuningVM == nil {
            _performanceTuningVM = PerformanceTuningViewModel(serverId: serverId, domain: domain, engine: engine)
        }
        return _performanceTuningVM!
    }

    private var _siteCloningVM: SiteCloningViewModel?
    var siteCloningVM: SiteCloningViewModel {
        if _siteCloningVM == nil {
            _siteCloningVM = SiteCloningViewModel(serverId: serverId, domain: domain, docRoot: docRoot, engine: engine)
        }
        return _siteCloningVM!
    }

    private var _scheduledBackupVM: ScheduledBackupViewModel?
    var scheduledBackupVM: ScheduledBackupViewModel {
        if _scheduledBackupVM == nil {
            _scheduledBackupVM = ScheduledBackupViewModel(serverId: serverId, domain: domain, docRoot: docRoot)
        }
        return _scheduledBackupVM!
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
