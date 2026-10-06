import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

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
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('You must be logged in to create a listing')),
                      );
                      return;
                    }

                    // Upload each selected image
                    for (int i = 0; i < _images.length; i++) {
                      final image = _images[i];
                      if (image != null && image is XFile) {
                        try {
                          final timestamp = DateTime.now().millisecondsSinceEpoch;
                          final imageName = '${user.uid}_${timestamp}_$i.jpg';
                          final ref = FirebaseStorage.instance
                              .ref()
                              .child('animal_images')
                              .child(imageName);

                          // Use bytes for both web and mobile (more reliable)
                          final bytes = await image.readAsBytes();
                          final uploadTask = await ref.putData(bytes);
                          final url = await uploadTask.ref.getDownloadURL();
                          imageUrls.add(url);
                        } catch (e) {
                          // Skip failed uploads but continue with others
                          debugPrint('Error uploading image $i: $e');
                        }
                      }
                    }

                    // Save the form data to Firestore
                    try {
                    await FirebaseFirestore.instance.collection('listings').add({
                      'hostId': user.uid,
                      'hostName': user.displayName ?? user.email?.split('@')[0] ?? 'Unknown',
                      'hostEmail': user.email,
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
                      'status': 'available', // Default status
                      'createdAt': Timestamp.now(),
                      'updatedAt': Timestamp.now(),
                    });
                    } catch (e) {
                      if (context.mounted) {
                        final denied = e.toString().toLowerCase().contains('permission');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              denied
                                  ? 'Firestore blocked this listing. Publish firestore.rules in the Firebase console, then try again.'
                                  : 'Could not save the listing: $e',
                            ),
                          ),
                        );
                      }
                      return;
                    }

                    // Handle successful form submission
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pet listed successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context);
                    }
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
  List<XFile?> _images = [null, null, null, null, null]; // Store 5 image files
  // Method to pick an image and store it
  Future<void> _pickImage(int index) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        // Store the XFile (works for both web and mobile)
        _images[index] = pickedFile;
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
                ? const Center(child: Text('Select Image'))
                : FutureBuilder<Uint8List>(
                    future: image.readAsBytes(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasData) {
                        return Image.memory(
                          snapshot.data!,
                          fit: BoxFit.cover,
                        );
                      }
                      return const Center(child: Text('Error loading image'));
                    },
                  ),
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
