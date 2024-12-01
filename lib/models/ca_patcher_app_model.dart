import 'dart:io';
import 'dart:typed_data';
import 'package:grpc/grpc.dart';


class GRPCController {
  final String clientCertPath;
  final String clientKeyPath;
  final String? authority;

  GRPCController(
      {required this.clientCertPath,
      required this.clientKeyPath,
      this.authority})  {
  }


  Future<MyChannelCredentials> initCred(
) async {
    final caCrtByteData = await File(clientCertPath).readAsBytes();
    final privateKeyByteData = await File(clientKeyPath).readAsBytes();
    final caCrt = caCrtByteData.buffer.asUint8List();
    final privateKey = privateKeyByteData.buffer.asUint8List();
    return await MyChannelCredentials(
      trustedRoots: caCrt,
      certificateChain: caCrt,
      privateKey: privateKey,
      authority: authority,
    );
  }


}

class MyChannelCredentials extends ChannelCredentials {
  final Uint8List? certificateChain;
  final Uint8List? privateKey;

  MyChannelCredentials({
    Uint8List? trustedRoots,
    this.certificateChain,
    this.privateKey,
    super.authority,
    super.onBadCertificate,
  }) : super.secure(certificates: trustedRoots);

  @override
  SecurityContext? get securityContext {
    final ctx = super.securityContext;
    if (certificateChain != null) {
      ctx?.useCertificateChainBytes(certificateChain!);
    }
    if (privateKey != null) {
      ctx?.usePrivateKeyBytes(privateKey!);
    }
    return ctx;
  }
}
