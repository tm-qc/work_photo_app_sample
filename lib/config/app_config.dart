// アプリ全体の設定値を一箇所で管理
// このファイルを変更するだけで、アプリ全体の設定を変更できる

class AppConfig {
  // ==============================================
  // 📱 表示関連の設定
  // ==============================================
  
  /// 未設定時の表示テキスト
  static const String notSetText = '未設定';
  
  /// アプリ名
  static const String appName = 'work_photo_app_sample';
  
  /// アプリ表示名（日本語）
  static const String appDisplayName = '作業写真撮影アプリ';
  
  // ==============================================
  // 🎥 カメラ関連の設定
  // ==============================================
  
  // /// デフォルトのカメラ解像度
  // /// 'low' | 'medium' | 'high' | 'veryHigh'
  // static const String defaultCameraResolution = 'low';
  
  // /// 黒板の初期サイズ
  // static const double defaultBlackboardWidth = 200.0;
  // static const double defaultBlackboardHeight = 150.0;
  
  // /// 黒板の最小・最大サイズ
  // static const double minBlackboardWidth = 200.0;
  // static const double minBlackboardHeight = 150.0;
  // static const double maxBlackboardHeight = 300.0;
  
  // /// リサイズハンドルのサイズ
  // static const double resizeHandleSize = 28.0;
  
  // ==============================================
  // 🔧 アプリ動作の設定
  // ==============================================
  
  // /// ログレベル設定（開発時は true、本番では false）
  // static const bool enableDebugLog = true;
  
  // /// 自動保存の間隔（秒）
  // static const int autoSaveInterval = 30;
  
  // /// 最大リトライ回数
  // static const int maxRetryCount = 3;
  
  // ==============================================
  // 🎨 UI関連の設定
  // ==============================================
  
  // /// デフォルトのテーマカラー
  // static const String primaryColorSeed = 'deepPurple';
  
  // /// ボタンの角の丸み
  // static const double buttonBorderRadius = 0.0; // 四角ボタン
  
  // /// グリッドレイアウトの列数
  // static const int gridColumns = 2;
  
  // /// グリッドの縦横比
  // static const double gridAspectRatio = 0.5;
  
  // ==============================================
  // 📊 データ関連の設定
  // ==============================================
  
  // /// SharedPreferencesのキー名
  // static const String prefsKeyPrefix = 'work_photo_app_';
  
  // /// ファイル保存先のフォルダ名
  // static const String logFolderName = 'logs';
  // static const String photoFolderName = 'photos';
  
  // ==============================================
  // 🌐 将来的にサーバー設定なども追加可能
  // ==============================================
  
  // /// API のベースURL（将来的に追加）
  // static const String apiBaseUrl = 'https://api.example.com';
  
  // /// タイムアウト時間（秒）
  // static const int apiTimeout = 30;
}