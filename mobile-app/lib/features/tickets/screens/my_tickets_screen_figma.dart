import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/design_tokens.dart';
import '../models/ticket_model.dart';
import '../providers/ticket_provider.dart';
import '../widgets/ticket_card.dart';
import '../widgets/ticket_skeleton_loading.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  My Tickets screen — Figma nodes 2131:23613 (empty) & 2131:23655 (list).
//
//  Structure:
//    • "My ticket" header + 3-dot menu
//    • Carousel tab pane (Upcoming / Past / Cancelled) — reuses the same
//      horizontal chip pattern from HomeCategories
//    • TabBarView body:
//        – Empty state → "no tickets.png" + message
//        – Ticket list → grouped by month, TicketCard widgets
// ═══════════════════════════════════════════════════════════════════════════════

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  int _selectedTab = 0;

  static const _tabs = [
    {'name': 'Upcoming', 'iconPath': 'assets/icons/categories/upcoming.png'},
    {'name': 'Past', 'iconPath': 'assets/icons/categories/past.png'},
    {'name': 'Cancelled', 'iconPath': 'assets/icons/categories/cancelled.png'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketProvider>().fetchUserTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.bgLight,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My ticket',
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  // 3‑dot menu
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showOptionsMenu(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.more_vert,
                          size: 24,
                          color: isDark ? AppColors.white : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Category tab pane (carousel chips) ──────────────────────
            SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                itemCount: _tabs.length,
                itemBuilder: (context, index) {
                  final tab = _tabs[index];
                  final isSelected = _selectedTab == index;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedTab = index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.bg01 : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            tab['iconPath']!,
                            width: 18,
                            height: 18,
                            color: isSelected
                                ? AppColors.background
                                : (isDark ? AppColors.grey300 : Colors.grey[600]),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tab['name']!,
                            style: TextStyle(
                              fontFamily: kFontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? AppColors.background
                                  : (isDark
                                      ? AppColors.grey300
                                      : Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // ── Body ────────────────────────────────────────────────────
            Expanded(
              child: Consumer<TicketProvider>(
                builder: (context, ticketProvider, child) {
                  if (ticketProvider.isLoading) {
                    return const TicketListSkeletonLoading();
                  }

                  if (ticketProvider.error != null) {
                    return _ErrorState(
                      error: ticketProvider.error!,
                      onRetry: () => ticketProvider.refreshTickets(),
                    );
                  }

                  // Pick the ticket list for the selected tab
                  final List<Ticket> tickets;
                  switch (_selectedTab) {
                    case 0: // Upcoming
                      tickets = _upcomingTickets(ticketProvider);
                      break;
                    case 1: // Past
                      tickets = ticketProvider.completedTickets;
                      break;
                    case 2: // Cancelled
                      tickets = ticketProvider.cancelledTickets;
                      break;
                    default:
                      tickets = [];
                  }

                  if (tickets.isEmpty) {
                    return _EmptyState(tabName: _tabs[_selectedTab]['name']!);
                  }

                  return _TicketList(
                    tickets: tickets,
                    isDark: isDark,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pulls plain upcoming tickets from the provider's payment groups.
  List<Ticket> _upcomingTickets(TicketProvider provider) {
    final fromGroups = provider.upcomingPaymentGroups
        .expand((g) => g.tickets)
        .toList();
    if (fromGroups.isNotEmpty) return fromGroups;
    // Fallback: direct ticket list
    return provider.upcomingTickets;
  }

  void _showOptionsMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Refresh tickets',
                    style: TextStyle(fontFamily: kFontFamily)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<TicketProvider>().refreshTickets();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Ticket list (grouped by month)
// ═════════════════════════════════════════════════════════════════════════════

class _TicketList extends StatelessWidget {
  final List<Ticket> tickets;
  final bool isDark;

  const _TicketList({required this.tickets, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Group tickets by "Month Year"
    final grouped = <String, List<Ticket>>{};
    for (final t in tickets) {
      final key = _monthYear(t.eventStartDate);
      grouped.putIfAbsent(key, () => []).add(t);
    }

    final sections = grouped.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: sections.length,
      itemBuilder: (context, sectionIdx) {
        final section = sections[sectionIdx];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month header
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: Text(
                section.key,
                style: TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.white : AppColors.textPrimaryLight,
                ),
              ),
            ),
            // Ticket cards
            ...section.value.map(
              (ticket) => TicketCard(
                ticket: ticket,
                isDark: isDark,
                onTap: () {
                  context.push(
                    '/ticket/${ticket.id}',
                    extra: {'ticket': ticket},
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static String _monthYear(DateTime d) => '${_months[d.month - 1]} ${d.year}';
}

// ═════════════════════════════════════════════════════════════════════════════
//  Empty state — "No tickets yet!"  (Figma 2131:23613)
// ═════════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final String tabName;
  const _EmptyState({required this.tabName});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/no tickets.png',
              width: 88,
              height: 88,
            ),
            const SizedBox(height: 20),
            Text(
              'No tickets yet!',
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.white : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Make sure you're in the same account that\npurchased your tickets",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isDark ? AppColors.grey300 : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Error state
// ═════════════════════════════════════════════════════════════════════════════

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: isDark ? AppColors.grey300 : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 14,
                color: isDark ? AppColors.grey200 : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.dark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Retry',
                  style: TextStyle(fontFamily: kFontFamily)),
            ),
          ],
        ),
      ),
    );
  }
}
