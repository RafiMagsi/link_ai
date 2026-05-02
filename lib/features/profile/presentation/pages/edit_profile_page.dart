import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../../../../core/widgets/app_loader.dart';
import '../../../../core/errors/error_handler.dart';
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
  final _lookingForController = TextEditingController();
  final _websiteController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _githubController = TextEditingController();
  final _xController = TextEditingController();
  String _collaborationIntent = 'open_to_collaborate';
  String _projectStage = 'mvp';

  bool _initialized = false;
  final _imagePicker = ImagePicker();
  File? _selectedAvatarFile;
  bool _isSaving = false;

  void _leaveProfilePage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
        return;
      }

      context.go('/feed');
    });
  }

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
    _lookingForController.dispose();
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
    _lookingForController.text = profile.lookingFor.join(', ');
    _websiteController.text = profile.links['website'] ?? '';
    _linkedinController.text = profile.links['linkedin'] ?? '';
    _githubController.text = profile.links['github'] ?? '';
    _xController.text = profile.links['x'] ?? '';
    _collaborationIntent = profile.collaborationIntent;
    _projectStage = profile.projectStage;

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
    if (_isSaving) return;

    // Validate reserved names
    final reservedNames = ['snow', 'admin', 'moderator'];
    final nameLower = _nameController.text.trim().toLowerCase();

    if (reservedNames.contains(nameLower)) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('The name "$nameLower" is reserved and cannot be used.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      String? avatarUrl = profile.avatarUrl;

      if (_selectedAvatarFile != null) {
        try {
          avatarUrl = await ref
              .read(profileControllerProvider.notifier)
              .uploadAvatar(uid: profile.uid, file: _selectedAvatarFile!);

          if (avatarUrl == null) {
            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Unable to upload avatar.'),
                action: SnackBarAction(
                  label: 'Retry',
                  onPressed: () => _save(profile),
                ),
              ),
            );
            return;
          }
        } catch (e) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Avatar upload failed: ${ErrorHandler.getUserFriendlyMessage(e)}',
              ),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () => _save(profile),
              ),
            ),
          );
          return;
        }
      }

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
        collaborationIntent: _collaborationIntent,
        projectStage: _projectStage,
        lookingFor: _splitCsv(_lookingForController.text),
        avatarUrl: avatarUrl,
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
          SnackBar(
            content: Text(
              'Unable to update profile: ${ErrorHandler.getUserFriendlyMessage(state.error)}',
            ),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _save(profile),
            ),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );

      _leaveProfilePage();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update profile: ${ErrorHandler.getUserFriendlyMessage(e)}',
          ),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _save(profile),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (pickedFile == null) return; // User cancelled

      if (!mounted) return;

      setState(() {
        _selectedAvatarFile = File(pickedFile.path);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to pick image: ${ErrorHandler.getUserFriendlyMessage(e)}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(myProfileProvider);
    final controllerState = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _isSaving ? null : _leaveProfilePage,
        ),
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
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: CircleAvatar(
                        radius: 46,
                        backgroundImage: _selectedAvatarFile != null
                            ? FileImage(_selectedAvatarFile!)
                            : profile.avatarUrl != null
                            ? NetworkImage(profile.avatarUrl!) as ImageProvider
                            : null,
                        child:
                            _selectedAvatarFile == null &&
                                profile.avatarUrl == null
                            ? const Icon(Icons.camera_alt, size: 30)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _pickAvatar,
                      child: const Text('Change Avatar'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Field(controller: _nameController, label: 'Name'),
              _Field(controller: _roleController, label: 'Role'),
              _Field(controller: _bioController, label: 'Bio', maxLines: 4),
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
              const SizedBox(height: 8),
              _DropdownField<String>(
                label: 'Collaboration intent',
                value: _collaborationIntent,
                items: const [
                  DropdownMenuItem(
                    value: 'open_to_collaborate',
                    child: Text('Open to collaborate'),
                  ),
                  DropdownMenuItem(value: 'hiring', child: Text('Hiring')),
                  DropdownMenuItem(
                    value: 'looking_for_cofounder',
                    child: Text('Looking for cofounder'),
                  ),
                  DropdownMenuItem(
                    value: 'open_to_consulting',
                    child: Text('Open to consulting'),
                  ),
                  DropdownMenuItem(
                    value: 'not_looking',
                    child: Text('Not looking right now'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _collaborationIntent = value);
                },
              ),
              _DropdownField<String>(
                label: 'Project stage',
                value: _projectStage,
                items: const [
                  DropdownMenuItem(value: 'idea', child: Text('Idea')),
                  DropdownMenuItem(value: 'mvp', child: Text('MVP')),
                  DropdownMenuItem(value: 'launched', child: Text('Launched')),
                  DropdownMenuItem(value: 'growing', child: Text('Growing')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _projectStage = value);
                },
              ),
              _Field(
                controller: _lookingForController,
                label: 'Looking for',
                hint: 'Engineer, Designer, Growth, Feedback',
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
                onPressed: controllerState.isLoading || _isSaving
                    ? null
                    : () => _save(profile),
                child: controllerState.isLoading || _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Profile'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _isSaving ? null : _leaveProfilePage,
                child: const Text('Cancel'),
              ),
            ],
          );
        },
        loading: () => const Center(child: AppLoader()),
        error: (error, stackTrace) =>
            const Center(child: Text('Unable to load profile.')),
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

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            isExpanded: true,
            value: value,
            items: items,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
