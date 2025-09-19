import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

import 'package:aroosi_flutter/core/toast_service.dart';

class AppPermissions {
  AppPermissions._();

  static Future<bool> ensurePhotoAccess() async {
    if (Platform.isAndroid) {
      final status = await Permission.photos.status;
      if (status.isGranted) return true;
      final req = await Permission.photos.request();
      if (req.isGranted) return true;
      if (req.isPermanentlyDenied) {
        _promptSettings('photo library');
      }
      return false;
    }
    if (Platform.isIOS) {
      final status = await Permission.photos.status;
      if (status.isGranted) return true;
      final req = await Permission.photos.request();
      if (req.isGranted) return true;
      if (req.isPermanentlyDenied) {
        _promptSettings('photo library');
      }
      return false;
    }
    return true;
  }

  static Future<bool> ensureCamera() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    final req = await Permission.camera.request();
    if (req.isGranted) return true;
    if (req.isPermanentlyDenied) {
      _promptSettings('camera');
    }
    return false;
  }

  static Future<bool> ensureMicrophone() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    final req = await Permission.microphone.request();
    if (req.isGranted) return true;
    if (req.isPermanentlyDenied) {
      _promptSettings('microphone');
    }
    return false;
  }

  static void _promptSettings(String permissionName) {
    ToastService.instance.warning(
      'Enable $permissionName access in Settings to continue.',
    );
    openAppSettings();
  }
}


