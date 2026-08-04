import 'package:flutter/material.dart';

/// Loading screen ringan (latar sama dengan welcome screen agar mulus) yang
/// tampil selagi Clerk diinisialisasi di background — bukan welcome screen.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF012242), Color(0xFF00558C), Color(0xFF1E9BF0)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Center(
          child: SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
          ),
        ),
      ),
    );
  }
}
