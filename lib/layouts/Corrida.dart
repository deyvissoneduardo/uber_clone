import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uber_clone/model/Usuario.dart';
import 'package:uber_clone/utils/FirebaseCollections.dart';
import 'package:uber_clone/utils/StatusRequisicao.dart';
import 'package:uber_clone/utils/UsuarioFirebase.dart';

class Corrida extends StatefulWidget {
  /** rebece o idRequisicao por paramentro de motorista para corrida **/
  String idRequisicao;

  Corrida(this.idRequisicao);

  @override
  _CorridaState createState() => _CorridaState();
}

class _CorridaState extends State<Corrida> {
  String _idRequisicao;
  Map<String, dynamic> _dadosRequisicao;

  /** configura local do motorista **/
  Position _localMotorista;

  /** instacia firebase **/
  Firestore _banco = Firestore.instance;

  /** inicia marcadores **/
  Set<Marker> _marcadores = {};
  static const String _idMarkerMotorista = 'marcador-motorista';

  /** controlador de exibir elementos na tela **/
  String _textoBotao = 'Aceitar Corrida';
  Color _corBotao = Color(0xff1ebbd8);
  Function _functionBotao;

  /** inica camera do mapa **/
  CameraPosition _cameraPosition =
      CameraPosition(target: LatLng(-15.904634, -47.773108), zoom: 19);

  /** controlador do mapa **/
  Completer<GoogleMapController> _controllerMap = Completer();

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
      // _movimentaCamera(_cameraPosition);
      _localMotorista = position;
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
      //  _movimentaCamera(_cameraPosition);
      setState(() {
        _localMotorista = position;
      });
    });
  }

  /** marca local do passageiro **/
  _exibirMarcadorPassageiro(Position local) async {
    /** recupera pixel do dispositivo **/
    double pixelRadio = MediaQuery.of(context).devicePixelRatio;

    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(devicePixelRatio: pixelRadio),
            'images/motorista.png')
        .then((BitmapDescriptor icone) {
      Marker marcadorPassageiro = Marker(
          markerId: MarkerId(_idMarkerMotorista),
          position: LatLng(local.latitude, local.longitude),
          infoWindow: InfoWindow(title: 'Meu Local'),
          icon: icone);
      setState(() {
        _marcadores.add(marcadorPassageiro);
      });
    });
  }

  /** metodos que definem exibicao **/
  _alterarBotaoPrincipal(String text, Color cor, Function funcao) {
    setState(() {
      _textoBotao = text;
      _corBotao = cor;
      _functionBotao = funcao;
    });
  }

  /** recupera status da requisicao **/
  _recuperaRequisicao() async {
    String idRequisicao = widget.idRequisicao;

    /** realiza uma unica consulta **/
    DocumentSnapshot documentSnapshot = await _banco
        .collection(FirebaseCollection.COLECAO_REQUISICOES)
        .document(idRequisicao)
        .get();

    _dadosRequisicao = documentSnapshot.data;
    _adicionarListenerRequisicao();
  }

  /** controla status da requisicao **/
  _adicionarListenerRequisicao() async {
    _idRequisicao = _dadosRequisicao[FirebaseCollection.DOC_ID_DESTINO];
    await _banco
        .collection(FirebaseCollection.COLECAO_REQUISICOES)
        .document(_idRequisicao)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.data != null) {
        Map<String, dynamic> dados = snapshot.data;
        String status = dados[FirebaseCollection.DOC_STATUS];
        switch (status) {
          case StatusRequisicao.AGUARDANDO:
            _statusAguardando();
            break;
          case StatusRequisicao.A_CAMINHO:
            _statusACaminho();
            break;
          case StatusRequisicao.VIAGEM:
            break;
          case StatusRequisicao.FINALIZADA:
            break;
        }
      }
    });
  }

  /** metotos de status de viagem **/
  _statusAguardando() {
    _alterarBotaoPrincipal('Aceitar Corrida', Color(0xff1ebbd8), () {
      _aceitarCorrida();
    });
  }

  _statusACaminho() {
    _alterarBotaoPrincipal('A Caminho do Passageiro', Colors.green, null);
    /** exibir local do passageiro e motorista na tela do motorista **/
    double latitudePassageiro =
        _dadosRequisicao[FirebaseCollection.NO_PASSAGEIRO]
            [FirebaseCollection.DOC_LATITUDE];
    double longitudePassageiro =
        _dadosRequisicao[FirebaseCollection.NO_PASSAGEIRO]
            [FirebaseCollection.DOC_LONGITUDE];

    /** local motorista **/
    double latitudeMotorista = _dadosRequisicao[FirebaseCollection.NO_MOTORISTA]
        [FirebaseCollection.DOC_LATITUDE];
    double longitudeMotorista =
        _dadosRequisicao[FirebaseCollection.NO_MOTORISTA]
            [FirebaseCollection.DOC_LONGITUDE];

    _exibirDoisMarcadores(LatLng(latitudeMotorista, longitudeMotorista),
        LatLng(latitudePassageiro, longitudePassageiro));
    /**  'southwest.latitude <= northeast.latitude': is not true. **/
    var nLat, nLon, sLat, sLon;
    if (latitudeMotorista <= latitudePassageiro) {
      sLat = latitudeMotorista;
      nLat = latitudePassageiro;
    } else {
      sLat = latitudePassageiro;
      nLat = latitudeMotorista;
    }
    if (longitudeMotorista <= longitudePassageiro) {
      sLon = longitudeMotorista;
      nLon = longitudePassageiro;
    } else {
      sLon = longitudePassageiro;
      nLon = longitudeMotorista;
    }
    _movimentaCameraBounds(LatLngBounds(
        northeast: LatLng(nLat, nLon), southwest: LatLng(sLat, sLon)));
  }

  _exibirDoisMarcadores(LatLng latLngMotorista, LatLng latLngPassageiro) {
    /** recupera pixel do dispositivo **/
    double pixelRadio = MediaQuery.of(context).devicePixelRatio;
    Set<Marker> _listaMarcadores = {};
    /** motorista **/
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(devicePixelRatio: pixelRadio),
            'images/motorista.png')
        .then((BitmapDescriptor icone) {
      Marker marcadorMotorista = Marker(
          markerId: MarkerId(_idMarkerMotorista),
          position: LatLng(latLngMotorista.latitude, latLngMotorista.longitude),
          infoWindow: InfoWindow(title: 'Local Motorista'),
          icon: icone);
      _listaMarcadores.add(marcadorMotorista);
    });
    /** passageiro **/
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(devicePixelRatio: pixelRadio),
            'images/passageiro.png')
        .then((BitmapDescriptor icone) {
      Marker marcadorPassageiro = Marker(
          markerId: MarkerId(_idMarkerMotorista),
          position:
              LatLng(latLngPassageiro.latitude, latLngPassageiro.longitude),
          infoWindow: InfoWindow(title: 'Local Passageiro'),
          icon: icone);
      _listaMarcadores.add(marcadorPassageiro);
    });
    setState(() {
      _marcadores = _listaMarcadores;
    });
  }

  _movimentaCameraBounds(LatLngBounds latLngBounds) async {
    GoogleMapController googleMapController = await _controllerMap.future;

    googleMapController
        .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 100));
  }

  _aceitarCorrida() async {
    _idRequisicao = _dadosRequisicao[FirebaseCollection.DOC_ID_DESTINO];
    /** recupera dados do motorista **/
    Usuario motorista = await UsuarioFirebse.getDadosUsuarioLogado();
    motorista.latitude = _localMotorista.latitude;
    motorista.longitude = _localMotorista.longitude;

    /** adcionar o motorista na requisicao **/
    _banco
        .collection(FirebaseCollection.COLECAO_REQUISICOES)
        .document(_idRequisicao)
        .updateData({
      FirebaseCollection.NO_MOTORISTA: motorista.toMap(),
      FirebaseCollection.DOC_STATUS: StatusRequisicao.A_CAMINHO
    }).then((_) {
      /** atulizar requisicao ativa **/
      String idPassageiro = _dadosRequisicao[FirebaseCollection.NO_PASSAGEIRO]
          [FirebaseCollection.DOC_ID_USUARIO];
      _banco
          .collection(FirebaseCollection.COLECAO_REQUISICAO_ATIVA)
          .document(idPassageiro)
          .updateData(
              {FirebaseCollection.DOC_STATUS: StatusRequisicao.A_CAMINHO});
      /** salvar requisicao ativa para motorista **/
      String idMotorista = motorista.idUsuario;
      _banco
          .collection(FirebaseCollection.COLECAO_REQUISICAO_ATIVA_MOTORISTA)
          .document(idMotorista)
          .setData({
        FirebaseCollection.DOC_ID_REQUISICAO: _idRequisicao,
        FirebaseCollection.DOC_ID_USUARIO: idMotorista,
        FirebaseCollection.DOC_STATUS: StatusRequisicao.A_CAMINHO
      });
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _recuperaUltimaLocalizacaoConhecida();
    _adicionarListernerLocalizacao();
    _recuperaRequisicao();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Painel Corrida")),
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
          Positioned(
              /** btn chama uber **/
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
