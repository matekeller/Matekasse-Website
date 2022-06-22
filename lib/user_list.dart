import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:matemate/graphql_helper.dart';

class UserWidget extends StatelessWidget {
  final User user;
  const UserWidget({required this.user, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // just showing the absolute value. Whether its positive or negative
    // internally doesnt matter
    return Container(
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
            Text(user.username, style: Theme.of(context).textTheme.bodyLarge),
            const Divider(),
            Text("Full Name: " + user.fullName),
            Text(
              "Balance: " +
                  (-user.balanceCents ~/ 100).toString() +
                  "," +
                  (-user.balanceCents % 100 < 10 ? "0" : "") +
                  (-user.balanceCents % 100).toString() +
                  "€",
            )
          ],
        ),
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
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          foregroundColor: Colors.white,
          iconTheme: Theme.of(context).iconTheme,
          title: const Text("Users"),
          leading: IconButton(
            icon: const Icon(FontAwesomeIcons.arrowLeft),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: FutureBuilder(
          future: () async {
            _users = await GraphQlHelper.updateAllUsers();
            return _users;
          }(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return RefreshIndicator(
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
                        FontAwesomeIcons.dog,
                        color: Colors.grey,
                        size: 50,
                      ),
                    ),
                  ],
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                  child: Text(
                      "There was an error.\n" + snapshot.error.toString()));
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      ),
    );
  }
}

class User {
  final String username;
  final String fullName;
  final int balanceCents;

  const User(
      {required this.username,
      required this.fullName,
      required this.balanceCents});
}
