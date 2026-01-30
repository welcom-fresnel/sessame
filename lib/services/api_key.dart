import 'package:flutter_dotenv/flutter_dotenv.dart';

final String apikey = dotenv.env['API_KEY'] ?? '';
