import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/product_ids.dart';
import '../../shared/providers/purchase_provider.dart';
import '../../shared/services/entitlement_service.dart';

class ProScreen extends ConsumerStatefulWidget {
  const ProScreen({super.key});

  @override
  ConsumerState<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends ConsumerState<ProScreen> {
  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final entitlementsAsync = ref.watch(entitlementsProvider);
    final purchaseState = ref.watch(purchaseUiProvider);
    final isPro = entitlementsAsync.valueOrNull?.isPro ?? false;

    ref.listen(purchaseUiProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        _showSnack(next.errorMessage!);
      }
      if (next.successMessage != null &&
          next.successMessage != previous?.successMessage) {
        _showSnack(next.successMessage!);
      }
    });

    final lifetime = purchaseState.productById(ProductIds.proLifetime);
    final monthly = purchaseState.productById(ProductIds.proMonthly);
    final isBusy = purchaseState.isPurchasing || purchaseState.isRestoring;

    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade to Pro')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(Icons.workspace_premium, size: 64, color: colors.tertiary),
          const SizedBox(height: 16),
          Text(
            'PDF & Image Toolbox Pro',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isPro
                ? 'You have Pro access on this device.'
                : 'Unlock the full power of offline file processing.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          if (isPro) ...[
            const SizedBox(height: 16),
            Card(
              color: colors.primaryContainer,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.verified_outlined),
                    SizedBox(width: 12),
                    Expanded(child: Text('Pro is active on this device.')),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const _BenefitItem(icon: Icons.block, text: 'Remove all ads'),
          const _BenefitItem(
            icon: Icons.layers,
            text: 'Unlimited batch processing',
          ),
          const _BenefitItem(
            icon: Icons.high_quality,
            text: 'Premium compression quality',
          ),
          const _BenefitItem(
            icon: Icons.all_inclusive,
            text: 'Unlimited daily operations',
          ),
          const SizedBox(height: 32),
          if (purchaseState.isLoadingProducts)
            const Center(child: CircularProgressIndicator())
          else if (!purchaseState.storeAvailable)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Purchases are unavailable on this device right now. '
                  'Configure products in Google Play Console to enable billing.',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
            )
          else ...[
            FilledButton(
              onPressed: isPro || isBusy || lifetime == null
                  ? null
                  : () => ref
                      .read(purchaseUiProvider.notifier)
                      .purchase(ProductIds.proLifetime),
              child: Text(
                lifetime == null
                    ? 'Lifetime Pro unavailable'
                    : 'Get Lifetime Pro${lifetime.price.isNotEmpty ? ' — ${lifetime.price}' : ''}',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: isPro || isBusy || monthly == null
                  ? null
                  : () => ref
                      .read(purchaseUiProvider.notifier)
                      .purchase(ProductIds.proMonthly),
              child: Text(
                monthly == null
                    ? 'Monthly subscription unavailable'
                    : 'Monthly Pro${monthly.price.isNotEmpty ? ' — ${monthly.price}' : ''}',
              ),
            ),
          ],
          const SizedBox(height: 8),
          TextButton(
            onPressed: isBusy
                ? null
                : () => ref.read(purchaseUiProvider.notifier).restore(),
            child: purchaseState.isRestoring
                ? const Text('Restoring purchases...')
                : const Text('Restore Purchases'),
          ),
          const SizedBox(height: 16),
          Text(
            'Purchases are processed by Google Play. Pro access is granted after '
            'Google Play validates the purchase on this device.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 12),
            Text(
              'Product IDs: ${ProductIds.proLifetime}, ${ProductIds.proMonthly}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
