import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:matemate/graphql_helper.dart';
import 'package:matemate/local_store.dart';
import 'package:matemate/offering.dart';
import 'package:matemate/transaction.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class Statistics extends StatefulWidget {
  const Statistics({
    Key? key,
  }) : super(key: key);

  @override
  State<Statistics> createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics>
    with SingleTickerProviderStateMixin {
  List<Transaction> transactions = [];
  List<Transaction> transactionsToHandle = [];
  late TabController _tabController;
  var tabIndex = 0;

  @override
  void initState() {
    super.initState();

    GraphQlHelper.getTransactionList(fromBeginning: true, first: 100000).then(
      (value) {
        setState(() {
          transactions = value.where((element) => !element.deleted).toList();
        });
      },
    );
    _tabController = TabController(length: 4, vsync: this);

    _tabController.addListener(() {
      setState(() {
        tabIndex = _tabController.index;
        transactionsToHandle =
            getTransactionSlice(transactions, _tabController.index);
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Transaction>>(future: () async {
      transactionsToHandle = getTransactionSlice(transactions, tabIndex);

      return transactionsToHandle;
    }(), builder: ((context, snapshot) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.amber,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.light,
          ),
          child: SafeArea(
              child: Scaffold(
            appBar: AppBar(
                bottom: TabBar(
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  controller: _tabController,
                  tabs: const [
                    Text("Today"),
                    Text("Last Month"),
                    Text("Last Year"),
                    Text("All")
                  ],
                ),
                foregroundColor: Colors.white,
                iconTheme: Theme.of(context).iconTheme,
                title: const Text("Statistics"),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                )),
            body: TabBarView(controller: _tabController, children: [
              ((snapshot.hasData && transactions.isNotEmpty
                  ? Column(
                      children: [
                        const Text("Offerings",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                            child: ListView.separated(
                                itemBuilder: (context, index) {
                                  Offering offering = (LocalStore.offerings
                                    ..sort((b, a) {
                                      var compare = transactionsToHandle
                                          .where((element) =>
                                              element.offeringName == a.name)
                                          .length
                                          .compareTo(transactionsToHandle
                                              .where((element) =>
                                                  element.offeringName ==
                                                  b.name)
                                              .length);
                                      return compare == 0
                                          ? b.readableName
                                              .compareTo(a.readableName)
                                          : compare;
                                    }))[index];

                                  return ListTile(
                                    contentPadding: const EdgeInsets.all(4),
                                    leading: CachedNetworkImage(
                                      imageUrl: offering.imageUrl,
                                      placeholder: (context, url) =>
                                          const CircularProgressIndicator(),
                                    ),
                                    title: Text(offering.readableName),
                                    subtitle: RichText(
                                        text: TextSpan(
                                            style: DefaultTextStyle.of(context)
                                                .style,
                                            children: <TextSpan>[
                                          const TextSpan(
                                              text: "Sold: ",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          TextSpan(
                                              text: transactionsToHandle
                                                  .where((element) =>
                                                      element.offeringName ==
                                                      offering.name)
                                                  .length
                                                  .toString()),
                                          const TextSpan(
                                              text: "\nTotal: ",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          TextSpan(
                                              text: NumberFormat(
                                                      "###0.00", "de")
                                                  .format(transactionsToHandle
                                                          .where((element) =>
                                                              element
                                                                  .offeringName ==
                                                              offering.name)
                                                          .fold<int>(
                                                              0,
                                                              (sum, transaction) =>
                                                                  sum +
                                                                  transaction
                                                                      .pricePaidCents)
                                                          .toDouble() /
                                                      100)),
                                          const TextSpan(text: "€")
                                        ])),
                                  );
                                },
                                separatorBuilder: (context, index) =>
                                    const Divider(),
                                itemCount: LocalStore.offerings.length))
                      ],
                    )
                  : (snapshot.hasError
                      ? Center(
                          child: Text("There was an error.\n" +
                              snapshot.error.toString()))
                      : const Center(child: CircularProgressIndicator())))),
              ((snapshot.hasData && transactions.isNotEmpty
                  ? Column(
                      children: [
                        const Text("Offerings",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                            child: ListView.separated(
                                itemBuilder: (context, index) {
                                  Offering offering = (LocalStore.offerings
                                    ..sort((b, a) {
                                      var compare = transactionsToHandle
                                          .where((element) =>
                                              element.offeringName == a.name)
                                          .length
                                          .compareTo(transactionsToHandle
                                              .where((element) =>
                                                  element.offeringName ==
                                                  b.name)
                                              .length);
                                      return compare == 0
                                          ? b.readableName
                                              .compareTo(a.readableName)
                                          : compare;
                                    }))[index];

                                  return ListTile(
                                    contentPadding: const EdgeInsets.all(4),
                                    leading: CachedNetworkImage(
                                      imageUrl: offering.imageUrl,
                                      placeholder: (context, url) =>
                                          const CircularProgressIndicator(),
                                    ),
                                    title: Text(offering.readableName),
                                    subtitle: RichText(
                                        text: TextSpan(
                                            style: DefaultTextStyle.of(context)
                                                .style,
                                            children: <TextSpan>[
                                          const TextSpan(
                                              text: "Sold: ",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          TextSpan(
                                              text: transactionsToHandle
                                                  .where((element) =>
                                                      element.offeringName ==
                                                      offering.name)
                                                  .length
                                                  .toString()),
                                          const TextSpan(
                                              text: "\nTotal: ",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          TextSpan(
                                              text: NumberFormat(
                                                      "###0.00", "de")
                                                  .format(transactionsToHandle
                                                          .where((element) =>
                                                              element
                                                                  .offeringName ==
                                                              offering.name)
                                                          .fold<int>(
                                                              0,
                                                              (sum, transaction) =>
                                                                  sum +
                                                                  transaction
                                                                      .pricePaidCents)
                                                          .toDouble() /
                                                      100)),
                                          const TextSpan(text: "€")
                                        ])),
                                  );
                                },
                                separatorBuilder: (context, index) =>
                                    const Divider(),
                                itemCount: LocalStore.offerings.length))
                      ],
                    )
                  : (snapshot.hasError
                      ? Center(
                          child: Text("There was an error.\n" +
                              snapshot.error.toString()))
                      : const Center(child: CircularProgressIndicator())))),
              ((snapshot.hasData && transactions.isNotEmpty
                  ? Column(
                      children: [
                        const Text("Offerings",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                            child: ListView.separated(
                                itemBuilder: (context, index) {
                                  Offering offering = (LocalStore.offerings
                                    ..sort((b, a) {
                                      var compare = transactionsToHandle
                                          .where((element) =>
                                              element.offeringName == a.name)
                                          .length
                                          .compareTo(transactionsToHandle
                                              .where((element) =>
                                                  element.offeringName ==
                                                  b.name)
                                              .length);
                                      return compare == 0
                                          ? b.readableName
                                              .compareTo(a.readableName)
                                          : compare;
                                    }))[index];

                                  return ListTile(
                                    contentPadding: const EdgeInsets.all(4),
                                    leading: CachedNetworkImage(
                                      imageUrl: offering.imageUrl,
                                      placeholder: (context, url) =>
                                          const CircularProgressIndicator(),
                                    ),
                                    title: Text(offering.readableName),
                                    subtitle: RichText(
                                        text: TextSpan(
                                            style: DefaultTextStyle.of(context)
                                                .style,
                                            children: <TextSpan>[
                                          const TextSpan(
                                              text: "Sold: ",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          TextSpan(
                                              text: transactionsToHandle
                                                  .where((element) =>
                                                      element.offeringName ==
                                                      offering.name)
                                                  .length
                                                  .toString()),
                                          const TextSpan(
                                              text: "\nTotal: ",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          TextSpan(
                                              text: NumberFormat(
                                                      "###0.00", "de")
                                                  .format(transactionsToHandle
                                                          .where((element) =>
                                                              element
                                                                  .offeringName ==
                                                              offering.name)
                                                          .fold<int>(
                                                              0,
                                                              (sum, transaction) =>
                                                                  sum +
                                                                  transaction
                                                                      .pricePaidCents)
                                                          .toDouble() /
                                                      100)),
                                          const TextSpan(text: "€")
                                        ])),
                                  );
                                },
                                separatorBuilder: (context, index) =>
                                    const Divider(),
                                itemCount: LocalStore.offerings.length))
                      ],
                    )
                  : (snapshot.hasError
                      ? Center(
                          child: Text("There was an error.\n" +
                              snapshot.error.toString()))
                      : const Center(child: CircularProgressIndicator())))),
              ((snapshot.hasData && transactions.isNotEmpty
                  ? Column(
                      children: [
                        const Text("Offerings",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                            child: ListView.separated(
                                itemBuilder: (context, index) {
                                  Offering offering = (LocalStore.offerings
                                    ..sort((b, a) {
                                      var compare = transactionsToHandle
                                          .where((element) =>
                                              element.offeringName == a.name)
                                          .length
                                          .compareTo(transactionsToHandle
                                              .where((element) =>
                                                  element.offeringName ==
                                                  b.name)
                                              .length);
                                      return compare == 0
                                          ? b.readableName
                                              .compareTo(a.readableName)
                                          : compare;
                                    }))[index];

                                  return ListTile(
                                    contentPadding: const EdgeInsets.all(4),
                                    leading: CachedNetworkImage(
                                      imageUrl: offering.imageUrl,
                                      placeholder: (context, url) =>
                                          const CircularProgressIndicator(),
                                    ),
                                    title: Text(offering.readableName),
                                    subtitle: RichText(
                                        text: TextSpan(
                                            style: DefaultTextStyle.of(context)
                                                .style,
                                            children: <TextSpan>[
                                          const TextSpan(
                                              text: "Sold: ",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          TextSpan(
                                              text: transactionsToHandle
                                                  .where((element) =>
                                                      element.offeringName ==
                                                      offering.name)
                                                  .length
                                                  .toString()),
                                          const TextSpan(
                                              text: "\nTotal: ",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          TextSpan(
                                              text: NumberFormat(
                                                      "###0.00", "de")
                                                  .format(transactionsToHandle
                                                          .where((element) =>
                                                              element
                                                                  .offeringName ==
                                                              offering.name)
                                                          .fold<int>(
                                                              0,
                                                              (sum, transaction) =>
                                                                  sum +
                                                                  transaction
                                                                      .pricePaidCents)
                                                          .toDouble() /
                                                      100)),
                                          const TextSpan(text: "€")
                                        ])),
                                  );
                                },
                                separatorBuilder: (context, index) =>
                                    const Divider(),
                                itemCount: LocalStore.offerings.length))
                      ],
                    )
                  : (snapshot.hasError
                      ? Center(
                          child: Text("There was an error.\n" +
                              snapshot.error.toString()))
                      : const Center(child: CircularProgressIndicator())))),
            ]),
          )));
    }));
  }

  List<Transaction> getTransactionSlice(
      List<Transaction> transactions, int index) {
    List<Transaction> transactionsToHandle = [];

    switch (index) {
      case 0: // Today
        transactionsToHandle = transactions
            .where(
              (element) => DateFormat("yy-MM-dd HH:mm:ss")
                  .parse(element.date.toString(), true)
                  .toLocal()
                  .isAfter(DateTime(DateTime.now().year, DateTime.now().month,
                      DateTime.now().day)),
            )
            .toList();
        break;
      case 1: // Last Month
        transactionsToHandle = transactions
            .where(
              (element) => DateFormat("yy-MM-dd HH:mm:ss")
                  .parse(element.date.toString(), true)
                  .toLocal()
                  .isAfter(DateTime(DateTime.now().year, DateTime.now().month,
                          DateTime.now().day)
                      .subtract(const Duration(days: 30))),
            )
            .toList();
        break;
      case 2: // Last Year
        transactionsToHandle = transactions
            .where(
              (element) => DateFormat("yy-MM-dd HH:mm:ss")
                  .parse(element.date.toString(), true)
                  .toLocal()
                  .isAfter(DateTime(DateTime.now().year, DateTime.now().month,
                          DateTime.now().day)
                      .subtract(const Duration(days: 365))),
            )
            .toList();
        break;
      case 3: // All
        transactionsToHandle = transactions;
        break;
      default:
    }
    return transactionsToHandle;
  }
}
