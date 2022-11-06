import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Authentication extends StatefulWidget {
  const Authentication({Key? key}) : super(key: key);

  @override
  State<Authentication> createState() => _AuthenticationState();
}

class _AuthenticationState extends State<Authentication> {
  final LocalAuthentication auth = LocalAuthentication();

  List<BiometricType> biometrics = [];
  bool canAuthenticateWithBiometrics = false;
  bool authSwitch = false;

  @override
  void initState() {
    super.initState();
    getSwitch();
  }

  getSwitch() async {
    authSwitch = await getSwitchState();
    setState(() {});
  }

  Future<bool> saveSwitchState(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('authSwitch', value);
    print('Auth Switch value saved $value');
    return prefs.setBool('authSwitch', value);
  }

  Future<bool> getSwitchState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isSwitched = prefs.getBool('authSwitch') ?? false;
    print(isSwitched);
    return isSwitched;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.amber,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.light,
          ),
          foregroundColor: Colors.white,
          title: const Text("Authentification"),
          iconTheme: IconTheme.of(context)),
      body: SafeArea(
        child: Column(
          children: [
            FutureBuilder(future: () async {
              canAuthenticateWithBiometrics = await auth.isDeviceSupported();
              return canAuthenticateWithBiometrics;
            }(), builder: ((context, snapshot) {
              if (canAuthenticateWithBiometrics) {
                return const ListTile(
                    title:
                        Text("Your device supports biometric authentication."));
              } else {
                return const ListTile(
                    title: Text(
                        "Your device does not support biometric authentication."));
              }
            })),
            FutureBuilder(builder: ((context, snapshot) {
              return SwitchListTile(
                  title: const Text("Activate authentication"),
                  value: authSwitch,
                  onChanged: (bool value) {
                    setState(() {
                      authSwitch = value;
                      saveSwitchState(value);
                      print("Saved state is $authSwitch");
                    });
                    print(authSwitch);
                  });
            })),
            const ListTile(
              title: Text(
                "SUPPORTED MODES",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            FutureBuilder(
              future: () async {
                biometrics = await auth.getAvailableBiometrics();
                return biometrics;
              }(),
              builder: ((context, snapshot) {
                return Column(
                  children: [
                    for (BiometricType bio in biometrics)
                      ListTile(
                        title: Text(bio.name.capitalize()),
                        leading: () {
                          switch (bio.name) {
                            case "weak":
                              return const Icon(FontAwesomeIcons.shieldHalved);
                            case "strong":
                              return const Icon(FontAwesomeIcons.shield);
                            case "face":
                              return const Icon(FontAwesomeIcons.imagePortrait);
                            case "fingerprint":
                              return const Icon(FontAwesomeIcons.fingerprint);
                            case "iris":
                              return const Icon(FontAwesomeIcons.eye);
                            default:
                          }
                        }(),
                      )
                  ],
                );
              }),
            )
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}
