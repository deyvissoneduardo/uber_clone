import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:uber_clone/layouts/Cadastro.dart';
import 'package:uber_clone/model/Usuario.dart';
import 'package:uber_clone/routes/Routes.dart';
import 'package:uber_clone/utils/FirebaseCollections.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  /** controladores **/
  TextEditingController _controllerEmail = TextEditingController();
  TextEditingController _controllerSenha = TextEditingController();

  /** icon carregando **/
  bool _carregando = false;

  /** instancias do firebase **/
  FirebaseAuth auth = FirebaseAuth.instance;
  Firestore banco = Firestore.instance;

  /** inicia mensagem de error **/
  String _mensaemError = "";

  /** valida os campos antes de salvar **/
  _validarCampos() {
    /** recupera dados dos campos **/
    String emial = _controllerEmail.text;
    String senha = _controllerSenha.text;

    /** verifica os campos **/
    if (emial.isNotEmpty && emial.contains("@")) {
      if (senha.isNotEmpty && senha.length > 6) {
        /** usa model usuario para logar **/
        Usuario usuario = Usuario();
        usuario.email = emial;
        usuario.senha = senha;
        /** logar o usuario **/
        _logarUsuario(usuario);
      } else {
        setState(() {
          _mensaemError = 'Senha deve conter no minino 7 caracteres';
        });
      }
    } else {
      setState(() {
        _mensaemError = 'Preencha com e-mail valido';
      });
    }
  }

  /** logar usuario **/
  _logarUsuario(Usuario usuario) {

    setState(() {
      _carregando = true;
    });

    auth
        .signInWithEmailAndPassword(
            email: usuario.email, password: usuario.senha)
        .then((firebaseUser) {
      _redirecionarPainelPorTipoUsuario(firebaseUser.user.uid);
    }).catchError((error) {
      _mensaemError =
          'Error ao autenticar, verifique os dados e tente novamente';
    });
  }

  /** redireciona por usuario **/
  _redirecionarPainelPorTipoUsuario(String idUsuario) async {
    /** realiza uma unica consulta **/
    DocumentSnapshot snapshot = await banco
        .collection(FirebaseCollection.COLECAO_USUARIO)
        .document(idUsuario)
        .get();

    /** recupera dados da consulta **/
    Map<String, dynamic> dados = snapshot.data;
    String tipoUsuario = dados[FirebaseCollection.DOC_TIPOUSUARIO];

    setState(() {
      _carregando = false;
    });

    /**chama proxima tela de acordo com usuario **/
    switch (tipoUsuario) {
      case 'motorista':
        Navigator.pushReplacementNamed(context, Rotas.ROTA_MOTORISTA);
        break;
      case 'passageiro':
        Navigator.pushReplacementNamed(context, Rotas.ROTA_PASSAGEIRO);
        break;
    }

    _verificaUsuarioLogado() async{

      FirebaseUser usuarioLogado = await auth.currentUser();
      if ( usuarioLogado != null){
        String idUsuario = usuarioLogado.uid;
        _redirecionarPainelPorTipoUsuario(idUsuario);
      }
    }

    @override
    void initState() {
      super.initState();
      _verificaUsuarioLogado();
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage('images/fundo.png'), fit: BoxFit.cover)),
        padding: EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(bottom: 32),
                  child: Image.asset(
                    "images/logo.png",
                    width: 200,
                    height: 150,
                  ),
                ),
                /** campo email **/
                TextField(
                  controller: _controllerEmail,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                      hintText: 'e-mail',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6))),
                ),
                /** campo senha **/
                TextField(
                  controller: _controllerSenha,
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                  style: TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                      hintText: 'Senha',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6))),
                ),
                /** btn entrar **/
                Padding(
                  padding: EdgeInsets.only(bottom: 10, top: 16),
                  child: RaisedButton(
                    child: Text(
                      'Entrar',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    color: Color(0xff1ebbd8),
                    padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                    onPressed: () {
                      _validarCampos();
                    },
                  ),
                ),
                /** nao tem conta **/
                Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Center(
                    child: GestureDetector(
                      child: Text(
                        'Não tem conta? Cadastre-se',
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.pushNamed(context, Rotas.ROTA_CADASTRO);
                      },
                    ),
                  ),
                ),
                /** carregando **/
                _carregando
                    ? Center(
                        child: CircularProgressIndicator(
                          backgroundColor: Colors.white,
                        ),
                      )
                    : Container(),
                /** msngs de error **/
                Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(
                    child: Text(
                      _mensaemError,
                      style: TextStyle(color: Colors.red, fontSize: 20),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
