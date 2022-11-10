import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:matemate/graphql_helper.dart';
import 'package:matemate/transaction_list.dart';
import 'package:matemate/user_list.dart';
import 'package:matemate/transaction_list.dart';

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
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.amber,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.light,
          ),
          foregroundColor: Colors.white,
          title: Text("Transaction History of ${widget.username}"),
          iconTheme: IconTheme.of(context)),
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
