import 'package:permission_handler/permission_handler.dart';

abstract class PermissionService {
  Future<bool> requestMicrophone();
  Future<bool> requestCamera();
}

class DevicePermissionService implements PermissionService {
  @override
  Future<bool> requestMicrophone() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  @override
  Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }
}
