import 'package:flutter/material.dart';
import 'package:matemate/graphql_helper.dart';
import 'package:matemate/transaction.dart';
import 'package:matemate/user_stats.dart';

import 'user_list.dart';

class UserPage extends StatefulWidget {
  final String username;
  const UserPage({Key? key, required this.username}) : super(key: key);

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  late Future<Map> futureData;

  Future<Map> getData() async {
    List<User> _users = await GraphQlHelper.updateAllUsers();
    List<Transaction> transactions =
        await GraphQlHelper.getTransactionListByUser(username: widget.username);
    Map<User, List<Transaction>> _transactions = {};
    User _user =
        _users.firstWhere((element) => element.username == widget.username);
    _transactions.addEntries({_user: transactions}.entries);
    return _transactions;
  }

  @override
  void initState() {
    super.initState();
    futureData = getData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map>(
      future: futureData,
      builder: ((context, snapshot) {
        if (snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: Text("User Page of ${widget.username}"),
              iconTheme: IconTheme.of(context),
            ),
            body: SafeArea(
                child: ListView(
              children: [
                UserWidget(
                    user: User(
                        balanceCents: snapshot.data!.keys.first.balanceCents,
                        bluecardId: snapshot.data!.keys.first.bluecardId,
                        smartcards: snapshot.data!.keys.first.smartcards,
                        fullName: snapshot.data!.keys.first.fullName,
                        username: snapshot.data!.keys.first.username,
                        isAdmin: snapshot.data!.keys.first.isAdmin)),
                const Divider(),
                ListTile(
                    title: const Text(
                      "Transactions:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: TextButton(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return UserStats(
                          username: widget.username,
                        );
                      })),
                      child: const Text("Graph"),
                    )),
                for (Transaction transaction in snapshot.data!.values.first)
                  TransactionWidget(transaction: transaction)
              ],
            )),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      }),
    );
  }
}
