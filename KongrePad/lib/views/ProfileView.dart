import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/Participant.dart';
import '../utils/app_constants.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  Future<void> getData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final url = Uri.parse('http://app.kongrepad.com/api/v1/auth/profile');

      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        // API response'una göre düzeltildi: data.participant
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final participantData =
              jsonData['data']['participant']; // Burada değişiklik
          final participant = Participant.fromJson(participantData);

          setState(() {
            this.participant = participant;
            _loading = false;
          });
        } else {
          print('API Error: ${jsonData['message']}');
          setState(() {
            _loading = false;
          });
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        print('Error Body: ${response.body}');
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      print('Exception Error: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  Participant? participant;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double screenWidth = screenSize.width;
    double screenHeight = screenSize.height;
    return Scaffold(
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : SingleChildScrollView(
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(10),
                      height: screenHeight * 0.1,
                      decoration: BoxDecoration(
                        color: AppConstants.backgroundBlue,
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white, // Border color
                            width: screenWidth * 0.003, // Border width
                          ),
                        ),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        width: screenWidth,
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Container(
                                height: screenHeight * 0.05,
                                width: screenHeight * 0.05,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      width: 2.0,
                                      color: const Color(0xFFFFFFFF)),
                                  shape: BoxShape.circle,
                                  color:
                                      Colors.white, // Circular background color
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: SvgPicture.asset(
                                    'assets/icon/chevron.left.svg',
                                    color: AppConstants.backgroundBlue,
                                    height: screenHeight * 0.03,
                                  ),
                                ),
                              ),
                            ),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)
                                        .translate("my_account"),
                                    style: const TextStyle(
                                        fontSize: 27, color: Colors.white),
                                  )
                                ]),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: screenWidth,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Container(
                              alignment: Alignment.centerLeft,
                              width: screenWidth * 0.9,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                        screenWidth * 0.4),
                                    child: Container(
                                      color: Colors.white,
                                      width: screenHeight * 0.17,
                                      height: screenHeight * 0.17,
                                      child: const Image(
                                        image: AssetImage(
                                            'assets/default_profile_photo.jpeg'),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: screenHeight * 0.01,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    // Adjust padding as needed
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      // Set background color to transparent
                                      borderRadius: BorderRadius.circular(20),
                                      // Adjust border radius as needed
                                      border: Border.all(
                                          color: AppConstants.logoutButtonBlue,
                                          width: 2), // Add border
                                    ),
                                    child: Row(
                                      children: [
                                        SvgPicture.asset(
                                          'assets/icon/person.svg',
                                          color: Colors.white,
                                          height: screenHeight * 0.03,
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          participant?.fullName.toString() ??
                                              "",
                                          style: const TextStyle(
                                              fontSize: 20,
                                              color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    height: screenHeight * 0.01,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    // Adjust padding as needed
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      // Set background color to transparent
                                      borderRadius: BorderRadius.circular(20),
                                      // Adjust border radius as needed
                                      border: Border.all(
                                          color: AppConstants.logoutButtonBlue,
                                          width: 2), // Add border
                                    ),
                                    child: Row(
                                      children: [
                                        SvgPicture.asset(
                                          'assets/icon/envelope.open.fill.svg',
                                          color: Colors.white,
                                          height: screenHeight * 0.03,
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          participant?.email.toString() ?? "",
                                          style: const TextStyle(
                                              fontSize: 20,
                                              color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    height: screenHeight * 0.01,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    // Adjust padding as needed
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      // Set background color to transparent
                                      borderRadius: BorderRadius.circular(20),
                                      // Adjust border radius as needed
                                      border: Border.all(
                                          color: AppConstants.logoutButtonBlue,
                                          width: 2), // Add border
                                    ),
                                    child: Row(
                                      children: [
                                        SvgPicture.asset(
                                          'assets/icon/phone.fill.svg',
                                          color: Colors.white,
                                          height: screenHeight * 0.03,
                                        ),
                                        SizedBox(
                                          width: screenWidth * 0.01,
                                        ),
                                        Text(
                                          participant?.phone.toString() ?? "",
                                          style: const TextStyle(
                                              fontSize: 20,
                                              color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    // Adjust padding as needed
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      // Set background color to transparent
                                      borderRadius: BorderRadius.circular(20),
                                      // Adjust border radius as needed
                                      border: Border.all(
                                          color: AppConstants.logoutButtonBlue,
                                          width: 2), // Add border
                                    ),
                                    child: Row(
                                      children: [
                                        SvgPicture.asset(
                                          'assets/icon/building.columns.fill.svg',
                                          color: Colors.white,
                                          height: screenHeight * 0.03,
                                        ),
                                        SizedBox(
                                          width: screenWidth * 0.01,
                                        ),
                                        Text(
                                          participant?.organisation
                                                  .toString() ??
                                              "",
                                          style: const TextStyle(
                                              fontSize: 20,
                                              color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.25),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: screenWidth,
                            decoration: BoxDecoration(
                              color: AppConstants.backgroundBlue,
                              border: Border(
                                top: BorderSide(
                                  color: Colors.white, // Border color
                                  width: screenWidth * 0.003, // Border width
                                ),
                              ),
                            ),
                            child: Text(
                              AppLocalizations.of(context)
                                  .translate("contact_registration_desk"),
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ]),
                  )
                ]),
              ));
  }
}
