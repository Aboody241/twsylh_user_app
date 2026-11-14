import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:twsylh_user/common/models/config_model.dart';
import 'package:twsylh_user/common/models/module_model.dart';
import 'package:twsylh_user/common/models/response_model.dart';
import 'package:twsylh_user/features/favourite/controllers/favourite_controller.dart';
import 'package:twsylh_user/features/favourite/domain/services/favourite_service_interface.dart';
import 'package:twsylh_user/features/item/domain/models/item_model.dart';
import 'package:twsylh_user/features/splash/controllers/splash_controller.dart';
import 'package:twsylh_user/features/splash/domain/services/splash_service_interface.dart';
import 'package:twsylh_user/features/store/domain/models/store_model.dart';

void main() {
  late _FakeFavouriteService favouriteService;
  late FavouriteController controller;

  setUp(() {
    Get.reset();
    Get.put<SplashController>(
      _TestSplashController(selectedModule: ModuleModel(id: 7, moduleType: 'food')),
    );
    favouriteService = _FakeFavouriteService();
    controller = FavouriteController(favouriteServiceInterface: favouriteService);
  });

  tearDown(Get.reset);

  test('getFavouriteList keeps a loading state until the response arrives', () async {
    favouriteService.response = _successResponse();
    await controller.getFavouriteList();
    expect(controller.wishItemList, isNotEmpty);

    final completer = Completer<Response>();
    favouriteService
      ..response = null
      ..completer = completer;

    final future = controller.getFavouriteList();

    expect(controller.wishItemList, isNull);
    expect(controller.wishStoreList, isNull);

    completer.complete(_successResponse());
    await future;

    expect(controller.wishItemList, isNotNull);
    expect(controller.wishStoreList, isNotNull);
  });

  test('getFavouriteList populates item and store lists from a successful response', () async {
    favouriteService.response = _successResponse();

    await controller.getFavouriteList();

    expect(favouriteService.getFavouriteListCallCount, 1);
    expect(controller.wishItemList, hasLength(1));
    expect(controller.wishItemList!.single!.id, 11);
    expect(controller.wishItemList!.single!.name, 'Test item');
    expect(controller.wishItemIdList, <int?>[11]);
    expect(controller.wishStoreList, hasLength(1));
    expect(controller.wishStoreList!.single!.id, 21);
    expect(controller.wishStoreList!.single!.name, 'Test store');
    expect(controller.wishStoreIdList, <int?>[21]);
  });

  test('getFavouriteList returns empty lists for an empty response', () async {
    favouriteService.response = _emptyResponse();

    await controller.getFavouriteList();

    expect(controller.wishItemList, isNotNull);
    expect(controller.wishItemList, isEmpty);
    expect(controller.wishStoreList, isNotNull);
    expect(controller.wishStoreList, isEmpty);
    expect(controller.wishItemIdList, isEmpty);
    expect(controller.wishStoreIdList, isEmpty);
  });

  test('getFavouriteList clears the lists when the API responds with an error', () async {
    favouriteService.response = _successResponse();
    await controller.getFavouriteList();
    expect(controller.wishItemList, isNotEmpty);

    favouriteService.response = Response(
      statusCode: 500,
      body: <String, dynamic>{'message': 'Internal server error'},
    );

    await controller.getFavouriteList();

    expect(favouriteService.getFavouriteListCallCount, 2);
    expect(controller.wishItemList, isNull);
    expect(controller.wishStoreList, isNull);
  });

  test('removeFavourite clears the favourite id lists', () async {
    favouriteService.response = _successResponse();
    await controller.getFavouriteList();
    expect(controller.wishItemIdList, isNotEmpty);
    expect(controller.wishStoreIdList, isNotEmpty);

    controller.removeFavourite();

    expect(controller.wishItemIdList, isEmpty);
    expect(controller.wishStoreIdList, isEmpty);
  });
}

Response _successResponse() {
  return Response(
    statusCode: 200,
    body: <String, dynamic>{
      'item': <dynamic>[
        <String, dynamic>{
          'id': 11,
          'name': 'Test item',
          'price': 5.5,
          'discount': 0,
          'module_type': 'food',
          'module_id': 7,
          'variations': <dynamic>[],
          'food_variations': <dynamic>[],
        },
      ],
      'store': <dynamic>[
        <String, dynamic>{
          'id': 21,
          'name': 'Test store',
          'featured': 0,
          'module_id': 7,
        },
      ],
    },
  );
}

Response _emptyResponse() {
  return Response(
    statusCode: 200,
    body: <String, dynamic>{
      'item': <dynamic>[],
      'store': <dynamic>[],
    },
  );
}

class _FakeFavouriteService implements FavouriteServiceInterface {
  Response? response;
  Completer<Response>? completer;
  int getFavouriteListCallCount = 0;

  @override
  Future<Response> getFavouriteList() async {
    getFavouriteListCallCount++;
    return completer?.future ?? response!;
  }

  @override
  Future<ResponseModel> addFavouriteList(int? id, bool isStore) {
    throw UnimplementedError('addFavouriteList is not exercised by these tests');
  }

  @override
  Future<ResponseModel> removeFavouriteList(int? id, bool isStore) {
    throw UnimplementedError('removeFavouriteList is not exercised by these tests');
  }

  @override
  List<Item?> wishItemList(Item item) => <Item?>[item];

  @override
  List<int?> wishItemIdList(Item item) => <int?>[item.id];

  @override
  List<Store?> wishStoreList(dynamic store) {
    return <Store?>[Store.fromJson(store as Map<String, dynamic>)];
  }

  @override
  List<int?> wishStoreIdList(dynamic store) {
    return <int?>[Store.fromJson(store as Map<String, dynamic>).id];
  }
}

class _TestSplashController extends SplashController {
  _TestSplashController({this.selectedModule})
      : super(splashServiceInterface: _StubSplashService());

  final ModuleModel? selectedModule;

  @override
  ModuleModel? get module => selectedModule;

  @override
  Module getModuleConfig(String? moduleType) => Module(newVariation: false);
}

class _StubSplashService implements SplashServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'SplashServiceInterface.${invocation.memberName} is not exercised by these tests',
    );
  }
}
