package com.taobao.hybridstackmanager;

import android.content.Context;
import android.content.Intent;
import android.app.Activity;
import android.net.Uri;
import java.util.HashMap;

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
        if (!kOpenUrlPrefix.equals(tmpUri.getScheme())) {
            return false;
        }
        if ("native".equals(tmpUri.getHost())) {
            if (mNativeRouterHandler != null) {
                mNativeRouterHandler.openUrlWithQueryAndParams(url, query, params);
                return true;
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
        return false;
    }
    public void handleCallFromFlutter(Activity activity, String method, HashMap params) {
      if (mNativeRouterHandler != null) {
          mNativeRouterHandler.handleCallFromFlutter(activity, method, params);
      }
    }
}
