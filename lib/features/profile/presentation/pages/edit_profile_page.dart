import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/profile_model.dart';
import '../providers/profile_providers.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _skillsController = TextEditingController();
  final _toolsController = TextEditingController();
  final _buildingController = TextEditingController();
  final _needController = TextEditingController();
  final _wantToMeetController = TextEditingController();
  final _websiteController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _githubController = TextEditingController();
  final _xController = TextEditingController();

  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _skillsController.dispose();
    _toolsController.dispose();
    _buildingController.dispose();
    _needController.dispose();
    _wantToMeetController.dispose();
    _websiteController.dispose();
    _linkedinController.dispose();
    _githubController.dispose();
    _xController.dispose();
    super.dispose();
  }

  void _setInitialValues(ProfileModel profile) {
    if (_initialized) return;

    _nameController.text = profile.name;
    _roleController.text = profile.role;
    _bioController.text = profile.bio;
    _locationController.text = profile.location;
    _skillsController.text = profile.skills.join(', ');
    _toolsController.text = profile.tools.join(', ');
    _buildingController.text = profile.building;
    _needController.text = profile.need;
    _wantToMeetController.text = profile.wantToMeet;
    _websiteController.text = profile.links['website'] ?? '';
    _linkedinController.text = profile.links['linkedin'] ?? '';
    _githubController.text = profile.links['github'] ?? '';
    _xController.text = profile.links['x'] ?? '';

    _initialized = true;
  }

  List<String> _splitCsv(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Future<void> _save(ProfileModel profile) async {
    final updatedProfile = profile.copyWith(
      name: _nameController.text.trim(),
      role: _roleController.text.trim(),
      bio: _bioController.text.trim(),
      location: _locationController.text.trim(),
      skills: _splitCsv(_skillsController.text),
      tools: _splitCsv(_toolsController.text),
      building: _buildingController.text.trim(),
      need: _needController.text.trim(),
      wantToMeet: _wantToMeetController.text.trim(),
      links: {
        'website': _websiteController.text.trim(),
        'linkedin': _linkedinController.text.trim(),
        'github': _githubController.text.trim(),
        'x': _xController.text.trim(),
      },
    );

    await ref
        .read(profileControllerProvider.notifier)
        .updateProfile(updatedProfile);

    final state = ref.read(profileControllerProvider);

    if (!mounted) return;

    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update profile.')),
      );
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(myProfileProvider);
    final controllerState = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: profileState.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found.'));
          }

          _setInitialValues(profile);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _Field(controller: _nameController, label: 'Name'),
              _Field(controller: _roleController, label: 'Role'),
              _Field(
                controller: _bioController,
                label: 'Bio',
                maxLines: 4,
              ),
              _Field(controller: _locationController, label: 'Location'),
              _Field(
                controller: _skillsController,
                label: 'Skills',
                hint: 'Flutter, Laravel, OpenAI',
              ),
              _Field(
                controller: _toolsController,
                label: 'AI Tools / Tech',
                hint: 'Firebase, ChatGPT, Claude, n8n',
              ),
              _Field(
                controller: _buildingController,
                label: 'What are you building?',
                maxLines: 3,
              ),
              _Field(
                controller: _needController,
                label: 'What do you need?',
                maxLines: 3,
              ),
              _Field(
                controller: _wantToMeetController,
                label: 'Who do you want to meet?',
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              const Text(
                'Links',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _Field(controller: _websiteController, label: 'Website'),
              _Field(controller: _linkedinController, label: 'LinkedIn'),
              _Field(controller: _githubController, label: 'GitHub'),
              _Field(controller: _xController, label: 'X / Twitter'),
              const SizedBox(height: 20),
              FilledButton(
                onPressed:
                    controllerState.isLoading ? null : () => _save(profile),
                child: controllerState.isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Profile'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Text('Unable to load profile.'),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}