import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:pocus_app/cores/cores.dart';
import 'package:pocus_app/routes/app_router.dart';

void main() async {



  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: const FirebaseOptions(
        apiKey: "AIzaSyDEZuuEmpT_PVYwhq8-hzG8H4z4iXmtUIw",
        authDomain: "pocus-app-82836.firebaseapp.com",
        projectId: "pocus-app-82836",
        databaseURL:"https://pocus-app-82836-default-rtdb.firebaseio.com/",
        storageBucket: "pocus-app-82836.firebasestorage.app",
        messagingSenderId: "860367108462",
        appId: "1:860367108462:web:7dfc66034290fd68c8297f",
        measurementId: "G-EC5JKWM9XT"));
        


  Gemini.init(apiKey:'AIzaSyA5Iqq4ZQXZwPJrwZLWV6dl7MuEQBAZDd8');




  if(kIsWeb) { 
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDEZuuEmpT_PVYwhq8-hzG8H4z4iXmtUIw",
        authDomain: "pocus-app-82836.firebaseapp.com",
        projectId: "pocus-app-82836",
        databaseURL:"https://pocus-app-82836-default-rtdb.firebaseio.com/",
        storageBucket: "pocus-app-82836.firebasestorage.app",
        messagingSenderId: "860367108462",
        appId: "1:860367108462:web:7dfc66034290fd68c8297f",
        measurementId: "G-EC5JKWM9XT"));
        }else{
         await  Firebase.initializeApp();
        }
 
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Pocus',
        theme: AppTheme().lightTheme,
        themeMode: ThemeMode.light,
        routerConfig: AppRouter.router,
    );




  }




}