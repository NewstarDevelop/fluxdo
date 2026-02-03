import 'package:dio/dio.dart';
import 'package:ota_update/ota_update.dart';

import 'update_service.dart';

/// APK 下载状态
enum ApkDownloadStatus {
  idle,
  downloading,
  verifying,
  installing,
  completed,
  error,
}

/// APK 下载进度
class ApkDownloadProgress {
  final ApkDownloadStatus status;
  final int progress; // 0-100
  final String? error;

  ApkDownloadProgress({
    required this.status,
    this.progress = 0,
    this.error,
  });
}

/// APK 下载安装服务
class ApkDownloadService {
  final Dio _dio;
  bool _cancelled = false;

  ApkDownloadService({Dio? dio}) : _dio = dio ?? Dio();

  /// 下载并安装 APK
  ///
  /// 返回进度 Stream
  Stream<ApkDownloadProgress> downloadAndInstall(ApkAsset asset) async* {
    _cancelled = false;

    // 阶段 1：获取 SHA256 校验和（如果有）
    String? expectedSha256;
    if (asset.sha256Url != null) {
      yield ApkDownloadProgress(
        status: ApkDownloadStatus.verifying,
        progress: 0,
      );

      try {
        expectedSha256 = await _fetchSha256Checksum(asset.sha256Url!);
      } catch (e) {
        // SHA256 获取失败不影响下载
      }
    }

    if (_cancelled) return;

    // 阶段 2：使用 ota_update 下载并安装 APK
    yield ApkDownloadProgress(
      status: ApkDownloadStatus.downloading,
      progress: 0,
    );

    try {
      final otaEvent = OtaUpdate().execute(
        asset.downloadUrl,
        destinationFilename: asset.name,
        sha256checksum: expectedSha256,
      );

      await for (final event in otaEvent) {
        if (_cancelled) {
          return;
        }

        switch (event.status) {
          case OtaStatus.DOWNLOADING:
            final progress = int.tryParse(event.value ?? '0') ?? 0;
            yield ApkDownloadProgress(
              status: ApkDownloadStatus.downloading,
              progress: progress,
            );
            break;

          case OtaStatus.INSTALLING:
            yield ApkDownloadProgress(
              status: ApkDownloadStatus.installing,
              progress: 100,
            );
            break;

          case OtaStatus.ALREADY_RUNNING_ERROR:
            yield ApkDownloadProgress(
              status: ApkDownloadStatus.error,
              error: '已有下载任务正在进行',
            );
            break;

          case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
            yield ApkDownloadProgress(
              status: ApkDownloadStatus.error,
              error: '未授予安装权限，请在设置中允许安装未知应用',
            );
            break;

          case OtaStatus.INTERNAL_ERROR:
            yield ApkDownloadProgress(
              status: ApkDownloadStatus.error,
              error: event.value ?? '下载安装过程中发生内部错误',
            );
            break;

          case OtaStatus.DOWNLOAD_ERROR:
            yield ApkDownloadProgress(
              status: ApkDownloadStatus.error,
              error: '下载失败: ${event.value ?? '未知错误'}',
            );
            break;

          case OtaStatus.CHECKSUM_ERROR:
            yield ApkDownloadProgress(
              status: ApkDownloadStatus.error,
              error: '文件校验失败，下载的文件可能已损坏',
            );
            break;

          case OtaStatus.INSTALLATION_DONE:
            yield ApkDownloadProgress(
              status: ApkDownloadStatus.completed,
              progress: 100,
            );
            break;

          case OtaStatus.INSTALLATION_ERROR:
            yield ApkDownloadProgress(
              status: ApkDownloadStatus.error,
              error: '安装失败: ${event.value ?? '未知错误'}',
            );
            break;

          case OtaStatus.CANCELED:
            // 用户取消，不需要额外处理
            return;
        }
      }
    } catch (e) {
      yield ApkDownloadProgress(
        status: ApkDownloadStatus.error,
        error: '下载失败: $e',
      );
    }
  }

  /// 获取 SHA256 校验和
  Future<String?> _fetchSha256Checksum(String url) async {
    try {
      final response = await _dio.get<String>(url);
      if (response.statusCode == 200 && response.data != null) {
        // SHA256 文件格式通常为："hash  filename" 或仅 "hash"
        final content = response.data!.trim();
        final parts = content.split(RegExp(r'\s+'));
        return parts.first;
      }
    } catch (e) {
      // 忽略获取 SHA256 失败
    }
    return null;
  }

  /// 取消下载
  void cancelDownload() {
    _cancelled = true;
  }
}
