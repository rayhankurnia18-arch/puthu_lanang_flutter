import 'package:flutter/material.dart';
import '../main.dart';
class AppCard extends StatelessWidget { final Widget child; final EdgeInsets padding; const AppCard({super.key,required this.child,this.padding=const EdgeInsets.all(14)}); @override Widget build(BuildContext context)=>Container(padding:padding,decoration:BoxDecoration(color:brown2,border:Border.all(color:border),borderRadius:BorderRadius.circular(18),boxShadow:const [BoxShadow(color:Colors.black26,blurRadius:12,offset:Offset(0,6))]),child:child); }
