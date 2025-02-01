import 'package:ifoot_academy/Pages/Authentification/services/AuthProvider.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
// Import other providers here

class AppProviders {
  static List<SingleChildWidget> providers = [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
  ];
}
