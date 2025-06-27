import 'dart:async';  // TimeoutException用
import 'package:geolocator/geolocator.dart';
import '../../utils/global_logger.dart';

/// GPS情報の取得を担当するサービスクラス
///
/// 【利用想定】
/// ViewModelから呼び出される
/// カメラ撮影時のGPS情報取得を主な用途とする
class GpsService {

  // ==============================================
  // 📍 GPS情報取得
  // ==============================================

  /// 現在のGPS位置を安全に取得
  ///
  /// 【戻り値】
  /// Position?: 取得成功時は位置情報、失敗時はnull
  ///
  /// 【エラー対応】
  /// - 権限なし → 権限要求
  /// - GPS無効 → ログ出力してnull返却
  /// - タイムアウト → ログ出力してnull返却
  Future<Position?> getCurrentPosition() async {
    try {
      // 1. スマホの設定で位置情報サービスが有効かチェック
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // TODO：位置情報サービスが無効な場合は、ユーザーに通知して終了にする
        print('位置情報サービスが無効です。設定でONにしてください。');
        return null;
      }

      // 2. 位置情報がアプリに許可されてるか権限をチェック
      LocationPermission permission = await Geolocator.checkPermission();
      
      // 権限が拒否されている場合は権限要求
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        
        // それでも権限要求拒否された場合は終了(1回拒否した場合は、再度権限要求のアラートは出る)
          print('位置情報の権限が拒否されました');
          return null;
      }
      
      // 永続的に拒否された場合は設定画面への案内(2回目以降の権限要求は出ない)
      if (permission == LocationPermission.deniedForever) {
        print('位置情報の権限が永続的に拒否されています。設定画面で許可してください。');
        return null;
      }

      // 3. 現在位置を取得
      // 
      // LocationAccuracy(位置精度)について
      // 
      // 基本的にGPSはざっくりしかとれない、時間をかける、何回も取得するなど取得制度は運任せ前提らしい
      // GoogleMapなどは大企業で費用かけて研究しまくってるらしい
      // 
      // ※精度について:Androidのhighで0mから100m以内の精度です。
      // これが最高精度っぽい。
      // LocationAccuracyの定義ファイル。/AppData/Local/Pub/Cache/hosted/pub.dev/geolocator_platform_interface-4.2.6/lib/src/enums/location_accuracy.dartに書いてあった
      // 
      // 取れる情報の制御について
      // 現状LocationAccuracy.bestだと、±5-25mらしいが、現状都道府県市区町村までしかとれないっぽい？(動作確認場所が室内だから？)
      // ただ、いつどこまで情報がとれるか不安定なのがGPSなので、出力情報は自作でメソッド作成して制御しないといけないらしい
      // （信じられないけど、これが一般的みたい）
      // 
      // 室内ではGPS電波が届かないため、以下のような代替手段で位置推定を試みるらしい
      // 1. WiFi測位（WiFiアクセスポイントのデータベース使用:±30-200m）
      // 2. 携帯基地局測位（携帯電話の基地局使用:±200m-2km）  
      // 3. Bluetooth測位（Bluetoothビーコン使用、限定的:±1-5km）
      // 
      // LocationSettingsの制御オプション一覧
      // 
      // LocationAccuracy(精度制御):上記参照
      // distanceFilter（距離フィルター）:0なら即座に取得（デフォルト）、10なら10m移動したら取得
      // timeLimit（タイムアウト制御）:指定時間内に取得できなければタイムアウト
      // 
      // 取れる情報の項目について
      // ==============================================
      // 📍 位置情報系
      // ==============================================
      // - latitude(緯度): 必須 - 撮影場所の特定、地図表示、法的記録
      // - longitude(経度): 必須 - 撮影場所の特定、地図表示、法的記録
      // - altitude(高度): 推奨 - 山間部作業、ビル階層記録、3D位置情報
      // - accuracy(水平精度): 推奨 - 位置記録の信頼性、再撮影判断
      // - altitudeAccuracy(高度精度): 推奨 - 高度情報の信頼性
      // ==============================================
      // ⏰ 時刻情報系
      // ==============================================
      // - timestamp(GPS取得時刻): 必須 - 正確な作業時刻記録、改ざん防止
      // ==============================================
      // 🧭 移動・方向系
      // ==============================================
      // - speed(移動速度): 不要 - 車載カメラ用、作業現場では不要
      // - heading(移動方向): 不要 - 風景撮影用、黒板で方向は十分
      // - headingAccuracy(方向精度): 不要 - 方向情報の精度、作業現場では不要
      // - speedAccuracy(速度精度): 不要 - 速度情報の精度、作業現場では不要
      // - course(進行方向): 不要 - iOS専用、移動方向情報、作業現場では不要
      // - courseAccuracy(進行方向精度): 不要 - iOS専用、進行方向の精度
      // ==============================================
      // 🛰️ 衛星・システム情報系
      // ==============================================
      // - satelliteCount(衛星数): 参考 - Android専用、技術的診断用
      // - satellitesUsedInFix(測位使用衛星数): 参考 - Android専用、技術的診断用
      // - provider(位置情報プロバイダ): 参考 - Android専用、GPS/Network/Passive等
      // - isMocked(偽装GPS判定): 重要 - GPS偽装アプリ検出、記録の信頼性
      // - isFromMockProvider(モックプロバイダ判定): 重要 - Android専用、偽装検出の補助
      // ==============================================
      // 🏢 建物・階層系
      // ==============================================
      // - floor(階層情報): 限定的 - 屋内測位、ビル内作業（対応端末少ない）
      // ==============================================
      // 🔧 システム内部情報
      // ==============================================
      // - hashCode(オブジェクト識別子): 不要 - プログラム内部用、記録には不要
      // - runtimeType(オブジェクト型): 不要 - プログラム内部用、記録には不要
      // 
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,  // Android最高精度 0~100m
          distanceFilter: 0,                // 距離フィルタなし
        ),
      ).timeout(Duration(seconds: 10));     // タイムアウト設定

      // 4. 取得成功のログ出力
      print('GPS取得成功: 緯度=${position.latitude.toStringAsFixed(6)}, '
              '経度=${position.longitude.toStringAsFixed(6)}, '
              '精度=${position.accuracy.toStringAsFixed(1)}m');
      
      return position;

    } catch (e) {
      // エラーの種類別ハンドリング
      // TimeoutExceptionは、非同期処理がタイムアウト（時間切れ）した時に発生する例外
      // TODO:エラー対応は権限許可されないパターンも含め、あとで検討する
      if (e is TimeoutException) {
        print('GPS取得がタイムアウトしました（10秒経過）');
      } else if (e is LocationServiceDisabledException) {
        print('位置情報サービスが無効です');
      } else if (e is PermissionDeniedException) {
        print('位置情報の権限がありません');
      } else {
        logger.e('GPS取得で予期しないエラーが発生: $e');
      }
      
      return null;
    }
  }

  /// 前回取得した位置情報を優先して高速取得
  ///
  /// 【用途】
  /// - 連続撮影時の高速化
  /// - キャッシュされた位置情報の活用
  ///
  /// 【戻り値】
  /// Position?: キャッシュまたは新規取得の位置情報
  ///
  /// 【動作】
  /// 1時間以内のキャッシュがあれば使用、なければ新規取得
  /// 
  /// TODO: キャッシュの有効期限は1時間に設定されてるが、不整合にならないか？さじ加減が難しいので使うか未定
  Future<Position?> getLastKnownOrCurrentPosition() async {
    try {
      // 1. 前回の位置情報を取得（高速）
      Position? lastPosition = await Geolocator.getLastKnownPosition(
        forceAndroidLocationManager: false,
      );
      
      if (lastPosition != null) {
        // 前回の位置情報が1時間以内なら使用
        Duration timeDiff = DateTime.now().difference(lastPosition.timestamp);
        if (timeDiff.inHours < 1) {
          logger.i('キャッシュされた位置情報を使用: 緯度=${lastPosition.latitude.toStringAsFixed(6)}, '
                  '経度=${lastPosition.longitude.toStringAsFixed(6)}');
          return lastPosition;
        }
      }
      
      // 2. キャッシュが古いか存在しない場合は新規取得
      logger.i('新しい位置情報を取得中...');
      return await getCurrentPosition();
      
    } catch (e) {
      logger.e('位置情報取得エラー: $e');
      return null;
    }
  }

  // ==============================================
  // 🔧 ユーティリティメソッド
  // ==============================================

  /// GPS座標を人間が読みやすい文字列に変換
  ///
  /// 【用途】
  /// - デバッグ表示
  /// - ログ出力
  /// - UI表示用
  ///
  /// 【引数】
  /// position: 変換対象の位置情報
  ///
  /// 【戻り値】
  /// String: "緯度: 35.6762, 経度: 139.6503, 精度: 5.0m"
  String formatPosition(Position position) {
    return '緯度: ${position.latitude.toStringAsFixed(4)}, '
          '経度: ${position.longitude.toStringAsFixed(4)}, '
          '精度: ${position.accuracy.toStringAsFixed(1)}m';
  }

  /// 2つの座標間の距離を計算（メートル）
  ///
  /// 【用途】
  /// - 撮影位置の比較
  /// - 移動距離の計算
  ///
  /// 【引数】
  /// startLatitude: 開始点の緯度
  /// startLongitude: 開始点の経度  
  /// endLatitude: 終了点の緯度
  /// endLongitude: 終了点の経度
  ///
  /// 【戻り値】
  /// double: 距離（メートル）
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// 位置情報サービスの状態をチェック
  ///
  /// 【用途】
  /// - GPS取得前の事前チェック
  /// - エラー原因の特定
  ///
  /// 【戻り値】
  /// Map<String, dynamic>: GPS関連の状態情報
  Future<Map<String, dynamic>> getGpsStatus() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      
      return {
        'serviceEnabled': serviceEnabled,
        'permission': permission.toString(),
        'hasPermission': permission == LocationPermission.always || 
                        permission == LocationPermission.whileInUse,
      };
    } catch (e) {
      logger.e('GPS状態取得エラー: $e');
      return {
        'serviceEnabled': false,
        'permission': 'unknown',
        'hasPermission': false,
        'error': e.toString(),
      };
    }
  }
}