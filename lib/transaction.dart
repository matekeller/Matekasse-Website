import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:matemate/local_store.dart';
import 'package:intl/intl.dart';
import 'package:matemate/user_page.dart';

class TransactionWidget extends StatelessWidget {
  final Transaction transaction;
  const TransactionWidget({required this.transaction, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // just showing the absolute value. Whether its positive or negative
    // internally doesnt matter.
    int pricePaidCents = transaction.pricePaidCents;
    double pricePaidEuros = pricePaidCents / 100;

    TextStyle deletedStyle = const TextStyle(
        decoration: TextDecoration.lineThrough, color: Colors.grey);

    var dateLocal = DateFormat("dd.MM.yyyy - HH:mm").format(
        DateFormat("yy-MM-dd HH:mm:ss")
            .parse(transaction.date.toString(), true)
            .toLocal());
    return Container(
      margin: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          //border: Border.all(width: 2, color: Colors.blueGrey),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                offset: const Offset(0, 5),
                blurRadius: 5,
                color:
                    Theme.of(context).colorScheme.brightness == Brightness.dark
                        ? Colors.black
                        : Colors.grey)
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
                  decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(7)),
                      color: !transaction.deleted
                          ? (transaction.offeringName == "topup"
                              ? (pricePaidCents < 0
                                  ? Theme.of(context).colorScheme.tertiary
                                  : Theme.of(context)
                                      .colorScheme
                                      .error) // if cents < 0 its an actual topup, else its a topdown via database
                              : Theme.of(context).colorScheme.error)
                          : Colors.grey,
                      boxShadow: Theme.of(context).brightness == Brightness.dark
                          ? [
                              BoxShadow(
                                  blurRadius: 8,
                                  color: !transaction.deleted
                                      ? (transaction.offeringName == "topup"
                                          ? (pricePaidCents < 0
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .tertiary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .error) // if cents < 0 its an actual topup, else its a topdown via database
                                          : Theme.of(context).colorScheme.error)
                                      : Colors.grey)
                            ]
                          : []),
                  padding: const EdgeInsets.all(8),
                  child: Text(
                      transaction.offeringName == "topup"
                          ? NumberFormat.currency(
                                  locale: "de_DE",
                                  symbol: "€",
                                  customPattern: '#,##0.00\u00A4')
                              .format(pricePaidEuros * -1)
                          : NumberFormat.currency(
                                  locale: "de_DE",
                                  symbol: "€",
                                  customPattern: '#,##0.00\u00A4')
                              .format(pricePaidEuros),
                      style: const TextStyle(color: Colors.white)),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                      transaction.offeringName == "topup"
                          ? (transaction.pricePaidCents < 0
                              ? "Aufladung"
                              : "Ausbuchung")
                          : LocalStore.offerings
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
                child: RichText(
                    text: TextSpan(children: [
                  TextSpan(
                      text: "Payer: ",
                      style: !transaction.deleted
                          ? Theme.of(context).textTheme.bodyMedium
                          : deletedStyle),
                  TextSpan(
                      text: transaction.payerUsername,
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => UserPage(
                                    username: transaction.payerUsername))),
                      style: !transaction.deleted
                          ? Theme.of(context).textTheme.bodyMedium
                          : deletedStyle)
                ]))),
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
