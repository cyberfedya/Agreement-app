class Validators {
  const Validators._();

  static bool isNotEmpty(String? value) => value != null && value.trim().isNotEmpty;
}
