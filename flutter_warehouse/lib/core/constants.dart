class AppConstants {
  // 生产环境改为你的服务器地址
  static const String baseUrl = 'http://localhost:3000/api'; // Chrome开发用localhost，Android模拟器改为10.0.2.2

  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'current_user';
  /// true = user chose "Remember me"; session persists across restarts.
  static const String rememberMeKey = 'remember_me';
}
