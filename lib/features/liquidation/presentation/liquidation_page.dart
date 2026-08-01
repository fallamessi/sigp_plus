import 'package:flutter/material.dart';
import '../../common/presentation/remote_entity_page.dart';
class LiquidationPage extends StatelessWidget { const LiquidationPage({super.key}); @override Widget build(BuildContext context)=>const RemoteEntityPage(title:'Liquidations',entity:'liquidations',columns:{'numero_titre': 'N° titre', 'montant_mensuel': 'Montant', 'date_effet': 'Date effet', 'statut': 'Statut'},fields:['dossier_id', 'numero_titre', 'montant_mensuel', 'date_effet', 'statut', 'calcule_par'],readOnly:false); }
