# example using package
```
flutter pub add cosmos_ca_patcher
flutter pub add cosmos_ca_patcher --project-only
flutter pub add cosmos_ca_patcher --project-only --path ../cosmos_ca_patcher
```

# example using widget
```
import 'package:cosmos_ca_patcher/cosmos_ca_patcher.dart';
import 'package:example/proto/echo.pbgrpc.dart';
import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

MyChannelCredentials? creds;

class _MyAppState extends State<MyApp> {
  final String url = "http://192.168.0.169:3000";
  final String sha =
      "fb397bc7e93ff3accca190381bef5ce46eba6ca1063251ae5f3e6295bea0e9da";
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: DownloadCAPage(
          url: url,
          sha: sha,
          child: creds == null ? Container() : Home(),
          onChannelCreated: (c) {
            setState(() {
              creds = c;
            });
          },
        ));
  }
}

class Home extends StatefulWidget {
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String txt = "";
  late EchoClient echoClient;

  final downloadCA = DownloadCA();
  initChannel(ClientChannel? channel) async {
    // channel = cmPatcher.grpcController!.getChannel("192.168.1.10", 6969);
    echoClient = EchoClient(channel!);
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 200), () {
      print(creds!.authority);
      var channel = downloadCA.getChannel(creds!, "192.168.0.169", 6969);
      initChannel(channel);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton(
            onPressed: () {
              echoClient
                  .echo(EchoRequest()..message = "Hello World")
                  .then((value) {
                setState(() {
                  txt = value.message;
                });
              });
            },
            child: Icon(Icons.download)),
        appBar: AppBar(
          title: Text('Home'),
        ),
        body: Center(
          child: Text(txt),
        ));
  }
}
```

