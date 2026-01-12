enum AuthStatus { initial, loading, authenticated, error }

class LoginState {
  final AuthStatus status;
  final String? errorMessage;
  final String? userRole;

  LoginState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.userRole,
  });

  // Helper to create new state instances
  LoginState copyWith({
    AuthStatus? status,
    String? errorMessage,
    String? userRole,
  }) {
    return LoginState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      userRole: userRole ?? this.userRole,
    );
  }
}