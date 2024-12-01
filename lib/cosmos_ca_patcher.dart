library cosmos_ca_patcher;

export 'screen/download_ca_page.dart';
export 'models/ca_renewer.dart';
export 'models/ca_patcher_app_model.dart';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:cosmos_ca_patcher/models/ca_patcher_app_model.dart';
import 'package:cosmos_ca_patcher/models/ca_renewer.dart';
import 'package:grpc/grpc.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/subjects.dart';

class DownloadCA {
  static final DownloadCA _instance = DownloadCA._internal();
  late String _url;
  late String _sha;
  BuildVersionModel? _patchVersion;
  BuildVersionModel? get patchVersion => _patchVersion;
  String? clientKey;
  String? clientCert;
  final BehaviorSubject<MyChannelCredentials> subjectCred =
      BehaviorSubject<MyChannelCredentials>();

  setPatchVersion(BuildVersionModel version) {
    _patchVersion = version;
  }

  setClientKey(String key) {
    clientKey = key;
  }

  setClientCert(String cert) {
    clientCert = cert;
  }

  DownloadCA._internal();

  DownloadCA() {
    _instance;
  }

  void init(String url, String sha) {
    _url = url;
    _sha = sha;
  }

  Future<http.Response> checkVersionBuildVersion() async {
    final response =
        await http.get(Uri.parse('$_url/ca_renewer/build_version'), headers: {
      'sha': _sha,
    });
    if (response.statusCode == 200) {
      return response;
    } else {
      return http.Response('Failed to check version', 500);
    }
  }

  Future<List<String>?> retrieveAndSaveFile() async {
    String downloadUrl = '$_url/ca_renewer/download_client';

    try {
      // Fetch the file from the server with headers
      final response = await http.get(
        Uri.parse(downloadUrl),
        headers: {
          'sha': _sha,
        },
      );

      if (response.statusCode == 200) {
        // Get the directory for the app

        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/zipfile.zip';
        final file = File(filePath);
        // Write the file
        await file.writeAsBytes(response.bodyBytes);
        // Check the sha256 of the file
        // Extract the zip file
        await _extractZipFile(file, directory.path);
        return listFilesInDirectory(directory.path);
      } else {
        print('Failed to download file');
        return null;
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  ClientChannel getChannel(
      MyChannelCredentials cred, String address, int port) {
    var client = ClientChannel(address,
        port: port,
        options: ChannelOptions(
            credentials: ChannelCredentials.secure(
          certificates: cred.certificateChain,
          authority: cred.authority,
        )));
    return client;
  }
}

Future<void> _extractZipFile(File file, String destinationPath) async {
  final bytes = file.readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);
  for (final file in archive) {
    var filename = '$destinationPath/${file.name}';
    if (Platform.isIOS && file.name.contains('ca-cert.pem')) {
      filename = '$destinationPath/ca-cert.crt';
    }
    if (Platform.isIOS && file.name.contains('ca-key.pem')) {
      filename = '$destinationPath/ca-key.key';
    }
    if (file.isFile) {
      final data = file.content as List<int>;
      File(filename)
        ..createSync(recursive: true)
        ..writeAsBytesSync(data);
    } else {
      Directory(filename).create(recursive: true);
    }
  }
}

Future<List<String>> listFilesInDirectory(String directoryPath) async {
  final directory = Directory(directoryPath);
  if (await directory.exists()) {
    final files = directory.listSync(recursive: true);
    return files.map((file) => file.path).toList();
  } else {
    return [];
  }
}
