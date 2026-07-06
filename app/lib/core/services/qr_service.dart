abstract class QrService {
  Future<String> generate(String data);
  Future<String?> scan();
}
