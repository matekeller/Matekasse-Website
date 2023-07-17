import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:matemate/authentication.dart';

import 'dark_mode.dart';

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
          title: const Text("Settings"), iconTheme: IconTheme.of(context)),
      body: SafeArea(
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(FontAwesomeIcons.fingerprint),
              title: const Text("Authentication"),
              subtitle: const Text(
                  "(De)activate and manage authentication functionality"),
              onTap: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                return const Authentication();
              })),
            ),
            ListTile(
              leading: const Icon(FontAwesomeIcons.moon),
              title: const Text("Dark Mode"),
              subtitle: const Text("(De)activate Dark Mode"),
              onTap: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                return const DarkMode();
              })),
            )
          ],
        ),
      ),
    );
  }
}
