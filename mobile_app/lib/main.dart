import 'package:flutter/material.dart';

void main() {
  runApp(FoodCalorieApp());
}

class FoodCalorieApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Calorie Detector',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: UserProfileScreen(),
    );
  }
}

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _weightController = TextEditingController();
  String _activityLevel = 'Sedentary';
  String _dietPreference = 'None';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Weight (kg)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your weight';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _activityLevel,
                decoration: InputDecoration(
                  labelText: 'Activity Level',
                ),
                items: ['Sedentary', 'Lightly Active', 'Active', 'Very Active']
                    .map((level) => DropdownMenuItem(
                          value: level,
                          child: Text(level),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _activityLevel = value!;
                  });
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _dietPreference,
                decoration: InputDecoration(
                  labelText: 'Dietary Preference',
                ),
                items: ['None', 'Vegetarian', 'Vegan', 'Keto', 'Paleo']
                    .map((pref) => DropdownMenuItem(
                          value: pref,
                          child: Text(pref),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _dietPreference = value!;
                  });
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MealInputScreen(
                          weight: double.parse(_weightController.text),
                          activityLevel: _activityLevel,
                          dietPreference: _dietPreference,
                        ),
                      ),
                    );
                  }
                },
                child: Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MealInputScreen extends StatefulWidget {
  final double weight;
  final String activityLevel;
  final String dietPreference;

  MealInputScreen({
    required this.weight,
    required this.activityLevel,
    required this.dietPreference,
  });

  @override
  _MealInputScreenState createState() => _MealInputScreenState();
}

class _MealInputScreenState extends State<MealInputScreen> {
  File? _imageFile;
  final TextEditingController _mealDescriptionController = TextEditingController();
  String _calorieResult = '';
  String _dietRecommendation = '';

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _calorieResult = '';
        _dietRecommendation = '';
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    final uri = Uri.parse('http://localhost:8000/upload-image/');
    final request = http.MultipartRequest('POST', uri);

    // Add Firebase token here for authentication (placeholder)
    request.fields['token'] = 'your_firebase_id_token_here';

    request.files.add(await http.MultipartFile.fromPath('file', _imageFile!.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final data = json.decode(respStr);
      setState(() {
        _calorieResult = 'Estimated Calories: \${data['calories_estimated']}';
        _dietRecommendation = 'Diet Recommendation: Suitable for your diet'; // Placeholder
      });
    } else {
      setState(() {
        _calorieResult = 'Failed to get calorie estimation.';
      });
    }
  }

  Future<void> _submitMeal() async {
    final description = _mealDescriptionController.text;
    if (description.isEmpty) return;

    final uri = Uri.parse('http://localhost:8000/submit-meal/');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'description': description,
        'calories': null,
        'token': 'your_firebase_id_token_here', // Placeholder
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _dietRecommendation = data['recommendation'] ?? 'No recommendation';
      });
    } else {
      setState(() {
        _dietRecommendation = 'Failed to get diet recommendation.';
      });
    }
  }

  @override
  void dispose() {
    _mealDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meal Input'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'User Weight: \${widget.weight} kg\n'
              'Activity Level: \${widget.activityLevel}\n'
              'Diet Preference: \${widget.dietPreference}',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            _imageFile == null
                ? Text('No image selected.')
                : Image.file(_imageFile!),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pick Image from Gallery'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _uploadImage,
              child: Text('Upload Image for Calorie Detection'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _mealDescriptionController,
              decoration: InputDecoration(
                labelText: 'Enter meal description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _submitMeal,
              child: Text('Submit Meal Details'),
            ),
            SizedBox(height: 20),
            Text(
              _calorieResult,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              _dietRecommendation,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
