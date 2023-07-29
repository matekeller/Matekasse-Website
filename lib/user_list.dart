import 'dart:math';

import 'package:flutter/gestures.dart';
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
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4)
              : Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
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
                      icon: Icon(
                        FontAwesomeIcons.ellipsis,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                      .format(user.balanceCents == 0
                          ? 0
                          : user.balanceCents.toDouble() * (-1) / 100)),
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
        contentPadding: const EdgeInsets.only(left: 8, right: 8),
        titlePadding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
        title: const Text("New BluecardID"),
        children: [
          UserScanRow(
            onChanged: (bluecardId) {
              newBlueCardId = bluecardId ?? oldBluecardId;
            },
          ),
          FilledButton(
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

enum SortMode { nameDesc, nameAsc, balanceDesc, balanceAsc }

enum AscOrDesc { asc, desc }

class UserList extends StatefulWidget {
  const UserList({Key? key}) : super(key: key);

  @override
  State<UserList> createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  List<User> _users = [];
  SortMode compare = SortMode.nameAsc;
  AscOrDesc ascordesc = AscOrDesc.asc;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<User>>(future: () async {
      _users = await GraphQlHelper.updateAllUsers();
      return _users..sort(getCompare(compare));
    }(), builder: (context, snapshot) {
      return SafeArea(
        child: Scaffold(
          appBar: AppBar(
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
                  icon: const Icon(Icons.search)),
              PopupMenuButton(
                child: const Icon(Icons.more_vert),
                itemBuilder: (context) => <PopupMenuEntry>[
                  CheckedTappablePopupMenuItem(
                    child: const Text("Sort by name"),
                    checked: compare == SortMode.nameAsc ||
                        compare == SortMode.nameDesc,
                    onTap: () {
                      if (!(compare == SortMode.nameAsc ||
                          compare == SortMode.nameDesc)) {
                        // not checked?
                        setState(() => compare = ascordesc == AscOrDesc.asc
                            ? SortMode.nameAsc
                            : SortMode.nameDesc);
                      }
                    },
                  ),
                  CheckedTappablePopupMenuItem(
                    child: const Text("Sort by balance"),
                    onTap: () {
                      if (!(compare == SortMode.balanceAsc ||
                          compare == SortMode.balanceDesc)) {
                        // not checked?
                        setState(() => compare = ascordesc == AscOrDesc.asc
                            ? SortMode.balanceAsc
                            : SortMode.balanceDesc);
                      }
                    },
                    checked: compare == SortMode.balanceAsc ||
                        compare == SortMode.balanceDesc,
                  ),
                  const PopupMenuDivider(),
                  CheckedTappablePopupMenuItem(
                    child: const Text("Sort ascending"),
                    checked: ascordesc == AscOrDesc.asc,
                    onTap: () {
                      if (ascordesc != AscOrDesc.asc) {
                        // not checked?
                        setState(() => compare = compare == SortMode.nameDesc
                            ? SortMode.nameAsc
                            : SortMode.balanceAsc);
                      }
                    },
                  ),
                  CheckedTappablePopupMenuItem(
                    child: const Text("Sort descending"),
                    checked: ascordesc == AscOrDesc.desc,
                    onTap: () {
                      if (ascordesc != AscOrDesc.desc) {
                        // not checked?
                        setState(() => compare = compare == SortMode.nameAsc
                            ? SortMode.nameDesc
                            : SortMode.balanceDesc);
                      }
                    },
                  )
                ],
              ),
            ],
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Container(
            child: ((snapshot.hasData
                ? RefreshIndicator(
                    color: Theme.of(context).colorScheme.primary,
                    onRefresh: () async {
                      _users = await GraphQlHelper.updateAllUsers();
                      setState(
                        () {},
                      );
                    },
                    child: ListView(
                      children: [
                        for (User user in _users) UserWidget(user: user),
                        SizedBox(
                          height: 700,
                          child: Icon(
                            FontAwesomeIcons.cat,
                            color: Theme.of(context).colorScheme.onBackground,
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
      );
    });
  }

  int Function(User, User)? getCompare(SortMode mode) {
    switch (mode) {
      case SortMode.nameAsc:
        return (a, b) => a.username.compareTo(b.username);
      case SortMode.nameDesc:
        return (a, b) => b.username.compareTo(a.username);
      case SortMode.balanceAsc:
        return (a, b) => b.balanceCents.compareTo(a.balanceCents);
      case SortMode.balanceDesc:
        return (a, b) => a.balanceCents.compareTo(b.balanceCents);
      default:
        return (a, b) => a.username.compareTo(b.username);
    }
  }
}

class CheckedTappablePopupMenuItem<T> extends PopupMenuItem<T> {
  final bool checked;

  const CheckedTappablePopupMenuItem(
      {super.key,
      super.value,
      this.checked = false,
      super.enabled,
      super.padding,
      super.height,
      super.mouseCursor,
      super.child,
      super.onTap});

  @override
  PopupMenuItemState<T, CheckedTappablePopupMenuItem<T>> createState() =>
      _CheckedTappablePopupMenuItemState<T>();
}

class _CheckedTappablePopupMenuItemState<T>
    extends PopupMenuItemState<T, CheckedTappablePopupMenuItem<T>>
    with SingleTickerProviderStateMixin {
  static const Duration _fadeDuration = Duration(milliseconds: 150);
  late AnimationController _controller;
  Animation<double> get _opacity => _controller.view;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: _fadeDuration, vsync: this)
      ..value = widget.checked ? 1.0 : 0.0
      ..addListener(() => setState(() {/* animation changed */}));
  }

  @override
  void handleTap() {
    // This fades the checkmark in or out when tapped.
    if (widget.checked) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    super.handleTap();
  }

  @override
  Widget buildChild() {
    return IgnorePointer(
      child: ListTile(
        enabled: widget.enabled,
        onTap: widget.onTap,
        leading: FadeTransition(
          opacity: _opacity,
          child: Icon(_controller.isDismissed ? null : Icons.done),
        ),
        title: widget.child,
      ),
    );
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

  @override
  Widget buildResults(BuildContext context) {
    List<User> results = userList.where((user) {
      final result = user.username.toLowerCase();
      final input = query.toLowerCase();

      return result.contains(input);
    }).toList();

    return ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final suggestion = results[index];

          return UserWidget(user: suggestion);
        });
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<User> suggestions = userList.where((user) {
      final result = user.username.toLowerCase();
      final input = query.toLowerCase();

      return input == "" ? false : result.contains(input);
    }).toList();
    suggestions = suggestions.sublist(0, min(5, suggestions.length));

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];

        return ListTile(
            title: Text(suggestion.username),
            subtitle: Text(suggestion.fullName),
            onTap: () {
              query = suggestion.username;
              buildResults(context);
              showResults(context);
            });
      },
    );
  }
}
