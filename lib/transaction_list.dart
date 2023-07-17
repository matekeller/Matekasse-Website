import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'graphql_helper.dart';
import 'transaction.dart';

class TransactionList extends StatefulWidget {
  final void Function(BuildContext context) onSocketException;
  final String username;
  const TransactionList(
      {Key? key, required this.onSocketException, this.username = "asdf"})
      : super(key: key);

  @override
  State<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  List<Transaction> _transactions = [];
  bool _loading = false;
  late ScrollController scrollController;
  late int endCursor;
  int timesScrolledToBottom = 0;
  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    scrollController.addListener(_scrolledToBottom);
    GraphQlHelper.getEndCursor().then((value) => setState(() {
          endCursor = value;
        }));
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

          if (widget.username != "asdf") {
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
                  !transaction.deleted
                      ? getDismissible(transaction, context)
                      : TransactionWidget(transaction: transaction),
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

  Dismissible getDismissible(Transaction transaction, BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      child: TransactionWidget(transaction: transaction),
      onDismissed: (direction) async {
        if (transaction.offeringName == "topup") {
          var balanceOfUser = (await GraphQlHelper.updateAllUsers())
                  .firstWhere((element) =>
                      element.username == transaction.payerUsername)
                  .balanceCents *
              -1;

          if (balanceOfUser - (transaction.pricePaidCents * -1) < 0) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    "Transaction deletion denied. Deletion would result in negative user balance.")));
          } else {
            await GraphQlHelper.undoPurchase(transaction.id);
            setState(
              () {},
            );
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    'Transaction with ID ${transaction.id} by payer ${transaction.payerUsername} dismissed.')));
          }
        } else {
          await GraphQlHelper.undoPurchase(transaction.id);
          setState(
            () {},
          );
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Transaction with ID ${transaction.id} by payer ${transaction.payerUsername} dismissed.')));
        }
      },
      confirmDismiss: (DismissDirection direction) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Are you sure you want to delete?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Yes'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('No'),
                )
              ],
            );
          },
        );

        return confirmed;
      },
    );
  }

  Future<void> _refreshTransactionList() async {
    try {
      if (widget.username != "asdf") {
        _transactions = await GraphQlHelper.getTransactionListByUser(
            username: widget.username);
      } else {
        _transactions =
            await GraphQlHelper.getTransactionList(fromBeginning: true);
      }

      await GraphQlHelper.updateOfferings();
      GraphQlHelper.getEndCursor().then((value) {
        endCursor = value;
      });
      timesScrolledToBottom = 0;
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
        timesScrolledToBottom += 1;
        _loading = true;
      });
      if (widget.username != "asdf") {
        GraphQlHelper.getTransactionListByUser(username: widget.username)
            .then((value) => setState(() {
                  _transactions.addAll(value);
                  _loading = false;
                }));
      } else {
        GraphQlHelper.getTransactionList(
                after: endCursor - timesScrolledToBottom * 10 + 1)
            .then((value) => setState(() {
                  _transactions.addAll(value);
                  _loading = false;
                }));
      }
    }
  }
}
