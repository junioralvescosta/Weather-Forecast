import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool permissao = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            permissao ? Text('tem permissão') : Text('não tem permissão'),
            if (!permissao)TextButton(
              onPressed: () async {
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
                  permissao = true;
                });
              },
              child: Text('pedi permissão'),
            ),
          ],
        ),
      ),
    );
  }
}
