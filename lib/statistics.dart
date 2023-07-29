import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:matemate/graphql_helper.dart';
import 'package:matemate/local_store.dart';
import 'package:matemate/offering.dart';
import 'package:matemate/transaction.dart';
import 'package:matemate/util/widgets/scaffolded_dialog.dart';

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
      return SafeArea(
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
      ));
    }));
  }

  Widget getTab(AsyncSnapshot<List<Transaction>> snapshot) {
    return (snapshot.hasData && transactions.isNotEmpty
        ? Container(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: Column(
              children: [
                Expanded(
                    child: StatisticsList(
                  itemCount: LocalStore.offerings.length + 5,
                  transactionsToLookAt: transactionsToHandle,
                  onOfferingTap: (offering) =>
                      showOfferingInfoDialog(offering, transactions),
                ))
              ],
            ),
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

  Future<void> showOfferingInfoDialog(
      Offering offering, List<Transaction> allTransactions) {
    var totalWeek = allTransactions
        .where((element) =>
            element.offeringName == offering.name &&
            !element.deleted &&
            DateFormat("yy-MM-dd HH:mm:ss")
                .parse(element.date.toString(), true)
                .toLocal()
                .isAfter(DateTime(DateTime.now().year, DateTime.now().month,
                        DateTime.now().day)
                    .subtract(const Duration(days: 7))))
        .length;

    var avgWeek = double.parse((allTransactions
                .where((element) =>
                    element.offeringName == offering.name &&
                    DateFormat("yy-MM-dd HH:mm:ss")
                        .parse(element.date.toString(), true)
                        .toLocal()
                        .isAfter(DateTime(DateTime.now().year,
                                DateTime.now().month, DateTime.now().day)
                            .subtract(const Duration(days: 7))))
                .length /
            7)
        .toStringAsFixed(2));

    var totalMonth = allTransactions
        .where((element) =>
            element.offeringName == offering.name &&
            DateFormat("yy-MM-dd HH:mm:ss")
                .parse(element.date.toString(), true)
                .toLocal()
                .isAfter(DateTime(DateTime.now().year, DateTime.now().month,
                        DateTime.now().day)
                    .subtract(const Duration(days: 30))))
        .length;

    var avgMonth = double.parse((allTransactions
                .where((element) =>
                    element.offeringName == offering.name &&
                    DateFormat("yy-MM-dd HH:mm:ss")
                        .parse(element.date.toString(), true)
                        .toLocal()
                        .isAfter(DateTime(DateTime.now().year,
                                DateTime.now().month, DateTime.now().day)
                            .subtract(const Duration(days: 30))))
                .length /
            30)
        .toStringAsFixed(2));

    var weeklyAvgMonth = (avgMonth * 7).toStringAsFixed(2);

    var totalYear = allTransactions
        .where((element) =>
            element.offeringName == offering.name &&
            DateFormat("yy-MM-dd HH:mm:ss")
                .parse(element.date.toString(), true)
                .toLocal()
                .isAfter(DateTime(DateTime.now().year, DateTime.now().month,
                        DateTime.now().day)
                    .subtract(const Duration(days: 365))))
        .length;

    var avgYear = double.parse((allTransactions
                .where((element) =>
                    element.offeringName == offering.name &&
                    DateFormat("yy-MM-dd HH:mm:ss")
                        .parse(element.date.toString(), true)
                        .toLocal()
                        .isAfter(DateTime(DateTime.now().year,
                                DateTime.now().month, DateTime.now().day)
                            .subtract(const Duration(days: 365))))
                .length /
            365)
        .toStringAsFixed(2));

    var weeklyAvgYear = (avgYear * 7).toStringAsFixed(2);

    var totalAll = allTransactions
        .where((element) => element.offeringName == offering.name)
        .length;

    return showDialog(
        context: context,
        builder: (context) {
          return ScaffoldedDialog(
            contentPadding: const EdgeInsets.all(12),
            title: Flexible(
              child: Text(
                "Details for ${offering.readableName}:",
                maxLines: 3,
                softWrap: true,
              ),
            ),
            children: [
              Text.rich(TextSpan(children: [
                const TextSpan(text: "Total Last Week: "),
                TextSpan(
                    text: totalWeek.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ])),
              Text.rich(TextSpan(children: [
                const TextSpan(text: "Daily Average Last Week: "),
                TextSpan(
                    text: avgWeek.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ])),
              const Padding(padding: EdgeInsets.only(top: 8, bottom: 8)),
              Text.rich(TextSpan(children: [
                const TextSpan(text: "Total Last Month: "),
                TextSpan(
                    text: totalMonth.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ])),
              Text.rich(TextSpan(children: [
                const TextSpan(text: "Daily Average Last Month: "),
                TextSpan(
                    text: avgMonth.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ])),
              Text.rich(TextSpan(children: [
                const TextSpan(text: "Weekly Average Last Month: "),
                TextSpan(
                    text: weeklyAvgMonth.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ])),
              const Padding(padding: EdgeInsets.only(top: 8, bottom: 8)),
              Text.rich(TextSpan(children: [
                const TextSpan(text: "Total Last Year: "),
                TextSpan(
                    text: totalYear.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ])),
              Text.rich(TextSpan(children: [
                const TextSpan(text: "Daily Average Last Year: "),
                TextSpan(
                    text: avgYear.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ])),
              Text.rich(TextSpan(children: [
                const TextSpan(text: "Weekly Average Last Year: "),
                TextSpan(
                    text: weeklyAvgYear.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ])),
              const Padding(padding: EdgeInsets.only(top: 8, bottom: 8)),
              Text.rich(TextSpan(children: [
                const TextSpan(text: "Total All: "),
                TextSpan(
                    text: totalAll.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ]))
            ],
          );
        });
  }
}

class StatisticsList extends ListView {
  final int itemCount;
  final int? Function(Key)? findChildIndexCallback;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final List<Transaction> transactionsToLookAt;

  final void Function(Offering offering) onOfferingTap;

  StatisticsList(
      {required this.itemCount,
      this.findChildIndexCallback,
      this.addAutomaticKeepAlives = true,
      this.addRepaintBoundaries = true,
      this.addSemanticIndexes = true,
      required this.transactionsToLookAt,
      required this.onOfferingTap,
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
          return TotalOfferingsListTile(
              transactionsToLookAt: transactionsToLookAt);
        } else if (index == LocalStore.offerings.length + 2) {
          return const Center(
              child: Text("Top-Ups",
                  style: TextStyle(fontWeight: FontWeight.bold)));
        } else if (index == LocalStore.offerings.length + 3) {
          return TopupsListTile(transactionsToLookAt: transactionsToLookAt);
        } else if (index == LocalStore.offerings.length + 4) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total: ",
                  style: TextStyle(fontWeight: FontWeight.bold)),
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

        return OfferingTile(
          offering: offering,
          transactionsToLookAt: transactionsToLookAt,
          onTap: (off) => onOfferingTap(off),
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

class OfferingTile extends StatelessWidget {
  const OfferingTile(
      {Key? key,
      required this.offering,
      required this.transactionsToLookAt,
      required this.onTap})
      : super(key: key);

  final Offering offering;
  final List<Transaction> transactionsToLookAt;
  final void Function(Offering) onTap;

  @override
  Widget build(BuildContext context) {
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
                text: "Sold: ", style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(
                text: transactionsToLookAt
                    .where((element) => element.offeringName == offering.name)
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
      onTap: () => onTap(offering),
    );
  }
}

class TopupsListTile extends StatelessWidget {
  const TopupsListTile({Key? key, required this.transactionsToLookAt})
      : super(key: key);

  final List<Transaction> transactionsToLookAt;

  @override
  Widget build(BuildContext context) {
    var total = transactionsToLookAt
        .where((element) =>
            element.offeringName == "topup" &&
            element.payerUsername != "matekasse" &&
            element.payerUsername != "matekiosk")
        .length
        .toString();

    var subtotal = (transactionsToLookAt.where((element) =>
            element.offeringName == "topup" &&
            element.payerUsername != "matekasse" &&
            element.payerUsername != "matekiosk"))
        .fold<int>(0, (sum, transaction) => sum + transaction.pricePaidCents)
        .toDouble();

    var subtotalwithAusbuchungen = transactionsToLookAt
        .where((element) =>
            element.offeringName == "topup" && element.pricePaidCents > 0)
        .fold<int>(0, (sum, transaction) => sum + transaction.pricePaidCents)
        .toDouble();

    var average = (transactionsToLookAt
                .where((element) =>
                    element.offeringName == "topup" &&
                    element.payerUsername != "matekasse" &&
                    element.payerUsername != "matekiosk")
                .fold<int>(
                    0, (sum, transaction) => sum + transaction.pricePaidCents)
                .toDouble() /
            100) /
        (transactionsToLookAt
                .where((element) =>
                    element.offeringName == "topup" &&
                    element.payerUsername != "matekasse" &&
                    element.payerUsername != "matekiosk")
                .isEmpty
            ? 1
            : transactionsToLookAt
                .where((element) =>
                    element.offeringName == "topup" &&
                    element.payerUsername != "matekasse" &&
                    element.payerUsername != "matekiosk")
                .length);

    return ListTile(
      leading: Container(
          margin: const EdgeInsets.all(4), child: const Icon(Icons.euro)),
      contentPadding: const EdgeInsets.all(4),
      title: const Text("Top-Ups"),
      subtitle: RichText(
          text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: <TextSpan>[
            const TextSpan(
                text: "Amount: ",
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: total),
            const TextSpan(
                text: "\nSubtotal: ",
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(
                text: NumberFormat.currency(
                        locale: "de_DE",
                        symbol: "€",
                        customPattern: '#,##0.00\u00A4')
                    .format(subtotal == 0 ? 0 : -1 * subtotal / 100)),
            const TextSpan(
                text: "\n    Ausbuchungen: ",
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
            TextSpan(
                text: NumberFormat.currency(
                        locale: "de_DE",
                        symbol: "€",
                        customPattern: '#,##0.00\u00A4')
                    .format(subtotalwithAusbuchungen == 0
                        ? 0
                        : -1 * subtotalwithAusbuchungen / 100)),
            const TextSpan(
                text: "\nAverage: ",
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(
                text: NumberFormat.currency(
                        locale: "de_DE",
                        symbol: "€",
                        customPattern: '#,##0.00\u00A4')
                    .format(average == 0 ? 0 : -1 * average)),
          ])),
    );
  }
}

class TotalOfferingsListTile extends StatelessWidget {
  const TotalOfferingsListTile({
    Key? key,
    required this.transactionsToLookAt,
  }) : super(key: key);

  final List<Transaction> transactionsToLookAt;

  @override
  Widget build(BuildContext context) {
    return ListTile(
        leading: const Icon(FontAwesomeIcons.wineBottle),
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
                        .where((element) => element.offeringName != "topup")
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
  }
}
