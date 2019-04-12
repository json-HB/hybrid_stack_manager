package com.taobao.hybridstackmanager;

import java.util.HashMap;
import android.app.Activity;

public interface XURLRouterHandler {
    public void openUrlWithQueryAndParams(String url, HashMap query, HashMap params);
    public void handleCallFromFlutter(Activity activity, String method, HashMap params);
}
