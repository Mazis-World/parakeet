import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // For platform checking
import 'dart:convert'; // For base64 encoding

class AnimalFormScreen extends StatefulWidget {
  @override
  _AnimalFormScreenState createState() => _AnimalFormScreenState();
}

class _AnimalFormScreenState extends State<AnimalFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Fields to collect data
  String? _animalType;
  String? _name;
  String? _breed;
  String? _age;
  String? _gender;
  String? _color;
  String? _weight;
  List<String> _selectedImages = [];

  // Health information
  List<String> _vaccinationHistory = [];
  String? _microchipNumber;
  bool _spayedNeutered = false;
  String? _recentVetCheckDate;

  // Behavioral information
  String? _temperament;
  List<String> _trainingStatus = [];
  String? _socialization;
  String? _exerciseRequirements;

  // Grooming needs
  String? _coatMaintenance;
  String? _sheddingLevel;

  // Diet and feeding
  String? _preferredDiet;
  String? _feedingSchedule;

  // Identification and history
  String? _adoptionSource;
  String? _licensingInfo;

  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'List Your Companion Animal',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Image Selection (5 boxes for animal image selection)
              const Text('Select Animal Images', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildImageSelection(),

              // Animal Type
              _buildTextField('Animal Type', 'Enter Animal Type', (value) {
                _animalType = value;
              }),

              // Animal Name
              _buildTextField('Name', 'Enter Animal Name', (value) {
                _name = value;
              }),

              // Breed
              _buildTextField('Breed', 'Enter Animal Breed', (value) {
                _breed = value;
              }),

              // Age
              _buildTextField('Age', 'Enter Animal Age', (value) {
                _age = value;
              }),

              // Gender
              _buildTextField('Gender', 'Enter Animal Gender', (value) {
                _gender = value;
              }),

              // Color
              _buildTextField('Color', 'Enter Animal Color', (value) {
                _color = value;
              }),

              // Weight
              _buildTextField('Weight', 'Enter Animal Weight', (value) {
                _weight = value;
              }),

              const SizedBox(height: 20),

              // Health Information
              const Text('Health Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildCheckboxListTile('Spayed/Neutered', _spayedNeutered, (value) {
                setState(() {
                  _spayedNeutered = value!;
                });
              }),

              _buildTextField('Microchip Number', 'Enter Microchip Number', (value) {
                _microchipNumber = value;
              }),

              _buildTextField('Recent Vet Check Date', 'Enter Date of Last Vet Check', (value) {
                _recentVetCheckDate = value;
              }),

              const SizedBox(height: 20),

              // Behavioral Information
              const Text('Behavioral Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildTextField('Temperament', 'Enter Animal Temperament', (value) {
                _temperament = value;
              }),

              _buildTextField('Training Status', 'Enter Training Status', (value) {
                _trainingStatus.add(value!);
              }),

              _buildTextField('Socialization', 'Enter Socialization Info', (value) {
                _socialization = value;
              }),

              _buildTextField('Exercise Requirements', 'Enter Exercise Requirements', (value) {
                _exerciseRequirements = value;
              }),

              const SizedBox(height: 20),

              // Grooming Needs
              const Text('Grooming Needs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildTextField('Coat Maintenance', 'Enter Coat Maintenance', (value) {
                _coatMaintenance = value;
              }),

              _buildTextField('Shedding Level', 'Enter Shedding Level', (value) {
                _sheddingLevel = value;
              }),

              const SizedBox(height: 20),

              // Diet and Feeding
              const Text('Diet and Feeding', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildTextField('Preferred Diet', 'Enter Preferred Diet', (value) {
                _preferredDiet = value;
              }),

              _buildTextField('Feeding Schedule', 'Enter Feeding Schedule', (value) {
                _feedingSchedule = value;
              }),

              const SizedBox(height: 20),

              // Identification and History
              const Text('Identification and History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildTextField('Adoption Source', 'Enter Adoption Source', (value) {
                _adoptionSource = value;
              }),

              _buildTextField('Licensing Info', 'Enter Licensing Information', (value) {
                _licensingInfo = value;
              }),

              const SizedBox(height: 20),

              // Submit Button
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // Upload images to Firebase Storage and get URLs
                    List<String> imageUrls = [];
                    for (var image in _selectedImages) {
                      final ref = FirebaseStorage.instance.ref().child('animal_images').child(DateTime.now().millisecondsSinceEpoch.toString());
                      final uploadTask = await ref.putFile(File(image));
                      final url = await uploadTask.ref.getDownloadURL();
                      imageUrls.add(url);
                    }

                    // Save the form data to Firestore
                    await FirebaseFirestore.instance.collection('listings').add({
                      'animalType': _animalType,
                      'name': _name,
                      'breed': _breed,
                      'age': _age,
                      'gender': _gender,
                      'color': _color,
                      'weight': _weight,
                      'vaccinationHistory': _vaccinationHistory,
                      'microchipNumber': _microchipNumber,
                      'spayedNeutered': _spayedNeutered,
                      'recentVetCheckDate': _recentVetCheckDate,
                      'temperament': _temperament,
                      'trainingStatus': _trainingStatus,
                      'socialization': _socialization,
                      'exerciseRequirements': _exerciseRequirements,
                      'coatMaintenance': _coatMaintenance,
                      'sheddingLevel': _sheddingLevel,
                      'preferredDiet': _preferredDiet,
                      'feedingSchedule': _feedingSchedule,
                      'adoptionSource': _adoptionSource,
                      'licensingInfo': _licensingInfo,
                      'images': imageUrls,
                      'createdAt': Timestamp.now(),
                    });
                    // Handle successful form submission (e.g., show a message, navigate back, etc.)
                  }
                },
                child: const Text('Submit'),
                style: ElevatedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }
  List<File?> _images = [null, null, null, null, null]; // Store 5 image files
  // Method to pick an image and store it
  Future<void> _pickImage(int index) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (kIsWeb) {
          // For web, convert image to base64 string
          _images[index] = pickedFile.readAsBytes().then((bytes) => base64Encode(bytes)) as File?;
        } else {
          // For mobile, store the file
          _images[index] = File(pickedFile.path);
        }
      });
    }
  }

  // Helper method for image selection
  Widget _buildImageSelection() {
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 5, // 5 image boxes
      itemBuilder: (context, index) {
        final image = _images[index];

        return GestureDetector(
          onTap: () => _pickImage(index), // Allow image selection on tap
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.black,
                width: 2,
              ),
            ),
            child: image == null
                ? Center(child: Text('Select Image'))
                : (kIsWeb
                ? Image.memory(
              base64Decode(image as String), // Display image from base64 for Web
              fit: BoxFit.cover,
            )
                : Image.file(
              image, // Display the selected file on mobile
              fit: BoxFit.cover,
            )),
          ),
        );
      },
    );
  }

  // Helper methods to build form fields
  Widget _buildTextField(String label, String hintText, Function(String?) onSaved) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildCheckboxListTile(String title, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
