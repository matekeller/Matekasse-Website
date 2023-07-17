import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:matemate/graphql_helper.dart';
import 'package:matemate/util/widgets/scaffolded_dialog.dart';
import 'package:matemate/util/widgets/user_scan_row.dart';
import 'package:matemate/history.dart';

class UserWidget extends StatelessWidget {
  final User user;
  const UserWidget({required this.user, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // just showing the absolute value. Whether its positive or negative
    // internally doesnt matter
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: user.bluecardId));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text("Copied BluecardID ${user.bluecardId} to Clipboard!")));
      },
      child: Container(
        margin: const EdgeInsets.all(12.0),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.white,
            //border: Border.all(width: 2, color: Colors.blueGrey),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(offset: Offset(0, 5), blurRadius: 5, color: Colors.grey)
            ]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(user.username,
                      style: Theme.of(context).textTheme.bodyLarge),
                  PopupMenuButton(
                      itemBuilder: (context) => [
                            PopupMenuItem(
                              child: const Text("Change BluecardID"),
                              onTap: () async {
                                WidgetsBinding.instance.addPostFrameCallback(
                                  (_) {
                                    _showChangeBluecardIdDialog(
                                        oldBluecardId: user.bluecardId,
                                        context: context);
                                  },
                                );
                              },
                            ),
                            PopupMenuItem(
                              child: const Text("Transaction History"),
                              onTap: () async {
                                WidgetsBinding.instance.addPostFrameCallback(
                                    (_) => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => History(
                                                username: user.username))));
                              },
                            )
                          ],
                      icon: const Icon(
                        FontAwesomeIcons.ellipsis,
                        color: Colors.grey,
                      ))
                ],
              ),
              const Divider(),
              Text("Full Name: " + user.fullName),
              Text('BluecardID: ${user.bluecardId}'),
              Text("SmartCards: " + user.smartcards.length.toString()),
              Text("Balance: " +
                  NumberFormat.currency(
                          locale: "de_DE",
                          symbol: "€",
                          customPattern: '#,##0.00\u00A4')
                      .format(user.balanceCents.toDouble() * (-1) / 100)),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangeBluecardIdDialog(
      {required String oldBluecardId, required BuildContext context}) {
    String newBlueCardId = oldBluecardId;
    bool canPop = true;
    showDialog(
      context: context,
      builder: (context) => ScaffoldedDialog(
        contentPadding: const EdgeInsets.all(8),
        titlePadding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
        title: const Text("New BluecardID"),
        children: [
          UserScanRow(
            onChanged: (bluecardId) {
              newBlueCardId = bluecardId ?? oldBluecardId;
            },
          ),
          TextButton(
              onPressed: () async {
                bool success = await GraphQlHelper.updateBluecardId(
                    oldBluecardId, newBlueCardId);
                if (success) {
                  if (canPop) {
                    canPop = false;
                    Navigator.pop(context);
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("There was an error. Please try again")));
                }
              },
              child: const Text("Submit"))
        ],
      ),
    );
  }
}

class UserList extends StatefulWidget {
  const UserList({Key? key}) : super(key: key);

  @override
  State<UserList> createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  List<User> _users = [];
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<User>>(future: () async {
      _users = await GraphQlHelper.updateAllUsers();
      return _users;
    }(), builder: (context, snapshot) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.amber,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.light,
        ),
        child: SafeArea(
          child: Scaffold(
            appBar: AppBar(
              foregroundColor: Colors.white,
              iconTheme: Theme.of(context).iconTheme,
              title: const Text("Users"),
              actions: [
                IconButton(
                    onPressed: !snapshot.hasData
                        ? null
                        : () {
                            showSearch(
                                context: context,
                                delegate: UserSearchDelegate(
                                    userList: snapshot.data ?? []));
                          },
                    icon: const Icon(Icons.search))
              ],
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Container(
              child: ((snapshot.hasData
                  ? RefreshIndicator(
                      onRefresh: () async {
                        _users = await GraphQlHelper.updateAllUsers();
                        setState(
                          () {},
                        );
                      },
                      child: ListView(
                        children: [
                          for (User user in _users) UserWidget(user: user),
                          const SizedBox(
                            height: 700,
                            child: Icon(
                              FontAwesomeIcons.cat,
                              color: Colors.grey,
                              size: 50,
                            ),
                          ),
                        ],
                      ),
                    )
                  : (snapshot.hasError
                      ? Center(
                          child: Text("There was an error.\n" +
                              snapshot.error.toString()))
                      : const Center(
                          child: CircularProgressIndicator(),
                        )))),
            ),
          ),
        ),
      );
    });
  }
}

class User {
  final String bluecardId;
  final List<String> smartcards;
  final String username;
  final String fullName;
  final int balanceCents;
  final bool isAdmin;

  const User(
      {required this.username,
      required this.fullName,
      required this.balanceCents,
      required this.bluecardId,
      required this.smartcards,
      required this.isAdmin});
}

class UserSearchDelegate extends SearchDelegate {
  UserSearchDelegate({
    required this.userList,
  });
  final List<User> userList;

// Prevent SearchDelegate from applying dark AppBarTheme
  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
        appBarTheme: const AppBarTheme(
          systemOverlayStyle:
              SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
          foregroundColor: Colors.white,
        ),
        textTheme: Theme.of(context)
            .textTheme
            .copyWith(titleLarge: const TextStyle(color: Colors.white)),
        inputDecorationTheme: const InputDecorationTheme(
            hintStyle: TextStyle(color: Colors.white)));
  }

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null));
  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            if (query.isEmpty) {
              close(context, null);
            } else {
              query = '';
            }
          },
        ),
      ];

  @override // unused
  Widget buildResults(BuildContext context) => ListView(children: [
        UserWidget(
            user: userList.firstWhere(
                (user) => user.username == query || user.username.contains("")))
      ]);

  @override
  Widget buildSuggestions(BuildContext context) {
    List<User> suggestions = userList.where((user) {
      final result = user.username.toLowerCase();
      final input = query.toLowerCase();

      return result.contains(input);
    }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];

        return UserWidget(user: suggestion);
      },
    );
  }
}
