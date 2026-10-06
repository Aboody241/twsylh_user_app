import 'package:flutter/foundation.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

class CustomValidator {

  static Future<PhoneValid> isPhoneValid(String number) async {
    String phone = '';
    String countryCode = '';
    bool isValid = false;
    try {
      String cleanNumber = number.trim().replaceAll(RegExp(r'[\s\-()]'), '');
      if (cleanNumber.isNotEmpty) {
        if (cleanNumber.startsWith('00')) {
          cleanNumber = '+${cleanNumber.substring(2)}';
        } else if (!cleanNumber.startsWith('+')) {
          cleanNumber = '+$cleanNumber';
        }

        PhoneNumber phoneNumber = PhoneNumber.parse(cleanNumber);
        isValid = phoneNumber.isValid(type: PhoneNumberType.mobile);

        // If not valid, check if removing leading 0 from NSN makes it valid (e.g. +20010... -> +2010...)
        if (!isValid && phoneNumber.nsn.startsWith('0')) {
          try {
            String retryNumber = '+${phoneNumber.countryCode}${phoneNumber.nsn.replaceFirst(RegExp(r'^0+'), '')}';
            PhoneNumber retryPhone = PhoneNumber.parse(retryNumber);
            if (retryPhone.isValid(type: PhoneNumberType.mobile) || retryPhone.isValid()) {
              phoneNumber = retryPhone;
              isValid = true;
            }
          } catch (_) {}
        }

        // Fallback to general validity check if mobile-specific check was too strict
        if (!isValid) {
          isValid = phoneNumber.isValid();
        }

        countryCode = phoneNumber.countryCode;
        if (isValid) {
          phone = '+${phoneNumber.countryCode}${phoneNumber.nsn}';
        }
      }
    } catch (e) {
      debugPrint('Phone Number is not parsing: $e');
      isValid = false;
    }
    return PhoneValid(isValid: isValid, countryCode: countryCode,  phone: phone);
  }

  static bool isEmailValid(String email) {
    const pattern = r"(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'"
        r'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-'
        r'\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*'
        r'[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4]'
        r'[0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9]'
        r'[0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\'
        r'x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])';
    final kEmailValid = RegExp(pattern);
    bool isValid = kEmailValid.hasMatch(email.toString());
    return isValid;
  }

}

class PhoneValid {
  bool isValid;
  String countryCode;
  String phone;
  PhoneValid({required this.isValid, required this.countryCode, required this.phone});
}