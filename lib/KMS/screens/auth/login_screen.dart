import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/constants/app_style.dart';
import 'package:innovator/KMS/constants/mediaquery.dart';
import 'package:innovator/KMS/screens/auth/forgot_password_screen.dart';
import 'package:innovator/KMS/screens/auth/signup_screen.dart';
import 'package:innovator/KMS/screens/dashboard/admin_dashboard_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  // final TextEditingController schoolNameController = TextEditingController();
  // final TextEditingController rollNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();
  // bool agreeToTerms = false;
  // String selectedRole = 'Admin';
  @override
  Widget build(BuildContext context) {
    // bool isStudent = selectedRole=='Student';

    return SafeArea(
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/kms/auth_backgroundimage.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(
                      top: context.screenHeight*0.02,
                bottom: context.screenHeight*.05,
                right: context.screenWidth*0.05,
               left:   context.screenWidth*0.05,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ColorFilter.mode(
                    Color(0xffC3C9CD),

                    BlendMode.dstOver,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white60,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Put the logo here after logo is designed
                            Container(
                              height: 50,
                              width: 50,
                              color: AppStyle.primaryColor,
                              child: Image.asset(
                                'assets/kms/settings.png',
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Title
                            Text(
                              'Welcome Back',
                              style: AppStyle.heading1.copyWith(
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Full Name Field
                            // textFormField(
                            //   formFieldTopText: 'Full Name',

                            //   controller: nameController,

                            //   icon: Icons.person_outline,
                            // ),
                            const SizedBox(height: 16),

                            // Email / Username
                            textFormField(
                              formFieldTopText: 'EMAIL',
                              controller: emailController,

                              icon: Icons.mail_outline,
                            ),
                           SizedBox(height: context.screenHeight * 0.02),

                            // Password
                            textFormField(
                              formFieldTopText: 'PASSWORD',
                              controller: passwordController,
                              icon: Icons.lock_outline,
                              isPassword: true,
                              fieldId: 'password',
                            ),
                           SizedBox(height: context.screenHeight * 0.04),

                            // Role Dropdown uncomment if needed in the login part
                            //                   Column(
                            //                     crossAxisAlignment: CrossAxisAlignment.start,
                            //                     children: [
                            //                       Text('ROLE',style: TextStyle(
                            //                                  fontSize: AppStyle.mediumText,
                            // fontWeight: FontWeight.w600,
                            // color: Colors.black
                            //                       ),),
                            //                       Container(
                            //                         padding: const EdgeInsets.symmetric(horizontal: 16),
                            //                         decoration: BoxDecoration(
                            //                           color: Colors.white ,
                            //                           borderRadius: BorderRadius.circular(12),
                            //                           border: Border.all(color: Colors.black),
                            //                         ),
                            //                         child: DropdownButtonHideUnderline(
                            //                           child: DropdownButton<String>(
                            //                             value: selectedRole,
                            //                             isExpanded: true,
                            //                             icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
                            //                             dropdownColor: Colors.white,
                            //                             style: const TextStyle(color: Colors.black),
                            //                             items: ['Admin', 'School', 'Partner', 'Student']
                            //                                 .map((role) => DropdownMenuItem(
                            //                                       value: role,
                            //                                       child: Text(role),
                            //                                     ))
                            //                                 .toList(),
                            //                             onChanged: (value) {
                            //                               setState(() {
                            //                                 selectedRole = value!;
                            //                               });
                            //                             },
                            //                           ),
                            //                         ),
                            //                       ),
                            //                     ],
                            //                   ),
                            // const SizedBox(height: 16),
                            // if(isStudent)...[
                            //     textFormField(
                            //     formFieldTopText: 'School Name',
                            //   controller: schoolNameController,
                            //     icon: Icons.lock_outline,
                            //   isPassword: true,
                            // ),
                            // const SizedBox(height: 16),
                            //   textFormField(
                            //     formFieldTopText: 'Roll Number',
                            //   controller: rollNumberController,
                            //     icon: Icons.lock_outline,
                            //   isPassword: true,
                            // ),
                            // const SizedBox(height: 16),

                            // ],

                            //Login Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    isLoading
                                        ? null
                                        : () {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>AdminDashboardScreen()));
                                          }
                                        },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppStyle.buttonColor,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child:
                                    isLoading
                                        ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                        : Text(
                                          'Log in',
                                          style: TextStyle(
                                            fontSize: 18.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                              ),
                            ),
                      SizedBox(height: context.screenHeight * 0.02),


                            // Login Link
                            Column(
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => ForgotPasswordScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      decoration: TextDecoration.underline,
                                      color: Colors.black,
                                      fontSize: AppStyle.mediumText,
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Donot have an account? ',
                                      style: TextStyle(
                                 color: Colors.black,
                                      fontSize: AppStyle.mediumText,
                                    
                                  ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => SignupScreen(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'Signup',
                                        style: TextStyle(
                                          color: Colors.black,
                                      fontSize: AppStyle.mediumText,
                                      
                                      decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget textFormField({
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    required String formFieldTopText,
    String? fieldId,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formFieldTopText,
          style: TextStyle(
            fontSize: AppStyle.mediumText,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 5,),
        Consumer(
          builder: (context, ref, child) {
            final obscureText =
                isPassword && fieldId != null
                    ? ref.watch(obscureProvider(fieldId))
                    : false;

            return TextFormField(
              controller: controller,
              obscureText: obscureText,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelStyle: const TextStyle(color: Colors.black),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.black),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.black),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.black, width: 2),
                ),
                suffixIcon:
                    isPassword && fieldId != null
                        ? IconButton(
                          icon: Icon(
                            obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            // Toggle the obscure state
                            ref.read(obscureProvider(fieldId).notifier).state =
                                !obscureText;
                          },
                        )
                        : null,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter $formFieldTopText';
                }
                return null;
              },
            );
          },
        ),
      ],
    );
  }
}
