import 'package:flutter/material.dart';import 'router.dart';
class SigpApp extends StatelessWidget{const SigpApp({super.key});@override Widget build(BuildContext context)=>MaterialApp.router(title:'SIGP+',debugShowCheckedModeBanner:false,theme:ThemeData(colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xFF0B5A3C)),useMaterial3:true),routerConfig:router);}
