import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/ScoreGamePoint.dart';
import '../utils/app_constants.dart';

class ScoreGamePointsView extends StatefulWidget {
  final int? scoreGameId; // Belirli bir score game için filtreleme

  const ScoreGamePointsView({super.key, this.scoreGameId});

  @override
  State<ScoreGamePointsView> createState() => _ScoreGamePointsViewState();
}

class _ScoreGamePointsViewState extends State<ScoreGamePointsView> {
  List<ScoreGamePoint>? points;
  Map<String, dynamic>? myScoresData;
  List<dynamic>? scoreGames;
  int? selectedScoreGameId;
  bool _loading = true;

  Future<void> getData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      print("Token bulunamadı, kullanıcı giriş yapmamış.");
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    try {
      // 1. My scores detaylı veriyi al
      await getMyScoresDetails(token);

      // 2. Eğer belirli bir score game seçilmişse, o game'in detaylarını al
      if (widget.scoreGameId != null) {
        selectedScoreGameId = widget.scoreGameId;
        await getScoreGameDetails(widget.scoreGameId!, token);
      }

      setState(() {
        _loading = false;
      });

    } catch (e) {
      print('Error: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> getMyScoresDetails(String token) async {
    try {
      final url = Uri.parse('https://api.kongrepad.com/api/v1/score-games/my-scores');
      print("My Scores URL: $url");

      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print("My Scores API Status Code: ${response.statusCode}");
      print("My Scores API Response: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          setState(() {
            myScoresData = jsonData['data'];
          });

          // Eğer response'da score history varsa onu kullan
          if (myScoresData!['score_history'] != null) {
            final scoreHistory = myScoresData!['score_history'] as List;
            setState(() {
              points = scoreHistory.map((item) => ScoreGamePoint.fromJson(item)).toList();
            });
          }
          // Eğer games array'i varsa
          else if (myScoresData!['games'] != null) {
            final games = myScoresData!['games'] as List;
            List<ScoreGamePoint> allPoints = [];

            for (var game in games) {
              if (game['points'] != null) {
                final gamePoints = game['points'] as List;
                allPoints.addAll(gamePoints.map((point) => ScoreGamePoint.fromJson(point)));
              }
            }

            setState(() {
              points = allPoints;
            });
          }

          print("My Scores Data: $myScoresData");
          print("Extracted Points: ${points?.length ?? 0}");
        }
      } else {
        print("My Scores API Error (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      print('My Scores API Error: $e');
    }
  }

  Future<void> getScoreGameDetails(int scoreGameId, String token) async {
    try {
      final url = Uri.parse('https://api.kongrepad.com/api/v1/score-games/$scoreGameId');

      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          final gameData = jsonData['data'];
          print("Score Game Details: $gameData");

          // Bu game'e ait puanları filtrele
          if (points != null) {
            setState(() {
              points = points!.where((point) =>
              point.scoreGameId == scoreGameId ||
                  point.gameId == scoreGameId
              ).toList();
            });
          }
        }
      }
    } catch (e) {
      print('Score Game Details Error: $e');
    }
  }

  Future<void> getAllScoreGames(String token) async {
    try {
      final url = Uri.parse('https://api.kongrepad.com/api/v1/score-games');

      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          setState(() {
            scoreGames = jsonData['data'] as List;
          });
        }
      }
    } catch (e) {
      print('Score Games List Error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    getData();
  }

  Widget _buildScoreGameFilter() {
    if (scoreGames == null || scoreGames!.length <= 1) {
      return Container();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        border: Border.all(color: AppConstants.backgroundBlue),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: DropdownButton<int?>(
        value: selectedScoreGameId,
        isExpanded: true,
        underline: Container(),
        hint: const Text('Tüm Oyunlar'),
        items: [
          const DropdownMenuItem<int?>(
            value: null,
            child: Text('Tüm Oyunlar'),
          ),
          ...scoreGames!.map<DropdownMenuItem<int?>>((game) {
            return DropdownMenuItem<int?>(
              value: game['id'],
              child: Text(game['title'] ?? 'Score Game ${game['id']}'),
            );
          }).toList(),
        ],
        onChanged: (int? newValue) {
          setState(() {
            selectedScoreGameId = newValue;
          });
          // Filtreleme işlemi yapılabilir
        },
      ),
    );
  }

  List<ScoreGamePoint> _getFilteredPoints() {
    if (points == null) return [];

    if (selectedScoreGameId == null) {
      return points!;
    }

    return points!.where((point) =>
    point.scoreGameId == selectedScoreGameId ||
        point.gameId == selectedScoreGameId
    ).toList();
  }

  Widget _buildPointsList() {
    final filteredPoints = _getFilteredPoints();

    if (filteredPoints.isEmpty) {
      return const Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Henüz puan geçmişi bulunamadı',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: filteredPoints.length,
        itemBuilder: (context, index) {
          final point = filteredPoints[index];
          return _buildPointItem(point, index);
        },
      ),
    );
  }

  Widget _buildPointItem(ScoreGamePoint point, int index) {
    Size screenSize = MediaQuery.of(context).size;
    double screenWidth = screenSize.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Puan container'ı
            Container(
              width: screenWidth * 0.2,
              decoration: BoxDecoration(
                color: point.point! > 0
                    ? AppConstants.programBackgroundYellow
                    : Colors.red[100],
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${point.point! > 0 ? '+' : ''}${point.point}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: point.point! > 0
                          ? AppConstants.backgroundBlue
                          : Colors.red[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Text(
                    'pts',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Detay container'ı
            Expanded(
              child: Container(
                alignment: AlignmentDirectional.centerStart,
                decoration: BoxDecoration(
                  color: AppConstants.hallsButtonBlue,
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      point.title?.toString() ?? 'Puan Kazanıldı',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    if (point.description != null && point.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          point.description!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(point.createdAt?.toString()),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Bilinmeyen tarih';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} gün önce';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} saat önce';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} dakika önce';
      } else {
        return 'Az önce';
      }
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildSummary() {
    if (myScoresData == null) return Container();

    final totalPoints = myScoresData!['total_points'] ?? 0;
    final totalGames = myScoresData!['total_games'] ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.backgroundBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                '$totalPoints',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'Toplam Puan',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          Container(
            height: 30,
            width: 1,
            color: Colors.white30,
          ),
          Column(
            children: [
              Text(
                '$totalGames',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'Oyun Sayısı',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          Container(
            height: 30,
            width: 1,
            color: Colors.white30,
          ),
          Column(
            children: [
              Text(
                '${_getFilteredPoints().length}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'Aktivite',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double screenHeight = screenSize.height;

    return Scaffold(
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppConstants.backgroundBlue),
        ),
      )
          : Column(
        children: [
          // App Bar
          Container(
            padding: const EdgeInsets.all(10),
            height: screenHeight * 0.1,
            decoration: const BoxDecoration(
              color: AppConstants.virtualStandBlue,
            ),
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: screenHeight * 0.05,
                    width: screenHeight * 0.05,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppConstants.backgroundBlue,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SvgPicture.asset(
                        'assets/icon/chevron.left.svg',
                        color: Colors.white,
                        height: screenHeight * 0.03,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    AppLocalizations.of(context).translate('score_history'),
                    style: const TextStyle(
                      fontSize: 25,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Summary
          _buildSummary(),

          // Score Game Filter
          _buildScoreGameFilter(),

          // Points List
          _buildPointsList(),
        ],
      ),
    );
  }
}