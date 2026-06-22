/// Identity passed to the JWT auth handler when a token is requested.
class IterableAuthRequest {
  IterableAuthRequest({this.email, this.userId});

  final String? email;
  final String? userId;

  factory IterableAuthRequest.fromMap(Map<String, dynamic> map) {
    return IterableAuthRequest(
      email: map['email'] as String?,
      userId: map['userId'] as String?,
    );
  }
}
