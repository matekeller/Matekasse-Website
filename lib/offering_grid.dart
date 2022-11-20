import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
  Border border = Border.all(color: Colors.transparent);
  @override
  Widget build(BuildContext context) {
    return Container(
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
              selectedOfferingsName = [];
              widget.onChanged(null);
            },
          );
        },
        child: GridView(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3),
          children: [
            for (Offering offering in LocalStore.offerings
                .where((element) => element.name != "topup")
                .toList())
              Container(
                  decoration: BoxDecoration(
                      border: getBorder(LocalStore.offerings
                          .where((element) => element.name != "topup")
                          .toList()
                          .indexOf(offering))),
                  child: MaterialButton(
                    elevation: 0,
                    child: Column(
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
                                (offering.priceCents ~/ 100).toString() +
                                    "," +
                                    (offering.priceCents % 100 >= 10
                                        ? (offering.priceCents % 100).toString()
                                        : "0" +
                                            (offering.priceCents % 100)
                                                .toString()) +
                                    "€",
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
                    ),
                    color: selectedOfferingsName!.contains(offering.name)
                        ? Theme.of(context).primaryColor
                        : Colors.white,
                    onPressed: () {
                      setState(
                        () {
                          selectedOfferingsName!.add(offering.name);
                          widget.onChanged(selectedOfferingsName);
                        },
                      );
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
        ),
      ),
    );
  }

  Border getBorder(int offeringIndex) {
    Border border = Border.all(color: Colors.transparent);

    if (offeringIndex % 3 == 0 || offeringIndex % 3 == 1) {
      border = Border(
          right: BorderSide(color: Colors.grey, width: 0.5),
          bottom: border.bottom,
          top: border.top,
          left: border.left);
    }

    if (offeringIndex <
        LocalStore.offerings
                .where((element) => element.name != "topup")
                .toList()
                .length -
            3) {
      border = Border(
          bottom: BorderSide(color: Colors.grey, width: 0.5),
          top: border.top,
          left: border.left,
          right: border.right);
    }
    return border;
  }
}
