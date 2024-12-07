class AuthCredentials {
  final String email;
  final String password;
  final String? username;

  AuthCredentials({
    required this.email,
    required this.password,
    this.username,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'email': email,
      'password': password,
    };
    if (username != null) {
      data['username'] = username;
    }
    return data;
  }
}
