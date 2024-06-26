import 'package:connectivity_plus/connectivity_plus.dart';
import '../common/third_party/OdooRepository/odoo_repository.dart'
    show netConnState, NetConnState;

class NetworkConnectivity implements NetConnState {
  static NetworkConnectivity? _singleton;
  static late Connectivity _connectivity;

  factory NetworkConnectivity() {
    _singleton ??= NetworkConnectivity._();
    return _singleton!;
  }

  NetworkConnectivity._() {
    _connectivity = Connectivity();
  }

  @override
  Future<netConnState> checkNetConn() async {
    final connectivityResult = await (_connectivity.checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      return netConnState.online;
    } else if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.ethernet) {
      return netConnState.online;
    }
    return netConnState.offline;
  }

  @override
  Stream<netConnState> get onNetConnChanged async* {
    await for (var netState in _connectivity.onConnectivityChanged) {
      if (netState == ConnectivityResult.mobile) {
        // Went online now
        yield netConnState.online;
      } else if (netState == ConnectivityResult.wifi  ||
        netState == ConnectivityResult.ethernet) {
        // Went online now
        yield netConnState.online;
      } else if (netState == ConnectivityResult.none) {
        // Went offline now
        yield netConnState.offline;
      }
    }
  }
}
