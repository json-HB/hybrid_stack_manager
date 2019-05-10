package com.taobao.hybridstackmanager;

import android.content.Context;
import android.content.Intent;
import android.app.Activity;
import android.net.Uri;
import java.util.HashMap;
import io.flutter.plugin.common.MethodChannel.Result;

public class XURLRouter {
    final static String kOpenUrlPrefix = "hrd";
    static XURLRouter sRouterInst;
    Context mAppContext;
    XURLRouterHandler mNativeRouterHandler;
    public static XURLRouter sharedInstance(){
        if(sRouterInst==null){
            sRouterInst = new XURLRouter();
        }
        return sRouterInst;
    }
    public void setAppContext(Context context){
        mAppContext = context;
    }
    public void setNativeRouterHandler(XURLRouterHandler handler){
        mNativeRouterHandler = handler;
    }
    public boolean openUrlWithQueryAndParams(String url, HashMap query, HashMap params) {
        Uri tmpUri = Uri.parse(url);
        String scheme = tmpUri.getScheme();
        if (scheme == null || !scheme.equals(kOpenUrlPrefix) && !scheme.startsWith("http")) {
            return false;
        }
        if (scheme.startsWith("http") || "native".equals(tmpUri.getHost())) {
            if (mNativeRouterHandler != null) {
                mNativeRouterHandler.openUrlWithQueryAndParams(url, query, params);
                return true;
            } else {
                return false;
            }
        } else {
            Intent intent = new Intent(mAppContext,FlutterWrapperActivity.class);
            intent.putExtra("url", url);
            intent.putExtra("query", query);
            intent.putExtra("params", params);
            // intent.setAction(Intent.ACTION_VIEW);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            mAppContext.startActivity(intent);
            return true;
        }
    }
    public void handleCallFromFlutter(Activity activity, Result result, String method, HashMap params) {
      if (mNativeRouterHandler != null) {
          mNativeRouterHandler.handleCallFromFlutter(activity, result, method, params);
      }
    }
}
