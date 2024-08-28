import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:downloads_path_provider_28/downloads_path_provider_28.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gpspro/arguments/ReportArguments.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ReportTripPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _ReportTripPageState();
}

class _ReportTripPageState extends State<ReportTripPage> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  static ReportArguments? args;
  StreamController<int>? _postsController;
  Timer? _timer;
  bool isLoading = true;
  static var httpClient = new HttpClient();
  File? file;

  var bytes;
  Color _mapTypeBackgroundColor = CustomColor.primaryColor;
  Color _mapTypeForegroundColor = CustomColor.secondaryColor;
  @override
  void initState() {
    _postsController = new StreamController();
    getReport();
    super.initState();
  }

  Future<File?> _downloadFile(String url, String filename) async {
    Random random = new Random();
    int randomNumber = random.nextInt(100);
    var request = await httpClient.getUrl(Uri.parse(url));
    var response = await request.close();
    bytes = await consolidateHttpClientResponseBytes(response);
    String dir = (await getApplicationDocumentsDirectory()).path;
    print(dir);
    File pdffile = new File('$dir/$filename-$randomNumber.pdf');
    //Navigator.pop(context); // Load from assets
    file = pdffile;
    _postsController!.add(1);
    setState(() {
      isLoading = false;
    });
    await file!.writeAsBytes(bytes);
    return file;
  }

  getReport() {
    _timer = new Timer.periodic(Duration(seconds: 1), (timer) {
      if (args != null) {
        timer.cancel();
        APIService.getReport(args!).then((value) => {
              _downloadFile(value!.url!, "work"),
            });
      }
    });
  }

  Future<File?> writeFile() async {
    // storage permission ask
    Random random = new Random();
    int randomNumber = random.nextInt(100);
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
    // the downloads folder path
    Directory? tempDir = await DownloadsPathProvider.downloadsDirectory;
    String tempPath = tempDir!.path;
    File pdffile = new File('$tempPath/work-$randomNumber.pdf');
    file = pdffile;
    await file!.writeAsBytes(bytes);

    Fluttertoast.showToast(
        msg: "Archivo exportado a la carpeta de descargas",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0);

    return file;
  }

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as ReportArguments;

    return Scaffold(
        appBar: AppBar(
          title: Text(args!.name, style: TextStyle(color: CustomColor.secondaryColor)),
          iconTheme: IconThemeData(
            color: CustomColor.secondaryColor, //change your color here
          ),
        ),
        floatingActionButton: !isLoading
            ? FloatingActionButton(
                heroTag: "mapType",
                mini: true,
                onPressed: writeFile,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                backgroundColor: _mapTypeBackgroundColor,
                foregroundColor: _mapTypeForegroundColor,
                child: const Icon(Icons.download_rounded, size: 30.0),
              )
            : Container(),
        body: StreamBuilder<int>(
            stream: _postsController!.stream,
            builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
              if (snapshot.hasData) {
                return SfPdfViewer.file(
                  file!,
                  key: _pdfViewerKey,
                );
              } else if (isLoading) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              } else {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
            }));
  }
}
