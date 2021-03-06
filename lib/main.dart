import 'package:flutter/material.dart';
import 'package:uber_clone/layouts/Home.dart';
import 'package:uber_clone/routes/Routes.dart';
import 'package:uber_clone/themes/ThemePadrao.dart';

void main() {
  runApp(MaterialApp(
    title: 'Uber Clone',
    home: Home(),
    debugShowCheckedModeBanner: false,
    theme: temaPadrao,
    initialRoute: Rotas.ROTA_HOME,
    onGenerateRoute: Rotas.geraRotas,
  ));
}
