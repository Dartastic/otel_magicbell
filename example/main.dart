// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_magicbell/otel_magicbell.dart';

/// Traces MagicBell calls with OpenTelemetry.
///
/// `otel_magicbell` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each MagicBell call in
/// [tracedMagicbell]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'magicbell-example');

  // Wraps a MagicBell API call in a CLIENT span.
  final magicbellId = await tracedMagicbell<String>(
    operation: 'notifications.create',
    project: 'example',
    invoke: () async {
      // Make the MagicBell call here, then report what it returned.
      const id = 'magicbell_8f3a2c';
      return const MagicbellCallResult(
          value: id,
          result: MagicbellResult(
              notificationId: 'notification.id',
              broadcastId: 'broadcast.id',
              recipientCount: 3,
              categories: 'category',
              deliveredVia: 'in_app',
              unreadCount: 3,
              seenCount: 3,
              project: 'example',
              requestId: 'request_8f3a2c',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedMagicbell notifications.create returned $magicbellId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutMagicbellInstrumentationAsync.
  await runWithoutMagicbellInstrumentationAsync(
    () => tracedMagicbell<String>(
      operation: 'notifications.create',
      project: 'example',
      invoke: () async {
        const id = 'magicbell_8f3a2c';
        return const MagicbellCallResult(
            value: id,
            result: MagicbellResult(
                notificationId: 'notification.id',
                broadcastId: 'broadcast.id',
                recipientCount: 3,
                categories: 'category',
                deliveredVia: 'in_app',
                unreadCount: 3,
                seenCount: 3,
                project: 'example',
                requestId: 'request_8f3a2c',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
