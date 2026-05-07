import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

enum MediaPermissionTarget { galleryImages, galleryVideos, camera }

class MediaPermissionService {
  const MediaPermissionService();

  Future<bool> request(MediaPermissionTarget target) async {
    final permission = permissionFor(target);
    final status = await permission.status;

    if (status.isGranted || status.isLimited) {
      return true;
    }

    final result = await permission.request();
    return result.isGranted || result.isLimited;
  }

  Future<PermissionStatus> status(MediaPermissionTarget target) {
    return permissionFor(target).status;
  }

  Permission permissionFor(MediaPermissionTarget target) {
    if (Platform.isIOS) {
      switch (target) {
        case MediaPermissionTarget.galleryImages:
        case MediaPermissionTarget.galleryVideos:
          return Permission.photos;
        case MediaPermissionTarget.camera:
          return Permission.camera;
      }
    }

    if (Platform.isAndroid) {
      switch (target) {
        case MediaPermissionTarget.galleryImages:
          return Permission.photos;
        case MediaPermissionTarget.galleryVideos:
          return Permission.videos;
        case MediaPermissionTarget.camera:
          return Permission.camera;
      }
    }

    switch (target) {
      case MediaPermissionTarget.galleryImages:
      case MediaPermissionTarget.galleryVideos:
        return Permission.storage;
      case MediaPermissionTarget.camera:
        return Permission.camera;
    }
  }
}
