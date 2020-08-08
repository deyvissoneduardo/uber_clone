import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Corrida extends StatefulWidget {
  /** rebece o idRequisicao por paramentro de motorista para corrida **/
  String idRequisicao;
  Corrida(this.idRequisicao);
  @override
  _CorridaState createState() => _CorridaState();
}

class _CorridaState extends State<Corrida> {
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _recuperaUltimaLocalizacaoConhecida();
    _adicionarListernerLocalizacao();
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
