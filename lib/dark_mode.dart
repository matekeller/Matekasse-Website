import 'package:flutter/material.dart';
import 'package:matemate/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DarkMode extends StatefulWidget {
  const DarkMode({Key? key}) : super(key: key);

  @override
  State<DarkMode> createState() => _DarkModeState();
}

class _DarkModeState extends State<DarkMode> {
  bool themeSwitch = false;

  @override
  void initState() {
    super.initState();
    getSwitch();
  }

  getSwitch() async {
    themeSwitch = await getSwitchState();
    setState(() {});
  }

  Future<bool> getSwitchState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isSwitched = prefs.getBool('themeSwitch') ?? false;
    return isSwitched;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Dark Mode"), iconTheme: IconTheme.of(context)),
      body: SafeArea(
        child: Column(
          children: [
            FutureBuilder(builder: ((context, snapshot) {
              final themeProvider = Provider.of<ThemeProvider>(context);

              return SwitchListTile(
                  title: const Text("Activate Dark Mode"),
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    final provider =
                        Provider.of<ThemeProvider>(context, listen: false);
                    provider.toggleTheme(value);
                    setState(() {
                      themeSwitch = value;
                    });
                  });
            })),
          ],
        ),
      ),
    );
  }
}
