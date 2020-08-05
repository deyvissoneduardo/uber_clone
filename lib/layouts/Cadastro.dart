import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:uber_clone/model/Usuario.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uber_clone/routes/Routes.dart';
import 'package:uber_clone/utils/FirebaseCollections.dart';

class Cadastro extends StatefulWidget {
  @override
  _CadastroState createState() => _CadastroState();
}

class _CadastroState extends State<Cadastro> {
  /** controladores **/
  TextEditingController _controllerNome = TextEditingController();
  TextEditingController _controllerEmail = TextEditingController();
  TextEditingController _controllerSenha = TextEditingController();

  /** instancias do firebase **/
  FirebaseAuth auth = FirebaseAuth.instance;
  Firestore banco = Firestore.instance;

  /** inicia mensagem de error **/
  String _mensaemError = "";

  /* bool tipo de cadastro
   * false = passageiro
   * true = motorista
   */
  bool _tipoUsuario = false;

  /** valida os campos antes de salvar **/
  _validarCampos() {
    /** recupera dados dos campos **/
    String nome = _controllerNome.text;
    String emial = _controllerEmail.text;
    String senha = _controllerSenha.text;

    /** verifica os campos **/
    if (nome.isNotEmpty) {
      if (emial.isNotEmpty && emial.contains("@")) {
        if (senha.isNotEmpty && senha.length > 6) {
          /** usa model usuario para salvar **/
          Usuario usuario = Usuario();
          usuario.nome = nome;
          usuario.email = emial;
          usuario.senha = senha;
          usuario.tipoUsuario = usuario.verificaTipoUsuario(_tipoUsuario);
          /** cadastra o usuario **/
          _cadastraUsuario(usuario);
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
    } else {
      setState(() {
        _mensaemError = 'Nome Obrigatorio';
      });
    }
  }

  /** metodo que salva usuario **/
  _cadastraUsuario(Usuario usuario) {
    auth
        .createUserWithEmailAndPassword(
            email: usuario.email, password: usuario.senha)
        .then((firebaseUser) {
      banco
          .collection(FirebaseCollection.COLECAO_USUARIO)
          .document(firebaseUser.user.uid)
          .setData(usuario.toMap());
      /** chama tela de acordo com tipo de usuario **/
      switch (usuario.tipoUsuario) {
        case 'motorista':
          Navigator.pushNamedAndRemoveUntil(
              context, Rotas.ROTA_MOTORISTA, (_) => false);
          break;
        case 'passageiro':
          Navigator.pushNamedAndRemoveUntil(
              context, Rotas.ROTA_PASSAGEIRO, (_) => false);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cadastro"),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                /** campo nome **/
                Padding(
                  padding: EdgeInsets.only(bottom: 3),
                  child: TextField(
                    controller: _controllerNome,
                    autofocus: true,
                    keyboardType: TextInputType.text,
                    style: TextStyle(fontSize: 20),
                    decoration: InputDecoration(
                        contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                        hintText: 'Nome',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6))),
                  ),
                ),
                /** campo email **/
                Padding(
                  padding: EdgeInsets.only(bottom: 3),
                  child: TextField(
                    controller: _controllerEmail,
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
                ),
                /** campo senha **/
                Padding(
                  padding: EdgeInsets.only(bottom: 3),
                  child: TextField(
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
                ),
                /** passageiro ou motorista **/
                Padding(
                    padding: EdgeInsets.only(bottom: 10, top: 20, right: 200),
                    child: Column(
                      children: <Widget>[
                        Text(
                          "Cadastra-se como:",
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        ),
                        Row(
                          children: <Widget>[
                            Text('Passageiro'),
                            Switch(
                                value: _tipoUsuario,
                                onChanged: (bool valor) {
                                  setState(() {
                                    _tipoUsuario = valor;
                                  });
                                }),
                            Text('Motorista')
                          ],
                        ),
                      ],
                    )),
                /** btn entrar **/
                Padding(
                  padding: EdgeInsets.only(bottom: 10, top: 16),
                  child: RaisedButton(
                    child: Text(
                      'Cadastra',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    color: Color(0xff1ebbd8),
                    padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                    onPressed: () {
                      /** valida os campos **/
                      _validarCampos();
                    },
                  ),
                ),
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
