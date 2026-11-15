import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:twsylh_user/common/models/config_model.dart';
import 'package:twsylh_user/features/auth/controllers/auth_controller.dart';
import 'package:twsylh_user/features/auth/domain/services/auth_service_interface.dart';
import 'package:twsylh_user/features/order/controllers/order_controller.dart';
import 'package:twsylh_user/features/order/domain/models/order_model.dart';
import 'package:twsylh_user/features/order/domain/services/order_service_interface.dart';
import 'package:twsylh_user/features/order/widgets/order_calcuation_widget.dart';
import 'package:twsylh_user/features/splash/controllers/splash_controller.dart';
import 'package:twsylh_user/features/splash/domain/services/splash_service_interface.dart';

class MockOrderService implements OrderServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSplashService implements SplashServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthService implements AuthServiceInterface {
  @override
  bool isSharedPrefNotificationActive() => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class TestSplashController extends SplashController {
  TestSplashController({required super.splashServiceInterface});

  @override
  ConfigModel? get configModel => ConfigModel(
    currencySymbol: 'EGP',
    digitAfterDecimalPoint: 0,
    currencySymbolDirection: 'right',
    additionalChargeName: 'رسوم إضافية',
  );

  @override
  Module getModuleConfig(String? moduleType) => Module(addOn: false);
}

class TestAuthController extends AuthController {
  TestAuthController({required super.authServiceInterface});

  @override
  bool isLoggedIn() => false;

  @override
  bool isGuestLoggedIn() => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OrderModel Price Update Reason Tests', () {
    test('parses price_update_reason from JSON correctly', () {
      final json = {
        'id': 101,
        'order_amount': 55.0,
        'coupon_discount_amount': 0.0,
        'total_tax_amount': 0.0,
        'delivery_charge': 15.0,
        'store_discount_amount': 0.0,
        'dm_tips': 0.0,
        'price_update_reason': 'انتقال من سوق لآخر',
      };

      final order = OrderModel.fromJson(json);
      expect(order.priceUpdateReason, 'انتقال من سوق لآخر');
    });

    test('parses reason fallback from JSON correctly', () {
      final json = {
        'id': 102,
        'order_amount': 60.0,
        'coupon_discount_amount': 0.0,
        'total_tax_amount': 0.0,
        'delivery_charge': 15.0,
        'store_discount_amount': 0.0,
        'dm_tips': 0.0,
        'reason': 'وزن الأوردر أكثر من 10 كجم',
      };

      final order = OrderModel.fromJson(json);
      expect(order.priceUpdateReason, 'وزن الأوردر أكثر من 10 كجم');
    });
  });

  group('OrderCalculationWidget Price Reason Visibility Tests', () {
    late OrderController orderController;

    setUp(() {
      Get.reset();
      Get.put<SplashController>(TestSplashController(splashServiceInterface: FakeSplashService()));
      Get.put<AuthController>(TestAuthController(authServiceInterface: FakeAuthService()));
      orderController = OrderController(orderServiceInterface: MockOrderService());
      Get.put<OrderController>(orderController);
    });

    testWidgets('shows price update reason banner when priceUpdateReason is present', (tester) async {
      final order = OrderModel(
        id: 101,
        orderAmount: 60,
        deliveryCharge: 15,
        dmTips: 0,
        priceUpdateReason: 'انتقال من سوق لآخر',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OrderCalculationWidget(
                orderController: orderController,
                order: order,
                ongoing: true,
                parcel: true,
                prescriptionOrder: false,
                deliveryCharge: 15,
                itemsPrice: 0,
                discount: 0,
                couponDiscount: 0,
                tax: 0,
                addOns: 0,
                dmTips: 0,
                taxIncluded: false,
                subTotal: 0,
                total: 75,
                bottomView: const SizedBox(),
                extraPackagingAmount: 0,
                referrerBonusAmount: 0,
                timerCancel: () {},
                startApiCall: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('سبب تعديل السعر بواسطة المندوب:'), findsOneWidget);
      expect(find.text('انتقال من سوق لآخر'), findsOneWidget);
    });

    testWidgets('hides price update reason banner when priceUpdateReason is null', (tester) async {
      final order = OrderModel(
        id: 101,
        orderAmount: 50,
        deliveryCharge: 15,
        dmTips: 0,
        priceUpdateReason: null,
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OrderCalculationWidget(
                orderController: orderController,
                order: order,
                ongoing: true,
                parcel: true,
                prescriptionOrder: false,
                deliveryCharge: 15,
                itemsPrice: 0,
                discount: 0,
                couponDiscount: 0,
                tax: 0,
                addOns: 0,
                dmTips: 0,
                taxIncluded: false,
                subTotal: 0,
                total: 65,
                bottomView: const SizedBox(),
                extraPackagingAmount: 0,
                referrerBonusAmount: 0,
                timerCancel: () {},
                startApiCall: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('سبب تعديل السعر بواسطة المندوب:'), findsNothing);
    });

    testWidgets('uses updated deliveryCharge parameter instead of stale order.deliveryCharge', (tester) async {
      final order = OrderModel(
        id: 103,
        orderAmount: 60,
        deliveryCharge: 50, // Old delivery charge from database
        dmTips: 0,
        priceUpdateReason: 'انتقال من سوق لآخر',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OrderCalculationWidget(
                orderController: orderController,
                order: order,
                ongoing: true,
                parcel: true,
                prescriptionOrder: false,
                deliveryCharge: 60, // Updated delivery charge reflecting order_amount
                itemsPrice: 0,
                discount: 0,
                couponDiscount: 0,
                tax: 0,
                addOns: 0,
                dmTips: 0,
                taxIncluded: false,
                subTotal: 0,
                total: 60,
                bottomView: const SizedBox(),
                extraPackagingAmount: 0,
                referrerBonusAmount: 0,
                timerCancel: () {},
                startApiCall: () {},
              ),
            ),
          ),
        ),
      );

      // Verify that the updated 60 is shown in the delivery charge, not the stale 50
      expect(find.textContaining('60'), findsWidgets);
      expect(find.textContaining('50'), findsNothing);
    });
  });
}
