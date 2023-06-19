import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:matemate/graphql_helper.dart';
import 'package:matemate/local_store.dart';
import 'package:matemate/offering.dart';
import 'package:matemate/transaction.dart';

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
  int offeringsNumber = LocalStore.offerings.length;
  double userBalances = 0;
  double inventoryValue = 0;
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
    GraphQlHelper.updateAllUsers().then((value) {
      setState(() {
        userBalances = -1 *
            (value
                    .where((element) =>
                        element.username != "matekasse" &&
                        element.username != "matekiosk")
                    .fold<int>(0, (sum, user) => sum + user.balanceCents)
                    .toDouble() /
                100);
      });

      GraphQlHelper.getInventory().then((value) {
        setState(() {
          inventoryValue = value
                  .fold<int>(
                      0,
                      (sum, offering) =>
                          sum +
                          LocalStore.offerings
                                  .firstWhere((element) =>
                                      element.name == offering.offeringID)
                                  .priceCents *
                              offering.amount)
                  .toDouble() /
              100;
        });
      });
    });
    _tabController = TabController(length: 5, vsync: this);

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
                    Text("Last 6 Months"),
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
            body: TabBarView(
                controller: _tabController,
                children: List.filled(5, getTab(snapshot))),
          )));
    }));
  }

  RenderObjectWidget getTab(AsyncSnapshot<List<Transaction>> snapshot) {
    return (snapshot.hasData &&
            transactions.isNotEmpty &&
            userBalances != 0 &&
            inventoryValue != 0
        ? Column(
            children: [
              Expanded(
                  child: StatisticsList(
                itemCount: LocalStore.offerings.length + 7,
                userBalances: userBalances,
                transactionsToLookAt: transactionsToHandle,
                inventoryValue: inventoryValue,
              ))
            ],
          )
        : (snapshot.hasError
            ? Center(
                child:
                    Text("There was an error.\n" + snapshot.error.toString()))
            : const Center(child: CircularProgressIndicator())));
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
      case 2:
        transactionsToHandle = transactions
            .where(
              (element) => DateFormat("yy-MM-dd HH:mm:ss")
                  .parse(element.date.toString(), true)
                  .toLocal()
                  .isAfter(DateTime(DateTime.now().year, DateTime.now().month,
                          DateTime.now().day)
                      .subtract(const Duration(days: 180))),
            )
            .toList();
        break;
      case 3: // Last Year
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
      case 4: // All
        transactionsToHandle = transactions;
        break;
      default:
    }
    return transactionsToHandle;
  }
}

class StatisticsList extends ListView {
  final int itemCount;
  final int? Function(Key)? findChildIndexCallback;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final List<Transaction> transactionsToLookAt;
  final double userBalances;
  final double inventoryValue;

  StatisticsList(
      {required this.userBalances,
      required this.inventoryValue,
      required this.itemCount,
      this.findChildIndexCallback,
      this.addAutomaticKeepAlives = true,
      this.addRepaintBoundaries = true,
      this.addSemanticIndexes = true,
      required this.transactionsToLookAt,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      separatorBuilder: (context, index) {
        return const Divider();
      },
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
              padding: const EdgeInsets.only(top: 4),
              child: const Center(
                child: Text("Offerings",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ));
        } else if (index == LocalStore.offerings.length + 1) {
          return ListTile(
              title: const Text("Total Offerings"),
              subtitle: RichText(
                text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: <TextSpan>[
                      const TextSpan(
                          text: "Sold: ",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(
                          text: transactionsToLookAt
                              .where(
                                  (element) => element.offeringName != "topup")
                              .length
                              .toString()),
                      const TextSpan(
                          text: "\nTotal: ",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(
                          text: NumberFormat.currency(
                                  locale: "de_DE",
                                  symbol: "€",
                                  customPattern: '#,##0.00\u00A4')
                              .format((transactionsToLookAt.where((element) =>
                                          element.offeringName != "topup"))
                                      .fold<int>(
                                          0,
                                          (sum, transaction) =>
                                              sum + transaction.pricePaidCents)
                                      .toDouble() /
                                  100)),
                      const TextSpan(
                          text: "\n    Sold via Matekasse: ",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic)),
                      TextSpan(
                          text: transactionsToLookAt
                              .where((element) =>
                                  element.offeringName != "topup" &&
                                  element.payerUsername == "matekasse")
                              .length
                              .toString()),
                      const TextSpan(
                          text: "\n    Total via Matekasse: ",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic)),
                      TextSpan(
                          text: NumberFormat.currency(
                                  locale: "de_DE",
                                  symbol: "€",
                                  customPattern: '#,##0.00\u00A4')
                              .format(transactionsToLookAt
                                      .where((element) =>
                                          element.offeringName != "topup" &&
                                          element.payerUsername == "matekasse")
                                      .fold<int>(
                                          0,
                                          (sum, transaction) =>
                                              sum + transaction.pricePaidCents)
                                      .toDouble() /
                                  100))
                    ]),
              ));
        } else if (index == LocalStore.offerings.length + 2) {
          return const Center(
              child: Text("Top-Ups",
                  style: TextStyle(fontWeight: FontWeight.bold)));
        } else if (index == LocalStore.offerings.length + 3) {
          return ListTile(
            leading: Container(
                margin: const EdgeInsets.all(4),
                child: const Icon(FontAwesomeIcons.euroSign)),
            contentPadding: const EdgeInsets.all(4),
            title: const Text("Top-Ups"),
            subtitle: RichText(
                text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: <TextSpan>[
                  const TextSpan(
                      text: "Amount: ",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(
                      text: transactionsToLookAt
                          .where((element) =>
                              element.offeringName == "topup" &&
                              element.payerUsername != "matekasse" &&
                              element.payerUsername != "matekiosk")
                          .length
                          .toString()),
                  const TextSpan(
                      text: "\nSubtotal: ",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(
                      text: NumberFormat.currency(
                              locale: "de_DE",
                              symbol: "€",
                              customPattern: '#,##0.00\u00A4')
                          .format(-1 *
                              (transactionsToLookAt.where((element) =>
                                      element.offeringName == "topup" &&
                                      element.payerUsername != "matekasse" &&
                                      element.payerUsername != "matekiosk"))
                                  .fold<int>(
                                      0,
                                      (sum, transaction) =>
                                          sum + transaction.pricePaidCents)
                                  .toDouble() /
                              100)),
                  const TextSpan(
                      text: "\n    Ausbuchungen: ",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic)),
                  TextSpan(
                      text: NumberFormat.currency(
                              locale: "de_DE",
                              symbol: "€",
                              customPattern: '#,##0.00\u00A4')
                          .format(-1 *
                              transactionsToLookAt
                                  .where((element) =>
                                      element.offeringName == "topup" &&
                                      element.pricePaidCents > 0)
                                  .fold<int>(
                                      0,
                                      (sum, transaction) =>
                                          sum + transaction.pricePaidCents)
                                  .toDouble() /
                              100)),
                  const TextSpan(
                      text: "\nAverage: ",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(
                      text: NumberFormat.currency(locale: "de_DE", symbol: "€", customPattern: '#,##0.00\u00A4')
                          .format(-1 *
                              (transactionsToLookAt
                                      .where((element) =>
                                          element.offeringName == "topup" &&
                                          element.payerUsername !=
                                              "matekasse" &&
                                          element.payerUsername != "matekiosk")
                                      .fold<int>(
                                          0,
                                          (sum, transaction) =>
                                              sum + transaction.pricePaidCents)
                                      .toDouble() /
                                  100) /
                              (transactionsToLookAt
                                      .where((element) =>
                                          element.offeringName == "topup" &&
                                          element.payerUsername !=
                                              "matekasse" &&
                                          element.payerUsername != "matekiosk")
                                      .isEmpty
                                  ? 1
                                  : transactionsToLookAt
                                      .where((element) =>
                                          element.offeringName == "topup" &&
                                          element.payerUsername != "matekasse" &&
                                          element.payerUsername != "matekiosk")
                                      .length))),
                  const TextSpan(
                      text: "\nTotal owed to users: ",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(
                      text: NumberFormat.currency(
                              locale: "de_DE",
                              symbol: "€",
                              customPattern: '#,##0.00\u00A4')
                          .format(userBalances))
                ])),
          );
        } else if (index == LocalStore.offerings.length + 4) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Both:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(NumberFormat.currency(
                      locale: "de_DE",
                      symbol: "€",
                      customPattern: '#,##0.00\u00A4')
                  .format((transactionsToLookAt
                          .where((element) => element.offeringName == "topup"
                              ? (element.payerUsername != "matekasse" &&
                                  element.payerUsername != "matekiosk")
                              : true)
                          .fold<int>(
                              0,
                              (sum, transaction) =>
                                  sum +
                                  (transaction.offeringName == "topup" &&
                                          transaction.pricePaidCents >
                                              0 // "Ausbuchungen"
                                      ? -1 * transaction.pricePaidCents
                                      : transaction.pricePaidCents.abs()))
                          .toDouble() /
                      100)))
            ],
          );
        } else if (index == LocalStore.offerings.length + 5) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                  text: TextSpan(
                      style: DefaultTextStyle.of(context)
                          .style
                          .merge(const TextStyle(fontWeight: FontWeight.bold)),
                      children: const <TextSpan>[
                    TextSpan(
                      text: "Total Both ",
                    ),
                    TextSpan(
                        text: "(Top-Ups = Debts, w/o Sales via Matekasse)",
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    TextSpan(text: ":")
                  ])),
              Text(NumberFormat.currency(
                      locale: "de_DE",
                      symbol: "€",
                      customPattern: '#,##0.00\u00A4')
                  .format((transactionsToLookAt
                          .where((element) =>
                              (element.payerUsername != "matekasse"))
                          .fold<int>(
                              0,
                              (sum, transaction) =>
                                  sum + transaction.pricePaidCents)
                          .toDouble() /
                      100)))
            ],
          );
        } else if (index == LocalStore.offerings.length + 6) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: const Text("Inventory Value:",
                      style: TextStyle(fontWeight: FontWeight.bold))),
              Container(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(NumberFormat.currency(
                          locale: "de_DE",
                          symbol: "€",
                          customPattern: '#,##0.00\u00A4')
                      .format(inventoryValue)))
            ],
          );
        }

        Offering offering = (LocalStore.offerings
          ..sort((b, a) {
            var compare = transactionsToLookAt
                .where((element) => element.offeringName == a.name)
                .length
                .compareTo(transactionsToLookAt
                    .where((element) => element.offeringName == b.name)
                    .length);
            return compare == 0
                ? b.readableName.compareTo(a.readableName)
                : compare;
          }))[index - 1];

        return ListTile(
          contentPadding: const EdgeInsets.all(4),
          leading: CachedNetworkImage(
            imageUrl: offering.imageUrl,
            placeholder: (context, url) => const CircularProgressIndicator(),
          ),
          title: Text(offering.readableName),
          subtitle: RichText(
              text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: <TextSpan>[
                const TextSpan(
                    text: "Sold: ",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(
                    text: transactionsToLookAt
                        .where(
                            (element) => element.offeringName == offering.name)
                        .length
                        .toString()),
                const TextSpan(
                    text: "\nTotal: ",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(
                    text: NumberFormat.currency(
                            locale: "de_DE",
                            symbol: "€",
                            customPattern: '#,##0.00\u00A4')
                        .format(transactionsToLookAt
                                .where((element) =>
                                    element.offeringName == offering.name)
                                .fold<int>(
                                    0,
                                    (sum, transaction) =>
                                        sum + transaction.pricePaidCents)
                                .toDouble() /
                            100))
              ])),
        );
      },
      itemCount: itemCount,
      dragStartBehavior: dragStartBehavior,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes,
      cacheExtent: cacheExtent,
      clipBehavior: clipBehavior,
      controller: controller,
      findChildIndexCallback: findChildIndexCallback,
      keyboardDismissBehavior: keyboardDismissBehavior,
      padding: padding,
      physics: physics,
      primary: primary,
      restorationId: restorationId,
      reverse: reverse,
      scrollDirection: scrollDirection,
      shrinkWrap: shrinkWrap,
    );
  }
}
