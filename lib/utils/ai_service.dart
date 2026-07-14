import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Função para obter detalhes de cuidado da planta via API de IA.
/// Recebe o nome científico da planta e retorna um mapa com os detalhes.
///
/// As credenciais do Azure OpenAI sao lidas das variaveis de ambiente
/// (arquivo .env): AZURE_OPENAI_ENDPOINT e AZURE_OPENAI_API_KEY.
Future<Map<String, String>?> detalhesPlantaAI(String nomeCientifico) async {
  debugPrint('Iniciando função detalhesPlantaAI para: $nomeCientifico');

  final endpoint = dotenv.env['AZURE_OPENAI_ENDPOINT'] ?? '';
  final apiKey = dotenv.env['AZURE_OPENAI_API_KEY'] ?? '';

  if (endpoint.isEmpty || apiKey.isEmpty) {
    debugPrint(
      '❌ Credenciais do Azure OpenAI não encontradas! '
      'Verifique AZURE_OPENAI_ENDPOINT e AZURE_OPENAI_API_KEY no arquivo .env.',
    );
    return null;
  }

  final headers = {'Content-Type': 'application/json', 'api-key': apiKey};

  // O prompt define o formato JSON que a IA deve retornar
  final prompt = '''
Me dê informações sobre a planta "$nomeCientifico". Use obrigatoriamente o seguinte formato JSON:

{
  "quantidade_ideal_de_agua": "Regar 2x por semana",
  "tipo_de_solo": "arenoso",
  "bioma_adequado": "temperado",
  "outras_plantas_compatíveis": "ardósia"
}
''';

  final body = jsonEncode({
    'model': 'gpt-4.1-mini', // Modelo da IA sendo utilizado
    'messages': [
      {
        'role': 'system',
        'content':
            'Você é um assistente de jardinagem. Sempre responda em JSON, fornecendo apenas o JSON sem texto adicional.',
      },
      {'role': 'user', 'content': prompt},
    ],
    'max_tokens': 500, // Limite de tokens na resposta
    'temperature': 0.7, // Criatividade da resposta (0.0 a 1.0)
    'response_format': {
      'type': 'json_object',
    }, // Sugere à IA que a resposta seja um objeto JSON
  });

  try {
    final response = await http.post(
      Uri.parse(endpoint),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final rawResponseContent = data['choices'][0]['message']['content'];

      try {
        final parsed = jsonDecode(
          rawResponseContent,
        ); // Tenta fazer o parsing do JSON
        // Retorna um mapa com os cuidados individuais extraídos do JSON
        return {
          'agua': parsed['quantidade_ideal_de_agua']?.toString() ?? 'N/A',
          'solo': parsed['tipo_de_solo']?.toString() ?? 'N/A',
          'bioma': parsed['bioma_adequado']?.toString() ?? 'N/A',
          'harmonizacao':
              parsed['outras_plantas_compatíveis']?.toString() ?? 'N/A',
        };
      } catch (e) {
        debugPrint('⚠️ Erro ao interpretar JSON da resposta da IA: $e');
        debugPrint(
          'Conteúdo da resposta bruta: $rawResponseContent',
        ); // Ajuda na depuração
        return null;
      }
    } else {
      debugPrint('❌ Erro na resposta da API: ${response.statusCode}');
      debugPrint(response.body); // Imprime o corpo da resposta para depuração
      return null;
    }
  } catch (e) {
    debugPrint('❌ Erro ao conectar com Azure OpenAI: $e');
    return null;
  }
}
