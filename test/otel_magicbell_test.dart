// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_magicbell/otel_magicbell.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_magicbell-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('notifications.create records categories + delivered_via', () async {
    await tracedMagicbell<String>(
      operation: 'notifications.create',
      project: 'main',
      invoke: () async => const MagicbellCallResult(
        value: 'ok',
        result: MagicbellResult(
          notificationId: 'n-1',
          categories: 'system,billing',
          deliveredVia: 'in_app,email',
          project: 'main',
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('magicbell notifications.create')!);
    expect(a['magicbell.notification.id'], 'n-1');
    expect(a['magicbell.categories'], 'system,billing');
    expect(a['magicbell.delivered_via'], 'in_app,email');
    expect(a['magicbell.project'], 'main');
  });

  test('broadcasts.create records recipient count', () async {
    await tracedMagicbell<String>(
      operation: 'broadcasts.create',
      invoke: () async => const MagicbellCallResult(
        value: 'ok',
        result: MagicbellResult(broadcastId: 'b-1', recipientCount: 500),
      ),
    );
    final a = attrsOf(spans.findSpanByName('magicbell broadcasts.create')!);
    expect(a['magicbell.broadcast.id'], 'b-1');
    expect(a['magicbell.recipient_count'], 500);
  });

  test('suppression skips spans', () async {
    await runWithoutMagicbellInstrumentationAsync(() async {
      await tracedMagicbell<String>(
        operation: 'notifications.list',
        invoke: () async => const MagicbellCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('magicbell '), isEmpty);
  });
}
