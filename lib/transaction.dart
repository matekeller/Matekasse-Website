import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:matemate/local_store.dart';
import 'package:intl/intl.dart';

class TransactionWidget extends StatelessWidget {
  final Transaction transaction;
  const TransactionWidget({required this.transaction, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // just showing the absolute value. Whether its positive or negative
    // internally doesnt matter.
    int pricePaidCents = transaction.pricePaidCents.abs();
    TextStyle deletedStyle = const TextStyle(
        decoration: TextDecoration.lineThrough, color: Colors.grey);

    var dateLocal = DateFormat("dd.MM.yyyy - HH:mm").format(
        DateFormat("yy-MM-dd HH:mm:ss")
            .parse(transaction.date.toString(), true)
            .toLocal());
    return Container(
      margin: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
          color: Colors.white,
          //border: Border.all(width: 2, color: Colors.blueGrey),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(offset: Offset(0, 5), blurRadius: 5, color: Colors.grey)
          ]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  color: !transaction.deleted
                      ? (transaction.offeringName == "topup"
                          ? Colors.green
                          : Colors.red)
                      : Colors.grey,
                  child: Text(
                    (pricePaidCents ~/ 100).toString() +
                        "," +
                        (pricePaidCents % 100 < 10 ? "0" : "") +
                        (pricePaidCents % 100).toString() +
                        "€",
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .copyWith(color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                      LocalStore.offerings
                          .firstWhere((element) =>
                              element.name == transaction.offeringName)
                          .readableName,
                      style: !transaction.deleted
                          ? Theme.of(context).textTheme.bodyLarge!
                          : deletedStyle),
                )
              ],
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Date: " + dateLocal.toString(),
                  style: !transaction.deleted
                      ? Theme.of(context).textTheme.bodyLarge!
                      : deletedStyle),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Payer: " + transaction.payerUsername.toString(),
                  style: !transaction.deleted ? null : deletedStyle),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Admin: " + transaction.adminUsername.toString(),
                  style: !transaction.deleted ? null : deletedStyle),
            ),
          ],
        ),
      ),
    );
  }
}

class Transaction {
  final String payerUsername;
  final String adminUsername;

  /// offeringID = 0 <=> topup
  final String offeringName;
  final int pricePaidCents;
  final DateTime date;
  final int id;
  final bool deleted;

  Transaction(
      {required this.payerUsername,
      required this.adminUsername,
      required this.offeringName,
      required this.pricePaidCents,
      required this.date,
      required this.id,
      required this.deleted});
}
