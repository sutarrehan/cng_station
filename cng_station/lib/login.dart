import 'package:flutter/material.dart';

class login_page extends StatefulWidget {
  const login_page({super.key});

  @override
  State<login_page> createState() => _login_pageState();
}

class _login_pageState extends State<login_page> {
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController passcontroller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: GlobalKey<FormState>(),
        child: Column(
          children: [
            TextField(controller: emailcontroller),
            TextField(controller: passcontroller),
            ElevatedButton(
              onPressed: () {
                print(emailcontroller.text);
                print(passcontroller.text);
                emailcontroller.clear();
                passcontroller.clear();
              },
              child: Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}
