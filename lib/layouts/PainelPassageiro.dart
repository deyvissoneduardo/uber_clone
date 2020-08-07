import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:uber_clone/model/Destino.dart';
import 'package:uber_clone/model/Requisicao.dart';
import 'package:uber_clone/model/Usuario.dart';
import 'package:uber_clone/routes/Routes.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:uber_clone/utils/FirebaseCollections.dart';
import 'package:uber_clone/utils/StatusRequisicao.dart';
import 'package:uber_clone/utils/UsuarioFirebase.dart';

class PainelPassageiro extends StatefulWidget {
  @override
  _PainelPassageiroState createState() => _PainelPassageiroState();
}

class _PainelPassageiroState extends State<PainelPassageiro> {
  /** carrega id da requisicao da viagem **/
  String _idRequisicao;

  /** controladores de texto **/
  TextEditingController _controllerDestino = TextEditingController();

  /** controlador do mapa **/
  Completer<GoogleMapController> _controllerMap = Completer();

  /** controlador de exibir elementos na tela **/
  bool _exibirCaixaDeEndereco = true;
  String _textoBotao = 'Chamar Uber';
  Color _corBotao = Color(0xff1ebbd8);
  Function _functionBotao;

  /** lista de opcoes **/
  List<String> itensMenu = ['config', 'Deslogar'];

  /** inicia marcadores **/
  Set<Marker> _marcadores = {};
  static const String _idMarkerPassageiro = 'marcador-passagiero';

  /** inica camera do mapa **/
  CameraPosition _cameraPosition =
      CameraPosition(target: LatLng(-15.904634, -47.773108), zoom: 19);

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

  /** metodo que cria o mapa **/
  _onMapCreated(GoogleMapController controller) {
    _controllerMap.complete(controller);
  }

  /** recupera ultima localizacao valida **/
  _recuperaUltimaLocalizacaoConhecida() async {
    Position position = await Geolocator()
        .getLastKnownPosition(desiredAccuracy: LocationAccuracy.high);

    /** verfica se a localizacao e valida **/
    setState(() {
      if (position != null) {
        _exibirMarcadorPassageiro(position);
        _cameraPosition = CameraPosition(
            target: LatLng(position.latitude, position.longitude), zoom: 19);
      }
      _movimentaCamera(_cameraPosition);
    });
  }

  /** movimenta camera de acordo com a posicao **/
  _movimentaCamera(CameraPosition cameraPosition) async {
    GoogleMapController googleMapController = await _controllerMap.future;
    googleMapController
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  /** monitora posicao do usuario em movimento **/
  _adicionarListernerLocalizacao() {
    var geolocator = Geolocator();
    var locationOptions =
        LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 10);

    /** retorna a posicao atual **/
    geolocator.getPositionStream(locationOptions).listen((Position position) {
      _exibirMarcadorPassageiro(position);
      _cameraPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude), zoom: 19);
      _movimentaCamera(_cameraPosition);
    });
  }

  /** marca local do passageiro **/
  _exibirMarcadorPassageiro(Position local) async {
    /** recupera pixel do dispositivo **/
    double pixelRadio = MediaQuery.of(context).devicePixelRatio;

    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(devicePixelRatio: pixelRadio),
            'images/passageiro.png')
        .then((BitmapDescriptor icone) {
      Marker marcadorPassageiro = Marker(
          markerId: MarkerId(_idMarkerPassageiro),
          position: LatLng(local.latitude, local.longitude),
          infoWindow: InfoWindow(title: 'Meu Local'),
          icon: icone);
      setState(() {
        _marcadores.add(marcadorPassageiro);
      });
    });
  }

  /** faz a requisicao da viagem **/
  _chamarUber() async {
    /** recupera valor **/
    String enderecoDestino = _controllerDestino.text;

    if (enderecoDestino.isNotEmpty) {
      List<Placemark> listaEndereco =
          await Geolocator().placemarkFromAddress(enderecoDestino);
      if (listaEndereco != null && listaEndereco.length > 0) {
        Placemark endereco = listaEndereco[0];
        /** pega model Destino para configura endereco **/
        Destino destino = Destino();
        destino.cidade = endereco.administrativeArea;
        destino.cep = endereco.postalCode;
        destino.bairro = endereco.subLocality;
        destino.rua = endereco.thoroughfare;
        destino.numero = endereco.subThoroughfare;
        destino.latitude = endereco.position.latitude;
        destino.longitude = endereco.position.longitude;

        /** monta mensagem de confirmacao **/
        String enderecoConfirmacao;
        enderecoConfirmacao = '\n Cidade: ' + destino.cidade;
        enderecoConfirmacao += "\n Rua: " + destino.rua + ', ' + destino.numero;
        enderecoConfirmacao += '\n Bairro: ' + destino.bairro;
        enderecoConfirmacao += '\n Cep: ' + destino.cep;

        /** exibe confirmacao **/
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Confirmação de Endereço'),
                content: Text(enderecoConfirmacao),
                contentPadding: EdgeInsets.all(16),
                actions: <Widget>[
                  /** cancelar viagem **/
                  FlatButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.red),
                      )),
                  /** confirma viagem **/
                  FlatButton(
                      onPressed: () {
                        /** salvar requisicao **/
                        _salvarRequisicao(destino);
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Confirmar',
                        style: TextStyle(color: Colors.green),
                      ))
                ],
              );
            });
      }
    }
  }

  /** metodo de cancelar viagem **/
  _cancelarUber() async {
    /** pega id usuario atual **/
    FirebaseUser firebaseUser = await UsuarioFirebse.getUsuarioAtual();
    banco
        .collection(FirebaseCollection.COLECAO_REQUISICOES)
        .document(_idRequisicao)
        .updateData({
      FirebaseCollection.DOC_STATUS: StatusRequisicao.CANCELADA
    }).then((_) {
      /** remove a ultima requisicao ativa **/
      banco
          .collection(FirebaseCollection.COLECAO_REQUISICAO_ATIVA)
          .document(firebaseUser.uid)
          .delete();
    });
  }

  /** salva dados da requisicao no firebase **/
  _salvarRequisicao(Destino destino) async {
    /** pega dados do usuario **/
    Usuario passageiro = await UsuarioFirebse.getDadosUsuarioLogado();

    /** monta requisicao de acordo com a model **/
    Requisicao requisicao = Requisicao();
    requisicao.destino = destino;
    requisicao.passageiro = passageiro;
    requisicao.status = StatusRequisicao.AGUARDANDO;

    /** salva no requisicao **/
    banco
        .collection(FirebaseCollection.COLECAO_REQUISICOES)
        .document(requisicao.id)
        .setData(requisicao.toMap());

    /** salva requisicao ativa **/
    Map<String, dynamic> dadosRequisicaoAtiva = {};
    dadosRequisicaoAtiva['id_requisicao'] = requisicao.id;
    dadosRequisicaoAtiva['id_usuario'] = passageiro.idUsuario;
    dadosRequisicaoAtiva['status'] = StatusRequisicao.AGUARDANDO;

    banco
        .collection(FirebaseCollection.COLECAO_REQUISICAO_ATIVA)
        .document(passageiro.idUsuario)
        .setData(dadosRequisicaoAtiva);
  }

  /** metodos que definem exibicao **/
  _alterarBotaoPrincipal(String text, Color cor, Function funcao) {
    setState(() {
      _textoBotao = text;
      _corBotao = cor;
      _functionBotao = funcao;
    });
  }

  _statusUberNaoChamado() {
    _exibirCaixaDeEndereco = true;
    _alterarBotaoPrincipal('Chamar Uber', Color(0xff1ebbd8), () {
      _chamarUber();
    });
  }

  /** metotos de status de viagem **/
  _statusAguardando() {
    _exibirCaixaDeEndereco = false;
    _alterarBotaoPrincipal('Cancelar', Colors.red, () {
      _cancelarUber();
    });
  }

  /** monitora requisicoes da viagem **/
  _adicionarListernerParaRequisicao() async {
    FirebaseUser firebaseUser = await UsuarioFirebse.getUsuarioAtual();

    await banco
        .collection(FirebaseCollection.COLECAO_REQUISICAO_ATIVA)
        .document(firebaseUser.uid)
        .snapshots()
        .listen((snapshots) {
      /** altera interface de acordo com a requisicao **/
      if (snapshots.data != null) {
        Map<String, dynamic> dados = snapshots.data;
        String status = dados[FirebaseCollection.DOC_STATUS];
        _idRequisicao = dados[FirebaseCollection.DOC_ID_REQUISICAO];

        switch (status) {
          case StatusRequisicao.AGUARDANDO:
            _statusAguardando();
            break;
          case StatusRequisicao.A_CAMINHO:
            break;
          case StatusRequisicao.VIAGEM:
            break;
          case StatusRequisicao.FINALIZADA:
            break;
        }
      } else {
        _statusUberNaoChamado();
      }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _recuperaUltimaLocalizacaoConhecida();
    _adicionarListernerLocalizacao();
    _adicionarListernerParaRequisicao();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Painel Passageiro"),
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
      body: Container(
          child: Stack(
        children: <Widget>[
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _cameraPosition,
            onMapCreated: _onMapCreated,
            // myLocationEnabled: true,
            markers: _marcadores,
            myLocationButtonEnabled: false,
          ),
          /** monta exibicao de acordo com status **/
          Visibility(
              visible: _exibirCaixaDeEndereco,
              child: Stack(
                children: <Widget>[
                  /** campo meu local **/
                  Positioned(
                    top: 0,
                    right: 0,
                    left: 0,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(3),
                            color: Colors.white),
                        child: TextField(
                          readOnly: true,
                          decoration: InputDecoration(
                              icon: Container(
                                margin: EdgeInsets.only(left: 20, bottom: 15),
                                width: 10,
                                height: 10,
                                child: Icon(
                                  Icons.location_on,
                                  color: Colors.green,
                                ),
                              ),
                              hintText: 'Meu Local',
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.only(left: 15, top: 0)),
                        ),
                      ),
                    ),
                  ),
                  /** campo endereco **/
                  Positioned(
                    top: 55,
                    right: 0,
                    left: 0,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(3),
                            color: Colors.white),
                        child: TextField(
                          controller: _controllerDestino,
                          decoration: InputDecoration(
                              icon: Container(
                                margin: EdgeInsets.only(left: 20, bottom: 15),
                                width: 10,
                                height: 10,
                                child: Icon(
                                  Icons.local_taxi,
                                  color: Colors.black87,
                                ),
                              ),
                              hintText: 'Digite o destino',
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.only(left: 15, top: 0)),
                        ),
                      ),
                    ),
                  )
                ],
              )),
          /** btn chama uber **/
          Positioned(
              right: 0,
              left: 0,
              bottom: 0,
              child: Padding(
                padding: Platform.isIOS
                    ? EdgeInsets.fromLTRB(20, 10, 20, 25)
                    : EdgeInsets.all(10),
                child: RaisedButton(
                    child: Text(
                      _textoBotao,
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    color: _corBotao,
                    padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                    onPressed: _functionBotao),
              )),
        ],
      )),
    );
  }
}
