import 'package:flutter/material.dart';
import 'routes/routes_app.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Petición de Material',
      initialRoute: '/panel',
      routes: getApplicationRoutes(),
    );
  }
}
