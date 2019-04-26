package com.taobao.hybridstackmanager;

import java.util.HashMap;
import android.app.Activity;
import io.flutter.plugin.common.MethodChannel.Result;

public interface XURLRouterHandler {
    public void openUrlWithQueryAndParams(String url, HashMap query, HashMap params);
    public void handleCallFromFlutter(Activity activity, Result result, String method, HashMap params);
}
