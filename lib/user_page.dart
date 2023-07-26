import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

    transactions = _insertDates(transactions);
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
                    trailing: FilledButton.tonal(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return UserStats(
                          username: widget.username,
                        );
                      })),
                      child: const Text("Graph"),
                    )),
                for (Transaction transaction in snapshot.data!.values.first)
                  transaction.offeringName != "Date"
                      ? TransactionWidget(transaction: transaction)
                      : Padding(
                          padding: const EdgeInsets.only(top: 5, bottom: 5),
                          child: Row(children: [
                            const Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(left: 5, right: 5),
                                child: Divider(),
                              ),
                            ),
                            Text(
                                DateFormat("EEEE, dd.MM.yyyy", "de_DE").format(
                                    DateFormat("yy-MM-dd HH:mm:ss")
                                        .parse(
                                            transaction.date.toString(), true)
                                        .toLocal()),
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.outline)),
                            const Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(left: 5, right: 5),
                                child: Divider(),
                              ),
                            ),
                          ]))
              ],
            )),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      }),
    );
  }

  List<Transaction> _insertDates(List<Transaction> transactions) {
    var insertions = [];

    for (Transaction element in transactions) {
      var transactionsDate = DateFormat("yy-MM-dd HH:mm:ss")
          .parse(element.date.toString(), true)
          .toLocal();
      var transactionsDay = DateTime(
          transactionsDate.year, transactionsDate.month, transactionsDate.day);

      if (element.offeringName != "Date" &&
          transactions.indexOf(element) != 0) {
        var prev = transactions[transactions.indexOf(element) - 1];

        var previousTransactionsDate = DateFormat("yy-MM-dd HH:mm:ss")
            .parse(prev.date.toString(), true)
            .toLocal();
        var previousTransactionsDay = DateTime(previousTransactionsDate.year,
            previousTransactionsDate.month, previousTransactionsDate.day);

        if (prev.offeringName != "Date" &&
            previousTransactionsDay.isAfter(transactionsDay)) {
          insertions.add({
            "tr": Transaction(
                payerUsername: "",
                adminUsername: "",
                offeringName: "Date",
                pricePaidCents: 0,
                date: transactionsDay,
                id: 0,
                deleted: false),
            "idx": transactions.indexOf(element)
          });
        } else {
          continue;
        }
      } else {
        element.offeringName != "Date"
            ? insertions.add({
                "tr": Transaction(
                    payerUsername: "",
                    adminUsername: "",
                    offeringName: "Date",
                    pricePaidCents: 0,
                    date: transactionsDay,
                    id: 0,
                    deleted: false),
                "idx": 0
              })
            : {};
        continue;
      }
    }

    var timesInserted = 0;
    for (Map element in insertions) {
      transactions.insert(element["idx"] + timesInserted, element["tr"]);
      timesInserted += 1;
    }

    return transactions;
  }
}
