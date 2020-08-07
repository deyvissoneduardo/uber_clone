import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uber_clone/model/Destino.dart';
import 'package:uber_clone/model/Usuario.dart';
import 'package:uber_clone/utils/FirebaseCollections.dart';

class Requisicao {
  /** atributos **/
  String _id;
  String _status;
  Usuario _passageiro;
  Usuario _motorista;
  Destino _destino;

  /** construtor **/
  Requisicao() {
    Firestore banco = Firestore.instance;
    DocumentReference reference =
        banco.collection(FirebaseCollection.COLECAO_REQUISICOES).document();
    this.id = reference.documentID;
  }

  /** cria ToMap para salvar no firebase **/
  Map<String, dynamic> toMap() {
    /** map passageiro **/
    Map<String, dynamic> dadosPassageiro = {
      "nome": this.passageiro.nome,
      "email": this.passageiro.email,
      "tipoUsuario": this.passageiro.tipoUsuario,
      "idUsuario": this.passageiro.idUsuario
    };

    /** map destino **/
    Map<String, dynamic> dadosDestino = {
      "rua": this.destino.rua,
      "numero": this.destino.numero,
      "bairro": this.destino.bairro,
      "cep": this.destino.cep,
      "latitute": this.destino.latitude,
      "longitude": this.destino.longitude,
    };

    /** map da requisicao **/
    Map<String, dynamic> dadosRequisicao = {
      "id": this.id,
      "status": this.status,
      "passageiro": dadosPassageiro,
      "motorista": null,
      "destino": dadosDestino
    };
    return dadosRequisicao;
  }

  /** gets e setrs **/
  Destino get destino => _destino;

  set destino(Destino value) {
    _destino = value;
  }

  Usuario get motorista => _motorista;

  set motorista(Usuario value) {
    _motorista = value;
  }

  Usuario get passageiro => _passageiro;

  set passageiro(Usuario value) {
    _passageiro = value;
  }

  String get status => _status;

  set status(String value) {
    _status = value;
  }

  String get id => _id;

  set id(String value) {
    _id = value;
  }
}
