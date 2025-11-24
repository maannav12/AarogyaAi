import 'package:aarogya/bottom/bottom_bar.dart';
import 'package:aarogya/bottom/bottom_bar.dart';
import 'package:aarogya/home/home_page.dart';
import 'package:aarogya/login/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:get_storage/get_storage.dart';
import '../models/user_profile_model.dart';
import '../utils/snack_bar_utils.dart';

class LoginControler extends GetxController {
  final formkey = GlobalKey<FormState>();
  final TextEditingController emailcontroller = TextEditingController();
  final TextEditingController passwordcontroller = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  GetStorage box = GetStorage();

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
  }

  onlogin() {
    if (emailcontroller.text.isEmpty || !emailcontroller.text.contains("@")) {
      SnackBarUtils.showSnack(
        title: "your email is wrong",
        message: "Enter your vaild email",
      );

      return;
    }
    if (passwordcontroller.text.isEmpty || passwordcontroller.text.length < 8) {
      SnackBarUtils.showSnack(
        title: "your email is wrong",
        message: "Enter your vaild email",
      );
      return;
    }

    box.write('isLogin', true);

    final bool isLogin = box.read("isLogin") ?? false;

    print(isLogin);
    // if (formkey.currentState!.validate()) {
    // } else {
    //   Get.showSnackbar(
    //     GetSnackBar(
    //       duration: Duration(milliseconds: 100),
    //       title: "LOGIN FAIL",
    //       message: "plz try angin login",
    //       snackStyle: SnackStyle.FLOATING,
    //       animationDuration: Duration(milliseconds: 100),
    //     ),
    //   );
    // }
  }

  // Future<void> login() async {
  //   try {
  //     UserCredential userCredential = await _auth.signInWithEmailAndPassword(
  //       email: emailcontroller.text.trim(),
  //       password: passwordcontroller.text.trim(),
  //     );

  //     Get.snackbar(
  //       "Welcome",
  //       "Welcome: ${userCredential.user?.email}",
  //       snackPosition: SnackPosition.BOTTOM,
  //     );

  //     box.write('isLogin', true);

  //     // Navigate to Home Page after login

  //     Get.to(HomeScreen());
  //   } on FirebaseAuthException catch (e) {
  //     String message = '';
  //     if (e.code == 'user-not-found') {
  //       message = "No user found with this email.";
  //     } else if (e.code == 'wrong-password') {
  //       message = "Incorrect password.";
  //     } else {
  //       message = "Error: ${e.message}";
  //       Get.snackbar(
  //         "LOGIN ERROR",
  //         message,
  //         snackPosition: SnackPosition.BOTTOM,
  //       );
  //     }
  //   }
  // }

  Future<void> login() async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailcontroller.text.trim(),
        password: passwordcontroller.text.trim(),
      );

      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(content: Text("Welcome: ${userCredential.user?.email}")),
      );

      Get.offAll(BottomBar());
    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'user-not-found') {
        message = "No user found with this email.";
      } else if (e.code == 'wrong-password') {
        message = "Incorrect password.";
      } else {
        message = "Error: ${e.message}";
      }
      emailcontroller.clear();
      passwordcontroller.clear();

      ScaffoldMessenger.of(
        Get.context!,
      ).showSnackBar(SnackBar(content: Text(message)));
      emailcontroller.clear();
      passwordcontroller.clear();
    }
  }
  googleLogin() async {
    try {
      final GoogleSignIn signIn = GoogleSignIn.instance;
      
      // Force sign out to ensure fresh login
      await signIn.signOut();

      await signIn.initialize(
        serverClientId:
            "120899676261-cef1prvtrseid9seo6do20uivrla8ach.apps.googleusercontent.com",
      );

      final GoogleSignInAccount? googleUser = await signIn.authenticate();

      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: null,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        await saveDetailsOnDB(user.uid, {
          "socialId": user.uid,
          "name": user.displayName,
          "email": user.email,
          "image": user.photoURL,
        });

        // Save to local storage for ProfileController
        final userProfile = UserProfile(name: user.displayName);
        box.write('user_profile', userProfile.toJson());

        Get.offAll(() => BottomBar());
      }
    } catch (e) {
      print("Google Login Error: $e");
      Get.snackbar(
        "Login Failed",
        "Error: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> saveDetailsOnDB(
    String socialId,
    Map<String, dynamic> userData,
  ) async {
    final CollectionReference userCollection = _firebaseFirestore.collection(
      "users",
    );

    final query = await userCollection
        .where("socialId", isEqualTo: socialId)
        .get();

    if (query.docs.isEmpty) {
      await userCollection.add(userData);
    } else {
      await userCollection.doc(query.docs.first.id).update(userData);
    }
  }
  logout() async {
    await _auth.signOut();
    await GoogleSignIn.instance.signOut();
    box.write('isLogin', false);
    Get.offAll(() => LoginScreen());
  }
}
