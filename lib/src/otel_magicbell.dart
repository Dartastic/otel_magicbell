// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_magicbell_suppression.dart';

const _tracerName = 'dartastic_otel_libs_magicbell';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class MagicbellResult {
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

class MagicbellCallResult<T> {
  const MagicbellCallResult({required this.value, this.result});
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
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.notificationId != null) {
        extras.add(OTel.attributeString(
          'magicbell.notification.id',
          r.result!.notificationId!,
        ));
      }
      if (r.result!.broadcastId != null) {
        extras.add(OTel.attributeString(
          'magicbell.broadcast.id',
          r.result!.broadcastId!,
        ));
      }
      if (r.result!.recipientCount != null) {
        extras.add(OTel.attributeInt(
          'magicbell.recipient_count',
          r.result!.recipientCount!,
        ));
      }
      if (r.result!.categories != null) {
        extras.add(OTel.attributeString(
          'magicbell.categories',
          r.result!.categories!,
        ));
      }
      if (r.result!.deliveredVia != null) {
        extras.add(OTel.attributeString(
          'magicbell.delivered_via',
          r.result!.deliveredVia!,
        ));
      }
      if (r.result!.unreadCount != null) {
        extras.add(OTel.attributeInt(
          'magicbell.unread_count',
          r.result!.unreadCount!,
        ));
      }
      if (r.result!.seenCount != null) {
        extras.add(OTel.attributeInt(
          'magicbell.seen_count',
          r.result!.seenCount!,
        ));
      }
      if (r.result!.project != null) {
        extras.add(OTel.attributeString(
          'magicbell.project',
          r.result!.project!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTel.attributeString(
          'magicbell.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
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
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
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
