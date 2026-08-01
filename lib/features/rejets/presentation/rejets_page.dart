import 'package:flutter/material.dart';
import '../../common/presentation/remote_entity_page.dart';
class RejetsPage extends StatelessWidget { const RejetsPage({super.key}); @override Widget build(BuildContext context)=>const RemoteEntityPage(title:'Rejets et régularisations',entity:'rejets',columns:{'dossier_id': 'Dossier', 'categorie': 'Catégorie', 'motif': 'Motif', 'statut': 'Statut'},fields:['dossier_id', 'categorie', 'motif', 'statut', 'traite_par'],readOnly:false); }
