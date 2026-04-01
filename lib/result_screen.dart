import 'dart:io';
import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final String imagePath;
  final List defects;

  const ResultScreen({
    super.key,
    required this.imagePath,
    required this.defects,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Defect Result")),
      body: Stack(
        children: [
          Image.file(File(imagePath)),
          ...defects.map((d) {
            return Positioned(
              left: d["x"].toDouble(),
              top: d["y"].toDouble(),
              child: Container(
                width: d["w"].toDouble(),
                height: d["h"].toDouble(),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 3),
                ),
              ),
            );
          }).toList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }
}
