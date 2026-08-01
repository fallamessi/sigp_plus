import 'package:flutter/material.dart';
import '../../common/presentation/remote_entity_page.dart';
class PersonnesPage extends StatelessWidget { const PersonnesPage({super.key});
  @override Widget build(BuildContext context)=>
      const RemoteEntityPage(title:'Assurés et bénéficiaires',entity:'assures',
          columns:{'matricule': 'Matricule', 'nom_complet': 'Nom complet', 'telephone': 'Téléphone', 'email': 'E-mail'},fields:['matricule', 'nom_complet', 'date_naissance', 'telephone', 'email', 'adresse'],readOnly:false); }
