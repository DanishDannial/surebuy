import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class ToyyibPayService {
  static const String baseUrl = "https://dev.toyyibpay.com/";

  Future<String?> createBill({
    required String apiKey,
    required String categoryCode,
    required String billName,
    required String billDescription,
    required String amount,
    required String billTo,
    required String billEmail,
    required String billPhone,
    required String billReturnUrl,
  }) async {
    final url = Uri.parse("$baseUrl/api/createBill");

    // 🔹 Create Form Data (application/x-www-form-urlencoded format)
    Map<String, String> formData = {
      "userSecretKey":"n3yxm20v-d82i-4mzo-n11k-5rxlp3ei45hw",
      "categoryCode":"mng6ctzd",
      "billName":generateRandomBillName("TestPayment-"),
      "billDescription":billDescription.trim(),
      "billPriceSetting":"1",
      "billPayorInfo":"1",
      "billAmount":amount.trim(),
      "billReturnUrl":billReturnUrl.trim(),
      "billTo":billTo.trim(),
      "billEmail":billEmail.trim(),
      "billPhone":billPhone.trim(),
    };

    // String body = '''
    //   userSecretKey:$apiKey
    //   categoryCode:$categoryCode
    //   billName:$billName
    //   billDescription:$billDescription
    //   billPriceSetting:1
    //   billPayorInfo:1
    //   billAmount:$amount
    //   billReturnUrl:$billReturnUrl
    //   billTo:$billTo
    //   billEmail:$billEmail
    //   billPhone:$billPhone
    //   ''';

    print("Response Code: ${formData}");

    // 🔹 Send POST request
    var response = await http.post(
      url,
      headers: {
        "Content-Type": "application/x-www-form-urlencoded"
      },
      body: formData,
    );

    print("Response Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = jsonDecode(response.body);
      String billCode = jsonResponse[0]['BillCode'];
      print("Bill Code: $billCode");
      return billCode;
    } else {
      return null;
    }
  }
}

// 🔹 Helper function to generate a unique bill name
String generateRandomBillName(String prefix) {
  final random = Random();
  int randomNumber = 100000 + random.nextInt(900000); // Generates a 6-digit random number
  return "$prefix$randomNumber";
}
