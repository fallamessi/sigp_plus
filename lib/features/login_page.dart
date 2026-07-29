import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'shell_page.dart';

class LoginPage extends StatefulWidget { const LoginPage({super.key}); @override State<LoginPage> createState()=>_LoginPageState(); }
class _LoginPageState extends State<LoginPage> {
  final email=TextEditingController(), password=TextEditingController(); bool loading=false; String? error;
  Future<void> login() async { setState(()=>loading=true); try { await Supabase.instance.client.auth.signInWithPassword(email: email.text.trim(), password: password.text); if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder:(_)=>const ShellPage())); } catch(e){setState(()=>error=e.toString());} finally{if(mounted)setState(()=>loading=false);} }
  @override Widget build(BuildContext context)=>Scaffold(body:Row(children:[
    Expanded(child:Container(padding:const EdgeInsets.all(64),decoration:const BoxDecoration(gradient:LinearGradient(colors:[Color(0xFF063D2B),Color(0xFF0B6B4B)])),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[Icon(Icons.account_balance,size:72,color:Colors.white),SizedBox(height:24),Text('SIGP+',style:TextStyle(fontSize:52,fontWeight:FontWeight.w800,color:Colors.white)),Text('Système Intégré de Gestion des Pensions',style:TextStyle(fontSize:20,color:Colors.white70)),SizedBox(height:40),Text('Offline First • Audit • Workflow • GED • OCR / IA',style:TextStyle(color:Colors.white))]))),
    SizedBox(width:520,child:Padding(padding:const EdgeInsets.all(64),child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text('Connexion sécurisée',style:Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.bold)),const SizedBox(height:28),TextField(controller:email,decoration:const InputDecoration(labelText:'Adresse e-mail',prefixIcon:Icon(Icons.email_outlined))),const SizedBox(height:16),TextField(controller:password,obscureText:true,onSubmitted:(_)=>login(),decoration:const InputDecoration(labelText:'Mot de passe',prefixIcon:Icon(Icons.lock_outline))),if(error!=null)Padding(padding:const EdgeInsets.only(top:12),child:Text(error!,style:TextStyle(color:Theme.of(context).colorScheme.error))),const SizedBox(height:22),FilledButton.icon(onPressed:loading?null:login,icon:loading?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.login),label:const Padding(padding:EdgeInsets.all(14),child:Text('Se connecter')))])))
  ]));
}
