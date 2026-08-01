import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/dossiers/presentation/dossiers_page.dart';
import '../features/personnes/presentation/personnes_page.dart';
import '../features/documents/presentation/documents_page.dart';
import '../features/workflow/presentation/workflow_page.dart';
import '../features/liquidation/presentation/liquidation_page.dart';
import '../features/rejets/presentation/rejets_page.dart';
import '../features/imports/presentation/imports_page.dart';
import '../features/engagements/presentation/engagements_page.dart';
import '../features/archives/presentation/archives_page.dart';
import '../features/notifications/presentation/notifications_page.dart';
import '../features/administration/presentation/administration_page.dart';
import '../features/audit/presentation/audit_page.dart';
import '../features/ai/presentation/ai_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/shell/presentation/main_shell.dart';

final routerProvider=Provider<GoRouter>((ref){
 final auth=ref.watch(authControllerProvider);
 return GoRouter(initialLocation:'/login',redirect:(context,state){final atLogin=state.matchedLocation=='/login';if(!auth.authenticated)return atLogin?null:'/login';if(atLogin)return'/dashboard';return null;},routes:[
  GoRoute(path:'/login',builder:(_,__)=>const LoginPage()),
  StatefulShellRoute.indexedStack(builder:(context,state,shell)=>MainShell(navigationShell:shell),branches:[
   _b('/dashboard',const DashboardPage()),
    _b('/dossiers',const DossiersPage()),
    _b('/personnes',const PersonnesPage()),
    _b('/documents',const DocumentsPage()),
    _b('/workflow',const WorkflowPage()),
    _b('/liquidation',const LiquidationPage()),
    _b('/rejets',const RejetsPage()),
    _b('/imports',const ImportsPage()),
    _b('/engagements',const EngagementsPage()),
    _b('/archives',const ArchivesPage()),
    _b('/notifications',const NotificationsPage()),
    _b('/ai',const AiPage()),
    _b('/administration',const AdministrationPage()),
    _b('/audit',const AuditPage()),
    _b('/settings',const SettingsPage()),
  ])
 ]);
});
StatefulShellBranch _b(String path,Widget page)=>StatefulShellBranch(routes:[GoRoute(path:path,builder:(_,__)=>page)]);
