import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'dart:convert';

void main() => runApp(MaterialApp(
      home: PCBInspectorApp(),
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
    ));

class PCBInspectorApp extends StatefulWidget {
  @override
  _PCBInspectorAppState createState() => _PCBInspectorAppState();
}

class _PCBInspectorAppState extends State<PCBInspectorApp> {
  File? _image;
  String? _selectedProject;
  List<String> _existingProjects = [];
  String _batchNumber = "B01";
  String _status = "Ready";
  String? _reportUrl;

  final TextEditingController _projectController = TextEditingController();
  final String serverIp = "http://104.154.76.47:5000";

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  // Fetch folders from BASE_DATA_DIR on server
  Future<void> _fetchProjects() async {
    try {
      final response = await http.get(Uri.parse('$serverIp/get_projects'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _existingProjects = List<String>.from(data['projects']);
        });
      }
    } catch (e) {
      setState(() => _status = "Fetch Error: Check Connection");
    }
  }

  Future<void> _processImage({required bool isGolden}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      // 1. CROPPER LOGIC
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: isGolden ? 'Align Golden Sample' : 'Align Test PCB',
            toolbarColor: isGolden ? Colors.orange : Colors.indigo,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
        ],
      );

      if (croppedFile == null) return;

      setState(() {
        _image = File(croppedFile.path);
        _status = isGolden ? "Uploading Master..." : "Analyzing...";
        _reportUrl = null;
      });

      // 2. UPLOAD LOGIC
      try {
        String endpoint = isGolden ? "/upload_golden" : "/inspect";
        var request = http.MultipartRequest('POST', Uri.parse('$serverIp$endpoint'));

        // Sanitize project name
        String projName = _projectController.text.trim().replaceAll(" ", "_");
        if (projName.isEmpty) {
          setState(() => _status = "Error: Project Name Required");
          return;
        }

        request.fields['project_name'] = projName;
        request.fields['batch_number'] = _batchNumber;
        request.files.add(await http.MultipartFile.fromPath('image', _image!.path));

        var streamedResponse = await request.send().timeout(Duration(seconds: 60));
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          var data = json.decode(response.body);
          setState(() {
            _status = isGolden ? "Golden Saved!" : data['status'];
            if (!isGolden) _reportUrl = serverIp + data['report_url'];
          });
          // Refresh project list if we added a new one
          if (isGolden) _fetchProjects();
        } else {
          setState(() => _status = "Server Error: ${response.statusCode}");
        }
      } catch (e) {
        setState(() => _status = "Connection Failed");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AOI Factory Aggregator")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Custom Project Input
              TextField(
                controller: _projectController,
                decoration: InputDecoration(
                  labelText: "Current Project Name",
                  hintText: "Enter new or select from list",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.precision_manufacturing),
                ),
              ),
              SizedBox(height: 12),

              // 2. Flexible Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Quick Select Existing Project",
                ),
                value: _existingProjects.contains(_selectedProject) ? _selectedProject : null,
                items: _existingProjects.map((String val) {
                  return DropdownMenuItem<String>(value: val, child: Text(val));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedProject = val;
                    _projectController.text = val!;
                  });
                },
              ),
              SizedBox(height: 12),

              TextField(
                decoration: InputDecoration(labelText: "Batch Number", border: OutlineInputBorder()),
                onChanged: (val) => _batchNumber = val,
              ),
              SizedBox(height: 20),

              // 3. Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _processImage(isGolden: true),
                      icon: Icon(Icons.stars),
                      label: Text("Set Golden"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[800], foregroundColor: Colors.white),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _processImage(isGolden: false),
                      icon: Icon(Icons.camera_alt),
                      label: Text("Inspect"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ),

              Divider(height: 40),

              // 4. Status & Results
              Center(
                child: Text("Status: $_status",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                    color: _status.contains("Defect") ? Colors.red : Colors.green)),
              ),

              if (_reportUrl != null) ...[
                SizedBox(height: 20),
                Text("Inspection Report (Mumbai Factory):", style: TextStyle(fontWeight: FontWeight.bold)),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(_reportUrl!, key: ValueKey(_reportUrl)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(labelText: "Batch Number", border: OutlineInputBorder()),
                onChanged: (val) => _batchNumber = val,
              ),
              
              SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.star),
                      label: Text("Set Golden"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[800], foregroundColor: Colors.white),
                      onPressed: () => _processImage(isGolden: true),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.search),
                      label: Text("Inspect"),
                      onPressed: () => _processImage(isGolden: false),
                    ),
                  ),
                ],
              ),

              Divider(height: 40),
              
              Center(
                child: Text("Status: $_status", 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, 
                  color: _status.contains("Defect") ? Colors.red : Colors.green)
                ),
              ),
              
              if (_reportUrl != null) ...[
                SizedBox(height: 20),
                Text("Inspection Result:", style: TextStyle(fontWeight: FontWeight.bold)),
                Image.network(_reportUrl!, key: ValueKey(_reportUrl)),
              ] else if (_image != null) ...[
                SizedBox(height: 20),
                Text("Last Captured:"),
                Image.file(_image!, height: 200),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
