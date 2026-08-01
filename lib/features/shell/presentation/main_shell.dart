import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/security/permission.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cnps_brand.dart';
import '../../auth/presentation/auth_controller.dart';

class MainShell extends ConsumerWidget {
  const MainShell({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;

  static const _items = <_NavItem>[
    _NavItem('Tableau de bord', Icons.dashboard_rounded, Permission.dashboardRead),
    _NavItem('Dossiers', Icons.folder_copy_outlined, Permission.dossierRead),
    _NavItem('Assurés / bénéficiaires', Icons.people_alt_outlined, Permission.personneRead),
    _NavItem('Documents / GED', Icons.description_outlined, Permission.documentRead),
    _NavItem('Workflow', Icons.account_tree_outlined, Permission.workflowRead),
    _NavItem('Liquidation', Icons.calculate_outlined, Permission.liquidationRead),
    _NavItem('Rejets', Icons.report_problem_outlined, Permission.rejetRead),
    _NavItem('Imports de titres', Icons.upload_file_outlined, Permission.importRead),
    _NavItem('Engagements', Icons.account_balance_outlined, Permission.engagementRead),
    _NavItem('Archives', Icons.inventory_2_outlined, Permission.archiveRead),
    _NavItem('Notifications', Icons.notifications_outlined, Permission.notificationRead),
    _NavItem('OCR / Intelligence artificielle', Icons.psychology_outlined, Permission.aiRead),
    _NavItem('Administration', Icons.admin_panel_settings_outlined, Permission.administrationRead),
    _NavItem('Audit', Icons.history_outlined, Permission.auditRead),
    _NavItem('Paramètres', Icons.settings_outlined, Permission.settingsRead),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final selected = navigationShell.currentIndex.clamp(0, _items.length - 1);

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 292,
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppTheme.navy, Color(0xFF0D1933)]),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                  child: const CnpsLogo(height: 50),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text('SIGP+', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
                      Spacer(),
                      _StatusDot(),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 14),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('GESTION INTÉGRÉE DES PENSIONS', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.15)),
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final active = index == selected;
                      final allowed = user?.can(item.permission) ?? false;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Material(
                          color: active ? AppTheme.cnpsBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                          child: ListTile(
                            dense: true,
                            minLeadingWidth: 24,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                            leading: Icon(item.icon, color: active ? Colors.white : Colors.white60, size: 21),
                            title: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: active ? Colors.white : Colors.white70, fontWeight: active ? FontWeight.w700 : FontWeight.w500, fontSize: 13)),
                            trailing: allowed ? null : const Icon(Icons.lock_outline, color: Colors.white24, size: 15),
                            onTap: () {
                              if (!allowed) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vous ne disposez pas de la permission nécessaire.')));
                                return;
                              }
                              navigationShell.goBranch(index, initialLocation: index == selected);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(backgroundColor: AppTheme.cnpsGreen, foregroundColor: Colors.white, child: Text(user?.initials ?? 'U', style: const TextStyle(fontWeight: FontWeight.w800))),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user?.fullName.isNotEmpty == true ? user!.fullName : 'Utilisateur', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(user?.role ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                      ),
                      IconButton(tooltip: 'Déconnexion', onPressed: () => ref.read(authControllerProvider.notifier).logout(), icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 20)),
                    ],
                  ),
                ),
                const CnpsColorBar(height: 4),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 74,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  child: Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_items[selected].label, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppTheme.navy)),
                          const SizedBox(height: 3),
                          Text(_breadcrumb(selected), style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                        ],
                      ),
                      const Spacer(),
                      const _SyncBadge(),
                      const SizedBox(width: 10),
                      IconButton(tooltip: 'Rechercher', onPressed: () {}, icon: const Icon(Icons.search_rounded)),
                      IconButton(tooltip: 'Notifications', onPressed: () {}, icon: const Badge(label: Text('4'), child: Icon(Icons.notifications_outlined))),
                      IconButton(tooltip: 'Aide', onPressed: () {}, icon: const Icon(Icons.help_outline_rounded)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(child: navigationShell),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _breadcrumb(int index) => index == 0 ? 'Accueil  /  Vue d’ensemble' : 'Accueil  /  ${_items[index].label}';
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.permission);
  final String label;
  final IconData icon;
  final Permission permission;
}

class _StatusDot extends StatelessWidget {
  const _StatusDot();
  @override
  Widget build(BuildContext context) => const Row(children: [CircleAvatar(radius: 4, backgroundColor: AppTheme.cnpsGreen), SizedBox(width: 7), Text('EN LIGNE', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w700))]);
}

class _SyncBadge extends StatelessWidget {
  const _SyncBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: const Color(0xFFEAF8F0), borderRadius: BorderRadius.circular(999)),
    child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.cloud_done_outlined, size: 17, color: AppTheme.cnpsGreen), SizedBox(width: 7), Text('Synchronisé', style: TextStyle(color: Color(0xFF178447), fontSize: 12, fontWeight: FontWeight.w700))]),
  );
}
