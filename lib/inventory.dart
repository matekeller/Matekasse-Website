import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:matemate/graphql_helper.dart';
import 'package:matemate/local_store.dart';
import 'package:matemate/offering.dart';
import 'package:matemate/transaction.dart';
import 'package:matemate/util/widgets/scaffolded_dialog.dart';
import 'package:collection/collection.dart';
import 'dart:ui' as ui;

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
  List<InventoryItem> changes = [];
  ScrollController controller = ScrollController();
  double fabPadding = 0;

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
        return SafeArea(
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
              padding: const EdgeInsets.only(left: 8, right: 8),
              child: ((snapshot.hasData
                  ? NotificationListener<ScrollEndNotification>(
                      onNotification: (t) {
                        if (controller.position.pixels >=
                            controller.position.maxScrollExtent) {
                          setState(() {
                            fabPadding = 50;
                          });
                        } else {
                          setState(() {
                            fabPadding = 0;
                          });
                        }
                        return true;
                      },
                      child: RefreshIndicator(
                        color: Theme.of(context).colorScheme.primary,
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
                              if (transaction.offeringName == item.offeringID) {
                                count += 1;
                              }
                            }
                            thresholds
                                .addAll({item.offeringID: (count / 4).ceil()});
                          }

                          setState(() {});
                        },
                        child: InventoryList(
                          inventory: inventory,
                          thresholds: thresholds,
                          controller: controller,
                        ),
                      ),
                    )
                  : (snapshot.hasError
                      ? Center(
                          child: Text("There was an error.\n" +
                              snapshot.error.toString()))
                      : const Center(child: CircularProgressIndicator()))))),
          floatingActionButton: AnimatedPadding(
            padding: EdgeInsets.only(bottom: fabPadding),
            curve: Curves.easeInOut,
            duration: const Duration(milliseconds: 500),
            child: FloatingActionButton(
              child: const Icon(
                FontAwesomeIcons.pencil,
              ),
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return getChangeDialog();
                    });
              },
            ),
          ),
        ));
      }),
    );
  }

  ScaffoldedDialog getChangeDialog() {
    return ScaffoldedDialog(
      title: const Text("Change Inventory"),
      children: [
        SizedBox(
            height: 600,
            width: 500,
            child: InventoryChangeList(
              inventory: inventory,
              itemCount: inventory.length,
              onChanged: (list) {
                for (InventoryItem change in list ?? []) {
                  if (changes.firstWhereOrNull((element) =>
                          element.offeringID == change.offeringID) !=
                      null) {
                    for (InventoryItem item in changes) {
                      if (item.offeringID == change.offeringID) {
                        setState(() {
                          item.amount = change.amount;
                        });
                      }
                    }
                  } else {
                    if (change.amount != 0) {
                      setState(() {
                        changes.add(InventoryItem(
                            offeringID: change.offeringID,
                            amount: change.amount));
                      });
                    }
                  }
                }
              },
            )),
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 8),
          child: FilledButton(
              onPressed: () async {
                if (changes.isEmpty ||
                    changes.every((element) =>
                        element.amount ==
                        inventory
                            .firstWhere(
                                (el) => el.offeringID == element.offeringID)
                            .amount)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please change something")));
                  return;
                }

                if (await GraphQlHelper.updateInventory(changes
                    .where((element) =>
                        element.amount !=
                        inventory
                            .firstWhere(
                                (el) => el.offeringID == element.offeringID)
                            .amount)
                    .toList())) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Inventory successfully updated")));
                  Navigator.of(context).pop();
                  setState(() {});
                  return;
                }
              },
              child: const Text("Submit")),
        )
      ],
    );
  }
}

class InventoryList extends StatelessWidget {
  const InventoryList(
      {Key? key,
      required this.inventory,
      required this.thresholds,
      required this.controller})
      : super(key: key);

  final List<InventoryItem> inventory;
  final Map thresholds;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: controller,
      shrinkWrap: true,
      itemCount: inventory.length + 1,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        if (index < inventory.length) {
          if (!thresholds.containsKey(inventory[index].offeringID)) {
            thresholds.addEntries({inventory[index].offeringID: 0}.entries);
          }
          inventory.sort(((a, b) => b.amount.compareTo(a.amount)));
          Offering offering = LocalStore.offerings.firstWhere(
              (element) => element.name == inventory[index].offeringID);
          return ListTile(
            contentPadding: const EdgeInsets.all(4),
            leading: CachedNetworkImage(
                imageUrl: offering.imageUrl,
                placeholder: (context, url) =>
                    const CircularProgressIndicator()),
            title: Text(offering.readableName),
            subtitle: RichText(
                text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: <TextSpan>[
                  const TextSpan(text: "Amount: "),
                  TextSpan(
                      text: inventory[index].amount.toString(),
                      style: TextStyle(
                          color: inventory[index].amount > 0 &&
                                  (inventory[index].amount < 7 ||
                                      inventory[index].amount <=
                                          thresholds[
                                              inventory[index].offeringID])
                              ? Colors.red
                              : DefaultTextStyle.of(context).style.color,
                          fontWeight: inventory[index].amount > 0 &&
                                  (inventory[index].amount < 7 ||
                                      inventory[index].amount <=
                                          thresholds[
                                              inventory[index].offeringID])
                              ? FontWeight.bold
                              : DefaultTextStyle.of(context).style.fontWeight))
                ])),
          );
        } else {
          return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: ListTile(
                      leading: Icon(Icons.euro),
                      contentPadding: EdgeInsets.all(4),
                      title: Text("Inventory Value: ",
                          style: TextStyle(fontWeight: FontWeight.bold))),
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
                                                element.name ==
                                                offering.offeringID)
                                            .priceCents *
                                        offering.amount)
                            .toDouble() /
                        100))
              ]);
        }
      },
    );
  }
}

class InventoryItem {
  final String offeringID;
  int amount;

  InventoryItem({required this.offeringID, required this.amount});
}

class InventoryChangeList extends ListView {
  final int itemCount;
  final int? Function(Key)? findChildIndexCallback;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final List<InventoryItem> inventory;
  List<InventoryItem> changes = [];

  final void Function(List<InventoryItem>?) onChanged;

  InventoryChangeList(
      {required this.inventory,
      required this.itemCount,
      required this.onChanged,
      this.findChildIndexCallback,
      this.addAutomaticKeepAlives = true,
      this.addRepaintBoundaries = true,
      this.addSemanticIndexes = true,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
        itemCount: itemCount,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          inventory.sort(((a, b) => b.amount.compareTo(a.amount)));

          Offering offering = LocalStore.offerings.firstWhere(
              (element) => element.name == inventory[index].offeringID);
          return InventoryChangeListItem(
              inventory: inventory,
              offering: offering,
              index: index,
              onChanged: (value) => onChanged(changes
                ..add(InventoryItem(
                    offeringID: offering.name,
                    amount: inventory
                            .firstWhere((element) =>
                                element.offeringID == offering.name)
                            .amount +
                        value!))));
        });
  }
}

class InventoryChangeListItem extends StatefulWidget {
  final List<InventoryItem> inventory;
  final Offering offering;
  final int index;

  final void Function(int?) onChanged;

  const InventoryChangeListItem(
      {Key? key,
      required this.inventory,
      required this.offering,
      required this.index,
      required this.onChanged})
      : super(key: key);

  @override
  _InventoryChangeListItemState createState() =>
      _InventoryChangeListItemState();
}

class _InventoryChangeListItemState extends State<InventoryChangeListItem> {
  TextEditingController itemCountController = TextEditingController(text: "0");

  @override
  Widget build(BuildContext context) {
    final Size size = (TextPainter(
            text: TextSpan(
                text: "-99", style: Theme.of(context).textTheme.titleMedium),
            maxLines: 1,
            textScaleFactor: MediaQuery.of(context).textScaleFactor,
            textDirection: ui.TextDirection.ltr)
          ..layout())
        .size;
    return ListTile(
      contentPadding: const EdgeInsets.all(4),
      leading: CachedNetworkImage(
        imageUrl: widget.offering.imageUrl,
        placeholder: (context, url) => const CircularProgressIndicator(),
      ),
      title: Text(widget.offering.readableName),
      subtitle:
          Text("Current: " + widget.inventory[widget.index].amount.toString()),
      trailing: SizedBox(
          child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () => setState(() {
              itemCountController.text =
                  (int.parse(itemCountController.text.toString()) - 1)
                      .toString();
              widget.onChanged(int.parse(itemCountController.text.toString()));
            }),
          ),
          SizedBox(
              width: size.width,
              child: TextFormField(
                controller: itemCountController,
                maxLength: 3,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                keyboardType: TextInputType.number,
                onTap: () => setState(() => itemCountController.text = ""),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(counterText: ""),
                onTapOutside: (event) => setState(() {
                  if (itemCountController.text == "") {
                    itemCountController.text = "0";
                    widget.onChanged(0);
                  } else {
                    widget.onChanged(int.parse(itemCountController.text));
                  }
                  FocusManager.instance.primaryFocus?.unfocus();
                }),
                onFieldSubmitted: (value) => setState(() {
                  itemCountController.text = value.isEmpty ? "0" : value;
                  widget.onChanged(value.isEmpty ? 0 : int.parse(value));
                }),
              )),
          IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => setState(() {
                    itemCountController.text =
                        (int.parse(itemCountController.text.toString()) + 1)
                            .toString();
                    widget.onChanged(
                        int.parse(itemCountController.text.toString()));
                  }))
        ],
      )),
    );
  }
}
