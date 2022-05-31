import 'dart:io';

import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:matemate/graphql_helper.dart';
import 'package:matemate/local_store.dart';
import 'package:matemate/offering.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
      home: const MyHomePage(title: 'Transactions'),
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
                leading: const Icon(FontAwesomeIcons.arrowRightFromBracket),
                title: const Text("Log out"),
                onTap: () {
                  LocalStore.authToken = "";
                  LocalStore.userName = "";
                  LocalStore.password = "";
                  Navigator.pop(context);
                  _signIn(context);
                },
              )
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
                FontAwesomeIcons.dollarSign,
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
    String newUserName = "";
    String newPassword = "";
    bool authTokenExpired = true;
    try {
      authTokenExpired = JwtDecoder.isExpired(LocalStore.authToken);
      print(authTokenExpired);
    } catch (e) {
      // There is no auth token, therefore it cant be valid.
    }
    while (authTokenExpired) {
      try {
        await GraphQlHelper.signIn(LocalStore.userName, LocalStore.password);
      } on InvalidSignInCredentialsException {
        await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) => SimpleDialog(
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
                  Navigator.pop(context);
                },
              )
            ],
          ),
        );
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

  Future<void> _showNewUserDialog() async {
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
      builder: (context) => SimpleDialog(
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
          const Text("Bluecard Id"),
          const SizedBox(
            height: 10,
          ),
          BarcodeScanRow(onChanged: (value) => bluecardId = value),
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
                Navigator.pop(context);
              } on SocketException {
                _showNoConnectionDialog(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showTopUpDialog() async {
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
      builder: (context) => SimpleDialog(
        contentPadding: const EdgeInsets.all(8),
        titlePadding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
        title: const Text("Top-Up"),
        children: [
          const Text("Ammount €"),
          MoneyTextField(onChanged: (newPrice) => pricePaidEuros = newPrice),
          const SizedBox(
            height: 16,
          ),
          const Text("Payer-Code:"),
          BarcodeScanRow(
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
                Navigator.pop(context);
              } on SocketException {
                _showNoConnectionDialog(context);
              }
            },
          )
        ],
      ),
    );
  }

  Future<void> _showPurchaseDialog() async {
    String? selectedOfferingName;
    String? username;
    try {
      await GraphQlHelper.updateAllUsers();
    } on SocketException {
      _showNoConnectionDialog(context);
      return;
    }
    await showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          contentPadding: const EdgeInsets.all(8),
          titlePadding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
          title: const Text("Pruchase"),
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
            BarcodeScanRow(onChanged: (newBluecardId) {
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
  }

  Future<void> _showNoConnectionDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => SimpleDialog(
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
          if (pricePayedCents! % 5 != 0) {
            pricePayedCents = null;
            errorText = "Input a multiple of 5";
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

/// A simple row containing a text field and a button for a barcode scanner
/// After scanning, the textfield contains the scanned value, but can be explicitly edited
class BarcodeScanRow extends StatefulWidget {
  final void Function(String?) onChanged;

  /// How many scans have to be the same at the same time, improves accuracy
  final int redundantScans;
  const BarcodeScanRow(
      {required this.onChanged, this.redundantScans = 3, Key? key})
      : super(key: key);

  @override
  State<BarcodeScanRow> createState() => _BarcodeScanRowState();
}

class _BarcodeScanRowState extends State<BarcodeScanRow> {
  String? code;

  /// Once in a while, a barcode will be scanned incorrectly, but almost never
  /// twice in a row in the same way. Therefore, we scan multiple times until
  /// all [redundantScans] last scans are the same.
  List<String> scannedCodes = [];

  /// For some reason, the scanning widget would be popped many times after scanning,
  /// crashing the app. This ensures that this wont happen
  bool canPop = true;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (value) {
              code = value;
              widget.onChanged(code);
            },
            controller: TextEditingController(text: code ?? ""),
          ),
        ),
        TextButton(
            onPressed: () async {
              scannedCodes = [];
              canPop = true;
              Navigator.of(context)
                  .push(
                MaterialPageRoute(
                  builder: (context) => MobileScanner(
                    allowDuplicates: true,
                    controller: MobileScannerController(),
                    onDetect: (barcode, args) {
                      // Removes the earliest scan if the list would get too long
                      if (scannedCodes.length >= widget.redundantScans) {
                        scannedCodes.removeAt(0);
                      }
                      // adds the newest scan
                      scannedCodes.add(barcode.rawValue ?? "");
                      // if we have enough scans, it changes the value if and
                      // only if all scans are the same.
                      if (scannedCodes.length == widget.redundantScans) {
                        for (int i = 1; i < widget.redundantScans; i++) {
                          if (scannedCodes[i] != scannedCodes[0]) {
                            return;
                          }
                        }
                        // Ensuring that everything is only popped once.
                        if (canPop) {
                          code = scannedCodes[0];
                          Navigator.of(context).pop();
                          canPop = false;
                        }
                      }
                    },
                  ),
                ),
              )
                  .then((value) {
                setState(() {
                  widget.onChanged(code);
                });
              });
            },
            child: const Icon(
              FontAwesomeIcons.barcode,
            ))
      ],
    );
  }
}
