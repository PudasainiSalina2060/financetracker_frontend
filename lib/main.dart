import 'package:financetracker_frontend/screens/home_screen.dart';
import 'package:financetracker_frontend/screens/welcome_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:financetracker_frontend/api_test.dart';
void main() async {

// Initializing Firebase before running the app
  WidgetsFlutterBinding.ensureInitialized(); 
  await Firebase.initializeApp();

  ConnectionTest.checkServer();

  const storage = FlutterSecureStorage();

//check if the user token is saved
  String? token = await storage.read(key: 'accessToken'); 

 //start the app and check if user is logged in
  runApp( MyApp(isLoggedIn: token != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Budget',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      //home: const MyHomePage(title: 'Flutter Demo Home Page'),
      home: isLoggedIn ? const HomeScreen() :const WelcomeScreen(),
    );
  }
}
