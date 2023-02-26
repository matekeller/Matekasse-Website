import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:circular_menu/circular_menu.dart';
import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:matemate/graphql_helper.dart';
import 'package:matemate/inventory.dart';
import 'package:matemate/local_store.dart';
import 'package:matemate/nfc_scanner.dart';
import 'package:matemate/offering.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:matemate/user_list.dart';
import 'package:matemate/util/widgets/scaffolded_dialog.dart';
import 'package:matemate/util/widgets/user_scan_row.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'offering_grid.dart';
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
    return MaterialApp(
      title: 'MateMate',
      theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.
          primarySwatch: Colors.amber,
          textButtonTheme: TextButtonThemeData(
            style: ButtonStyle(
              foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
              backgroundColor: MaterialStateProperty.all<Color>(Colors.amber),
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          textTheme:
              const TextTheme(headline3: TextStyle(color: Colors.white))),
      home: const AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.amber,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.light,
          ),
          child: MyHomePage(title: 'Transactions')),
    );
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

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      prefsMap = await getPrefs();
      if (prefsMap['authSwitch'] != null && prefsMap['authSwitch']) {
        _showAuthDialog();
      }
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    getPrefs();
    if (state == AppLifecycleState.resumed &&
        !showingAuthDialog &&
        prefsMap['authSwitch']) {
      if (didJustCloseAuthDialog) {
        didJustCloseAuthDialog = false;
      } else {
        _showAuthDialog();
      }
    }
  }

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
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.amber,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.light,
          ),
          foregroundColor: Colors.white,
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
          iconTheme: IconTheme.of(context),
        ),
        drawer: Drawer(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(FontAwesomeIcons.users),
                title: const Text("Users"),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) {
                  return const UserList();
                })),
              ),
              ListTile(
                leading: const Icon(FontAwesomeIcons.boxesStacked),
                title: const Text("Inventory"),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) {
                  return const Inventory();
                })),
              ),
              ListTile(
                  leading: const Icon(FontAwesomeIcons.gear),
                  title: const Text("Settings"),
                  onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return const Settings();
                      }))),
              const Divider(),
              ListTile(
                leading: const Icon(FontAwesomeIcons.arrowRightFromBracket),
                title: const Text("Log out"),
                onTap: () {
                  AlertDialog alert = AlertDialog(
                      title: const Text("Log Out"),
                      content: const Text("Are you sure you want to log out?"),
                      actions: [
                        TextButton(
                            onPressed: () {
                              Navigator.pop(context, true);
                              LocalStore.authToken = "";
                              LocalStore.userName = "";
                              LocalStore.password = "";
                              Navigator.pop(context);
                              _signIn(context);
                            },
                            child: const Text("Yes")),
                        TextButton(
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
                },
              ),
            ],
          ),
        ),
        body: FutureBuilder(
          future: _signIn(context),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return TransactionList(
                onSocketException: _showNoConnectionDialog,
              );
            } else {
              return Container();
            }
          },
        ),
        floatingActionButton: CircularMenu(
          radius: 120,
          animationDuration: const Duration(milliseconds: 500),
          curve: Curves.bounceOut,
          reverseCurve: Curves.easeInOutQuint,
          toggleButtonColor: Colors.amber,
          toggleButtonIconColor: Colors.white,
          items: [
            CircularMenuItem(
                icon: FontAwesomeIcons.user,
                color: Colors.amber,
                onTap: () {
                  _showNewUserDialog();
                }),
            CircularMenuItem(
                icon: FontAwesomeIcons.euroSign,
                color: Colors.amber,
                onTap: () {
                  _showTopUpDialog();
                }),
            CircularMenuItem(
                icon: FontAwesomeIcons.wineBottle,
                color: Colors.amber,
                onTap: () {
                  _showPurchaseDialog();
                }),
            CircularMenuItem(
                icon: FontAwesomeIcons.creditCard,
                color: Colors.amber,
                onTap: () {
                  _showAddSmartCardDialog();
                })
          ],
          alignment: Alignment.bottomRight,
        ),
      ),
      //makes auto-formatting nicer for build methods.
    );
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
        contentPadding: const EdgeInsets.all(8),
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
          TextButton(
            //color: Colors.blueAccent,
            child: Text(
              "Log-In",
              style: Theme.of(context)
                  .textTheme
                  .button!
                  .copyWith(color: Colors.white),
            ),
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
              Navigator.pop(context, false);
            },
          )
        ],
      ),
    );
    showingSignInDialog = false;
  }

  Future<void> _showNewUserDialog() async {
    if (showingNewUserDialog) {
      return;
    }
    showingNewUserDialog = true;
    String? username;
    String? fullName;
    String? password;
    String? bluecardId;
    try {
      await GraphQlHelper.updateAllUsers();
    } on SocketException {
      await _showNoConnectionDialog(context);
      return;
    }

    await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return ScaffoldedDialog(
              contentPadding: const EdgeInsets.all(8),
              titlePadding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
              title: const Text("New User"),
              children: [
                const Text("Username"),
                const SizedBox(
                  height: 10,
                ),
                Text(username ?? '',
                    style: const TextStyle(color: Colors.black38)),
                const SizedBox(
                  height: 20,
                ),
                const Text("Full Name"),
                const SizedBox(
                  height: 10,
                ),
                TextField(onChanged: (value) {
                  setState(() {
                    fullName = value;
                    var names = fullName?.split(' ');

                    if (names!.length == 1) {
                      username = names[0].toLowerCase();
                    } else if (names.length > 1) {
                      try {
                        username = (names[0] + names.last[0]).toLowerCase();
                      } on RangeError {
                        username = names[0].toLowerCase();
                      }
                    }
                    var additionalChars = 1;
                    while (GraphQlHelper.userExists(username!) &&
                        names.last.length >= additionalChars) {
                      username =
                          (names[0] + names.last.substring(0, additionalChars))
                              .toLowerCase();
                      additionalChars++;
                    }
                  });
                }),
                const SizedBox(
                  height: 20,
                ),
                const Text("Bluecard ID"),
                const SizedBox(
                  height: 10,
                ),
                UserScanRow(
                    searchable: false,
                    onChanged: (value) => bluecardId = value),
                const SizedBox(
                  height: 20,
                ),
                const Text("Password"),
                const SizedBox(
                  height: 10,
                ),
                TextField(
                  obscureText: true,
                  onChanged: ((value) => password = value),
                ),
                TextButton(
                  //color: Colors.blueAccent,
                  child: Text(
                    "Register",
                    style: Theme.of(context)
                        .textTheme
                        .button!
                        .copyWith(color: Colors.white),
                  ),
                  onPressed: () {
                    // Gate clauses for username
                    if (username == null || username == "") {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Enter a username")));
                      return;
                    }
                    if (GraphQlHelper.userExists(username!)) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              "A user with this username already exists")));
                      return;
                    }
                    // Gate clauses for fullName
                    if (fullName == null || fullName == "") {
                      fullName = "";
                    }

                    // Gate clauses for bluecardId
                    if (bluecardId == null || bluecardId == "") {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Enter or scan a bluecard-id")));
                      return;
                    }
                    if (GraphQlHelper.getUsernameByBluecardId(bluecardId!) !=
                        null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              "There already is an account with this bluecard-id")));
                      return;
                    }
                    if (bluecardId!.length != 12) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("This is not a valid bluecardId")));
                      return;
                    }
                    // Gate clauses for pw
                    if (password == null || password == "") {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Enter a password")));
                      return;
                    }
                    // Maybe ad password strength checker?
                    if (password!.length < 8) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              "The password needs at least 8 characters")));
                      return;
                    }
                    // No problem occured, we can add the user
                    try {
                      GraphQlHelper.addUser(
                          username, fullName, password, bluecardId);
                      showingNewUserDialog = false;
                      Navigator.pop(context);
                    } on SocketException {
                      _showNoConnectionDialog(context);
                    }
                  },
                ),
              ],
            );
          });
        });
    showingNewUserDialog = false;
  }

  Future<void> _showTopUpDialog() async {
    if (showingTopUpDialog) {
      return;
    }
    showingTopUpDialog = true;
    String? username;
    int? pricePaidEuros;
    try {
      await GraphQlHelper.updateAllUsers();
    } on SocketException {
      _showNoConnectionDialog(context);
      return;
    }
    showDialog(
      context: context,
      builder: (context) => ScaffoldedDialog(
        contentPadding: const EdgeInsets.all(8),
        titlePadding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
        title: const Text("Top-Up"),
        children: [
          const Text("Amount €"),
          MoneyTextField(onChanged: (newPrice) => pricePaidEuros = newPrice),
          const SizedBox(
            height: 16,
          ),
          const Text("Payer-Code:"),
          UserScanRow(
              onChanged: (bluecardId) => (username =
                  GraphQlHelper.getUsernameByBluecardId(bluecardId ?? ""))),
          TextButton(
            //color: Colors.blueAccent,
            child: Text(
              "Top-Up!",
              style: Theme.of(context)
                  .textTheme
                  .button!
                  .copyWith(color: Colors.white),
            ),
            onPressed: () {
              if (username == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("The bluecardID is invalid")));
                return;
              }
              if (pricePaidEuros == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("The ammount is invalid")));
                return;
              }
              try {
                GraphQlHelper.topUp(username!, pricePaidEuros! * 100);
                showingTopUpDialog = false;
                Navigator.pop(context);
              } on SocketException {
                _showNoConnectionDialog(context);
              }
            },
          )
        ],
      ),
    );
    showingTopUpDialog = false;
  }

  Future<void> _showPurchaseDialog() async {
    if (showingPurchaseDialog) {
      return;
    }
    showingPurchaseDialog = true;
    List<String>? selectedOfferingsName;
    String? username;
    int sumOfSelectedOfferings = 0;
    List<User> _users = [];
    try {
      _users = await GraphQlHelper.updateAllUsers();
    } on SocketException {
      _showNoConnectionDialog(context);
      return;
    }
    await showDialog(
      context: context,
      builder: (context) {
        return ScaffoldedDialog(
          contentPadding: const EdgeInsets.all(8),
          titlePadding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
          title: const Text("Purchase"),
          children: [
            const Text("Product"),
            const SizedBox(
              height: 10,
            ),
            Builder(builder: (context) {
              return SizedBox(
                width: 500,
                child: LimitedBox(
                    maxHeight: 500,
                    child: OfferingGrid(
                      onChanged: (newSelectedTiles) {
                        selectedOfferingsName = newSelectedTiles;
                      },
                    )),
              );
            }),
            const SizedBox(
              height: 20,
            ),
            const Text("User"),
            const SizedBox(height: 10),
            UserScanRow(onChanged: (newBluecardId) {
              username =
                  GraphQlHelper.getUsernameByBluecardId(newBluecardId ?? "");
            }),
            TextButton(
                child: Text(
                  "Buy",
                  style: Theme.of(context)
                      .textTheme
                      .button!
                      .copyWith(color: Colors.white),
                ),
                onPressed: () {
                  if (selectedOfferingsName == null ||
                      selectedOfferingsName!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("You have to choose an Offering")));
                    return;
                  }

                  if (username == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            "The bluecardID is not valid, or the user is not registered yet")));
                    return;
                  }

                  for (Offering offering in LocalStore.offerings.where(
                      (element) =>
                          selectedOfferingsName!.contains(element.name))) {
                    sumOfSelectedOfferings += offering.priceCents;
                  }

                  if (_users
                              .firstWhere(
                                  (element) => element.username == username)
                              .balanceCents *
                          (-1) < //Taking the additive inverse, because backend stores balance as negative.
                      sumOfSelectedOfferings) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            "The user does not have enough money on their account: ${_users.firstWhere((element) => element.username == username).balanceCents.abs()}ct.")));
                    sumOfSelectedOfferings = 0;
                    return;
                  }

                  try {
                    if (selectedOfferingsName!.length == 1) {
                      GraphQlHelper.purchaseProduct(
                          username!, selectedOfferingsName!.first);
                    } else {
                      GraphQlHelper.purchaseMultipleProducts(
                          username!, selectedOfferingsName!);
                    }

                    Navigator.of(context).pop();
                  } on SocketException {
                    _showNoConnectionDialog(context);
                  }
                })
          ],
        );
      },
    );
    showingPurchaseDialog = false;
  }

  Future<void> _showAddSmartCardDialog() async {
    if (showingAddSmartCardDialog) {
      return;
    }
    showingAddSmartCardDialog = true;
    var username;
    var smartcard;

    try {
      await GraphQlHelper.updateAllUsers();
    } on SocketException {
      _showNoConnectionDialog(context);
      return;
    }

    await showDialog(
        context: context,
        builder: (context) => ScaffoldedDialog(
                contentPadding: const EdgeInsets.all(8),
                titlePadding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                title: const Text("Add SmartCard to user"),
                children: [
                  const Text("User:"),
                  UserScanRow(
                    onChanged: (newBluecardId) {
                      username = GraphQlHelper.getUsernameByBluecardId(
                          newBluecardId ?? "");
                    },
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  const Text("SmartCard:"),
                  UserScanRow(
                      searchable: false,
                      barcodeEnabled: true,
                      nfcEnabled: false,
                      onChanged: (newSmartCard) {
                        smartcard = newSmartCard;
                      }),
                  TextButton(
                      onPressed: () async {
                        try {
                          GraphQlHelper.addSmartCardToUser(username, smartcard);
                          Navigator.pop(context);
                        } on Exception {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("error")));
                        }
                      },
                      child: const Text("Add"))
                ]));

    showingAddSmartCardDialog = false;
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

  Future<void> _showAuthDialog() async {
    prefsMap = await getPrefs();
    if (showingAuthDialog ||
        (prefsMap['authSwitch'] != null && !prefsMap['authSwitch'])) {
      return;
    }
    showingAuthDialog = true;
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return WillPopScope(
              onWillPop: () async => false,
              child: ScaffoldedDialog(
                barrierDismissable: false,
                closable: false,
                blurRadius: 25,
                contentPadding: const EdgeInsets.all(8),
                titlePadding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                title: const Text("Authentication"),
                children: [
                  const Text(
                      "Authentication is activated. Please authenticate."),
                  TextButton(
                      child: const Text("Authenticate"),
                      onPressed: () async {
                        bool didAuthenticate = false;
                        try {
                          didAuthenticate = await auth.authenticate(
                              options: const AuthenticationOptions(
                                  stickyAuth: true, biometricOnly: true),
                              localizedReason:
                                  "Authentication is activated. Please authenticate.");

                          if (didAuthenticate) {
                            if (Platform.operatingSystem == "ios") {
                              didJustCloseAuthDialog = true; // ios is weird.
                            } else {
                              didJustCloseAuthDialog =
                                  false; // with biometricOnly: true it somehow doesnt cause a AppLifeCycle resume
                            }
                          }
                        } on PlatformException catch (e) {
                          if (e.code == auth_error.notAvailable ||
                              e.code == auth_error.notEnrolled ||
                              e.code == auth_error.biometricOnlyNotSupported) {
                            didAuthenticate = await auth.authenticate(
                                options: const AuthenticationOptions(
                                    biometricOnly: false, stickyAuth: true),
                                localizedReason:
                                    "Authentication is activated. Please authenticate.");
                            if (didAuthenticate) {
                              didJustCloseAuthDialog = true;
                            }
                          } else {
                            didAuthenticate = true;
                          }
                        }

                        if (didAuthenticate) {
                          showingAuthDialog = false;
                          Navigator.pop(context);
                        }
                      })
                ],
              ));
        });
  }
}

class MoneyTextField extends StatefulWidget {
  final void Function(int?) onChanged;
  const MoneyTextField({required this.onChanged, Key? key}) : super(key: key);

  @override
  State<MoneyTextField> createState() => _MoneyTextFieldState();
}

class _MoneyTextFieldState extends State<MoneyTextField> {
  int? pricePayedCents = -1;
  String? errorText;
  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
          errorText: pricePayedCents == null ? errorText : null),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        try {
          pricePayedCents = int.parse(value);
          if (pricePayedCents! % 5 != 0 && pricePayedCents! <= 0) {
            pricePayedCents = null;
            errorText = "Input a positive multiple of 5";
          }
        } catch (e) {
          pricePayedCents = null;
          if (value == "") {
            errorText = "This field is empty";
          } else {
            errorText = "Input a whole, positive multiple of 5";
          }
        }
        widget.onChanged(pricePayedCents);
        setState(() {});
      },
    );
  }
}
