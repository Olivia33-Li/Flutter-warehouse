class AppConstants {
  // 生产环境改为你的服务器地址
  // static const String baseUrl = 'http://localhost:3000/api'; // 本地测试
  static const String baseUrl = 'http://43.160.237.65:3000/api'; // 生产服务器
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'current_user';
  /// true = user chose "Remember me"; session persists across restarts.
  static const String rememberMeKey = 'remember_me';
}
