import 'package:flutter/material.dart';
import 'package:monekin/app/accounts/account_form.dart';
import 'package:monekin/app/accounts/all_accounts_page.dart';
import 'package:monekin/app/accounts/details/account_details.dart';
import 'package:monekin/core/database/services/account/account_service.dart';
import 'package:monekin/core/models/account/account.dart';
import 'package:monekin/core/models/date-utils/date_period_state.dart';
import 'package:monekin/core/presentation/app_colors.dart';
import 'package:monekin/core/presentation/widgets/card_with_header.dart';
import 'package:monekin/core/presentation/widgets/number_ui_formatters/currency_displayer.dart';
import 'package:monekin/core/presentation/widgets/tappable.dart';
import 'package:monekin/core/presentation/widgets/trending_value.dart';
import 'package:monekin/core/routes/route_utils.dart';
import 'package:monekin/i18n/generated/translations.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Maximum number of accounts shown inline on the dashboard.
const _maxAccountsToShow = 3;

/// A vertical list of the user's active accounts (up to [_maxAccountsToShow]),
/// replacing the old horizontally-scrollable account cards.
class DashboardAccountList extends StatelessWidget {
  const DashboardAccountList({super.key, required this.dateRangeService});

  final DatePeriodState dateRangeService;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);

    return StreamBuilder(
      stream: AccountService.instance.getAccounts(
        predicate: (acc, curr) => acc.closingDate.isNull(),
      ),
      builder: (context, snapshot) {
        final accounts = snapshot.data;
        final total = accounts?.length ?? 0;
        final visible = accounts?.take(_maxAccountsToShow).toList();

        return CardWithHeader(
          title: t.home.my_accounts,
          bodyPadding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          onHeaderActionTap: total > _maxAccountsToShow
              ? () => RouteUtils.pushRoute(const AllAccountsPage())
              : null,
          headerActionLabel: t.ui_actions.see_all,
          body: Column(
            children: [
              if (accounts == null)
                for (var i = 0; i < 3; i++) const _AccountRowSkeleton()
              else ...[
                for (final account in visible!)
                  _AccountRow(
                    account: account,
                    dateRangeService: dateRangeService,
                  ),
                _AddAccountRow(),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.account, required this.dateRangeService});

  final Account account;
  final DatePeriodState dateRangeService;

  @override
  Widget build(BuildContext context) {
    return Tappable(
      bgColor: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      onTap: () => RouteUtils.pushRoute(
        AccountDetailsPage(
          account: account,
          accountIconHeroTag: 'dashboard-page__account-icon-${account.id}',
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Hero(
              tag: 'dashboard-page__account-icon-${account.id}',
              child: account.displayIcon(context, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    account.type.title(context),
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: AppColors.of(context).textHint,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StreamBuilder(
                  initialData: 0.0,
                  stream: AccountService.instance.getAccountMoney(
                    account: account,
                  ),
                  builder: (context, snapshot) {
                    final amount = snapshot.data ?? 0.0;

                    return CurrencyDisplayer(
                      amountToConvert: amount,
                      currency: account.currency,
                      compactView: amount >= 10000000,
                      integerStyle: Theme.of(context).textTheme.titleSmall!
                          .copyWith(fontWeight: FontWeight.bold),
                    );
                  },
                ),
                StreamBuilder(
                  initialData: 0.0,
                  stream: AccountService.instance
                      .getAccountsBalanceRelativeChange(
                        accounts: [account],
                        startDate: dateRangeService.startDate,
                        endDate: dateRangeService.endDate,
                        convertToPreferredCurrency: false,
                      ),
                  builder: (context, snapshot) {
                    return TrendingValue(
                      percentage: snapshot.data ?? 0,
                      decimalDigits: 0,
                      fontSize: 12,
                      padding: EdgeInsets.zero,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddAccountRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final accent = Theme.of(context).colorScheme.primary;

    return Tappable(
      bgColor: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      onTap: () => RouteUtils.pushRoute(const AccountFormPage()),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accent.withOpacity(0.6), width: 1.4),
              ),
              child: Icon(Icons.add_rounded, color: accent, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              t.account.form.create,
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountRowSkeleton extends StatelessWidget {
  const _AccountRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer.zone(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            const Bone.circle(size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Bone.text(width: 120),
                  const SizedBox(height: 4),
                  Bone.text(width: 70),
                ],
              ),
            ),
            Bone.text(width: 60),
          ],
        ),
      ),
    );
  }
}
