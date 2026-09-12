import 'dart:io';
import 'dart:math' as math;

import 'cancel_token.dart';

typedef BulkProgressCallback = void Function(int completed, int total);

/// Runs tasks with bounded concurrency to avoid OOM and UI freezes.
class WorkerPool {
  WorkerPool._();

  static int recommendedConcurrency({int? itemCount}) {
    final cpus = Platform.numberOfProcessors;
    final base = cpus <= 2
        ? 2
        : cpus <= 4
            ? 3
            : cpus <= 6
                ? 4
                : 5;
    if (itemCount != null && itemCount < base) return math.max(1, itemCount);
    return base;
  }

  /// Processes [items] in batches of [concurrency] workers.
  static Future<List<R>> mapConcurrent<T, R>({
    required List<T> items,
    required Future<R> Function(T item, int index) worker,
    int? concurrency,
    CancelToken? cancelToken,
    BulkProgressCallback? onProgress,
  }) async {
    if (items.isEmpty) return [];

    final limit = concurrency ?? recommendedConcurrency(itemCount: items.length);
    final results = List<R?>.filled(items.length, null);
    var completed = 0;

    for (var start = 0; start < items.length; start += limit) {
      cancelToken?.throwIfCancelled();

      final end = math.min(start + limit, items.length);
      final indices = List.generate(end - start, (offset) => start + offset);

      final batchResults = await Future.wait(
        indices.map((index) => worker(items[index], index)),
      );

      for (var i = 0; i < indices.length; i++) {
        results[indices[i]] = batchResults[i];
      }

      completed = end;
      onProgress?.call(completed, items.length);
    }

    return results.cast<R>();
  }
}
