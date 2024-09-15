import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:kongrepad/AppConstants.dart';
import 'package:http/http.dart' as http;
import 'package:kongrepad/Models/ScoreGamePoint.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ScoreGamePointsView extends StatefulWidget {
  const ScoreGamePointsView({super.key});


  @override
  State<ScoreGamePointsView> createState() => _ScoreGamePointsViewState();
}


class _ScoreGamePointsViewState extends State<ScoreGamePointsView> {

  Future<void> getData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ;

    try {
      final url = Uri.parse('http://app.kongrepad.com/api/v1/score-game/0/point');
      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final pointsJson = ScoreGamePointsJSON.fromJson(jsonData);
        setState(() {
          points = pointsJson.data;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  List<ScoreGamePoint>? points;
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
            : Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              height: screenHeight*0.1,
              decoration: const BoxDecoration(
                  color: AppConstants.virtualStandBlue
              ),
              child: Container(
                width: screenWidth,
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap:() {
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: screenHeight*0.05,
                        width: screenHeight*0.05,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppConstants.backgroundBlue, // Circular background color
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SvgPicture.asset(
                            'assets/icon/chevron.left.svg',
                            color:Colors.white,
                            height: screenHeight*0.03,
                          ),
                        ),
                      ),
                    ),
                    const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                              "Puan Geçmişim",
                            style: TextStyle(
                                fontSize: 25,
                                color: Colors.white
                            ),
                          )
                        ]
                    ),
                  ],
                ),
              ),
            ),
            SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Container(
              width: screenWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: points != null ? points!.map((point) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: screenWidth * 0.2,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppConstants.programBackgroundYellow,
                                border: Border.all(color: Colors.black),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  Text(
                                    point.createdAt.toString(),
                                    style: const TextStyle(
                                        fontSize: 20,
                                        color: AppConstants.backgroundBlue),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 5,),
                          SizedBox(
                            width: screenWidth * 0.6,
                            child: Container(
                              alignment: AlignmentDirectional.centerStart,
                              decoration: BoxDecoration(
                                color: AppConstants.hallsButtonBlue,
                                border: Border.all(color: Colors.black),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: EdgeInsets.all(10),
                              child: Container(
                                child:Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      point.title.toString(),
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.black),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList() : [],
              ),
            ),
          )]
        ));
  }

}
