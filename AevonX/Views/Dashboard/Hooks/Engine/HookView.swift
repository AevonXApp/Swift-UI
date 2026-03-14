//
//  HookView.swift
//  AevonX
//
//  Drop-in SwiftUI view that renders all plugins registered at a given hook point.
//  Usage: HookView(hook: .websitesCardActions, serverId: serverId, context: ["website.id": id])
//

import SwiftUI
import AevonXCore
import AevonXCoreBridge

// MARK: - Hook View

/// Renders all plugins registered at a given hook point.
/// This is the primary integration point — drop this into any existing view to enable plugin injection.
public struct HookView: View {

    let hook: HookPoint
    let serverId: String
    let context: [String: String]
    let axis: Axis.Set

    @ObservedObject private var registry = HookRegistry.shared

    public init(
        hook: HookPoint,
        serverId: String,
        context: [String: String] = [:],
        axis: Axis.Set = .horizontal
    ) {
        self.hook = hook
        self.serverId = serverId
        self.context = context
        self.axis = axis
    }

    public var body: some View {
        let plugins = registry.plugins(for: hook)

        if !plugins.isEmpty {
            if axis == .horizontal {
                HStack(spacing: AXSpacing.sm) {
                    ForEach(plugins) { plugin in
                        if evaluateConditions(plugin.conditions) {
                            HookComponentRenderer(
                                plugin: plugin,
                                serverId: serverId,
                                context: context
                            )
                        }
                    }
                }
            } else {
                VStack(spacing: AXSpacing.sm) {
                    ForEach(plugins) { plugin in
                        if evaluateConditions(plugin.conditions) {
                            HookComponentRenderer(
                                plugin: plugin,
                                serverId: serverId,
                                context: context
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Condition Evaluation

    private func evaluateConditions(_ conditions: [HookCondition]?) -> Bool {
        guard let conditions = conditions, !conditions.isEmpty else { return true }

        for condition in conditions {
            let contextValue = context[condition.field] ?? ""
            let conditionValue = condition.value.stringValue

            switch condition.op {
            case .equals:
                if contextValue != conditionValue { return false }
            case .notEquals:
                if contextValue == conditionValue { return false }
            case .contains:
                if !contextValue.contains(conditionValue) { return false }
            case .greaterThan:
                if let cv = Double(contextValue), let tv = Double(conditionValue) {
                    if cv <= tv { return false }
                }
            case .lessThan:
                if let cv = Double(contextValue), let tv = Double(conditionValue) {
                    if cv >= tv { return false }
                }
            case .exists:
                if contextValue.isEmpty { return false }
            }
        }

        return true
    }
}
