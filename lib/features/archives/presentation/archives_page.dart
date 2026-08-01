import 'package:flutter/material.dart';
import '../../common/presentation/remote_entity_page.dart';
class ArchivesPage extends StatelessWidget { const ArchivesPage({super.key}); @override Widget build(BuildContext context)=>const RemoteEntityPage(title:'Archives',entity:'archives',columns:{'dossier_id': 'Dossier', 'emplacement': 'Emplacement', 'date_archivage': 'Date', 'etat': 'État'},fields:['dossier_id', 'emplacement', 'date_archivage', 'etat', 'archive_par'],readOnly:false); }
