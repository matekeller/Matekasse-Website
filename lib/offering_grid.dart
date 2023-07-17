import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:matemate/graphql_helper.dart';
import 'package:matemate/local_store.dart';
import 'package:matemate/offering.dart';

class OfferingGrid extends StatefulWidget {
  final void Function(List<String>?) onChanged;
  const OfferingGrid({required this.onChanged, Key? key}) : super(key: key);

  @override
  State<OfferingGrid> createState() => _OfferingGridState();
}

class _OfferingGridState extends State<OfferingGrid> {
  List<String>? selectedOfferingsName = [];
  List<Offering> offerings = [];
  int noOfDummyOfferings = 0;
  Border border = Border.all(color: Colors.transparent);
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: () async {
          await GraphQlHelper.updateOfferings();
          offerings = LocalStore.offerings
              .where((element) => element.name != "topup")
              .toList();

          if (offerings.length % 3 != 0) {
            for (int i = 0; i < offerings.length % 3; i++) {
              // add dummy offerings to make a square grid
              noOfDummyOfferings++;
              offerings.add(Offering(
                  imageUrl: "https://picsum.photos/50",
                  name: "dummy",
                  priceCents: 0,
                  readableName: "Dummy"));
            }
          }
        }(),
        builder: (context, snapshot) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: RefreshIndicator(
                onRefresh: () async {
                  await GraphQlHelper.updateOfferings();
                  setState(
                    () {
                      widget.onChanged(null);
                      offerings = LocalStore.offerings
                          .where((element) => element.name != "topup")
                          .toList();
                      if (offerings.length % 3 != 0) {
                        for (int i = 0; i < offerings.length % 3; i++) {
                          // add dummy offerings to make a square grid
                          noOfDummyOfferings++;
                          offerings.add(Offering(
                              imageUrl: "https://picsum.photos/50",
                              name: "dummy",
                              priceCents: 0,
                              readableName: "Dummy"));
                        }
                      }
                    },
                  );
                },
                child: getGrid(context),
              ),
            ));
  }

  GridView getGrid(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
      children: [
        for (Offering offering in offerings)
          Container(
              decoration:
                  BoxDecoration(border: getBorder(offerings.indexOf(offering))),
              child: MaterialButton(
                elevation: 0,
                child: offering.name != "dummy"
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Align(
                            alignment: const Alignment(1.6, -1.2),
                            heightFactor: 0.0,
                            child: CircleAvatar(
                                maxRadius: 10.0,
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                child: Text(
                                  selectedOfferingsName!
                                          .where((element) =>
                                              element == offering.name)
                                          .isEmpty
                                      ? ""
                                      : selectedOfferingsName!
                                          .where((element) =>
                                              element == offering.name)
                                          .length
                                          .toString(),
                                )),
                          ),
                          Expanded(
                            child: CachedNetworkImage(
                              imageUrl: offering.imageUrl,
                              placeholder: (context, url) =>
                                  const CircularProgressIndicator(),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  offering.name != "dummy"
                                      ? NumberFormat.currency(
                                              locale: "de_DE",
                                              symbol: "€",
                                              customPattern: '#,##0.00\u00A4')
                                          .format(
                                              offering.priceCents.toDouble() /
                                                  100)
                                      : "",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                          color: selectedOfferingsName!
                                                  .contains(offering.name)
                                              ? Colors.white
                                              : Colors.black),
                                )),
                          )
                        ],
                      )
                    : const Text(""),
                enableFeedback: offering.name != "dummy" ? true : false,
                splashColor: offering.name == "dummy"
                    ? Colors.transparent
                    : Theme.of(context).splashColor,
                color: selectedOfferingsName!.contains(offering.name)
                    ? Theme.of(context).primaryColor
                    : Colors.white,
                onPressed: () {
                  if (offering.name != "dummy") {
                    setState(
                      () {
                        selectedOfferingsName!.add(offering.name);
                        widget.onChanged(selectedOfferingsName);
                      },
                    );
                  }
                },
                onLongPress: () {
                  if (selectedOfferingsName!.contains(offering.name)) {
                    setState(() {
                      selectedOfferingsName!.remove(offering.name);
                      widget.onChanged(selectedOfferingsName);
                    });
                  }
                },
              ))
      ],
    );
  }

  Border getBorder(int offeringIndex) {
    Border border = Border.all(color: Colors.transparent);

    if (offeringIndex % 3 == 0 || offeringIndex % 3 == 1) {
      border = Border(
          right: const BorderSide(color: Colors.grey, width: 0.5),
          bottom: border.bottom,
          top: border.top,
          left: border.left);
    }

    if (offeringIndex > 2) {
      border = Border(
          bottom: border.bottom,
          top: const BorderSide(color: Colors.grey, width: 0.5),
          left: border.left,
          right: border.right);
    }
    return border;
  }
}
