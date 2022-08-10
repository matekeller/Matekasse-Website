import 'dart:io';

import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:matemate/graphql_helper.dart';
import 'package:matemate/local_store.dart';
import 'package:matemate/nfc_scanner.dart';
import 'package:matemate/offering.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:matemate/user_list.dart';
import 'package:matemate/util/widgets/scaffolded_dialog.dart';
import 'package:matemate/util/widgets/user_scan_row.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'offering_grid.dart';
import 'transaction_list.dart';

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

class _MyHomePageState extends State<MyHomePage> {
  // Flags indicating which dialogs are open
  bool showingSignInDialog = false;
  bool showingNewUserDialog = false;
  bool showingPurchaseDialog = false;
  bool showingTopUpDialog = false;
  bool showingNoConnectionDialog = false;

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
              const Divider(),
              ListTile(
                leading: const Icon(FontAwesomeIcons.arrowRightFromBracket),
                title: const Text("Log out"),
                onTap: () {
                  LocalStore.authToken = "";
                  LocalStore.userName = "";
                  LocalStore.password = "";
                  Navigator.pop(context);
                  _signIn(context);
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
        floatingActionButton: FabCircularMenu(
          animationDuration: const Duration(milliseconds: 100),
          ringWidth: 40,
          ringDiameter: 300,
          fabOpenIcon: const Icon(
            FontAwesomeIcons.plus,
            color: Colors.white,
          ),
          fabCloseIcon: const Icon(FontAwesomeIcons.xmark, color: Colors.white),
          children: [
            IconButton(
              onPressed: () {
                _showNewUserDialog();
              },
              icon: const Icon(
                FontAwesomeIcons.user,
                color: Colors.white,
              ),
            ),
            IconButton(
              onPressed: () {
                _showTopUpDialog();
              },
              icon: const Icon(
                FontAwesomeIcons.euroSign,
                color: Colors.white,
              ),
            ),
            IconButton(
              onPressed: () {
                _showPurchaseDialog();
              },
              icon: const Icon(
                FontAwesomeIcons.wineBottle,
                color: Colors.white,
              ),
            ),
          ],
        ),
        //makes auto-formatting nicer for build methods.
      ),
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
              Navigator.pop(context);
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
      builder: (context) => ScaffoldedDialog(
        contentPadding: const EdgeInsets.all(8),
        titlePadding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
        title: const Text("New User"),
        children: [
          const Text("Username"),
          const SizedBox(
            height: 10,
          ),
          TextField(
            onChanged: (value) => username = value,
          ),
          const SizedBox(
            height: 20,
          ),
          const Text("Full Name"),
          const SizedBox(
            height: 10,
          ),
          TextField(
            onChanged: ((value) => fullName = value),
          ),
          const SizedBox(
            height: 20,
          ),
          const Text("Bluecard ID"),
          const SizedBox(
            height: 10,
          ),
          UserScanRow(onChanged: (value) => bluecardId = value),
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
                    content: Text("A user with this username already exists")));
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
              if (GraphQlHelper.getUsernameByBluecardId(bluecardId!) != null) {
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
                    content: Text("The password needs at least 8 characters")));
                return;
              }
              // No problem occured, we can add the user
              try {
                GraphQlHelper.addUser(username, fullName, password, bluecardId);
                showingNewUserDialog = false;
                Navigator.pop(context);
              } on SocketException {
                _showNoConnectionDialog(context);
              }
            },
          ),
        ],
      ),
    );
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
    String? selectedOfferingName;
    String? username;
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
                      onChanged: (newSelectedTile) {
                        selectedOfferingName = newSelectedTile;
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
                  if (selectedOfferingName == null) {
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
                  if (_users
                              .firstWhere(
                                  (element) => element.username == username)
                              .balanceCents *
                          (-1) < //Taking the additive inverse, because backend stores balance as negative.
                      LocalStore.offerings
                          .firstWhere(
                              (element) => element.name == selectedOfferingName)
                          .priceCents) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            "The user does not have enough money on their account: ${_users.firstWhere((element) => element.username == username).balanceCents}ct.")));
                    return;
                  }
                  try {
                    GraphQlHelper.purchaseProduct(
                        username!, selectedOfferingName!);
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
