import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:local_auth/local_auth.dart';
import 'package:matemate/graphql_helper.dart';
import 'package:matemate/local_store.dart';
import 'package:matemate/offering.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:matemate/statistics.dart';
import 'package:matemate/theme_provider.dart';
import 'package:matemate/util/widgets/scaffolded_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:side_navigation/side_navigation.dart';
import 'transaction_list.dart';
import 'settings.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(OfferingAdapter());
  await LocalStore.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ],
        child: Builder(builder: (BuildContext context) {
          final themeProvider = Provider.of<ThemeProvider>(context);

          return MaterialApp(
              title: 'MateMate',
              themeMode: themeProvider.themeMode,
              color: Colors.amber,
              theme: ThemeData(
                  useMaterial3: true,
                  colorScheme: ColorScheme.fromSeed(
                      seedColor: Colors.amber, primary: Colors.amber),
                  brightness: Brightness.light,
                  appBarTheme: const AppBarTheme(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.amber,
                      systemOverlayStyle: SystemUiOverlayStyle(
                          statusBarColor: Colors.amber,
                          statusBarBrightness: Brightness.dark,
                          statusBarIconBrightness: Brightness.light))),
              darkTheme: ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.amber,
                    primary: Colors.amber,
                    background: Colors.black,
                    brightness: Brightness.dark),
                brightness: Brightness.dark,
                progressIndicatorTheme:
                    const ProgressIndicatorThemeData(color: Color(0xFFCDA839)),

                /*appBarTheme: const AppBarTheme(
                      foregroundColor: Colors.white,
                      backgroundColor: Color(0xFFCDA839),
                      systemOverlayStyle: SystemUiOverlayStyle(
                          statusBarColor: Color(0xFFCDA839),
                          statusBarBrightness: Brightness.dark,
                          statusBarIconBrightness: Brightness.light))*/
              ),
              home: const MyHomePage(title: 'My Transactions'));
        }));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  // Flags indicating which dialogs are open
  bool showingSignInDialog = false;
  bool showingNewUserDialog = false;
  bool showingPurchaseDialog = false;
  bool showingTopUpDialog = false;
  bool showingNoConnectionDialog = false;
  bool showingAuthDialog = false;
  bool didJustCloseAuthDialog = false;
  bool showingAddSmartCardDialog = false;

  Map prefsMap = <String, dynamic>{};
  final LocalAuthentication auth = LocalAuthentication();

  TransactionList tList = TransactionList(
    onSocketException: (context) {},
    username: LocalStore.userName,
  );

  getPrefs() async {
    SharedPreferences? prefs = await SharedPreferences.getInstance();
    var keys = prefs.getKeys();
    for (String key in keys) {
      prefsMap[key] = prefs.get(key);
    }
    setState(() {});
    return prefsMap;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    int selectedIndex = 100;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        drawer: MediaQuery.of(context).size.width < 860
            ? Drawer(
                child: Column(
                  children: [
                    for (dynamic child in getDrawerChildren())
                      child["icon"] == null
                          ? const Divider()
                          : ListTile(
                              leading: Icon(child["icon"]),
                              title: Text(child["title"]),
                              onTap: child["to"],
                            )
                  ],
                ),
              )
            : null,
        body: MediaQuery.of(context).size.width < 860
            ? FutureBuilder(
                future: _signIn(context),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    tList = TransactionList(
                      onSocketException: _showNoConnectionDialog,
                      username: LocalStore.userName,
                    );
                    return tList;
                  } else {
                    return Container();
                  }
                },
              )
            : Row(children: [
                SideNavigationBar(
                  selectedIndex: selectedIndex,
                  items: [
                    for (dynamic child in getDrawerChildren())
                      if (child["icon"] != null)
                        SideNavigationBarItem(
                            icon: child["icon"], label: child["title"])
                  ],
                  onTap: (index) async {
                    setState(() {
                      selectedIndex = index;
                    });
                    switch (index) {
                      case 0:
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return const Statistics();
                        }));
                        break;
                      case 1:
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return const Settings();
                        }));
                        break;
                      case 3:
                        AlertDialog alert = AlertDialog(
                            title: const Text("Log Out"),
                            content:
                                const Text("Are you sure you want to log out?"),
                            actions: [
                              FilledButton.tonal(
                                  onPressed: () {
                                    Navigator.pop(context, true);
                                    LocalStore.authToken = "";
                                    LocalStore.userName = "";
                                    LocalStore.password = "";
                                    Navigator.pop(context);
                                    _signIn(context);
                                  },
                                  child: const Text("Yes")),
                              FilledButton.tonal(
                                  onPressed: () {
                                    Navigator.pop(context, false);
                                  },
                                  child: const Text("No"))
                            ]);
                        await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return alert;
                            });

                        break;
                      default:
                    }
                  },
                ),
                Expanded(
                  child: FutureBuilder(
                    future: _signIn(context),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        tList = TransactionList(
                          onSocketException: _showNoConnectionDialog,
                          username: LocalStore.userName,
                        );
                        return tList;
                      } else {
                        return Container();
                      }
                    },
                  ),
                )
              ]),
      ),
    );
  }

  List<Map<String, dynamic>> getDrawerChildren() {
    return [
      {
        "icon": FontAwesomeIcons.chartLine,
        "title": "Statistics",
        "to": () =>
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return const Statistics();
            }))
      },
      {
        "icon": FontAwesomeIcons.gear,
        "title": "Settings",
        "to": () =>
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return const Settings();
            }))
      },
      {"icon": null, "title": "Divider", "to": const Divider()},
      {
        "icon": FontAwesomeIcons.arrowRightFromBracket,
        "title": "Log out",
        "to": () {
          AlertDialog alert = AlertDialog(
              title: const Text("Log Out"),
              content: const Text("Are you sure you want to log out?"),
              actions: [
                FilledButton.tonal(
                    onPressed: () {
                      Navigator.pop(context, true);
                      LocalStore.authToken = "";
                      LocalStore.userName = "";
                      LocalStore.password = "";
                      Navigator.pop(context);
                      _signIn(context);
                    },
                    child: const Text("Yes")),
                FilledButton.tonal(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    child: const Text("No"))
              ]);
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return alert;
              });
        }
      }
    ];
  }

  Future<bool> _signIn(BuildContext context) async {
    bool authTokenExpired = true;
    try {
      authTokenExpired = JwtDecoder.isExpired(LocalStore.authToken);
    } catch (e) {
      // There is no auth token, therefore it cant be valid.
    }
    while (authTokenExpired) {
      try {
        await GraphQlHelper.signIn(LocalStore.userName, LocalStore.password);
      } on InvalidSignInCredentialsException {
        await _showSignInDialog();
      } on SocketException {
        await _showNoConnectionDialog(context);
      }
      try {
        authTokenExpired = JwtDecoder.isExpired(LocalStore.authToken);
      } catch (e) {
        // There is no auth token, therefore it cant be valid.
      }
    }
    return true;
  }

  Future<void> _showSignInDialog() async {
    String newUserName = "";
    String newPassword = "";
    if (showingSignInDialog) {
      return;
    }
    showingSignInDialog = true;
    await showDialog(
      context: context,
      builder: (context) => ScaffoldedDialog(
        barrierDismissable: false,
        contentPadding: const EdgeInsets.only(left: 8, right: 8),
        titlePadding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
        title: const Text("Log-In"),
        children: [
          const Text("Username"),
          const SizedBox(
            height: 10,
          ),
          TextField(onChanged: (value) => newUserName = value),
          const SizedBox(
            height: 20,
          ),
          const Text("Password"),
          const SizedBox(
            height: 10,
          ),
          TextField(
            obscureText: true,
            onChanged: (value) => newPassword = value,
          ),
          const SizedBox(
            height: 10,
          ),
          FilledButton(
            child: const Text("Log-In"),
            onPressed: () {
              if (newUserName == "") {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Enter a Username")));
                return;
              }
              if (newPassword == "") {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Enter a Password")));
                return;
              }
              LocalStore.userName = newUserName;
              LocalStore.password = newPassword;
              showingSignInDialog = false;
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
    showingSignInDialog = false;
  }

  Future<void> _showNoConnectionDialog(BuildContext context) async {
    if (showingNoConnectionDialog) {
      return;
    }
    showingNoConnectionDialog = true;
    await showDialog(
      context: context,
      builder: (context) => ScaffoldedDialog(
        contentPadding: const EdgeInsets.all(8),
        titlePadding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
        title: const Text("No Connection"),
        children: [
          const Center(
            child: Icon(
              FontAwesomeIcons.wifi,
              color: Colors.red,
              size: 100,
            ),
          ),
          const Center(
            child: Text(
              "You are either not connected to the internet, or the server is down. Anyway, connecting to the server itself failed. ",
              softWrap: true,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Close"),
          ),
        ],
      ),
    );
    showingNoConnectionDialog = false;
  }
}
