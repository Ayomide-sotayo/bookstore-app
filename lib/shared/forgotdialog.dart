import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  final emailController = TextEditingController();
  bool isLoading = false;
  final auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Reset Password"),
      content: TextField(
        controller: emailController,
        decoration: const InputDecoration(hintText: "Enter your email"),
      ),
      actions: [
        isLoading
            ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: CircularProgressIndicator(),
              )
            : TextButton(
                onPressed: () async {
                  setState(() => isLoading = true);
                  try {
                    await auth.sendPasswordResetEmail(
                      email: emailController.text.trim(),
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Reset link sent!")),
                    );
                  } on FirebaseAuthException catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.message ?? "Error")),
                    );
                  } finally {
                    setState(() => isLoading = false);
                  }
                },
                child: const Text("Send Link"),
              ),
      ],
    );
  }
}
