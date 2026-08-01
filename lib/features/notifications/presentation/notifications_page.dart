import 'package:flutter/material.dart';
import '../../common/presentation/remote_entity_page.dart';
class NotificationsPage extends StatelessWidget { const NotificationsPage({super.key}); @override Widget build(BuildContext context)=>const RemoteEntityPage(title:'Notifications',entity:'notifications',columns:{'titre': 'Titre', 'message': 'Message', 'type': 'Type', 'lue': 'Lue'},fields:['utilisateur_id', 'titre', 'message', 'type', 'lue'],readOnly:false); }
