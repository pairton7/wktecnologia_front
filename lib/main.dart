import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WK Tecnologia',
      theme: ThemeData(
        primaryColor: Color(0xFFB71C1C),
      ),
      home: const DataAnalysisScreen(),
    );
  }
}

class DataAnalysisScreen extends StatefulWidget {
  const DataAnalysisScreen({Key? key}) : super(key: key);

  @override
  State<DataAnalysisScreen> createState() => _DataAnalysisScreenState();
}

class _DataAnalysisScreenState extends State<DataAnalysisScreen> {
  String? fileName;
  Uint8List? fileBytes;
  String uploadStatus = "";
  Map<String, dynamic>? analysisResults;

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      fileBytes = result.files.first.bytes;
      fileName = result.files.first.name;
      setState(() {});
      await uploadFile();
    } else {
      setState(() {
        fileName = null;
        fileBytes = null;
      });
    }
  }

  Future<void> uploadFile() async {
    if (fileBytes != null && fileName != null) {
      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://localhost:8080/api/upload-json'),
        );

        request.files.add(http.MultipartFile.fromBytes(
          'file',
          fileBytes!,
          filename: fileName,
          contentType: MediaType('application', 'json'),
        ));

        var response = await request.send();

        if (response.statusCode == 200 || response.statusCode == 201) {
          setState(() {
            uploadStatus = "Arquivo enviado com sucesso!";
          });
          await fetchAnalysisData();
        } else {
          setState(() {
            uploadStatus = "Erro no upload: ${response.statusCode}";
          });
        }
      } catch (e) {
        setState(() {
          uploadStatus = "Erro ao enviar o arquivo: $e";
        });
      }
    } else {
      setState(() {
        uploadStatus = "Nenhum arquivo para enviar.";
      });
    }
  }

  Future<void> fetchAnalysisData() async {
    try {
      final candidatesByState = await fetchDataFromEndpoint(
          'http://localhost:8080/api/doadores-por-estado');
      final averageIMCByAgeRange = await fetchDataFromEndpoint(
          'http://localhost:8080/api/imc-por-faixa-etaria');
      final obesityPercentageByGender = await fetchDataFromEndpoint(
          'http://localhost:8080/api/percentual-obesos');
      final averageAgeByBloodType = await fetchDataFromEndpoint(
          'http://localhost:8080/api/media-idade-por-tipo-sanguineo');
      final donorsByBloodType = await fetchDataFromEndpoint(
          'http://localhost:8080/api/quantidade-doadores-por-tipo');

      setState(() {
        analysisResults = {
          'candidatesByState': candidatesByState,
          'averageIMCByAgeRange': averageIMCByAgeRange,
          'obesityPercentageByGender': obesityPercentageByGender,
          'averageAgeByBloodType': averageAgeByBloodType,
          'donorsByBloodType': donorsByBloodType,
        };
      });
    } catch (e) {
      setState(() {
        uploadStatus = "Erro ao buscar dados de análise: $e";
      });
    }
  }

  Future<dynamic> fetchDataFromEndpoint(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao carregar dados do endpoint $url: ${response.statusCode}');
    }
  }

  Widget buildFilePickerSection() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        margin: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 3,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              fileName == null ? 'Nenhum arquivo selecionado.' : 'Arquivo selecionado: $fileName',
              style: const TextStyle(
                color: Color(0xFFB71C1C),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: pickFile,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                backgroundColor: Color(0xFFB71C1C),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
                child: Text(
                  'Selecionar e Enviar Arquivo',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                backgroundColor: Colors.grey,
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
                child: Text(
                  'Sair',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TableRow buildTableHeader(List<String> headers) {
    return TableRow(
      decoration: const BoxDecoration(color: Color(0xFFB71C1C)),
      children: headers.map((header) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            header,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        );
      }).toList(),
    );
  }

  TableRow buildTableRow(List<String> cells) {
    return TableRow(
      children: cells.map((cell) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            cell,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildObesityResults(dynamic data) {
    if (data == null || data is! Map) return const Text('Dados indisponíveis');

    final homensQuantidade = data['homens']?['quantidade'] ?? 0;
    final homensPercentual = data['homens']?['percentual'] ?? '0,00%';
    final mulheresQuantidade = data['mulheres']?['quantidade'] ?? 0;
    final mulheresPercentual = data['mulheres']?['percentual'] ?? '0,00%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Percentual de Obesidade por Gênero:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFFB71C1C),
          ),
        ),
        const SizedBox(height: 10),
        Table(
          border: TableBorder.all(color: Colors.grey),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: const {
            0: FlexColumnWidth(1.5),
            1: FlexColumnWidth(2),
          },
          children: [
            buildTableHeader(['Gênero', 'Percentual']),
            buildTableRow([
              'Homens Obesos',
              'percentual: $homensPercentual\nquantidade: $homensQuantidade',
            ]),
            buildTableRow([
              'Mulheres Obesas',
              'percentual: $mulheresPercentual\nquantidade: $mulheresQuantidade',
            ]),
          ],
        ),
      ],
    );
  }

  Widget buildAnalysisTables() {
    if (analysisResults == null) {
      return const Text(
        'Resultados da Análise ainda não disponíveis.',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resultados da Análise:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFB71C1C),
          ),
        ),
        const SizedBox(height: 20),
        _buildTableSection('Candidatos por Estado', 'Estado', 'Quantidade', analysisResults?['candidatesByState']),
        const SizedBox(height: 20),
        _buildTableSection('IMC Médio por Faixa Etária', 'Faixa Etária', 'IMC Médio', analysisResults?['averageIMCByAgeRange']),
        const SizedBox(height: 20),
        _buildObesityResults(analysisResults?['obesityPercentageByGender']),
        const SizedBox(height: 20),
        _buildTableSection('Média de Idade por Tipo Sanguíneo', 'Tipo Sanguíneo', 'Média de Idade', analysisResults?['averageAgeByBloodType']?['tiposSanguineos']),
        const SizedBox(height: 20),
        _buildTableSection('Quantidade de Doadores por Tipo Sanguíneo', 'Tipo Sanguíneo', 'Quantidade de Doadores', analysisResults?['donorsByBloodType']?['tiposSanguineos']),
      ],
    );
  }

  Widget _buildTableSection(String title, String column1, String column2, dynamic data) {
    if (data == null || (data is Map && data.isEmpty) || (data is List && data.isEmpty)) {
      return const Text('Dados indisponíveis');
    }

    List<List<String>> rows = [];
    if (data is Map) {
      rows = data.entries.map((entry) => [entry.key.toString(), entry.value.toString()]).toList();
    } else if (data is List) {
      rows = data.map((entry) {
        final key = entry['tipo']?.toString() ?? 'N/A';
        final value = entry['mediaIdade']?.toString() ?? entry['quantidadeDoadores']?.toString() ?? 'N/A';
        return [key, value];
      }).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFFB71C1C),
          ),
        ),
        const SizedBox(height: 10),
        Table(
          border: TableBorder.all(color: Colors.grey),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: const {
            0: FlexColumnWidth(1.5),
            1: FlexColumnWidth(1),
          },
          children: [
            buildTableHeader([column1, column2]),
            ...rows.map((row) => buildTableRow(row)).toList(),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              height: 40,
            ),
            const SizedBox(width: 10),
            const Text(
              'WK Tecnologia',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Color(0xFFB71C1C),
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildFilePickerSection(),
              const SizedBox(height: 30),
              buildAnalysisTables(),
            ],
          ),
        ),
      ),
    );
  }
}
