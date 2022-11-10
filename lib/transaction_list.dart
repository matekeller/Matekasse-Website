import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'graphql_helper.dart';
import 'transaction.dart';

class TransactionList extends StatefulWidget {
  final void Function(BuildContext context) onSocketException;
  final String username;
  const TransactionList(
      {Key? key, required this.onSocketException, this.username = "matekasse"})
      : super(key: key);

  @override
  State<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  List<Transaction> _transactions = [];
  bool _loading = false;
  late ScrollController scrollController;
  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    scrollController.addListener(_scrolledToBottom);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: (() async {
        try {
          if (_transactions.isNotEmpty) {
            return _transactions;
          }
          List<Transaction> transactions = [];

          if (widget.username != "matekasse") {
            transactions = await GraphQlHelper.getTransactionListByUser(
                username: widget.username);
          } else {
            transactions =
                await GraphQlHelper.getTransactionList(fromBeginning: true);
          }

          await GraphQlHelper.updateOfferings();

          return transactions;
        } on SocketException {
          widget.onSocketException(context);
        }
        return <Transaction>[];
      })(),
      builder: (context, AsyncSnapshot<List<Transaction>> snapshot) {
        if (snapshot.hasData) {
          _transactions = snapshot.data ?? [];
          return RefreshIndicator(
            onRefresh: _refreshTransactionList,
            child: ListView(
              shrinkWrap: true,
              controller: scrollController,
              children: [
                for (Transaction transaction in _transactions)
                  TransactionWidget(transaction: transaction),
                Visibility(
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                  visible: _loading,
                ),
                const SizedBox(
                  height: 700,
                  child: Icon(
                    FontAwesomeIcons.cat,
                    color: Colors.grey,
                    size: 50,
                  ),
                )
              ],
            ),
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  Future<void> _refreshTransactionList() async {
    try {
      if (widget.username != "matekasse") {
        _transactions = await GraphQlHelper.getTransactionListByUser(
            username: widget.username);
      } else {
        _transactions =
            await GraphQlHelper.getTransactionList(fromBeginning: true);
      }

      await GraphQlHelper.updateOfferings();
      setState(() {});
    } on SocketException {
      widget.onSocketException(context);
    }
  }

  void _scrolledToBottom() {
    if (!GraphQlHelper.hasNextPage) {
      return;
    }

    if (scrollController.position.extentAfter < 300 && !_loading) {
      setState(() {
        _loading = true;
      });
      if (widget.username != "matekasse") {
        GraphQlHelper.getTransactionListByUser(username: widget.username)
            .then((value) => setState(() {
                  _transactions.addAll(value);
                  _loading = false;
                }));
      } else {
        GraphQlHelper.getTransactionList().then((value) => setState(() {
              _transactions.addAll(value);
              _loading = false;
            }));
      }
    }
  }
}
