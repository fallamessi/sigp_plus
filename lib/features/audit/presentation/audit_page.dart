import 'package:flutter/material.dart';
import '../../common/presentation/remote_entity_page.dart';
class AuditPage extends StatelessWidget { const AuditPage({super.key}); @override Widget build(BuildContext context)=>const RemoteEntityPage(title:'Journal d’audit',entity:'audit',columns:{'created_at': 'Date', 'entite': 'Entité', 'action': 'Action', 'reference': 'Référence'},fields:[],readOnly:true); }
