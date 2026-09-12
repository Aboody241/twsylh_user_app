import 'package:image_picker/image_picker.dart';
import 'package:twsylh_user/api/api_client.dart';
import 'package:twsylh_user/common/models/module_model.dart';
import 'package:twsylh_user/features/location/domain/models/zone_data_model.dart';
import 'package:twsylh_user/features/auth/domain/models/delivery_man_body.dart';
import 'package:twsylh_user/features/auth/domain/models/delivery_man_vehicles_model.dart';

abstract class DeliverymanRegistrationServiceInterface{
  Future<List<ZoneDataModel>?> getZoneList();
  Future<List<ModuleModel>?> getModules(int? zoneId);
  int? prepareSelectedZoneIndex(List<int>? zoneIds, List<ZoneDataModel>? zoneList);
  Future<List<DeliveryManVehicleModel>?> getVehicleList();
  List<int?>? prepareVehicleIds(List<DeliveryManVehicleModel>? vehicleList);
  Future<void> registerDeliveryMan(DeliveryManBody deliveryManBody, List<MultipartBody> multiParts);
  List<MultipartBody> prepareMultipart(XFile? pickedImage, List<XFile> pickedIdentities);
}