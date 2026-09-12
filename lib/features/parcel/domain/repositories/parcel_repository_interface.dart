import 'package:get/get_connect/http/src/response/response.dart';
import 'package:twsylh_user/common/enums/data_source_enum.dart';
import 'package:twsylh_user/features/parcel/domain/models/parcel_cancellation_reasons_model.dart';
import 'package:twsylh_user/interfaces/repository_interface.dart';

abstract class ParcelRepositoryInterface<T> implements RepositoryInterface {
  @override
  Future get(String? id, {bool isVideoDetails = true, DataSourceEnum source});
  @override
  Future getList({int? offset, bool parcelCategory = true});
  Future<Response> getPlaceDetails(String? placeID);
  Future<ParcelCancellationReasonsModel?> getParcelCancellationReasons({required bool isBeforePickup});
}