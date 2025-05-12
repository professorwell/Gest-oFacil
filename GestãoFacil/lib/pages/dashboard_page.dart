// lib/pages/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../main.dart';
import '../db/database_helper.dart';
import 'list_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Toque para falar';
  String _tipoSelecionado = 'À vista';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _verificarPermissaoMicrofone();
  }

  void _verificarPermissaoMicrofone() async {
    bool disponivel = await _speech.initialize();
    if (!disponivel) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissão de microfone não concedida')),
      );
    }
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (val) => setState(() => _text = val.recognizedWords));
      }
    } else {
      _speech.stop();
      setState(() => _isListening = false);
      if (_text.isNotEmpty && _text != 'Toque para falar') {
        await DatabaseHelper.instance.inserirVenda(_text, _tipoSelecionado);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venda registrada com sucesso!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color baseColor = Colors.white;
    final Color accentColor = const Color(0xFF55E6C1);
    final Color iconColor = Colors.black;
    final Color textColor = accentColor;

    return Scaffold(
      backgroundColor: baseColor,
      appBar: AppBar(
        backgroundColor: baseColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'GestãoFacil',
          style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: accentColor),
        actionsIconTheme: IconThemeData(color: accentColor),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined),
            onPressed: () {
              themeNotifier.value =
                  themeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ListPage()));
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Botões de filtro de tipo estilizados
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => setState(() => _tipoSelecionado = 'À vista'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tipoSelecionado == 'À vista' ? Colors.lightGreen : Colors.lightGreen.withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: _tipoSelecionado == 'À vista' ? 4 : 0,
                  ),
                  child: const Text(
                    'À VISTA',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => setState(() => _tipoSelecionado = 'Fiado'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tipoSelecionado == 'Fiado' ? Colors.amber : Colors.amber.withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: _tipoSelecionado == 'Fiado' ? 4 : 0,
                  ),
                  child: const Text(
                    'FIADO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Texto de status da fala
            Text(
              _text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            // Botão de microfone
            GestureDetector(
              onTap: _listen,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.stop : Icons.mic,
                  size: 96,
                  color: iconColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
