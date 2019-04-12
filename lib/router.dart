import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'router_option.dart';
import 'hybrid_stack_manager.dart';
import 'utils.dart';

typedef Widget FlutterWidgetHandler({RouterOption routeOption, Key key});

class XMaterialPageRoute<T> extends MaterialPageRoute<T> {
  final WidgetBuilder builder;
  final bool animated;
  Duration get transitionDuration {
    if (animated == true) return const Duration(milliseconds: 300);
    return const Duration(milliseconds: 0);
  }

  XMaterialPageRoute({
    this.builder,
    this.animated,
    RouteSettings settings: const RouteSettings(),
  }) : super(builder: builder, settings: settings);
}

class Router extends Object {
  static final Router singleton = new Router._internal();
  List<XMaterialPageRoute> flutterRootPageNameLst = new List();
  Map<String, XMaterialPageRoute> _routeNameMap = new Map();
  String currentPageUrl;
  FlutterWidgetHandler routerWidgetHandler;
  GlobalKey globalKeyForRouter;
  static Router sharedInstance() {
    return singleton;
  }

  Router._internal() {
    HybridStackManagerPlugin.hybridStackManagerPlugin
        .setMethodCallHandler((MethodCall methodCall) {
      String method = methodCall.method;
      if (method == "openURLFromFlutter") {
        Map args = methodCall.arguments;
        if (args != null) {
          bool animated = (args["animated"] == 1);
          Router.sharedInstance().pushPageWithOptionsFromFlutter(
              routeOption: new RouterOption(
                  url: args["url"],
                  query: args["query"],
                  params: args["params"]),
              animated: animated ?? false);
        }
      } else if (method == "popToRoot") {
        Router.sharedInstance().popToRoot();
      } else if (method == "popToRouteNamed") {
        Router.sharedInstance().popToRouteNamed(methodCall.arguments);
      } else if (method == "popRouteNamed") {
        Router.sharedInstance().popRouteNamed(methodCall.arguments);
      } else {
        HybridStackManagerPlugin.hybridStackManagerPlugin.callFallbackHandler(methodCall);
      }
    });
  }

  popToRoot() {
    NavigatorState navState = Navigator.of(globalKeyForRouter.currentContext);
    navState.popUntil((route) {
      if (route.isFirst) {
        return true;
      }
      _routeNameMap.remove(route.settings.name);
      return false;
    });
  }

  popToRouteNamed(String routeName) {
    NavigatorState navState = Navigator.of(globalKeyForRouter.currentContext);
    navState.popUntil((route) {
      if (!(route is XMaterialPageRoute)) {
        return false;
      } else if (route.settings.name != routeName) {
        _routeNameMap.remove(route.settings.name);
        return false;
      }
      return true;
    });
  }

  popRouteNamed(String routeName) {
    NavigatorState navState = Navigator.of(globalKeyForRouter.currentContext);
    XMaterialPageRoute route = _routeNameMap.remove(routeName);
    if (route != null) {
      navState.removeRoute(route);
    }
  }

  pushPageWithOptionsFromFlutter({RouterOption routeOption, bool animated}) {
    Widget page =
        Router.sharedInstance().pageFromOption(routeOption: routeOption);
    if (page != null) {
      XMaterialPageRoute pageRoute = new XMaterialPageRoute(
          settings: new RouteSettings(name: routeOption.userInfo),
          animated: animated,
          builder: (BuildContext context) {
            return page;
          });

      _routeNameMap[routeOption.userInfo] = pageRoute;
      Navigator.of(globalKeyForRouter.currentContext).push(pageRoute);
      HybridStackManagerPlugin.hybridStackManagerPlugin
          .updateCurFlutterRoute(routeOption.userInfo);
    } else {
      HybridStackManagerPlugin.hybridStackManagerPlugin.openUrlFromNative(
          url: routeOption.url,
          query: routeOption.query,
          params: routeOption.params);
    }
  }

  pushPageWithOptionsFromNative({RouterOption routeOption, bool animated}) {
    HybridStackManagerPlugin.hybridStackManagerPlugin.openUrlFromNative(
        url: routeOption.url,
        query: routeOption.query,
        params: routeOption.params,
        animated: animated);
  }

  pageFromOption({RouterOption routeOption, Key key}) {
    try {
      currentPageUrl = routeOption.url + "?" + converUrl(routeOption.query);
    } catch (e) {}
    routeOption.userInfo = Utils.generateUniquePageName(routeOption.url);
    if (routerWidgetHandler != null)
      return routerWidgetHandler(routeOption: routeOption, key: key);
  }

  static String converUrl(Map query) {
    String tmpUrl = "";
    if (query != null) {
      bool skipfirst = true;
      query.forEach((key, value) {
        if (skipfirst) {
          skipfirst = false;
        } else {
          tmpUrl = tmpUrl + "&";
        }
        tmpUrl = tmpUrl + (key + "=" + value.toString());
      });
    }
    return Uri.encodeFull(tmpUrl);
  }
}
