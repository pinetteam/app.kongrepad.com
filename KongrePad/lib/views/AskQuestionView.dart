import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/Session.dart';
import '../utils/app_constants.dart';

class AskQuestionView extends StatefulWidget {
  final int hallId;

  const AskQuestionView({super.key, required this.hallId});

  @override
  _AskQuestionViewState createState() => _AskQuestionViewState();
}

class _AskQuestionViewState extends State<AskQuestionView> {
  Session? _session;
  List<Map<String, dynamic>>? _questions;
  final TextEditingController _questionController = TextEditingController();
  bool _isAnonymous = false;
  bool _loading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    print('AskQuestionView - getData başladı');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final url = Uri.parse(
          'https://api.kongrepad.com/api/v1/sessions/${widget.hallId}');
      print('AskQuestionView - API çağrısı yapılıyor: $url');

      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('AskQuestionView - API yanıtı: ${response.statusCode}');
      print('AskQuestionView - API yanıt body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['data'] != null) {
          _session = Session.fromJson(jsonData['data']);

          // Soruları al
          if (_session != null) {
            await _getQuestions();
          }

          if (mounted) {
            setState(() {
              _loading = false;
            });
          }
        } else {
          setState(() {
            _loading = false;
            _hasError = true;
            _errorMessage =
                AppLocalizations.of(context).translate('no_active_session');
          });
        }
      } else if (response.statusCode == 401) {
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        print('AskQuestionView - API hatası: ${response.statusCode}');
        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = 'API Hatası: ${response.statusCode}';
        });
      }
    } catch (e, stackTrace) {
      print('AskQuestionView - Hata: $e');
      print('AskQuestionView - Stack trace: $stackTrace');
      setState(() {
        _loading = false;
        _hasError = true;
        _errorMessage = 'Bir hata oluştu: $e';
      });
    }
  }

  Future<void> _getQuestions() async {
    if (_session == null) return;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final url = Uri.parse(
          'https://api.kongrepad.com/api/v1/sessions/${_session!.id}/questions');
      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['data'] != null) {
          setState(() {
            _questions = List<Map<String, dynamic>>.from(jsonData['data']);
          });
        }
      }
    } catch (e) {
      print('Sorular alınırken hata: $e');
    }
  }

  Future<void> _askQuestion() async {
    if (_session == null || _questionController.text.trim().isEmpty) return;

    setState(() {
      _sending = true;
    });

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final url = Uri.parse(
          'https://api.kongrepad.com/api/v1/sessions/${_session!.id}/questions');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'question': _questionController.text.trim(),
          'anonymous': _isAnonymous,
          'session_id': _session!.id,
        }),
      );

      print('Soru gönderme yanıtı: ${response.statusCode}');
      print('Soru gönderme yanıt body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        _questionController.clear();
        await _getQuestions(); // Soruları yenile

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)
                .translate('question_sent_success')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final jsonResponse = jsonDecode(response.body);
        String errorMessage = jsonResponse['message'] ??
            AppLocalizations.of(context).translate('error_occurred');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Soru gönderme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${AppLocalizations.of(context).translate('error_occurred')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _sending = false;
      });
    }
  }

  Widget _buildQuestionsList() {
    return _questions == null || _questions!.isEmpty
        ? Center(
            child: Text(
              AppLocalizations.of(context).translate('no_questions'),
              style: const TextStyle(color: Colors.white70),
            ),
          )
        : ListView.builder(
            itemCount: _questions!.length,
            itemBuilder: (context, index) {
              final question = _questions![index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                color: Colors.white.withOpacity(0.9),
                child: ListTile(
                  leading: const Icon(Icons.question_answer),
                  title: Text(
                    question['question'] ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    question['participant']?['full_name'] ?? 'Anonim',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              );
            },
          );
  }

  Widget _buildQuestionInput() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _questionController,
            decoration: InputDecoration(
              hintText:
                  AppLocalizations.of(context).translate('ask_question_hint'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            maxLines: 3,
            minLines: 1,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Checkbox(
                      value: _isAnonymous,
                      onChanged: (value) {
                        setState(() {
                          _isAnonymous = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)
                            .translate('ask_anonymously'),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _sending || _questionController.text.trim().isEmpty
                    ? null
                    : _askQuestion,
                icon: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(AppLocalizations.of(context).translate('send')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.buttonGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _hasError = false;
                });
                getData();
              },
              child: Text(AppLocalizations.of(context).translate('try_again')),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: _buildQuestionsList(),
        ),
        _buildQuestionInput(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundBlue,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundBlue,
        title: Text(
          _session?.title ??
              AppLocalizations.of(context).translate('ask_question'),
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icon/chevron.left.svg',
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                _loading = true;
              });
              getData();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _buildContent(),
      ),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }
}
