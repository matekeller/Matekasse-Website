import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:matemate/authentication.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
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
          title: const Text("Settings"),
          iconTheme: IconTheme.of(context)),
      body: SafeArea(
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(FontAwesomeIcons.fingerprint),
              title: const Text("Authentification"),
              onTap: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                return const Authentication();
              })),
            )
          ],
        ),
      ),
    );
  }
}
