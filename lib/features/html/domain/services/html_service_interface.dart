import 'package:get/get.dart';
import 'package:twsylh_user/util/html_type.dart';

abstract class HtmlServiceInterface{
  Future<Response> getHtmlText(HtmlType htmlType);
}