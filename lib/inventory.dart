import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:matemate/graphql_helper.dart';
import 'package:matemate/local_store.dart';
import 'package:matemate/offering.dart';
import 'package:matemate/transaction.dart';

class Inventory extends StatefulWidget {
  const Inventory({
    Key? key,
  }) : super(key: key);

  @override
  State<Inventory> createState() => _InventoryState();
}

class _InventoryState extends State<Inventory> {
  List<InventoryItem> inventory = [];
  List<Transaction> transactions = [];

  Map thresholds = <dynamic, dynamic>{};

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<InventoryItem>>(
      future: () async {
        transactions = [];
        var first = 300;
        var count = 0;
        inventory = await GraphQlHelper.getInventory();
        var cursor = await GraphQlHelper.getEndCursor();
        cursor++;

        while (transactions.isEmpty ||
            DateFormat("yy-MM-dd HH:mm:ss")
                .parse(transactions.last.date.toString(), true)
                .toLocal()
                .isAfter(DateTime.now().subtract(const Duration(days: 28)))) {
          transactions.addAll(await GraphQlHelper.getTransactionList(
              after: cursor, first: first));
          cursor -= first;
        }
        transactions.removeWhere((element) =>
            element.deleted ||
            DateFormat("yy-MM-dd HH:mm:ss")
                .parse(element.date.toString(), true)
                .toLocal()
                .isBefore(DateTime.now().subtract(const Duration(days: 28))));

        for (InventoryItem item in inventory) {
          count = 0;
          for (Transaction transaction in transactions) {
            if (transaction.offeringName == item.offeringID) {
              count += 1;
            }
          }
          thresholds.addAll({item.offeringID: (count / 4).ceil()});
        }

        return inventory;
      }(),
      builder: ((context, snapshot) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.amber,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.light,
            ),
            child: SafeArea(
                child: Scaffold(
              appBar: AppBar(
                  foregroundColor: Colors.white,
                  iconTheme: Theme.of(context).iconTheme,
                  title: const Text("Inventory"),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  )),
              body: Container(
                  child: ((snapshot.hasData
                      ? RefreshIndicator(
                          onRefresh: () async {
                            transactions = [];
                            var first = 300;
                            var count = 0;

                            await GraphQlHelper.updateOfferings();

                            inventory = await GraphQlHelper.getInventory();

                            var cursor = await GraphQlHelper.getEndCursor();
                            cursor++;

                            while (transactions.isEmpty ||
                                DateFormat("yy-MM-dd HH:mm:ss")
                                    .parse(
                                        transactions.last.date.toString(), true)
                                    .toLocal()
                                    .isAfter(DateTime.now()
                                        .subtract(const Duration(days: 28)))) {
                              transactions.addAll(
                                  await GraphQlHelper.getTransactionList(
                                      after: cursor, first: first));
                              cursor -= first;
                            }

                            transactions.removeWhere((element) =>
                                element.deleted ||
                                DateFormat("yy-MM-dd HH:mm:ss")
                                    .parse(element.date.toString(), true)
                                    .toLocal()
                                    .isBefore(DateTime.now()
                                        .subtract(const Duration(days: 28))));

                            for (InventoryItem item in inventory) {
                              count = 0;
                              for (Transaction transaction in transactions) {
                                if (transaction.offeringName ==
                                    item.offeringID) {
                                  count += 1;
                                }
                              }
                              thresholds.addAll(
                                  {item.offeringID: (count / 4).ceil()});
                            }

                            setState(() {});
                          },
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: inventory.length + 1,
                            separatorBuilder: (context, index) =>
                                const Divider(),
                            itemBuilder: (context, index) {
                              if (index < inventory.length) {
                                if (!thresholds
                                    .containsKey(inventory[index].offeringID)) {
                                  thresholds.addEntries(
                                      {inventory[index].offeringID: 0}.entries);
                                }
                                inventory.sort(
                                    ((a, b) => b.amount.compareTo(a.amount)));
                                Offering offering = LocalStore.offerings
                                    .firstWhere((element) =>
                                        element.name ==
                                        inventory[index].offeringID);
                                return ListTile(
                                  contentPadding: const EdgeInsets.all(4),
                                  leading: CachedNetworkImage(
                                      imageUrl: offering.imageUrl,
                                      placeholder: (context, url) =>
                                          const CircularProgressIndicator()),
                                  title: Text(offering.readableName),
                                  subtitle: RichText(
                                      text: TextSpan(
                                          style: DefaultTextStyle.of(context)
                                              .style,
                                          children: <TextSpan>[
                                        const TextSpan(text: "Amount: "),
                                        TextSpan(
                                            text: inventory[index]
                                                .amount
                                                .toString(),
                                            style: TextStyle(
                                                color: inventory[index].amount > 0 &&
                                                        (inventory[index].amount < 7 ||
                                                            inventory[index]
                                                                    .amount <=
                                                                thresholds[inventory[index]
                                                                    .offeringID])
                                                    ? Colors.red
                                                    : DefaultTextStyle.of(context)
                                                        .style
                                                        .color,
                                                fontWeight: inventory[index].amount > 0 &&
                                                        (inventory[index].amount < 7 ||
                                                            inventory[index]
                                                                    .amount <=
                                                                thresholds[inventory[index].offeringID])
                                                    ? FontWeight.bold
                                                    : DefaultTextStyle.of(context).style.fontWeight))
                                      ])),
                                );
                              } else {
                                return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Flexible(
                                        child: ListTile(
                                            leading:
                                                Icon(FontAwesomeIcons.euroSign),
                                            contentPadding: EdgeInsets.all(4),
                                            title: Text("Inventory Value: ",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                      ),
                                      Text(NumberFormat.currency(
                                              locale: "de_DE",
                                              symbol: "€",
                                              customPattern: '#,##0.00\u00A4')
                                          .format(inventory
                                                  .fold<int>(
                                                      0,
                                                      (sum, offering) =>
                                                          sum +
                                                          LocalStore.offerings
                                                                  .firstWhere((element) =>
                                                                      element
                                                                          .name ==
                                                                      offering
                                                                          .offeringID)
                                                                  .priceCents *
                                                              offering.amount)
                                                  .toDouble() /
                                              100))
                                    ]);
                              }
                            },
                          ))
                      : (snapshot.hasError
                          ? Center(
                              child: Text("There was an error.\n" +
                                  snapshot.error.toString()))
                          : const Center(
                              child: CircularProgressIndicator()))))),
              floatingActionButton: /* FloatingActionButton(
                child: const Icon(FontAwesomeIcons.plus),
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          content: const Text("dis twickles senpwai UwU"),
                          actions: [
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text("OK"))
                          ],
                        );
                      });
                },
              ) */
                  null,
            )));
      }),
    );
  }
}

class InventoryItem {
  final String offeringID;
  final int amount;

  InventoryItem({required this.offeringID, required this.amount});
}
