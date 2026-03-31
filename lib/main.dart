import 'package:flutter/material.dart';
import 'capture_screen.dart';

void main() {
  runApp(const PCBApp());
}

class PCBApp extends StatelessWidget {
  const PCBApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "PCB Inspector",
      theme: ThemeData(primarySwatch: Colors.blue),
      home: CaptureScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
