import 'dart:async';
import 'package:flutter/services.dart';

typedef Future<dynamic> MethodHandler(MethodCall call);

class HybridStackManagerPlugin {
  static HybridStackManagerPlugin hybridStackManagerPlugin =
      new HybridStackManagerPlugin._internal();
  MethodChannel _channel;
  MethodHandler _handler;
  MethodHandler _fallbackHandler;

  void setMethodCallHandler(MethodHandler hdler) {
    _handler = hdler;
    _channel.setMethodCallHandler(_handler);
  }

  void setMethodCallFallbackHandler(MethodHandler hdler) {
    _fallbackHandler = hdler;
  }

  HybridStackManagerPlugin._internal() {
    _channel = new MethodChannel('hybrid_stack_manager');
  }

  void callFallbackHandler(MethodCall methodCall) {
    if (_fallbackHandler != null) {
      _fallbackHandler(methodCall);
    }
  }

  void openUrlFromNative({String url, Map query, Map params, bool animated}) {
    _channel.invokeMethod("openUrlFromNative", {
      "url": url ?? "",
      "query": query ?? {},
      "params": params ?? {},
      "animated": animated ?? true
    });
  }

  void popCurPage({bool animated = true}) {
    _channel.invokeMethod("popCurPage", animated);
  }

  void updateCurFlutterRoute(String curRouteName) {
    _channel.invokeMethod("updateCurFlutterRoute", curRouteName ?? "");
  }

  Future callNativeMethod(String method, [Map params]) async {
    return _channel.invokeMethod("callNativeMethod", {
      'method': method,
      'params': params ?? {}
    });
  }

  Future<Map> getMainEntryParams() async {
    dynamic info = await _channel.invokeMethod("getMainEntryParams");
    return new Future.sync(() => info as Map);
  }
}
