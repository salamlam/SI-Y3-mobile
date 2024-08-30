import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gpspro/arguments/ReportArguments.dart';
import 'package:gpspro/services/APIService.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ReportEventPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _ReportEventPageState();
}

class _ReportEventPageState extends State<ReportEventPage> {
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
          _downloadFile(value!.url!, "event"),
        });
      }
    });
  }

  Future<File?> writeFile() async {
    Random random = new Random();
    int randomNumber = random.nextInt(100);

    // Solicitar permiso de almacenamiento
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }

    // Obtener el directorio de descargas
    Directory? directory;
    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory();
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    if (directory == null) {
      Fluttertoast.showToast(
          msg: "No se pudo acceder al directorio de descargas",
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          textColor: Colors.white,
          fontSize: 16.0
      );
      return null;
    }

    String filePath = '${directory.path}/event-$randomNumber.pdf';
    File pdfFile = File(filePath);
    await pdfFile.writeAsBytes(bytes);

    Fluttertoast.showToast(
        msg: "Archivo exportado a ${pdfFile.path}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0
    );

    return pdfFile;
  }

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as ReportArguments;

    return Scaffold(
        appBar: AppBar(
          title: Text(args!.name, style: TextStyle(color: CustomColor.secondaryColor)),
          iconTheme: IconThemeData(
            color: CustomColor.secondaryColor,
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

class ReportEventArgument {
  final int eventId;
  final int positionId;
  final Map<String, dynamic> attributes;
  final String type;
  final String name;
  ReportEventArgument(this.eventId, this.positionId, this.attributes, this.type, this.name);
}
