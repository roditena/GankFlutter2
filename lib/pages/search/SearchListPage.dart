import 'dart:async';
import 'dart:convert';

import 'package:GankFlutter/common/GlobalConfig.dart';
import 'package:GankFlutter/api/Api.dart';
import 'package:GankFlutter/api/http.dart';
import 'package:GankFlutter/common/Constant.dart';
import 'package:GankFlutter/model/DailyResponse.dart';
import 'package:GankFlutter/pages/detail/DetailListView.dart';
import 'package:GankFlutter/utils/IndicatorUtils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class SearchListPage extends StatefulWidget {
  String id;

  SearchListPage(ValueKey<String> key) : super(key: key) {
    this.id = key.value.toString();
  }

  @override
  _SearchListPageState createState() => new _SearchListPageState();
}

class _SearchListPageState extends State<SearchListPage>
    with HttpExt, IndicatorFactory {
  /// 标志当前在请求中。
  var _isRequesting = false;

  ///请求是否异常
  var requestError = true;
  var listData;
  var curPage = 1;

  final controller = TextEditingController();

  RefreshController _refreshController = new RefreshController();

  void enterRefresh() {
    _refreshController.requestRefresh(true);
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      _isRequesting = true;
      requestError = true;
    });
    searchArticle(false);
  }

  @override
  Widget build(BuildContext context) {
    return requestError
        ? _isRequesting
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(GlobalConfig.colorPrimary),
                ),
              )
            : buildExceptionIndicator("是不是傻！不输东西搜啥")
        : listData == null
            ? new Center(
                child: buildExceptionIndicator("抱歉！这会我傻了，啥也没搜到"),
              )
            : new SmartRefresher(
                enablePullUp: true,
                enablePullDown: true,
                controller: _refreshController,
                headerBuilder: buildDefaultHeader,
                footerBuilder: buildDefaultFooter,
                footerConfig: new RefreshConfig(),
                onRefresh: (up) {
                  if (up) {
                    _pullToRefresh();
                  } else {
                    _loadingMore();
                  }
                },
                child: buildListViewBuilder(context, listData));
  }

  //刷新
  Future<Null> _pullToRefresh() async {
    curPage = 1;
    searchArticle(false);
    return null;
  }

  //加载更多
  void _loadingMore() async {
    print("load more ... ");
    curPage++;
    searchArticle(true);
  }

  //网络请求
  searchArticle(bool isLoadMore) {
    var url = Api.SEARCH_URL;
    url += 'listview/category/' +
        widget.id +
        '/count/10/page/' +
        this.curPage.toString();
    print("feedListUrl: $url");

    HttpExt.get(url, (data) {
      setState(() {
        _isRequesting = false;
        requestError = false;
        new Future.delayed(new Duration(milliseconds: 200)).then((val) {
          requestBack(isLoadMore);
        });
      });
      if (data != null) {
        CategoryResponse categoryResponse =
            CategoryResponse.fromJson(jsonDecode(data));
        if (!categoryResponse.error) {
          var _listData = categoryResponse.results;
          print(_listData);
          if (_listData.length > 0) {
            setState(() {
              if (!isLoadMore) {
                listData = _listData;
              } else {
                List list1 = new List();
                list1.addAll(listData);
                list1.addAll(_listData);
                listData = list1;
              }
            });
          } else {
            setState(() {
              listData = null;
            });
          }
        }
      }
    }, (e) {
      print("get news list error: $e");
      setState(() {
        requestError = true;
      });
    });
  }

  void initVar() {
    curPage = 1;
    requestError = true;
    _isRequesting = true;
  }

  void requestBack(bool isLoadMore) {
    if (isLoadMore) {
      _refreshController.sendBack(false, RefreshStatus.idle);
    } else {
      _refreshController.sendBack(true, RefreshStatus.completed);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
