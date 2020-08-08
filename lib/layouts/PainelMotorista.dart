import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uber_clone/routes/Routes.dart';
import 'package:uber_clone/utils/FirebaseCollections.dart';
import 'package:uber_clone/utils/StatusRequisicao.dart';

class PainelMotorista extends StatefulWidget {
  @override
  _PainelMotoristaState createState() => _PainelMotoristaState();
}

class _PainelMotoristaState extends State<PainelMotorista> {
  /** controlador stream **/
  final _controller = StreamController<QuerySnapshot>.broadcast();

  /** lista de opcoes **/
  List<String> itensMenu = ['config', 'Deslogar'];

  /** instancias do firebase **/
  FirebaseAuth auth = FirebaseAuth.instance;
  Firestore banco = Firestore.instance;

  /** intens de menu **/
  _escolhaMenuItem(String escolha) {
    switch (escolha) {
      case 'Deslogar':
        _deslogarUsuario();
        break;
    }
  }

  _deslogarUsuario() async {
    await auth.signOut();
    Navigator.pushReplacementNamed(context, Rotas.ROTA_HOME);
  }

  /** metodo que monitora requisicoes de passageiros **/
  Stream<QuerySnapshot> _adicionarListernerRequisicoes() {
    /** consulta requisoes somente com status aguardando **/
    final strem = banco
        .collection(FirebaseCollection.COLECAO_REQUISICOES)
        .where(FirebaseCollection.DOC_STATUS,
            isEqualTo: StatusRequisicao.AGUARDANDO)
        .snapshots();

    strem.listen((dados) {
      _controller.add(dados);
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _adicionarListernerRequisicoes();
  }

  @override
  Widget build(BuildContext context) {
    /** mensagens de inicio **/
    var mensagemCarregando = Center(
      child: Column(
        children: <Widget>[
          Text("Carregando Viagens"),
          CircularProgressIndicator()
        ],
      ),
    );

    var mensagemDados = Center(
      child: Text(
        "Voçẽ não tem viagens",
        style: TextStyle(
            fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text("Painel Motorista"),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: _escolhaMenuItem,
            itemBuilder: (context) {
              return itensMenu.map((String item) {
                return PopupMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList();
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _controller.stream,
        builder: (context, snapshot) {
          /** testa conexao **/
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return mensagemCarregando;
              break;
            case ConnectionState.active:
            case ConnectionState.done:
              if (snapshot.hasError) {
                return Text('Error ao carrega os dados');
              } else {
                QuerySnapshot querySnapshot = snapshot.data;
                if (querySnapshot.documents.length == 0) {
                  return mensagemDados;
                }else{
                  return ListView.separated(
                      itemCount: querySnapshot.documents.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 2,
                        color: Colors.grey,
                      ),
                    itemBuilder: (context, index){
                        List<DocumentSnapshot> requisicoes = querySnapshot.documents.toList();
                        DocumentSnapshot item = requisicoes[index];

                        String idRequisicao = item['id'];
                        String nomePassageiro = item[FirebaseCollection.NO_PASSAGEIRO][FirebaseCollection.DOC_NOME];
                        String rua  = item[FirebaseCollection.NO_DESTINO][FirebaseCollection.DOC_RUA];
                        String numero = item[FirebaseCollection.NO_DESTINO][FirebaseCollection.DOC_NUMERO];
                        String cep = item[FirebaseCollection.NO_DESTINO][FirebaseCollection.DOC_CEP];

                        return ListTile(
                          title: Text(nomePassageiro),
                          subtitle:  Text("Destino: $cep, \n Rua: $rua,\n Número $numero"),
                          onTap: (){
                            Navigator.pushNamed(context,
                                Rotas.ROTA_CORRIDA,
                            arguments: idRequisicao);
                          },
                        );
                    }
                  );
                }
              }
              break;
          }
          return null;
        },
      ),
    );
  }
}
