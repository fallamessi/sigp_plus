import 'package:flutter/material.dart';
import '../../common/presentation/remote_entity_page.dart';
class DocumentsPage extends StatelessWidget { const DocumentsPage({super.key}); @override Widget build(BuildContext context)=>const RemoteEntityPage(title:'Documents et GED',entity:'documents',columns:{'nom_fichier': 'Fichier', 'categorie': 'Catégorie', 'statut': 'Statut', 'score_ocr': 'OCR'},fields:['dossier_id', 'nom_fichier', 'categorie', 'chemin_stockage', 'mime_type', 'statut', 'score_ocr'],readOnly:false); }
