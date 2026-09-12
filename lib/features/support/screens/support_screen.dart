import 'package:twsylh_user/features/splash/controllers/splash_controller.dart';
import 'package:twsylh_user/features/support/widgets/web_help_support_widget.dart';
import 'package:twsylh_user/helper/responsive_helper.dart';
import 'package:twsylh_user/util/app_constants.dart';
import 'package:twsylh_user/util/dimensions.dart';
import 'package:twsylh_user/util/images.dart';
import 'package:twsylh_user/common/widgets/custom_app_bar.dart';
import 'package:twsylh_user/common/widgets/custom_snackbar.dart';
import 'package:twsylh_user/common/widgets/footer_view.dart';
import 'package:twsylh_user/common/widgets/menu_drawer.dart';
import 'package:twsylh_user/features/support/widgets/support_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'help_support'.tr),
      endDrawer: const MenuDrawer(),endDrawerEnableOpenDragGesture: false,
      body: SingleChildScrollView(
        padding: ResponsiveHelper.isDesktop(context) ? EdgeInsets.zero : const EdgeInsets.all(Dimensions.paddingSizeSmall),
        physics: const BouncingScrollPhysics(),
        child: Center(child: FooterView(
          child: ResponsiveHelper.isDesktop(context) ? const SizedBox(
            width: double.infinity, height: 650,
            child: WebSupportScreen(),
          ) : SizedBox(width: Dimensions.webMaxWidth, child: Column(children: [
            const SizedBox(height: Dimensions.paddingSizeSmall),

            Image.asset(Images.supportImage, height: 120),
            const SizedBox(height: 30),

            Image.asset(Images.logo, width: 220),
            const SizedBox(height: 40),

            SupportButtonWidget(
              icon: Icons.location_on, title: 'address'.tr, color: Colors.blue,
              info: Get.find<SplashController>().configModel?.address ?? AppConstants.supportAddress,
              onTap: () {},
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            SupportButtonWidget(
              icon: Icons.call, title: 'call'.tr, color: Colors.red,
              info: Get.find<SplashController>().configModel?.phone ?? AppConstants.supportPhone,
              onTap: () async {
                final String phone = Get.find<SplashController>().configModel?.phone ?? AppConstants.supportPhone;
                if(await canLaunchUrlString('tel:$phone')) {
                  launchUrlString('tel:$phone');
                }else {
                  showCustomSnackBar('${'can_not_launch'.tr} $phone');
                }
              },
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            SupportButtonWidget(
              icon: Icons.mail_outline, title: 'email_us'.tr, color: Colors.green,
              info: Get.find<SplashController>().configModel?.email ?? AppConstants.supportEmail,
              onTap: () {
                final String email = Get.find<SplashController>().configModel?.email ?? AppConstants.supportEmail;
                final Uri emailLaunchUri = Uri(
                  scheme: 'mailto',
                  path: email,
                );
                launchUrlString(emailLaunchUri.toString());
              },
            ),

          ])),
        )),
      ),
    );
  }
}
