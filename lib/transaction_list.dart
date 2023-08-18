import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'graphql_helper.dart';
import 'transaction.dart';

class TransactionList extends StatefulWidget {
  final void Function(BuildContext context) onSocketException;
  String username;
  TransactionList(
      {Key? key, required this.onSocketException, required this.username})
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
    initializeData();
  }

  Future<void> initializeData() async {
    try {
      endCursor = await GraphQlHelper.getEndCursor();
      await fetchTransactions();
    } on SocketException {
      widget.onSocketException(context);
    }
  }

  Future<void> fetchTransactions() async {
    List<Transaction> transactions = [];
    try {
      if (_transactions.isNotEmpty) {
        return;
      }

      transactions =
          await GraphQlHelper.getTransactionList(fromBeginning: true);

      await GraphQlHelper.updateOfferings();

      transactions = _insertDates(transactions);

      setState(() {
        _transactions = transactions;
      });
    } on SocketException {
      widget.onSocketException(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    initializeDateFormatting("de_DE");
    return FutureBuilder(
      future: (() async {
        try {
          if (_transactions.isNotEmpty) {
            return _transactions;
          }
          List<Transaction> transactions = [];

          transactions =
              await GraphQlHelper.getTransactionList(fromBeginning: true);

          await GraphQlHelper.updateOfferings();

          transactions = _insertDates(transactions);

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
            color: Theme.of(context).colorScheme.primary,
            onRefresh: _refreshTransactionList,
            child: ListView(
                shrinkWrap: true,
                controller: scrollController,
                children: _transactions
                    .map((transaction) => transaction.offeringName != "Date"
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
                                  DateFormat("EEEE, dd.MM.yyyy", "de_DE")
                                      .format(DateFormat("yy-MM-dd HH:mm:ss")
                                          .parse(
                                              transaction.date.toString(), true)
                                          .toLocal()),
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline)),
                              const Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(left: 5, right: 5),
                                  child: Divider(),
                                ),
                              ),
                            ])))
                    .toList()),
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  List<Transaction> _insertDates(List<Transaction> transactions) {
    // Initialize with first transactions' date
    List<Map> insertions = [
      {
        "tr": Transaction(
            payerUsername: "",
            adminUsername: "",
            offeringName: "Date",
            pricePaidCents: 0,
            date: DateTime(
                DateFormat("yy-MM-dd HH:mm:ss")
                    .parse(transactions.first.date.toString(), true)
                    .toLocal()
                    .year,
                DateFormat("yy-MM-dd HH:mm:ss")
                    .parse(transactions.first.date.toString(), true)
                    .toLocal()
                    .month,
                DateFormat("yy-MM-dd HH:mm:ss")
                    .parse(transactions.first.date.toString(), true)
                    .toLocal()
                    .day),
            id: 0,
            deleted: false),
        "idx": 0
      }
    ];

    insertions = transactions
        .where((element) =>
            element.offeringName != "Date" &&
            transactions.indexOf(element) != 0)
        .map((element) {
      var transactionsDate = DateFormat("yy-MM-dd HH:mm:ss")
          .parse(element.date.toString(), true)
          .toLocal();
      var transactionsDay = DateTime(
          transactionsDate.year, transactionsDate.month, transactionsDate.day);
      var prev = transactions[transactions.indexOf(element) - 1];

      var previousTransactionsDate = DateFormat("yy-MM-dd HH:mm:ss")
          .parse(prev.date.toString(), true)
          .toLocal();
      var previousTransactionsDay = DateTime(previousTransactionsDate.year,
          previousTransactionsDate.month, previousTransactionsDate.day);

      return (previousTransactionsDay, transactionsDay, prev, element);
    }).where((element) {
      return element.$3.offeringName != "Date" &&
          element.$1.isAfter(element.$2);
    }).fold(
            insertions,
            (prev, element) => prev
              ..add({
                "tr": Transaction(
                    payerUsername: "",
                    adminUsername: "",
                    offeringName: "Date",
                    pricePaidCents: 0,
                    date: element.$2,
                    id: 0,
                    deleted: false),
                "idx": transactions.indexOf(element.$4)
              }));

    var timesInserted = 0;
    for (Map element in insertions) {
      transactions.insert(element["idx"] + timesInserted, element["tr"]);
      timesInserted += 1;
    }

    return transactions;
  }

  Future<void> _refreshTransactionList() async {
    try {
      _transactions =
          await GraphQlHelper.getTransactionList(fromBeginning: true);
      _transactions = _insertDates(_transactions);

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

      GraphQlHelper.getTransactionList().then((value) => setState(() {
            _transactions.addAll(value);
            _transactions = _insertDates(_transactions);
            _loading = false;
          }));
    }
  }
}
