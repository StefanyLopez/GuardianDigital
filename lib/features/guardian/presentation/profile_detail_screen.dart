import 'package:flutter/material.dart';
class ProfileDetailScreen extends StatelessWidget {
  final String profileId;
  const ProfileDetailScreen({super.key, required this.profileId});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalle')),
    body: const Center(child: Text('Próximamente')),
  );
}
