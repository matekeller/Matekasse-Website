import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:matemate/graphql_helper.dart';
import 'package:matemate/local_store.dart';
import 'package:matemate/offering.dart';

class Inventory extends StatefulWidget {
  const Inventory({
    Key? key,
  }) : super(key: key);

  @override
  State<Inventory> createState() => _InventoryState();
}

class _InventoryState extends State<Inventory> {
  List<InventoryItem> inventory = [];
  Map thresholds = <String, int>{
    'club': 20,
    'mio_lemongrass': 10,
    'mio_ginger': 10,
    'water': 8,
    'mio_orange_caffeine': 10,
    'mio_lemon_caffeine': 10,
    'mio': 10,
    'stift_apfelschorle': 4,
    'mio_pomegranate': 10
  };

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<InventoryItem>>(
      future: () async {
        inventory = await GraphQlHelper.getInventory();
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
                    icon: const Icon(FontAwesomeIcons.arrowLeft),
                    onPressed: () => Navigator.pop(context),
                  )),
              body: Container(
                  child: ((snapshot.hasData
                      ? RefreshIndicator(
                          onRefresh: () async {
                            await GraphQlHelper.updateOfferings();
                            inventory = await GraphQlHelper.getInventory();

                            setState(() {});
                          },
                          child: ListView.separated(
                            itemCount: inventory.length,
                            separatorBuilder: (context, index) =>
                                const Divider(),
                            itemBuilder: (context, index) {
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
                                        style:
                                            DefaultTextStyle.of(context).style,
                                        children: <TextSpan>[
                                      const TextSpan(text: "Amount: "),
                                      TextSpan(
                                          text: inventory[index]
                                              .amount
                                              .toString(),
                                          style: TextStyle(
                                              color: inventory[index].amount <=
                                                      thresholds[
                                                          inventory[index]
                                                              .offeringID]
                                                  ? Colors.red
                                                  : DefaultTextStyle.of(context)
                                                      .style
                                                      .color,
                                              fontWeight: inventory[index]
                                                          .amount <=
                                                      thresholds[
                                                          inventory[index]
                                                              .offeringID]
                                                  ? FontWeight.bold
                                                  : DefaultTextStyle.of(context)
                                                      .style
                                                      .fontWeight))
                                    ])),
                              );
                            },
                          ))
                      : (snapshot.hasError
                          ? Center(
                              child: Text("There was an error.\n" +
                                  snapshot.error.toString()))
                          : const Center(
                              child: CircularProgressIndicator()))))),
              floatingActionButton: FloatingActionButton(
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
              ),
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
