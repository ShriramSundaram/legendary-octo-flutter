import 'package:flutter/material.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({
    super.key,
    required this.name,
    required this.email,
    required this.verified,
    required this.level,
    required this.photo,
    required this.onTest,
    required this.onDelete,
    required this.onBack,
    required this.onEdit,
  });

  final String name;
  final String email;
  final bool verified;
  final String level;
  final ImageProvider photo;
  final VoidCallback onTest;
  final VoidCallback onDelete;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Profile'), automaticallyImplyLeading: false),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                      child: CircleAvatar(radius: 48, backgroundImage: photo)),
                  const SizedBox(height: 16),
                  _ProfileField(label: 'Full Name', value: name),
                  _ProfileField(
                      label: 'Verified Email Status',
                      value: verified ? 'Yes' : 'No'),
                  _ProfileField(label: 'Email', value: email),
                  _ProfileField(label: 'Your German Level', value: level),
                  OutlinedButton(
                    onPressed: onTest,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    child: const Row(children: [
                      Expanded(
                          child: Text("Let's Test your German Level!",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold))),
                      SizedBox(width: 8),
                      Icon(Icons.note_alt_outlined,
                          color: Colors.deepOrangeAccent),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: onDelete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Delete Account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Row(children: [
              Expanded(
                  child: OutlinedButton(
                onPressed: onBack,
                style: _actionStyle(),
                child: const Text('Back'),
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: FilledButton(
                onPressed: onEdit,
                style: _actionStyle(),
                child: const Text('Edit'),
              )),
            ]),
          ),
        ),
      ),
    );
  }

  ButtonStyle _actionStyle() => OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        textStyle: const TextStyle(fontSize: 16),
      );
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value.isEmpty ? '—' : value,
              style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
