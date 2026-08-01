import 'package:flutter/material.dart';
import '../../common/presentation/remote_entity_page.dart';
class WorkflowPage extends StatelessWidget { const WorkflowPage({super.key}); @override Widget build(BuildContext context)=>const RemoteEntityPage(title:'Workflow de traitement',entity:'workflow',columns:{'dossier_id': 'Dossier', 'etape': 'Étape', 'statut': 'Statut', 'commentaire': 'Commentaire'},fields:['dossier_id', 'etape', 'statut', 'responsable_id', 'commentaire'],readOnly:false); }
