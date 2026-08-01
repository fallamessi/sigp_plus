import 'package:flutter/material.dart';
import '../../common/presentation/remote_entity_page.dart';
class EngagementsPage extends StatelessWidget { const EngagementsPage({super.key}); @override Widget build(BuildContext context)=>const RemoteEntityPage(title:'Engagements irrévocables',entity:'engagements',columns:{'numero_titre': 'Titre', 'banque': 'Banque', 'montant_pret': 'Montant', 'statut': 'Statut'},fields:['dossier_id', 'numero_titre', 'banque', 'montant_pret', 'date_engagement', 'statut'],readOnly:false); }
