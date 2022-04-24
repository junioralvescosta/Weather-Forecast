import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isPermitted = false;
  String? locality;
  String? coordinates;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMostrarTextoPermissao(),
              _buildMostrarTextoCoordenadas(),
              _buildBotao(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotao() {
    if (!isPermitted) {
      return ElevatedButton(
        onPressed: () {
          _pedirPermissao();
        },
        child: Text('Pedir permissão'),
      );
    }

    return ElevatedButton(
      onPressed: () {
        _pedirCoordenadas();
      },
      child: Text('Pedir Coordenadas'),
    );
  }

  Widget _buildMostrarTextoPermissao() {
    if (locality != null) {
      return Container();
    }

    if (isPermitted) {
      return Text('Tem permissão');
    }

    return Text('Não tem permissão');
  }

  _pedirPermissao() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    setState(() {
      isPermitted = true;
    });
  }

  void _pedirCoordenadas() async {
    Position position = await Geolocator.getCurrentPosition();

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      final mark = placemarks[0];
      print(mark);
      locality = mark.subAdministrativeArea ?? '';
      coordinates = 'Lat: ${position.latitude}, Lon: ${position.longitude}';
    } else {
      locality = '';
      coordinates = '';
    }

    setState(() {});
  }

  Widget _buildMostrarTextoCoordenadas() {
    if (locality == null) {
      return Container();
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            locality!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            coordinates!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
