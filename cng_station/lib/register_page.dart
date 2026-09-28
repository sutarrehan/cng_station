import 'package:flutter/material.dart';

class register_page extends StatefulWidget {
  const register_page({super.key});

  @override
  State<register_page> createState() => _register_pageState();
}

class _register_pageState extends State<register_page> {

  TextEditingController namecontroller= TextEditingController();
  TextEditingController emailcontroller= TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: GlobalKey<FormState>(),
        child: Column(
          children: [
            TextFormField(
              controller: emailcontroller,
            ),

            TextFormField(
              controller: namecontroller,
            ),

            SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                print(emailcontroller.text);
                print(namecontroller.text);
                namecontroller.clear();
                emailcontroller.clear();
              },
              child: Text("Add"),
            )

          ],
        ),
      ),
    );
  }
}