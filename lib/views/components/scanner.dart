import 'dart:collection';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:to_csv/to_csv.dart' as exportCSV;

class Scanner extends StatefulWidget {
  const Scanner({super.key});

  @override
  State<Scanner> createState() => _ScannerState();
}

class _ScannerState extends State<Scanner> {
  late MobileScannerController cameraController;
  Map<String, Uint8List> barcodesMap = Map();
  HashSet<String> barcodeStrings = HashSet();

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        detectionTimeoutMs: 2 * 1000,
        returnImage: true
    );
  }

  @override
  void dispose() {
    super.dispose();
    cameraController.dispose();
  }

  void showNotification(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
    ));
  }

  @override
  Widget build(BuildContext context) {
    var s = MediaQuery.of(context).size;
    var viewHeight = s.height;
    var viewWidth = s.width;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.all(15),
          height: viewHeight * 0.3,
          child: MobileScanner(
              overlay: Container(
                decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(width: 5, color: Colors.cyan),
                    borderRadius: BorderRadius.circular(2)),
              ),
              controller: cameraController,
              fit: BoxFit.cover,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  var barcodeStr = barcode.rawValue ?? "NA";
                  barcodeStrings.add(barcodeStr);
                  if (capture.image != null && !barcodesMap.containsKey(barcodeStr)) {
                    barcodesMap[barcodeStr] = capture.image!;
                  }
                }
                setState(() {});
              }),
        ),
        ButtonBar(
          alignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () {
                setState(() {
                  barcodeStrings.clear();
                  barcodesMap.clear();
                });
              },
            ),
            IconButton(
              icon: ValueListenableBuilder(
                valueListenable: cameraController.cameraFacingState,
                builder: (context, state, child) {
                  switch (state as CameraFacing) {
                    case CameraFacing.front:
                      return const Icon(Icons.camera_front);
                    case CameraFacing.back:
                      return const Icon(Icons.camera_rear);
                  }
                },
              ),
              onPressed: () => cameraController.switchCamera(),
            ),
            if (cameraController.hasTorch)
              IconButton(
                icon: ValueListenableBuilder(
                  valueListenable: cameraController.torchState,
                  builder: (context, state, child) {
                    switch (state) {
                      case TorchState.off:
                        return const Icon(Icons.flash_off, color: Colors.grey);
                      case TorchState.on:
                        return const Icon(Icons.flash_on, color: Colors.yellow);
                    }
                  },
                ),
                onPressed: () => cameraController.toggleTorch(),
              ),
            if (!kIsWeb)
              IconButton(
                icon: const Icon(Icons.image),
                onPressed: () async {
                  try {
                    FilePickerResult? result = await FilePicker.platform
                        .pickFiles(type: FileType.image);
                    String msg = "";
                    if (result != null) {
                      if (!kIsWeb) {
                        var imagePath = result.files.single.path;
                        if (imagePath != null && imagePath != "") {
                          var barcodeFound =
                              await cameraController.analyzeImage(imagePath);
                          if (barcodeFound) {
                            msg = "Barcode Found";
                          } else {
                            msg = "Barcode Not Found";
                          }
                        }
                      } else {
                        msg = "Feature not supported";
                      }
                    } else {
                      msg = "File not selected";
                    }
                    showNotification(msg);
                  } catch (e) {
                    showNotification(e.toString());
                    if (kDebugMode) {
                      print(e);
                    }
                  }
                },
              ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                var headers = ["Barcodes"];
                exportCSV.myCSV(
                    headers, barcodeStrings.map((e) => [e]).toList());
                showNotification("CSV exported successfully");
              },
            ),
          ],
        ),
        SizedBox(
          height: viewHeight * 0.4,
          child: ListView(
              children: barcodeStrings.map((barcode) {
            return ListTile(
              dense: true,
              key: Key(barcode),
              leading: barcodesMap.containsKey(barcode)
                  ? InkWell(
                onTap: () {
                  if(barcodesMap.containsKey(barcode)){
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) =>
                        Scaffold(
                          appBar: AppBar(title: Text("Preview",)),
                          body: Image.memory(barcodesMap[barcode]!),
                        )),
                  );}
                },
                    child: CircleAvatar(
                backgroundImage:MemoryImage(barcodesMap[barcode]!)),
                  )
                  : null,
              title: Text(
                barcode,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                iconSize: 20,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: barcode))
                      .then((value) => showNotification("Barcode copied"));
                },
              ),
            );
          }).toList()),
        )
      ],
    );
  }
}
