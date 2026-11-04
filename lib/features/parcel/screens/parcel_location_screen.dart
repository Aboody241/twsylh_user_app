import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:twsylh_user/common/widgets/custom_bottom_sheet_widget.dart';
import 'package:twsylh_user/common/widgets/custom_card.dart';
import 'package:twsylh_user/common/widgets/custom_loader.dart';
import 'package:twsylh_user/common/widgets/footer_view.dart';
import 'package:twsylh_user/common/widgets/web_page_title_widget.dart';
import 'package:twsylh_user/features/checkout/controllers/checkout_controller.dart';
import 'package:twsylh_user/features/location/controllers/location_controller.dart';
import 'package:twsylh_user/features/location/domain/models/prediction_model.dart';
import 'package:twsylh_user/features/location/domain/models/zone_response_model.dart';
import 'package:twsylh_user/features/location/screens/pick_map_screen.dart';
import 'package:twsylh_user/features/splash/controllers/splash_controller.dart';
import 'package:twsylh_user/features/profile/controllers/profile_controller.dart';
import 'package:twsylh_user/features/address/controllers/address_controller.dart';
import 'package:twsylh_user/features/address/domain/models/address_model.dart';
import 'package:twsylh_user/features/parcel/controllers/parcel_controller.dart';
import 'package:twsylh_user/features/parcel/domain/models/parcel_category_model.dart';
import 'package:twsylh_user/features/auth/controllers/auth_controller.dart';
import 'package:twsylh_user/features/parcel/widgets/saved_address_bottom_sheet.dart';
import 'package:twsylh_user/helper/address_helper.dart';
import 'package:twsylh_user/helper/auth_helper.dart';
import 'package:twsylh_user/helper/custom_validator.dart';
import 'package:twsylh_user/helper/responsive_helper.dart';
import 'package:twsylh_user/helper/route_helper.dart';
import 'package:twsylh_user/util/dimensions.dart';
import 'package:twsylh_user/util/images.dart';
import 'package:twsylh_user/util/styles.dart';
import 'package:twsylh_user/common/widgets/custom_app_bar.dart';
import 'package:twsylh_user/common/widgets/custom_button.dart';
import 'package:twsylh_user/common/widgets/custom_snackbar.dart';
import 'package:twsylh_user/common/widgets/custom_text_field.dart';
import 'package:twsylh_user/common/widgets/menu_drawer.dart';
import 'package:twsylh_user/features/location/domain/services/location_service_interface.dart';
import 'package:twsylh_user/util/app_constants.dart';

class ParcelLocationScreen extends StatefulWidget {
  final ParcelCategoryModel category;
  const ParcelLocationScreen({super.key, required this.category});

  @override
  State<ParcelLocationScreen> createState() => _ParcelLocationScreenState();
}

class _ParcelLocationScreenState extends State<ParcelLocationScreen> {
  // ── Controllers: Sender ──
  final TextEditingController _senderNameController    = TextEditingController();
  final TextEditingController _senderPhoneController   = TextEditingController();
  final TextEditingController _senderStreetNumberController = TextEditingController();
  final TextEditingController _senderHouseController   = TextEditingController();
  final TextEditingController _senderFloorController   = TextEditingController();
  final TextEditingController _guestSenderEmailController = TextEditingController();
  final TextEditingController _senderAddressController = TextEditingController();

  // ── Controllers: Receiver ──
  final TextEditingController _receiverNameController    = TextEditingController();
  final TextEditingController _receiverPhoneController   = TextEditingController();
  final TextEditingController _receiverStreetNumberController = TextEditingController();
  final TextEditingController _receiverHouseController   = TextEditingController();
  final TextEditingController _receiverFloorController   = TextEditingController();
  final TextEditingController _guestReceiverEmailController = TextEditingController();
  final TextEditingController _receiverAddressController = TextEditingController();

  // ── Controller: Order Note ──
  final TextEditingController _orderNoteController = TextEditingController();

  // ── FocusNodes: Sender ──
  final FocusNode _senderStreetNode    = FocusNode();
  final FocusNode _senderHouseNode     = FocusNode();
  final FocusNode _senderFloorNode     = FocusNode();
  final FocusNode _senderNameNode      = FocusNode();
  final FocusNode _senderPhoneNode     = FocusNode();
  final FocusNode _senderGuestEmailNode = FocusNode();
  final FocusNode _orderNoteNode       = FocusNode();

  // ── FocusNodes: Receiver ──
  final FocusNode _receiverStreetNode    = FocusNode();
  final FocusNode _receiverHouseNode     = FocusNode();
  final FocusNode _receiverFloorNode     = FocusNode();
  final FocusNode _receiverNameNode      = FocusNode();
  final FocusNode _receiverPhoneNode     = FocusNode();
  final FocusNode _receiverGuestEmailNode = FocusNode();

  String? _countryDialCode;

  // ── country dial codes per section ──
  String? _senderCountryDialCode;
  String? _receiverCountryDialCode;

  bool _isHqZoneLoading = false;
  bool _isHqZoneResolved = false;
  String? _hqZoneErrorMessage;

  // ── Form key for validation ──
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isValidCoordinate(String? latStr, String? lngStr) {
    final double? lat = double.tryParse(latStr ?? '');
    final double? lng = double.tryParse(lngStr ?? '');
    if (lat == null || lng == null) return false;
    if (!lat.isFinite || !lng.isFinite) return false;
    if (lat == 0.0 && lng == 0.0) return false;
    if (lat < -90.0 || lat > 90.0) return false;
    if (lng < -180.0 || lng > 180.0) return false;
    return true;
  }

  Future<void> _resolveHqZone() async {
    if (_isHqZoneLoading || !mounted) return;

    setState(() {
      _isHqZoneLoading = true;
      _hqZoneErrorMessage = null;
    });

    try {
      final ZoneResponseModel response = await Get.find<LocationController>().locationServiceInterface.getZone(
        AppConstants.hqLatitude.toString(),
        AppConstants.hqLongitude.toString(),
        handleError: false,
      );

      if (!mounted) return;

      if (response.isSuccess && response.zoneIds.isNotEmpty) {
        final parcelController = Get.find<ParcelController>();
        final currentPickup = parcelController.pickupAddress;
        if (currentPickup != null) {
          final updatedHq = AddressModel(
            address: currentPickup.address,
            latitude: currentPickup.latitude,
            longitude: currentPickup.longitude,
            contactPersonName: currentPickup.contactPersonName,
            contactPersonNumber: currentPickup.contactPersonNumber,
            addressType: currentPickup.addressType,
            zoneId: response.zoneIds[0],
            zoneIds: List<int>.from(response.zoneIds),
            zoneData: List<ZoneData>.from(response.zoneData),
          );
          parcelController.setPickupAddress(updatedHq, true);
        }
        _isHqZoneResolved = true;
        _hqZoneErrorMessage = null;
      } else {
        _isHqZoneResolved = false;
        _hqZoneErrorMessage = 'خدمة الطلبات غير متاحة حالياً في نطاق مقر الشركة';
      }
    } catch (e) {
      if (!mounted) return;
      _isHqZoneResolved = false;
      _hqZoneErrorMessage = 'تعذر التحقق من نطاق خدمة مقر الشركة، يرجى المحاولة مجدداً';
    } finally {
      if (mounted) {
        setState(() {
          _isHqZoneLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    initCall();
  }

  Future<void> initCall() async {
    _countryDialCode = Get.find<AuthController>().getUserCountryCode().isNotEmpty
        ? Get.find<AuthController>().getUserCountryCode()
        : CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).dialCode;

    final AddressModel hqAddress = AddressModel(
      address: AppConstants.hqAddressPlaceholder,
      latitude: AppConstants.hqLatitude.toString(),
      longitude: AppConstants.hqLongitude.toString(),
      contactPersonName: AppConstants.hqContactName,
      contactPersonNumber: AppConstants.hqPhone,
      addressType: 'others',
      zoneId: null,
      zoneIds: [],
      zoneData: [],
    );
    Get.find<ParcelController>().setPickupAddress(hqAddress, false);

    final saved = AddressHelper.getUserAddressFromSharedPref();
    if (saved != null) {
      Get.find<ParcelController>().setDestinationAddress(saved, notify: false);
      _receiverAddressController.text = saved.address ?? '';
    } else {
      Get.find<ParcelController>().resetDestinationSelection();
      _receiverAddressController.text = '';
    }

    Get.find<ParcelController>().setIsPickedUp(false, false);
    Get.find<ParcelController>().setIsSender(false, false);
    Get.find<ParcelController>().setCountryCode(_countryDialCode!, true);
    Get.find<ParcelController>().setCountryCode(_countryDialCode!, false);
    Get.find<ParcelController>().setOrderNote('', notify: false);
    _orderNoteController.text = '';

    _senderAddressController.text = AppConstants.hqAddressPlaceholder;

    if (AuthHelper.isLoggedIn() && Get.find<AddressController>().addressList == null) {
      Get.find<AddressController>().getAddressList();
    }

    if (AuthHelper.isLoggedIn()) {
      if (Get.find<ProfileController>().userInfoModel == null) {
        await Get.find<ProfileController>().getUserInfo();
      }
      final profile = Get.find<ProfileController>().userInfoModel;
      if (profile != null) {
        _receiverNameController.text = '${profile.fName ?? ''} ${profile.lName ?? ''}'.trim();
        _senderNameController.text   = '${profile.fName ?? ''} ${profile.lName ?? ''}'.trim();
        _countryDialCode = await splitPhoneNumber(profile.phone ?? '', true);
        _receiverPhoneController.text = await splitPhoneNumber(profile.phone ?? '', false);
        _senderPhoneController.text   = await splitPhoneNumber(profile.phone ?? '', false);
      }
      Get.find<ParcelController>().setCountryCode(_countryDialCode!, true);
      Get.find<ParcelController>().setCountryCode(_countryDialCode!, false);
      if (mounted) setState(() {});
    }

    _resolveHqZone();
  }

  Future<String> splitPhoneNumber(String number, bool returnCountyCode) async {
    String code = '';
    String pNumber = '';
    try {
      PhoneNumber phoneNumber = PhoneNumber.parse(number);
      code = '+${phoneNumber.countryCode}';
      pNumber = phoneNumber.international.substring(_countryDialCode!.length);
    } catch (e) {
      debugPrint('number can\'t parse : $e');
    }
    return returnCountyCode ? code : pNumber;
  }

  @override
  void dispose() {
    // ── Sender ──
    _senderNameController.dispose();
    _senderPhoneController.dispose();
    _senderStreetNumberController.dispose();
    _senderHouseController.dispose();
    _senderFloorController.dispose();
    _guestSenderEmailController.dispose();
    _senderAddressController.dispose();
    _senderStreetNode.dispose();
    _senderHouseNode.dispose();
    _senderFloorNode.dispose();
    _senderNameNode.dispose();
    _senderPhoneNode.dispose();
    _senderGuestEmailNode.dispose();
    _orderNoteNode.dispose();

    // ── Receiver ──
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _receiverStreetNumberController.dispose();
    _receiverHouseController.dispose();
    _receiverFloorController.dispose();
    _guestReceiverEmailController.dispose();
    _receiverAddressController.dispose();
    _receiverStreetNode.dispose();
    _receiverHouseNode.dispose();
    _receiverFloorNode.dispose();
    _receiverNameNode.dispose();
    _receiverPhoneNode.dispose();
    _receiverGuestEmailNode.dispose();

    // ── Order Note ──
    _orderNoteController.dispose();

    super.dispose();
  }

  // =========================================================
  //  BUILD
  // =========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'parcel_location'.tr),
      endDrawer: const MenuDrawer(),
      endDrawerEnableOpenDragGesture: false,
      body: SafeArea(
        child: GetBuilder<ParcelController>(builder: (parcelController) {
          return ResponsiveHelper.isDesktop(context)
              ? _webView(parcelController)
              : Column(children: [
            // ── Scrollable content ──
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: GetBuilder<AddressController>(builder: (addressController) {
                  return Column(children: [

                    // ════════════════════════════════
                    //   ORIGIN: COMPANY HEADQUARTERS
                    // ════════════════════════════════
                    CustomCard(
                      borderRadius: 0,
                      isBorder: false,
                      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.storefront_rounded, color: Theme.of(context).primaryColor, size: 24),
                        ),
                        const SizedBox(width: Dimensions.paddingSizeDefault),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('origin'.tr.isNotEmpty ? 'origin'.tr : 'نقطة الانطلاق', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
                          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                          Text(AppConstants.hqContactName, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
                          Text(AppConstants.hqAddressPlaceholder, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
                        ])),
                      ]),
                    ),
                    if (!_isHqZoneResolved && !_isHqZoneLoading && _hqZoneErrorMessage != null) ...[
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                          border: Border.all(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5)),
                        ),
                        child: Row(children: [
                          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 20),
                          const SizedBox(width: Dimensions.paddingSizeSmall),
                          Expanded(child: Text(_hqZoneErrorMessage!, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).colorScheme.error))),
                          TextButton(
                            onPressed: _resolveHqZone,
                            child: Text('retry'.tr.isNotEmpty ? 'retry'.tr : 'إعادة المحاولة', style: robotoMedium.copyWith(color: Theme.of(context).colorScheme.error)),
                          ),
                        ]),
                      ),
                    ],
                    const SizedBox(height: Dimensions.paddingSizeDefault),

                    // ════════════════════════════════
                    //   DELIVERY DESTINATION SECTION
                    // ════════════════════════════════
                    _buildLocationCard(
                      parcelController: parcelController,
                      addressController: addressController,
                      isSender: false,
                    ),
                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    _buildPersonInfoCard(
                      parcelController: parcelController,
                      isSender: false,
                    ),
                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    // ════════════════════════════════
                    //   ORDER NOTE  (فوق بيانات المرسل)
                    // ════════════════════════════════
                    CustomCard(
                      borderRadius: 0,
                      isBorder: false,
                      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('additional_instructions_for_driver'.tr, style: robotoMedium),
                        const SizedBox(height: Dimensions.paddingSizeDefault),
                        CustomTextField(
                          labelText: 'additional_instructions_for_driver'.tr,
                          titleText: 'additional_instructions_for_driver'.tr,
                          inputType: TextInputType.multiline,
                          maxLines: 3,
                          controller: _orderNoteController,
                          focusNode: _orderNoteNode,
                          nextFocus: _senderNameNode,
                          inputAction: TextInputAction.newline,
                          required: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'additional_instructions_for_driver'.tr;
                            }
                            return null;
                          },
                        ),
                      ]),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    // ════════════════════════════════
                    //   RECEIVER SECTION
                    // ════════════════════════════════
                    // _buildLocationCard(
                    //   parcelController: parcelController,
                    //   addressController: addressController,
                    //   isSender: false,
                    // ),
                    // const SizedBox(height: Dimensions.paddingSizeLarge),

                    // _buildPersonInfoCard(
                    //   parcelController: parcelController,
                    //   isSender: false,
                    // ),
                    const SizedBox(height: Dimensions.paddingSizeLarge),

                  ]);
                }),
                ),
              ),
            ),

            // ── Bottom Button ──
            _bottomButton(parcelController),
          ]);
        }),
      ),
    );
  }

  // =========================================================
  //  LOCATION CARD  (العنوان + الخريطة + street/house/floor)
  // =========================================================
  Widget _buildLocationCard({
    required ParcelController parcelController,
    required AddressController addressController,
    required bool isSender,
  }) {
    final addressController_ = addressController;
    final streetNode = isSender ? _senderStreetNode : _receiverStreetNode;
    final houseNode  = isSender ? _senderHouseNode  : _receiverHouseNode;
    final floorNode  = isSender ? _senderFloorNode  : _receiverFloorNode;
    final nameNode   = isSender ? _senderNameNode   : _receiverNameNode;
    final streetCtrl = isSender ? _senderStreetNumberController : _receiverStreetNumberController;
    final houseCtrl  = isSender ? _senderHouseController        : _receiverHouseController;
    final floorCtrl  = isSender ? _senderFloorController        : _receiverFloorController;
    final addrCtrl   = isSender ? _senderAddressController      : _receiverAddressController;

    return CustomCard(
      borderRadius: 0,
      isBorder: false,
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Column(children: [

        // ── Title + Change Address button ──
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(isSender ? 'pickup_location'.tr : 'delivery_location'.tr, style: robotoMedium),

          addressController_.addressList != null &&
              addressController_.addressList!.isNotEmpty &&
              AuthHelper.isLoggedIn()
              ? InkWell(
            onTap: () {
              showCustomBottomSheet(
                child: SavedAddressBottomSheet(
                  isSender: isSender,
                  nameController:   isSender ? _senderNameController   : _receiverNameController,
                  phoneController:  isSender ? _senderPhoneController  : _receiverPhoneController,
                  streetController: isSender ? _senderStreetNumberController : _receiverStreetNumberController,
                  houseController:  isSender ? _senderHouseController  : _receiverHouseController,
                  floorController:  isSender ? _senderFloorController  : _receiverFloorController,
                  guestEmailController: isSender ? _guestSenderEmailController : _guestReceiverEmailController,
                  senderAddressController:   _senderAddressController,
                  receiverAddressController: _receiverAddressController,
                  countryCode: isSender
                      ? parcelController.senderCountryCode
                      : parcelController.receiverCountryCode,
                ),
              );
            },
            child: Row(children: [
              Text('change_address'.tr,
                  style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: Theme.of(context).primaryColor)),
              Icon(Icons.arrow_drop_down_rounded, size: 34, color: Theme.of(context).primaryColor),
            ]),
          )
              : TextButton.icon(
            onPressed: () async {
              // ── اختيار من الخريطة ──
              Get.find<ParcelController>().setIsPickedUp(isSender, false);
              Get.toNamed(
                RouteHelper.getPickMapRoute('parcel', false),
                arguments: PickMapScreen(
                  fromSignUp: false,
                  fromAddAddress: false,
                  canRoute: false,
                  route: '',
                  onPicked: (AddressModel address) async {
                    ZoneResponseModel responseModel = await Get.find<LocationController>()
                        .getZone(address.latitude.toString(), address.longitude.toString(), false);
                    AddressModel modified = AddressModel(
                      id: address.id,
                      addressType: address.addressType,
                      contactPersonNumber: address.contactPersonNumber,
                      contactPersonName: address.contactPersonName,
                      address: address.address,
                      latitude: address.latitude,
                      longitude: address.longitude,
                      zoneId: responseModel.isSuccess ? responseModel.zoneIds[0] : 0,
                      zoneIds: responseModel.zoneIds,
                      method: address.method,
                      streetNumber: address.streetNumber,
                      house: address.house,
                      floor: address.floor,
                      zoneData: responseModel.zoneData,
                    );
                    if (isSender) {
                      _senderAddressController.text = address.address ?? '';
                      parcelController.setPickupAddress(modified, true);
                    } else {
                      _receiverAddressController.text = address.address ?? '';
                      parcelController.setDestinationAddress(modified, notify: true);
                    }
                  },
                ),
              );
            },
            icon: const Icon(Icons.location_on, size: 20),
            label: Text('select_from_map'.tr,
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
          ),
        ]),

        SizedBox(
            height: addressController_.addressList != null &&
                addressController_.addressList!.isNotEmpty
                ? Dimensions.paddingSizeDefault
                : 0),

        // ── TypeAhead address search ──
        // CustomTextField(
        //   titleText: 'address'.tr,
        //   labelText: 'address'.tr,
        //   focusNode: addressNode,
        //   nextFocus: streetNode,
        //   controller: isSender ? _senderAddressController : _receiverAddressController,
        //   required: true,
        // ),
        // const SizedBox(height: Dimensions.paddingSizeLarge),

        Builder(builder: (context) {
          bool emptyText = addrCtrl.text.isEmpty;

          return TypeAheadField(
            hideOnEmpty: true,
            controller: addrCtrl,
            builder: (context, controller, focusNode) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                onSubmitted: (_) => FocusScope.of(context).requestFocus(streetNode),
                textInputAction: TextInputAction.search,
                textCapitalization: TextCapitalization.words,
                keyboardType: TextInputType.streetAddress,
                decoration: InputDecoration(
                  hintText: isSender ? 'sender_address'.tr : 'receiver_address'.tr,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    borderSide: BorderSide(style: BorderStyle.solid, width: 0.3, color: Theme.of(context).disabledColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    borderSide: BorderSide(style: BorderStyle.solid, width: 1, color: Theme.of(context).primaryColor),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    borderSide: BorderSide(style: BorderStyle.solid, width: 0.3, color: Theme.of(context).primaryColor),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    borderSide: BorderSide(style: BorderStyle.solid, color: Theme.of(context).colorScheme.error),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    borderSide: BorderSide(style: BorderStyle.solid, color: Theme.of(context).colorScheme.error),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    borderSide: BorderSide(style: BorderStyle.solid, color: Theme.of(context).disabledColor.withValues(alpha: 0.2)),
                  ),
                  hintStyle: Theme.of(context).textTheme.displayMedium!.copyWith(
                    fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).disabledColor,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  suffixIcon: IconButton(
                    onPressed: () async {
                      if (!emptyText) {
                        controller.clear();
                        if (isSender) {
                          _senderAddressController.text = '';
                          parcelController.setPickupAddress(null, true);
                        } else {
                          _receiverAddressController.text = '';
                          parcelController.setDestinationAddress(null, notify: true);
                        }
                        return;
                      }
                      Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
                      AddressModel address = await Get.find<LocationController>().getCurrentLocation(true);
                      ZoneResponseModel responseModel = await Get.find<LocationController>()
                          .getZone(address.latitude.toString(), address.longitude.toString(), false);
                      AddressModel modifiedAddress = AddressModel(
                        id: address.id,
                        addressType: address.addressType,
                        contactPersonNumber: address.contactPersonNumber,
                        contactPersonName: address.contactPersonName,
                        address: address.address,
                        latitude: address.latitude,
                        longitude: address.longitude,
                        zoneId: responseModel.isSuccess ? responseModel.zoneIds[0] : 0,
                        zoneIds: responseModel.zoneIds,
                        method: address.method,
                        streetNumber: address.streetNumber,
                        house: address.house,
                        floor: address.floor,
                        zoneData: responseModel.zoneData,
                      );
                      if (isSender) {
                        _senderAddressController.text = address.address ?? '';
                        parcelController.setPickupAddress(modifiedAddress, true);
                      } else {
                        _receiverAddressController.text = address.address ?? '';
                        parcelController.setDestinationAddress(modifiedAddress, notify: true);
                      }
                      Get.back();
                    },
                    icon: Icon(
                      !emptyText ? Icons.clear : Icons.my_location,
                      color: !emptyText ? Theme.of(context).textTheme.bodyLarge!.color : Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                style: Theme.of(context).textTheme.displayMedium!.copyWith(
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                  fontSize: Dimensions.fontSizeLarge,
                ),
              );
            },
            suggestionsCallback: (pattern) async {
              return await Get.find<LocationController>().searchLocation(context, pattern);
            },
            itemBuilder: (context, PredictionModel suggestion) {
              return Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                child: Row(children: [
                  const Icon(Icons.location_on),
                  Expanded(
                    child: Text(
                      suggestion.description ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.displayMedium!.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge!.color,
                        fontSize: Dimensions.fontSizeLarge,
                      ),
                    ),
                  ),
                ]),
              );
            },
            onSelected: (PredictionModel suggestion) async {
              AddressModel address = await Get.find<LocationController>()
                  .setLocation(suggestion.placeId, suggestion.description, null);
              ZoneResponseModel responseModel = await Get.find<LocationController>()
                  .getZone(address.latitude.toString(), address.longitude.toString(), false);
              AddressModel modifiedAddress = AddressModel(
                id: address.id,
                addressType: address.addressType,
                contactPersonNumber: address.contactPersonNumber,
                contactPersonName: address.contactPersonName,
                address: address.address,
                latitude: address.latitude,
                longitude: address.longitude,
                zoneId: responseModel.isSuccess ? responseModel.zoneIds[0] : 0,
                zoneIds: responseModel.zoneIds,
                method: address.method,
                streetNumber: address.streetNumber,
                house: address.house,
                floor: address.floor,
                zoneData: responseModel.zoneData,
              );
              if (isSender) {
                _senderAddressController.text = suggestion.description ?? '';
                parcelController.setPickupAddress(modifiedAddress, true);
                if (_senderAddressController.text.isNotEmpty) {
                  FocusScope.of(Get.context!).requestFocus(streetNode);
                }
              } else {
                _receiverAddressController.text = suggestion.description ?? '';
                parcelController.setDestinationAddress(modifiedAddress, notify: true);
                if (_receiverAddressController.text.isNotEmpty) {
                  FocusScope.of(Get.context!).requestFocus(streetNode);
                }
              }
            },
            errorBuilder: (_, value) => const SizedBox(),
          );
        }),

        const SizedBox(height: Dimensions.paddingSizeLarge),

        // ── Street (mobile only – in Row on desktop) ──
        CustomTextField(
          titleText: 'street_number'.tr,
          labelText: 'street_number'.tr,
          inputType: TextInputType.streetAddress,
          focusNode: streetNode,
          nextFocus: houseNode,
          controller: streetCtrl,
          required: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'street_number'.tr;
            }
            return null;
          },
        ),
        const SizedBox(height: Dimensions.paddingSizeLarge),

        // ── House + Floor ──
        Row(children: [
          Expanded(child: CustomTextField(
            labelText: 'house'.tr,
            titleText: 'house'.tr,
            inputType: TextInputType.text,
            focusNode: houseNode,
            nextFocus: floorNode,
            controller: houseCtrl,
            required: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'house'.tr;
              }
              return null;
            },
          )),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(child: CustomTextField(
            labelText: 'floor'.tr,
            titleText: 'floor'.tr,
            inputType: TextInputType.text,
            focusNode: floorNode,
            nextFocus: nameNode,
            controller: floorCtrl,
            required: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'floor'.tr;
              }
              return null;
            },
          )),
        ]),
      ]),
    );
  }

  // =========================================================
  //  PERSON INFO CARD  (الاسم + التليفون + الإيميل للـ guest)
  // =========================================================
  Widget _buildPersonInfoCard({
    required ParcelController parcelController,
    required bool isSender,
  }) {
    final nameNode      = isSender ? _senderNameNode      : _receiverNameNode;
    final phoneNode     = isSender ? _senderPhoneNode     : _receiverPhoneNode;
    final guestEmailNode = isSender ? _senderGuestEmailNode : _receiverGuestEmailNode;
    final nameCtrl      = isSender ? _senderNameController      : _receiverNameController;
    final phoneCtrl     = isSender ? _senderPhoneController     : _receiverPhoneController;
    final guestEmailCtrl = isSender ? _guestSenderEmailController : _guestReceiverEmailController;
    final countryCode   = isSender ? parcelController.senderCountryCode : parcelController.receiverCountryCode;

    return CustomCard(
      borderRadius: 0,
      isBorder: false,
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Text(isSender ? 'sender_information'.tr : 'receiver_information'.tr, style: robotoMedium),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        CustomTextField(
          labelText: isSender ? 'sender_name'.tr : 'receiver_name'.tr,
          titleText: isSender ? 'sender_name'.tr : 'receiver_name'.tr,
          inputType: TextInputType.name,
          focusNode: nameNode,
          nextFocus: phoneNode,
          controller: nameCtrl,
          required: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return isSender ? 'enter_sender_name'.tr : 'enter_receiver_name'.tr;
            }
            return null;
          },
        ),
        const SizedBox(height: Dimensions.paddingSizeLarge),

        CustomTextField(
          titleText: isSender ? 'sender_phone_number'.tr : 'receiver_phone_number'.tr,
          labelText: isSender ? 'sender_phone_number'.tr : 'receiver_phone_number'.tr,
          controller: phoneCtrl,
          focusNode: phoneNode,
          inputType: TextInputType.phone,
          inputAction: AuthHelper.isGuestLoggedIn() ? TextInputAction.next : TextInputAction.done,
          nextFocus: AuthHelper.isGuestLoggedIn() ? guestEmailNode : null,
          isPhone: true,
          required: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return isSender ? 'enter_sender_phone_number'.tr : 'enter_receiver_phone_number'.tr;
            }
            return null;
          },
          onCountryChanged: (CountryCode code) {
            parcelController.setCountryCode(code.dialCode!, isSender);
            if (isSender) {
              _senderCountryDialCode = code.dialCode;
            } else {
              _receiverCountryDialCode = code.dialCode;
            }
          },
          countryDialCode: isSender
              ? (_senderCountryDialCode ?? countryCode)
              : (_receiverCountryDialCode ?? countryCode),
        ),

        SizedBox(height: AuthHelper.isGuestLoggedIn() ? Dimensions.paddingSizeLarge : 0),

        AuthHelper.isGuestLoggedIn()
            ? CustomTextField(
          titleText: isSender ? 'sender_email'.tr : 'receiver_email'.tr,
          labelText: isSender ? 'sender_email'.tr : 'receiver_email'.tr,
          controller: guestEmailCtrl,
          inputType: TextInputType.emailAddress,
          focusNode: guestEmailNode,
          required: isSender,
          prefixImage: Images.mail,
          inputAction: TextInputAction.done,
        )
            : const SizedBox(),
      ]),
    );
  }

  // =========================================================
  //  BOTTOM BUTTON  (validate الاتنين وروح للـ request screen)
  // =========================================================
  Widget _bottomButton(ParcelController parcelController) {
    return GetBuilder<ParcelController>(builder: (parcelController) {
      return CustomButton(
        margin: ResponsiveHelper.isDesktop(context)
            ? null
            : const EdgeInsets.all(Dimensions.paddingSizeSmall),
        width: ResponsiveHelper.isDesktop(context) ? 200 : double.infinity,
        buttonText: 'save_and_continue'.tr,
        onPressed: () async {
          // ── Inline form validation ──
          if (!(_formKey.currentState?.validate() ?? true)) return;

          // ── Validate Receiver / Customer Contact Info ──
          String receiverNum = '${parcelController.receiverCountryCode ?? ''}${_receiverPhoneController.text.trim()}';
          PhoneValid receiverValid = await CustomValidator.isPhoneValid(receiverNum);
          receiverNum = receiverValid.phone;

          if (parcelController.destinationAddress == null || !parcelController.isDestinationSelected) {
            showCustomSnackBar('select_destination_address'.tr); return;
          } else if (!_isValidCoordinate(parcelController.destinationAddress!.latitude, parcelController.destinationAddress!.longitude)) {
            showCustomSnackBar('invalid_destination_coordinates'.tr.isNotEmpty ? 'invalid_destination_coordinates'.tr : 'عنوان التوصيل غير صحيح'); return;
          } else if (_receiverNameController.text.trim().isEmpty) {
            showCustomSnackBar('enter_receiver_name'.tr); return;
          } else if (_receiverPhoneController.text.trim().isEmpty) {
            showCustomSnackBar('enter_receiver_phone_number'.tr); return;
          } else if (!receiverValid.isValid) {
            showCustomSnackBar('invalid_phone_number'.tr); return;
          } else if (AuthHelper.isGuestLoggedIn() && _guestReceiverEmailController.text.isEmpty) {
            showCustomSnackBar('please_enter_receiver_email'.tr); return;
          } else if (AuthHelper.isGuestLoggedIn() &&
              !CustomValidator.isEmailValid(_guestReceiverEmailController.text.trim())) {
            showCustomSnackBar('enter_valid_email_address'.tr); return;
          }

          if (_isHqZoneLoading) {
            showCustomSnackBar('verifying_service_availability'.tr.isNotEmpty ? 'verifying_service_availability'.tr : 'جاري التحقق من نطاق الخدمة...'); return;
          }
          if (!_isHqZoneResolved || parcelController.pickupAddress?.zoneId == null || parcelController.pickupAddress?.zoneId == 0) {
            showCustomSnackBar(_hqZoneErrorMessage ?? 'خدمة الطلبات غير متاحة حالياً، يرجى المحاولة لاحقاً', isError: true); return;
          }

          AddressModel pickup = AddressModel(
            address: AppConstants.hqAddressPlaceholder,
            latitude: AppConstants.hqLatitude.toString(),
            longitude: AppConstants.hqLongitude.toString(),
            contactPersonName: AppConstants.hqContactName,
            contactPersonNumber: AppConstants.hqPhone,
            addressType: 'others',
            zoneId: parcelController.pickupAddress!.zoneId,
            zoneIds: parcelController.pickupAddress!.zoneIds,
            zoneData: parcelController.pickupAddress!.zoneData,
          );

          AddressModel destination = AddressModel(
            address: parcelController.destinationAddress!.address,
            additionalAddress: parcelController.destinationAddress!.additionalAddress,
            addressType: parcelController.destinationAddress!.addressType,
            contactPersonName: _receiverNameController.text.trim(),
            contactPersonNumber: receiverNum,
            latitude: parcelController.destinationAddress!.latitude,
            longitude: parcelController.destinationAddress!.longitude,
            method: parcelController.destinationAddress!.method,
            zoneId: parcelController.destinationAddress!.zoneId,
            zoneIds: parcelController.destinationAddress!.zoneIds,
            id: parcelController.destinationAddress!.id,
            streetNumber: _receiverStreetNumberController.text.trim(),
            house: _receiverHouseController.text.trim(),
            floor: _receiverFloorController.text.trim(),
            email: _guestReceiverEmailController.text.trim(),
            zoneData: parcelController.destinationAddress!.zoneData,
          );

          parcelController.setPickupAddress(pickup, true);
          parcelController.setDestinationAddress(destination);
          parcelController.setOrderNote(_orderNoteController.text.trim(), notify: false);

          Get.toNamed(RouteHelper.getParcelRequestRoute(
            widget.category,
            parcelController.pickupAddress!,
            parcelController.destinationAddress!,
          ));
          Get.find<CheckoutController>().updateFirstTime();
          Get.find<CheckoutController>().updateFirstTimeCodActive();
        },
      );
    });
  }

  // =========================================================
  //  WEB VIEW
  // =========================================================
  Widget _webView(ParcelController parcelController) {
    return Column(children: [
      WebScreenTitleWidget(title: 'parcel_delivery_information'.tr),

      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeLarge),
          child: FooterView(
            child: GetBuilder<AddressController>(builder: (addressController) {
              return Container(
                width: Dimensions.webMaxWidth,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  boxShadow: [BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    spreadRadius: 1,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  )],
                ),
                padding: const EdgeInsets.symmetric(
                    vertical: Dimensions.paddingSizeLarge, horizontal: 200),
                child: Column(children: [

                  // ── Order Note ──
                  CustomCard(
                    borderRadius: Dimensions.radiusDefault,
                    isBorder: false,
                    padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('additional_instructions_for_driver'.tr, style: robotoMedium),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      CustomTextField(
                        labelText: 'additional_instructions_for_driver'.tr,
                        titleText: 'additional_instructions_for_driver'.tr,
                        inputType: TextInputType.multiline,
                        maxLines: 3,
                        controller: _orderNoteController,
                        focusNode: _orderNoteNode,
                        nextFocus: _senderNameNode,
                        inputAction: TextInputAction.newline,
                      ),
                    ]),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeLarge),

                  // ── Origin: Headquarters ──
                  CustomCard(
                    borderRadius: Dimensions.radiusDefault,
                    isBorder: false,
                    padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.storefront_rounded, color: Theme.of(context).primaryColor, size: 24),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeDefault),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('origin'.tr.isNotEmpty ? 'origin'.tr : 'نقطة الانطلاق', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
                        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                        Text(AppConstants.hqContactName, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
                        Text(AppConstants.hqAddressPlaceholder, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
                      ])),
                    ]),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeLarge),

                  // ── Receiver ──
                  _buildLocationCard(
                      parcelController: parcelController,
                      addressController: addressController,
                      isSender: false),
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                  _buildPersonInfoCard(
                      parcelController: parcelController, isSender: false),
                  const SizedBox(height: Dimensions.paddingSizeLarge),

                  // ── Button ──
                  _bottomButton(parcelController),

                ]),
              );
            }),
          ),
        ),
      ),
    ]);
  }
}