import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hex/hex.dart';
import 'package:nfc_manager/nfc_manager.dart';

class NfcScanner extends StatefulWidget {
  final Function(String tagData) onDiscovered;
  const NfcScanner({
    required this.onDiscovered,
    Key? key,
  }) : super(key: key);

  @override
  State<NfcScanner> createState() => _NfcScannerState();
}

class _NfcScannerState extends State<NfcScanner> {
  bool notScannedYet = true;
  @override
  Widget build(BuildContext context) {
    NfcManager.instance.startSession(onDiscovered: (tag) async {
      try {
        widget
            .onDiscovered(HEX.encode(tag.data['ndefformatable']['identifier']));
        NfcManager.instance.stopSession();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                "This NFC tag is not supported. Please make sure it uses the ndef format")));
      }
    });
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          FontAwesomeIcons.nfcSymbol,
          color: Colors.purple[400],
        ),
        const SizedBox(
          height: 10,
        ),
        const Text('Please put the NFC-tag on your devices NFC-reader'),
        const SizedBox(
          height: 10,
        ),
        const CircularProgressIndicator(),
      ],
    );
  }
}
