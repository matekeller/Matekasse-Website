import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:matemate/graphql_helper.dart';
import 'package:matemate/local_store.dart';
import 'package:matemate/offering.dart';

class OfferingGrid extends StatefulWidget {
  final void Function(String?) onChanged;
  const OfferingGrid({required this.onChanged, Key? key}) : super(key: key);

  @override
  State<OfferingGrid> createState() => _OfferingGridState();
}

class _OfferingGridState extends State<OfferingGrid> {
  String? selectedOfferingName;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(color: Colors.grey, offset: Offset(0, 5), blurRadius: 10)
        ],
        borderRadius: BorderRadius.circular(12),
      ),
      child: RefreshIndicator(
        onRefresh: () async {
          await GraphQlHelper.updateOfferings();
          setState(
            () {
              selectedOfferingName = null;
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
              MaterialButton(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CachedNetworkImage(
                      imageUrl: offering.imageUrl,
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(),
                    ),
                    Text(
                      (offering.priceCents ~/ 100).toString() +
                          "," +
                          (offering.priceCents % 100 >= 10
                              ? (offering.priceCents % 100).toString()
                              : "0" + (offering.priceCents % 100).toString()) +
                          "€",
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: selectedOfferingName == offering.name
                              ? Colors.white
                              : Colors.black),
                    ),
                  ],
                ),
                color: selectedOfferingName == offering.name
                    ? Theme.of(context).primaryColor
                    : Colors.white,
                onPressed: () {
                  if (selectedOfferingName != offering.name) {
                    setState(
                      () {
                        selectedOfferingName = offering.name;
                        widget.onChanged(offering.name);
                      },
                    );
                  }
                },
              )
          ],
        ),
      ),
    );
  }
}
