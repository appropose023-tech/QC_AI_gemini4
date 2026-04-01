import 'dart:io';
import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final File original;
  final File? processed;

  const ResultScreen({
    super.key,
    required this.original,
    required this.processed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Results")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text("Original PCB", style: TextStyle(fontSize: 18)),
            Image.file(original),

            const SizedBox(height: 25),

            const Text("Processed Result", style: TextStyle(fontSize: 18)),
            processed != null
                ? Image.file(processed!)
                : const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text("No defects detected OR server error."),
                  ),
          ],
        ),
      ),
    );
  }
}
