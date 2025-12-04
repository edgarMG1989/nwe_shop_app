import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:shop_app/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env.development");

  Stripe.publishableKey =
      "pk_test_51SZzjYBN3aDp6gEatwNcw2fi8mldo1Zg0H5oifxUmaXJDslczv59tEJuSGNtqgnFRhnn9YWU0a6jdDkJ6W4v7mRM00uc5tvhas";

  await Stripe.instance.applySettings();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomeScreen());
  }
}
