package com.taobao.hybridstackmanager;

import java.util.HashMap;
import android.net.Uri;
import android.app.Activity;
import android.os.Build;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * hybridstackmanager
 */
public class HybridStackManager implements MethodCallHandler {
    /**
     * Plugin registration.
     */
    private static HybridStackManager hybridStackManager = null;
    public MethodChannel methodChannel;
    public FlutterActivityChecker curFlutterActivity;
    public HashMap mainEntryParams;
    public HashMap deviceInfoParams;

    public static HybridStackManager sharedInstance() {
        if (hybridStackManager != null) { return hybridStackManager; }
        hybridStackManager = new HybridStackManager();
        return hybridStackManager;
    }

    public static void registerWith(Registrar registrar) {
        hybridStackManager = HybridStackManager.sharedInstance();
        hybridStackManager.methodChannel = new MethodChannel(registrar.messenger(), "hybrid_stack_manager");
        hybridStackManager.methodChannel.setMethodCallHandler(hybridStackManager);
    }

    public static HashMap assembleChanArgs(String url, HashMap query, HashMap params) {
        HashMap arguments = new HashMap();
        Uri uri = Uri.parse(url);
        String tmpUrl = url.split("\\?")[0];
        HashMap tmpQuery = new HashMap();
        if (query != null) { tmpQuery.putAll(query); }
        for (String key : uri.getQueryParameterNames()) {
            tmpQuery.put(key, uri.getQueryParameter(key));
        }

        HashMap tmpParams = new HashMap();
        if (params != null) { tmpParams.putAll(params); }

        if (tmpUrl != null) { arguments.put("url", tmpUrl); }
        if (tmpQuery != null) { arguments.put("query", tmpQuery); }
        if (tmpParams != null) { arguments.put("params", tmpParams); }
        return arguments;
    }

    public void openUrlFromFlutter(String url, HashMap query, HashMap params) {
        HybridStackManager.sharedInstance().methodChannel.invokeMethod("openURLFromFlutter",
            assembleChanArgs(url, query, params));
    }

    public void callFlutterMethod(String method, HashMap args, MethodChannel.Result result) {
      HybridStackManager.sharedInstance().methodChannel.invokeMethod(method, args, result);
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        if (call.method.equals("callNativeMethod")) {
            if (curFlutterActivity != null && curFlutterActivity.isActive()) {
                HashMap args = (HashMap)call.arguments;
                String method = (String)args.get("method");
                HashMap params = (HashMap)args.get("params");
                XURLRouter.sharedInstance().handleCallFromFlutter((Activity)curFlutterActivity, result, method, params);
            }
        } else if (call.method.equals("openUrlFromNative")) {
            if (curFlutterActivity != null && curFlutterActivity.isActive()) {
                HashMap openUrlInfo = (HashMap)call.arguments;
                String url = (String)openUrlInfo.get("url");
                HashMap query = (HashMap)openUrlInfo.get("query");
                HashMap params = (HashMap)openUrlInfo.get("params");
                curFlutterActivity.openUrl(url, query, params);
            }
            result.success("OK");
        } else if (call.method.equals("getMainEntryParams")) {
            if (mainEntryParams == null) { mainEntryParams = new HashMap(); }
            result.success(mainEntryParams);
            //      mainEntryParams = null;
        } else if (call.method.equals("updateCurPageFlutterRoute")) {
            String curRouteName = (String)call.arguments;
            if (curFlutterActivity != null && curFlutterActivity.isActive()) {
                curFlutterActivity.setCurFlutterRouteName(curRouteName);
            }
            result.success("OK");
        } else if (call.method.equals("popCurPage")) {
            if (curFlutterActivity != null && curFlutterActivity.isActive()) {
                curFlutterActivity.popCurActivity();
            }
            result.success("OK");
        } else {
            result.notImplemented();
        }
    }
}
