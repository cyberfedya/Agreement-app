import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_search_bar.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/skeletons.dart';
import 'package:app/features/deal/domain/deal_history.dart';
import 'package:app/features/deal/presentation/widgets/deal_card.dart';
import 'package:app/features/deal/providers/deal_history_provider.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/shared/animation/entrance.dart';

enum _HistoryFilter { all, draft, waiting, signed, cancelled }

class DealHistoryPage extends StatefulWidget {
  const DealHistoryPage({super.key});

  @override
  State<DealHistoryPage> createState() => _DealHistoryPageState();
}

class _DealHistoryPageState extends State<DealHistoryPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _query = '';
  _HistoryFilter _filter = _HistoryFilter.all;

  @override
  void initState() {
    super.initState();
    final provider = context.read<DealHistoryProvider>();
    Future.microtask(provider.load);
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels < _scrollController.position.maxScrollExtent - 200) return;
    context.read<DealHistoryProvider>().loadMore();
  }

  bool _matchesFilter(DealSummary deal) => switch (_filter) {
    _HistoryFilter.all => true,
    _HistoryFilter.draft => deal.status == DealHistoryStatus.draft,
    _HistoryFilter.waiting =>
      deal.status == DealHistoryStatus.waitingSecondParty || deal.status == DealHistoryStatus.waitingYourSignature,
    _HistoryFilter.signed => deal.status == DealHistoryStatus.signed,
    _HistoryFilter.cancelled => deal.status == DealHistoryStatus.cancelled,
  };

  List<DealSummary> _filtered(List<DealSummary> deals) {
    return deals.where((deal) {
      if (!_matchesFilter(deal)) return false;
      if (_query.isEmpty) return true;
      return deal.templateTitle.toLowerCase().contains(_query) ||
          (deal.secondPartyName?.toLowerCase().contains(_query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: CenteredContent(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Insets.x20, Insets.x8, Insets.x20, 0),
              child: AppSearchBar(controller: _searchController, hint: l10n.historySearchHint, autofocus: false),
            ),
            const SizedBox(height: Insets.x12),
            _FilterRow(selected: _filter, onChanged: (filter) => setState(() => _filter = filter)),
            const SizedBox(height: Insets.x4),
            Expanded(
              child: Consumer<DealHistoryProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.deals.isEmpty) {
                    return const SkeletonList();
                  }
                  if (provider.errorMessage != null && provider.deals.isEmpty) {
                    return AppErrorView(message: provider.errorMessage!, onRetry: provider.refresh);
                  }
                  if (provider.deals.isEmpty) {
                    return AppEmptyView(
                      title: l10n.historyEmptyTitle,
                      message: l10n.historyEmptyMessage,
                      action: FilledButton(
                        onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false),
                        child: Text(l10n.historyCreateDeal),
                      ),
                    );
                  }

                  final deals = _filtered(provider.deals);
                  if (deals.isEmpty) {
                    return AppEmptyView(message: l10n.historyNothingFoundMessage);
                  }

                  return RefreshIndicator(
                    onRefresh: provider.refresh,
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(Insets.x20, Insets.x12, Insets.x20, Insets.x32),
                      itemCount: deals.length + (provider.isLoadingMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: Insets.x12),
                      itemBuilder: (context, index) {
                        if (index >= deals.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: Insets.x16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final deal = deals[index];
                        return DealCard(
                          deal: deal,
                          onTap: () => Navigator.of(context).pushNamed(AppRoutes.dealHistoryDetail, arguments: deal.id),
                        ).animateEntranceStaggered(index, step: const Duration(milliseconds: 30));
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.selected, required this.onChanged});

  final _HistoryFilter selected;
  final ValueChanged<_HistoryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filters = <(_HistoryFilter, String)>[
      (_HistoryFilter.all, l10n.historyFilterAll),
      (_HistoryFilter.draft, l10n.historyFilterDraft),
      (_HistoryFilter.waiting, l10n.historyFilterWaiting),
      (_HistoryFilter.signed, l10n.historyFilterSigned),
      (_HistoryFilter.cancelled, l10n.historyFilterCancelled),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Insets.x20),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: Insets.x8),
        itemBuilder: (context, index) {
          final (filter, label) = filters[index];
          return FilterChip(
            label: Text(label),
            selected: selected == filter,
            showCheckmark: false,
            onSelected: (_) => onChanged(filter),
          );
        },
      ),
    );
  }
}
