import 'package:get/get.dart';
import 'package:twsylh_user/features/splash/controllers/splash_controller.dart';
import 'package:twsylh_user/util/app_constants.dart';

class TaxiHelper {

  static bool haveTaxiServiceRideModules() {
    final moduleList = Get.find<SplashController>().moduleList;

    return moduleList?.any((module) => module.moduleType == AppConstants.taxi || module.moduleType == AppConstants.service || module.moduleType == AppConstants.ride) ?? false;
  }
  static bool haveTaxiModule() {
    final moduleList = Get.find<SplashController>().moduleList;

    return moduleList?.any((module) => module.moduleType == AppConstants.taxi) ?? false;
  }

  // static bool haveServiceModule() {
  //   final moduleList = Get.find<SplashController>().moduleList;
  //
  //   return moduleList?.any((module) => module.moduleType == AppConstants.service) ?? false;
  // }

  static bool haveRideModule() {
    final moduleList = Get.find<SplashController>().moduleList;

    return moduleList?.any((module) => module.moduleType == AppConstants.ride) ?? false;
  }

}