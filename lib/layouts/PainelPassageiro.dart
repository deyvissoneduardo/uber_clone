import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uber_clone/routes/Routes.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';

class PainelPassageiro extends StatefulWidget {
  @override
  _PainelPassageiroState createState() => _PainelPassageiroState();
}

class _PainelPassageiroState extends State<PainelPassageiro> {
  List<String> itensMenu = ['config', 'Deslogar'];

  /** controlador do mapa **/
  Completer<GoogleMapController> _controllerMap = Completer();

  /** inica camera do mapa **/
  CameraPosition _cameraPosition =
      CameraPosition(target: LatLng(-15.904634, -47.773108), zoom: 19);

  /** instancias do firebase **/
  FirebaseAuth auth = FirebaseAuth.instance;

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
      _cameraPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude), zoom: 19);
      _movimentaCamera(_cameraPosition);
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
        child: GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: _cameraPosition,
          onMapCreated: _onMapCreated,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
        ),
      ),
    );
  }
}
