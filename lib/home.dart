import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

const endPointUrl = 'https://api.openweathermap.org/data/2.5/';
const APIKey = 'cc9d21dcba5cdac36ac39562b33758b8';
const DIFF_BETWEEN_TEMP = 273.15;

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isPermitted = false;
  String? locality;
  String? coordinates;
  int? currentTemp;
  List<int>? daysTemp;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  void _initApp() async {
    setState(() {
      loading = true;
    });

    await _pedirPermissao();

    if (!isPermitted) {
      setState(() {
        loading = false;
      });
      return;
    }

    Position position = await _pedirCoordenadas();

    await _pegarPrevisaoTempoAgora(position);

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: _buildApp(),
      floatingActionButton: loading ? null : FloatingActionButton(
        child: const Icon(Icons.refresh),
        onPressed: () {
          _initApp();
        },
      ),
    );
  }

  Widget _buildApp() {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMostrarTextoPermissao(),
            _buildMostrarTextoCoordenadas(),
            _buildMostrarTemperature(),
            _buildMostrarProxTemperature(),
          ],
        ),
      ),
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
    isPermitted = false;

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

    isPermitted = true;
  }

  Future<Position> _pedirCoordenadas() async {
    coordinates = locality = null;

    Position position = await Geolocator.getCurrentPosition();

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      final mark = placemarks[0];
      locality = mark.subAdministrativeArea ?? '';
      coordinates = 'Lat: ${position.latitude}, Lon: ${position.longitude}';
    }

    return position;
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

  _pegarPrevisaoTempoAgora(Position position) async {
    final httpClient = http.Client();
    final requestUrl = '$endPointUrl/onecall?'
        'lat=${position.latitude}&'
        'lon=${position.longitude}&'
        'exclude=hourly,minutely&'
        'appid=$APIKey';

    final response = await httpClient.get(Uri.parse(requestUrl));

    if (response.statusCode != 200) {
      throw Exception(
          'error retrieving location for city: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data?['current']?['temp'] != null) {
      double temp = data['current']['temp'] - DIFF_BETWEEN_TEMP;
      currentTemp = temp.round();
    }

    bool hasDaily = data['daily'] != null;
    if (hasDaily) {
      List days = data['daily'];
      daysTemp = [];
      for (int i = 0; i < 3; i++) {
        double day = days[i]['temp']['day'] - DIFF_BETWEEN_TEMP;
        daysTemp!.add(day.round());
      }
    }
  }

  Widget _buildMostrarTemperature() {
    if (currentTemp == null) {
      return Container();
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        '$currentTempº',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
        ),
      ),
    );
  }

  Widget _buildMostrarProxTemperature() {
    if (daysTemp == null) {
      return Container();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        daysTemp!.length,
        (index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '${daysTemp![index]}º',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
              ),
            ),
          );
        },
      ),
    );
  }
}
