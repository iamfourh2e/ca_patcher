import 'dart:convert';
import 'dart:io';

import 'package:cosmos_ca_patcher/cosmos_ca_patcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

class DownloadCAPage extends StatefulWidget {
  final String url;
  final String sha;
  final Widget child;
  final Function(MyChannelCredentials) onChannelCreated;

  const DownloadCAPage(
      {super.key,
      required this.url,
      required this.sha,
      required this.child,
      required this.onChannelCreated,
      this.loadingWidget = const Center(child: CircularProgressIndicator()),
      this.errorWidget =
          const Center(child: Text('Error downloading certificates'))});

  final Widget loadingWidget;
  final Widget errorWidget;
  @override
  _DownloadCAPageState createState() => _DownloadCAPageState();
}

class _DownloadCAPageState extends State<DownloadCAPage> {
  FlutterSecureStorage storage = const FlutterSecureStorage();
  bool _isDownloading = false;
  DownloadStatus _status = DownloadStatus.retrieved;
  final fileService = DownloadCA();

  late Directory _directory;
  bool isLoading = true;
  getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    _directory = directory;
  }

  listFilesInDirectory() async {
    final files = _directory.listSync();
    for (var file in files) {
      if (file.path.contains('ca-cert.pem') ||
          file.path.contains('ca-cert.crt')) {
        fileService.clientCert = file.path;
      } else if (file.path.contains('ca-key.pem') ||
          file.path.contains('ca-key.key')) {
        fileService.clientKey = file.path;
      }
    }

    if (fileService.clientCert != null && fileService.clientKey != null) {
      var grpcController = GRPCController(
          clientCertPath: fileService.clientCert!,
          clientKeyPath: fileService.clientKey!,
          authority: fileService.patchVersion!.agent.authority);
      var cred = await grpcController.initCred();

      widget.onChannelCreated(cred);
    }
  }

  @override
  void initState() {
    super.initState();
    getFilePath();
    fileService.init(widget.url, widget.sha);
    _checkForPatchVersion();
  }

  Future<void> _checkForPatchVersion() async {
    setState(() {
      _status = DownloadStatus.retrieved;
    });
    if (widget.sha.isEmpty) {
      _status = DownloadStatus.failed;
      _isDownloading = false;
      return;
    }
    // Simulate checversiok
    //check version from secure storage
    var key = 'version' + widget.sha;
    final version = await storage.read(key: key);
    try {
      final response = await fileService.checkVersionBuildVersion();
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        BuildVersionModel patch = BuildVersionModel.fromJson(body["data"]);
        fileService.setPatchVersion(patch);
        if (version == null) {
          int version = 1;
          await _downloadFile(version);
        } else {
          if (patch.buildVersion > int.parse(version)) {
            await _downloadFile(patch.buildVersion);
          } else {
            setState(() {
              _status = DownloadStatus.retrieved;
              _isDownloading = false;
            });
            listFilesInDirectory();
          }
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _downloadFile(int buildVersion) async {
    setState(() {
      _isDownloading = true;
      _status = DownloadStatus.downloading;
    });

    final files = await fileService.retrieveAndSaveFile();
    if (files != null) {
      var key = 'version' + widget.sha;
      await storage.write(key: key, value: buildVersion.toString());
      Future.delayed(const Duration(milliseconds: 200), () {
        setState(() {
          _status = DownloadStatus.downloaded;
          _isDownloading = false;
        });
      });
    } else {
      setState(() {
        _status = DownloadStatus.failed;
        _isDownloading = false;
      });
    }

    listFilesInDirectory();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDownloading) {
      return widget.loadingWidget;
    }
    if (_status == DownloadStatus.failed) {
      return widget.errorWidget;
    }
    return widget.child;
  }
}

enum DownloadStatus { downloading, downloaded, failed, retrieved }

extension DownloadStatusMessage on DownloadStatus {
  String get message {
    switch (this) {
      case DownloadStatus.downloading:
        return 'Downloading patch version...';
      case DownloadStatus.downloaded:
        return 'Patch version downloaded';
      case DownloadStatus.failed:
        return 'Failed to download patch version';
      case DownloadStatus.retrieved:
        return 'Patch version already downloaded';
      default:
        return '';
    }
  }
}
