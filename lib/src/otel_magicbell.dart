// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_magicbell_suppression.dart';

const _tracerName = 'dartastic_otel_libs_magicbell';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

class MagicbellResult {
  /// Creates a result.
  const MagicbellResult({
    this.notificationId,
    this.broadcastId,
    this.recipientCount,
    this.categories,
    this.deliveredVia,
    this.unreadCount,
    this.seenCount,
    this.project,
    this.requestId,
    this.statusCode,
  });

  /// `notification.id`.
  final String? notificationId;

  /// `broadcast.id` when sent via a broadcast.
  final String? broadcastId;

  /// Recipient count on a broadcast.
  final int? recipientCount;

  /// Comma-joined `category` values — drives per-user preferences.
  final String? categories;

  /// Comma-joined channels actually delivered to (`in_app` / `email` /
  /// `web_push` / `mobile_push` / `sms` / `slack` / `teams`).
  final String? deliveredVia;

  /// Unread badge count for a user (returned by fetch endpoints).
  final int? unreadCount;

  /// Seen-but-not-read count.
  final int? seenCount;

  /// Project key (multi-project workspaces).
  final String? project;

  /// `X-Request-Id`.
  final String? requestId;

  final int? statusCode;
}

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class MagicbellCallResult<T> {
  /// Creates a call result.
  const MagicbellCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final MagicbellResult? result;
}

/// Wraps a MagicBell API call in a CLIENT span. [operation] is one of
/// `notifications.list`, `notifications.create`, `notifications.delete`,
/// `notifications.mark_read`, `notifications.mark_seen`,
/// `notifications.mark_unread`, `notifications.archive`,
/// `broadcasts.create`, `broadcasts.list`, `users.list`,
/// `users.create`, `users.update`, `users.delete`,
/// `users.notification_preferences.get`,
/// `users.notification_preferences.set`, `channels.list`,
/// `categories.list`, `webhooks.create`, `import.users`.
Future<T> tracedMagicbell<T>({
  required String operation,
  required Future<MagicbellCallResult<T>> Function() invoke,
  String? project,
}) async {
  if (magicbellInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'magicbell',
    'rpc.method': operation,
    'magicbell.operation': operation,
  };
  if (project != null) m['magicbell.project'] = project;

  final span = _tracer().startSpan(
    'magicbell $operation',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.notificationId != null) {
        extras.add(OTelAPI.attributeString(
          'magicbell.notification.id',
          r.result!.notificationId!,
        ));
      }
      if (r.result!.broadcastId != null) {
        extras.add(OTelAPI.attributeString(
          'magicbell.broadcast.id',
          r.result!.broadcastId!,
        ));
      }
      if (r.result!.recipientCount != null) {
        extras.add(OTelAPI.attributeInt(
          'magicbell.recipient_count',
          r.result!.recipientCount!,
        ));
      }
      if (r.result!.categories != null) {
        extras.add(OTelAPI.attributeString(
          'magicbell.categories',
          r.result!.categories!,
        ));
      }
      if (r.result!.deliveredVia != null) {
        extras.add(OTelAPI.attributeString(
          'magicbell.delivered_via',
          r.result!.deliveredVia!,
        ));
      }
      if (r.result!.unreadCount != null) {
        extras.add(OTelAPI.attributeInt(
          'magicbell.unread_count',
          r.result!.unreadCount!,
        ));
      }
      if (r.result!.seenCount != null) {
        extras.add(OTelAPI.attributeInt(
          'magicbell.seen_count',
          r.result!.seenCount!,
        ));
      }
      if (r.result!.project != null) {
        extras.add(OTelAPI.attributeString(
          'magicbell.project',
          r.result!.project!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTelAPI.attributeString(
          'magicbell.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTelAPI.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'MagicBell HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTelAPI.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
