import 'package:flutter/material.dart';

class ParentControlScreen extends StatefulWidget {
  const ParentControlScreen({Key? key}) : super(key: key);

  @override
  _ParentControlScreenState createState() => _ParentControlScreenState();
}

class _ParentControlScreenState extends State<ParentControlScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('وضع الوالدين'),
        centerTitle: true,
        backgroundColor: const Color(0xFF607D8B),
      ),
      body: const Center(
        child: Text(
          'شاشة إعدادات الوالدين',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
