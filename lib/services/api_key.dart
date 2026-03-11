import 'package:flutter_dotenv/flutter_dotenv.dart';

String get apikey {
  // Essayer dart-define d'abord (priorité haute)
  const fromDartDefine = String.fromEnvironment('API_KEY');
  if (fromDartDefine.isNotEmpty) {
    print('✅ API_KEY loaded from dart-define');
    return fromDartDefine;
  }
  
  // Sinon, charger depuis .env
  final fromEnv = (dotenv.env['API_KEY'] ?? '').trim();
  if (fromEnv.isNotEmpty) {
    print('✅ API_KEY loaded from .env file');
    return fromEnv;
  }
  
  print('❌ API_KEY not found! Add it to .env or use --dart-define=API_KEY=...');
  return '';
}

