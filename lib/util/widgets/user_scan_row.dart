import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:matemate/nfc_scanner.dart';
import 'package:matemate/util/widgets/scaffolded_dialog.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// A simple row containing a text field and a button for a barcode scanner
/// After scanning, the textfield contains the scanned value, but can be explicitly edited
class UserScanRow extends StatefulWidget {
  final void Function(String?) onChanged;
  final bool barcodeEnabled;
  final bool nfcEnabled;

  /// How many scans have to be the same at the same time, improves accuracy
  final int redundantBarcodeScans;
  const UserScanRow(
      {required this.onChanged,
      this.redundantBarcodeScans = 3,
      this.barcodeEnabled = true,
      this.nfcEnabled = false,
      Key? key})
      : super(key: key);

  @override
  State<UserScanRow> createState() => _UserScanRowState();
}

class _UserScanRowState extends State<UserScanRow> {
  String? code;

  /// Whether code is a bluecardId. If it is false, code is a hex string from the
  /// NFC reader
  bool blueCardId = true;

  /// Once in a while, a barcode will be scanned incorrectly, but almost never
  /// twice in a row in the same way. Therefore, we scan multiple times until
  /// all [redundantBarcodeScans] last scans are the same.
  List<String> scannedCodes = [];

  /// For some reason, the scanning widget would be popped many times after scanning,
  /// crashing the app. This ensures that this wont happen
  bool canPop = true;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            style: Theme.of(context)
                .textTheme
                .subtitle1!
                .copyWith(color: blueCardId ? Colors.blue : Colors.purple),
            onChanged: (value) {
              code = value;
              widget.onChanged(code);
            },
            onTap: () {
              if (!blueCardId) {
                setState(() {
                  blueCardId = true;
                });
              }
            },
            controller: TextEditingController(text: code ?? ""),
          ),
        ),
        if (widget.nfcEnabled)
          const SizedBox(
            width: 5,
          ),
        if (widget.nfcEnabled)
          TextButton(
            style: TextButtonTheme.of(context).style!.copyWith(
                backgroundColor: MaterialStateProperty.all(Colors.purple[400])),
            onPressed: () async {
              FocusScope.of(context).unfocus();
              canPop = true;
              showDialog(
                context: context,
                builder: (context) => ScaffoldedDialog(children: [
                  NfcScanner(onDiscovered: (tagData) {
                    code = tagData;
                    Navigator.pop(context);
                  })
                ]),
              ).then((value) => setState(() {
                    blueCardId = false;
                    widget.onChanged(code);
                  }));
            },
            child: const Icon(FontAwesomeIcons.nfcSymbol),
          ),
        if (widget.barcodeEnabled)
          const SizedBox(
            width: 5,
          ),
        if (widget.barcodeEnabled)
          TextButton(
              style: TextButtonTheme.of(context).style!.copyWith(
                  backgroundColor: MaterialStateProperty.all(Colors.blue[400])),
              onPressed: () async {
                FocusScope.of(context).unfocus();
                scannedCodes = [];
                canPop = true;
                showDialog(
                  context: context,
                  builder: (context) => Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Stack(
                        children: [
                          MobileScanner(
                            allowDuplicates: true,
                            controller: MobileScannerController(),
                            onDetect: (barcode, args) {
                              // Removes the earliest scan if the list would get too long
                              if (scannedCodes.length >=
                                  widget.redundantBarcodeScans) {
                                scannedCodes.removeAt(0);
                              }
                              // adds the newest scan
                              scannedCodes.add(barcode.rawValue ?? "");
                              // if we have enough scans, it changes the value if and
                              // only if all scans are the same.
                              if (scannedCodes.length ==
                                  widget.redundantBarcodeScans) {
                                for (int i = 1;
                                    i < widget.redundantBarcodeScans;
                                    i++) {
                                  if (scannedCodes[i] != scannedCodes[0]) {
                                    return;
                                  }
                                }
                                // Ensuring that everything is only popped once.
                                if (canPop) {
                                  code = scannedCodes[0];
                                  Navigator.of(context).pop();
                                  canPop = false;
                                }
                              }
                            },
                          ),
                          Center(
                              child: Divider(
                            color: Colors.red.withAlpha(150),
                            thickness: 3,
                          )),
                        ],
                      ),
                    ),
                  ),
                ).then((value) {
                  setState(() {
                    blueCardId = true;
                    widget.onChanged(code);
                  });
                });
              },
              child: const Icon(
                FontAwesomeIcons.barcode,
              ))
      ],
    );
  }
}
