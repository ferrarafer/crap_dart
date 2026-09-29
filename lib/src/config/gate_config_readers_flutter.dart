part of 'config_loader.dart';

/// Readers for the Flutter-only gates: golden, hardcoded_strings and
/// accessibility.
class _FlutterGateConfigReaders {
  static GoldenGateConfig readGolden(
    Object? node,
    GoldenGateConfig base,
    String path,
  ) {
    return _ConfigScalars.readGateConfig(
      node,
      base,
      path,
      'gates.golden',
      const {
        _enabledKey,
        _severityKey,
        _ignorableKey,
        'min_widget_coverage',
        'widget_dirs',
        'test_dirs',
        'exclude_widgets',
      },
      (map, base, path, ctx) {
        final flags = _ConfigScalars.gateFlags(map, base, path, ctx);
        return GoldenGateConfig(
          enabled: flags.enabled,
          severity: flags.severity,
          ignorable: flags.ignorable,
          minWidgetCoverage: _ConfigScalars.readNum(
            map,
            'min_widget_coverage',
            base.minWidgetCoverage,
            path,
            ctx,
          ),
          widgetDirs: _ConfigScalars.strList(
            map,
            'widget_dirs',
            base.widgetDirs,
            path,
            ctx,
          ),
          testDirs: _ConfigScalars.strList(
            map,
            'test_dirs',
            base.testDirs,
            path,
            ctx,
          ),
          excludeWidgets: _ConfigScalars.strList(
            map,
            'exclude_widgets',
            base.excludeWidgets,
            path,
            ctx,
          ),
        );
      },
    );
  }

  static HardcodedStringsGateConfig readHardcodedStrings(
    Object? node,
    HardcodedStringsGateConfig base,
    String path,
  ) {
    return _ConfigScalars.readGateConfig(
      node,
      base,
      path,
      'gates.hardcoded_strings',
      const {
        _enabledKey,
        _severityKey,
        _ignorableKey,
        'ignore_marker',
        'check_params',
      },
      (map, base, path, ctx) {
        final flags = _ConfigScalars.gateFlags(map, base, path, ctx);
        return HardcodedStringsGateConfig(
          enabled: flags.enabled,
          severity: flags.severity,
          ignorable: flags.ignorable,
          ignoreMarker: _ConfigScalars.str(
            map,
            'ignore_marker',
            base.ignoreMarker,
            path,
            ctx,
          ),
          checkParams: _ConfigScalars.strList(
            map,
            'check_params',
            base.checkParams,
            path,
            ctx,
          ),
        );
      },
    );
  }

  static AccessibilityGateConfig readAccessibility(
    Object? node,
    AccessibilityGateConfig base,
    String path,
  ) {
    return _ConfigScalars.readGateConfig(
      node,
      base,
      path,
      'gates.accessibility',
      const {_enabledKey, _severityKey, _ignorableKey, 'require_label_for'},
      (map, base, path, ctx) {
        final flags = _ConfigScalars.gateFlags(map, base, path, ctx);
        return AccessibilityGateConfig(
          enabled: flags.enabled,
          severity: flags.severity,
          ignorable: flags.ignorable,
          requireLabelFor: _ConfigScalars.strList(
            map,
            'require_label_for',
            base.requireLabelFor,
            path,
            ctx,
          ),
        );
      },
    );
  }
}
