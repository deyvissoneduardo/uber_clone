import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uber_clone/model/Usuario.dart';
import 'package:uber_clone/utils/FirebaseCollections.dart';

class UsuarioFirebse {
  /** recupera usuario atual **/
  static Future<FirebaseUser> getUsuarioAtual() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    return await auth.currentUser();
  }

  /** recupera os dados do usuairo logado **/
  static Future<Usuario> getDadosUsuarioLogado() async {
    /** pega o id **/
    FirebaseUser firebaseUser = await getUsuarioAtual();
    String idUsuario = firebaseUser.uid;

    /** faz uma unica consulta **/
    Firestore banco = Firestore.instance;
    DocumentSnapshot snapshot = await banco
        .collection(FirebaseCollection.COLECAO_USUARIO)
        .document(idUsuario)
        .get();

    /** recupeda dados da colecao **/
    Map<String, dynamic> dados = snapshot.data;
    String tipoUsuario = dados[FirebaseCollection.DOC_TIPOUSUARIO];
    String email = dados[FirebaseCollection.DOC_EMIAL];
    String nome = dados[FirebaseCollection.DOC_NOME];

    /** retorna o usuario consultado pelo id **/
    Usuario usuario = Usuario();
    usuario.idUsuario = idUsuario;
    usuario.tipoUsuario = tipoUsuario;
    usuario.email = email;
    usuario.nome = nome;

    return usuario;
  }
}
