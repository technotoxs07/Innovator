import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:innovator/InnovatorAuthorization/Login.dart';
import 'package:innovator/InnovatorAuthorization/OTP_Validation.dart';
import 'package:innovator/Innovatorhelper/dialogs.dart';
import 'package:innovator/Innovatormain.dart';
import 'package:innovator/Innovatorservices/firebase_services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  bool _isPasswordVisible = false;
  final Color preciseGreen = const Color.fromRGBO(244, 135, 6, 1);
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  String completePhoneNumber = '';
  bool isLoading = false;
  DateTime? selectedDate;
  bool rememberMe = false;

  @override
  void initState() {
    super.initState();
    // Pre-filling the form with the provided data for testing
    nameController.text = "";
    emailController.text = "";
    passwordController.text = "";
    completePhoneNumber = "";
    dobController.text = "";
    // Parse the date from the string format YYYY-MM-DD
    final dateParts = "2005-08-08".split('-');
    if (dateParts.length == 3) {
      selectedDate = DateTime(
        int.parse(dateParts[0]), // year
        int.parse(dateParts[1]), // month
        int.parse(dateParts[2]), // day
      );
    }
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    dobController.dispose();
    super.dispose();
  }

  // Format date as YYYY-MM-DD
  String formatDate(DateTime date) {
    String year = date.year.toString();
    String month = date.month < 10 ? '0${date.month}' : date.month.toString();
    String day = date.day < 10 ? '0${date.day}' : date.day.toString();
    return '$year-$month-$day';
  }

  // Show date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: preciseGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        dobController.text = formatDate(picked);
      });
    }
  }

  // Validate form fields
  bool validateFields() {
    if (nameController.text.trim().isEmpty) {
      Dialogs.showSnackbar(context, 'Please enter your name');
      return false;
    }
    if (emailController.text.trim().isEmpty) {
      Dialogs.showSnackbar(context, 'Please enter your email');
      return false;
    }
    if (!RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(emailController.text)) {
      Dialogs.showSnackbar(context, 'Please enter a valid email');
      return false;
    }
    if (passwordController.text.isEmpty || passwordController.text.length < 6) {
      Dialogs.showSnackbar(context, 'Password must be at least 6 characters');
      return false;
    }
    if (completePhoneNumber.isEmpty) {
      Dialogs.showSnackbar(context, 'Please enter your phone number');
      return false;
    }
    if (dobController.text.isEmpty) {
      Dialogs.showSnackbar(context, 'Please enter your date of birth');
      return false;
    }
    return true;
  }

  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (rememberMe) {
        await prefs.setString('email', emailController.text.trim());
        await prefs.setString('password', passwordController.text.trim());
        await prefs.setBool('rememberMe', true);
      } else {
        await prefs.remove('email');
        await prefs.remove('password');
        await prefs.setBool('rememberMe', false);
      }
    } catch (e) {
      debugPrint('Error saving credentials: $e');
    }
  }

  Future<void> signUp() async {
    if (!validateFields()) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Create request body for API
      final Map<String, dynamic> requestBody = {
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "password": passwordController.text,
        "phone": completePhoneNumber,
        "dob": dobController.text,
      };

      developer.log('Signup request body: $requestBody');

      // Make API call
      final response = await http.post(
        Uri.parse('http://182.93.94.210:3067/api/v1/register-user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      developer.log(
        'Signup API Response: ${response.statusCode} - ${response.body}',
      );

      // Handle response
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Successfully registered
        final responseData = jsonDecode(response.body);

        // Extract user data from response
        Map<String, dynamic>? userData;
        if (responseData['user'] is Map) {
          userData = Map<String, dynamic>.from(responseData['user']);
        } else if (responseData['data'] is Map) {
          userData = Map<String, dynamic>.from(responseData['data']);
        }

        // Generate a user ID if not present and ensure consistency
        String userId =
            userData?['_id']?.toString() ??
            userData?['id']?.toString() ??
            userData?['userId']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString();

        developer.log('Using user ID for Firestore: $userId');

        // ENHANCED: Use verifyAndCreateUser for better consistency
        try {
          await FirebaseService.verifyAndCreateUser(
            userId: userId,
            name: nameController.text.trim(),
            email: emailController.text.trim(),
            phone: completePhoneNumber,
            dob: dobController.text,
            provider: 'email',
          );
          developer.log('User successfully created in Firestore');
        } catch (firestoreError) {
          developer.log('Error creating user in Firestore: $firestoreError');
          // Continue anyway as API signup was successful
        }

        //Dialogs.showSnackbar(context, 'Account successfully created! Please login.');

        await _saveCredentials();
        // Navigate to login page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpValidationScreen(email: emailController.text),
          ),
        );
        // Navigator.pushReplacement(context, MaterialPageRoute(
        //   builder: (context) => OtpValidationScreen(),
        // ));
      } else {
        // Registration failed
        final responseData = jsonDecode(response.body);
        final errorMessage =
            responseData['message'] ??
            responseData['error'] ??
            'Registration failed';
        developer.log('Registration failed: $errorMessage');
        Dialogs.showSnackbar(context, errorMessage);
      }
    } catch (e) {
      developer.log('Error creating account: $e');
      Dialogs.showSnackbar(context, 'Error creating account: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final mq = MediaQuery.of(context).size;
    return Theme(
      data: ThemeData(
        primaryColor: preciseGreen,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: preciseGreen, width: 2),
          ),
        ),
      ),
      child: Scaffold(
        body: Stack(
          children: [
            // Container(
            //   width: MediaQuery.of(context).size.width,
            //   height: MediaQuery.of(context).size.height / 1.8,
            //   decoration: const BoxDecoration(
            //     color: Color.fromRGBO(244, 135, 6, 1),
            //     borderRadius: BorderRadius.only(
            //       bottomRight: Radius.circular(70),
            //     ),
            //   ),
            //   child: Padding(
            //     padding: EdgeInsets.only(bottom: mq.height * 0.15),
            //     child: Center(
            //       child: Image.asset(
            //         'animation/signup.gif',
            //         width: mq.width * .95,
            //       ),
            //     ),
            //   ),
            // ),
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 2.0,
              decoration: BoxDecoration(
                color: Color.fromRGBO(244, 135, 6, 1),
                // color: Color(0xffFFC067),
                // color: Colors.orange.shade800,
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(70),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: mq.width * 0.03,
                  top: mq.height * 0.02,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      'CREATE\nACCOUNT',
                      style: TextStyle(
                        fontSize: 28,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),

                    Align(
                      alignment: Alignment.topRight,
                      child: Image.asset(
                        'animation/loginimage.gif',
                        width: screenSize.width * 0.5,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // White container with form
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height:
                    MediaQuery.of(context).size.height /
                    1.6, // Slightly larger to accommodate the new field
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(70)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),

                        // Name field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Full Name',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'InterThin',
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: mq.height * 0.004),
                            TextFormField(
                              controller: nameController,
                              decoration: InputDecoration(
                                hintText: 'Enter your name',

                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontFamily: 'InterThin',
                                ),

                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Color.fromRGBO(244, 135, 6, 1),
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: mq.height * 0.025),
                        // Email field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'InterThin',
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: mq.height * 0.004),
                            TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'Enter your email',
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontFamily: 'InterThin',
                                ),
                                prefixIcon: Icon(
                                  Icons.email,
                                  color: Colors.black54,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Color.fromRGBO(244, 135, 6, 1),
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: mq.height * 0.025),

                        // Phone number field with country code picker
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Phone Number',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'InterThin',
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: mq.height * 0.004),
                            IntlPhoneField(
                              controller: phoneController,
                              decoration: InputDecoration(
                                hintText: 'Phone Number',
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontFamily: 'InterThin',
                                ),
                                prefixIcon: Icon(
                                  Icons.email,
                                  color: Colors.black54,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Color.fromRGBO(244, 135, 6, 1),
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                              ),
                              initialCountryCode: 'NP', // Changed to Nepal
                              onChanged: (phone) {
                                completePhoneNumber = phone.completeNumber;
                              },
                            ),
                          ],
                        ),

                        // Date of Birth field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date of Birth',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'InterThin',
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: mq.height * 0.004),
                            TextField(
                              controller: dobController,
                              readOnly: true,

                              decoration: InputDecoration(
                                hintText: 'Enter your date of birth',
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontFamily: 'InterThin',
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.date_range),
                                  onPressed: () => _selectDate(context),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Color.fromRGBO(244, 135, 6, 1),
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                              ),
                              onTap: () => _selectDate(context),
                            ),
                          ],
                        ),
                        SizedBox(height: mq.height * 0.025),

                        // Password field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Password',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'InterThin',
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: mq.height * 0.004),
                            TextField(
                              obscureText: !_isPasswordVisible,
                              controller: passwordController,
                              decoration: InputDecoration(
                                hintText: 'Enter your password',
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontFamily: 'InterThin',
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Color.fromRGBO(244, 135, 6, 1),
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Checkbox(
                                  activeColor: Color.fromRGBO(244, 135, 6, 1),
                                  checkColor: Colors.white,
                                  value: rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      rememberMe = value!;
                                    });
                                  },
                                ),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      rememberMe = !rememberMe;
                                    });
                                  },
                                  child: const Text('Remember Me'),
                                ),
                                const Spacer(),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Sign up button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromRGBO(244, 135, 6, 1),
                            foregroundColor: Colors.white,
                            elevation: 10,
                            minimumSize: const Size(200, 50),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: isLoading ? null : signUp,
                          icon:
                              isLoading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.person_add),
                          label: Text(
                            isLoading ? 'Creating Account...' : 'Sign Up',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Back button
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back to Login'),
                          style: TextButton.styleFrom(
                            foregroundColor: preciseGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Show loading indicator if needed
            if (isLoading)
              Container(
                color: Colors.black.withAlpha(30),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
