import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:matemate/transaction_list.dart';

import 'user_stats.dart';

class History extends StatefulWidget {
  final String username;
  const History({Key? key, required this.username}) : super(key: key);

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Transaction History of ${widget.username}"),
        iconTheme: IconTheme.of(context),
        actions: [
          IconButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          UserStats(username: widget.username))),
              icon: const Icon(FontAwesomeIcons.chartLine))
        ],
      ),
      body: SafeArea(
        child: TransactionList(
          username: widget.username,
          onSocketException: (context) async {
            return await showDialog(
                context: context,
                builder: (context) {
                  return const Text("benis");
                });
          },
        ),
      ),
    );
  }
}
