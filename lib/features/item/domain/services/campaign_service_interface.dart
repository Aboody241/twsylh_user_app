import 'package:twsylh_user/common/enums/data_source_enum.dart';
import 'package:twsylh_user/features/item/domain/models/basic_campaign_model.dart';
import 'package:twsylh_user/features/item/domain/models/item_model.dart';

abstract class CampaignServiceInterface {
  Future<List<BasicCampaignModel>?> getBasicCampaignList(DataSourceEnum source);
  Future<BasicCampaignModel?> getCampaignDetails(String campaignID);
  Future<List<Item>?> getItemCampaignList(DataSourceEnum dataSource);
}