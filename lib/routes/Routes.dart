import 'dart:core';

import 'package:flutter/material.dart';
import 'package:uber_clone/layouts/Cadastro.dart';
import 'package:uber_clone/layouts/Home.dart';

class Rotas {
  /// contanstes de rotas **/
  static const String ROTA_HOME = "/";
  static const String ROTA_CADASTRO = "/cadastro";

  static Route<dynamic> geraRotas(RouteSettings settings) {
    switch (settings.name) {
      case ROTA_HOME:
        return MaterialPageRoute(builder: (_) => Home());
      case ROTA_CADASTRO:
        return MaterialPageRoute(builder: (_) => Cadastro());
      default:
        _erroRota();
    }
  }

  static Route<dynamic> _erroRota() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Tela não encontrada!"),
        ),
        body: Center(
          child: Text("Tela não encontrada!"),
        ),
      );
    });
  }
}
