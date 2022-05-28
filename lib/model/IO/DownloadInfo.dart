import 'dart:collection';

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:quiver/iterables.dart';
import 'package:rpmlauncher/launcher/CheckData.dart';
import 'package:rpmlauncher/launcher/InstallingState.dart';
import 'package:rpmlauncher/util/Logger.dart';
import 'package:rpmlauncher/util/RPMHttpClient.dart';
import 'package:rpmlauncher/util/data.dart';

class DownloadInfos extends IterableBase<DownloadInfo> {
  /// 一個下載資訊列表的類別
  /// [infos] 下載資訊列表
  /// [progress] 下載進度，如果尚未開始下載則為 0.0
  /// [downloading] 是否正在下載檔案中

  List<DownloadInfo> infos;
  double progress = 0.0;
  bool downloading = false;

  DownloadInfos(this.infos);

  factory DownloadInfos.empty() {
    return DownloadInfos([]);
  }

  /// 下載所有檔案
  Future<void> downloadAll(
      {Function(double progress)? onReceiveProgress,
      Function(double progress)? onAllDownloading,
      int max = 10}) async {
    downloading = true;

    int count = infos.length;
    int done = 0;

    await _downloadAsync(
        onDone: () {
          done++;
          progress = done / count;
          onReceiveProgress?.call(progress);
        },
        onDownloading: (progress) => onAllDownloading?.call(progress),
        max: max);
    infos.clear();

    downloading = false;
  }

  /// 異步下載檔案
  /// [max] 最多同時執行幾個異步函數
  Future<void> _downloadAsync(
      {Function? onDone,
      Function(double progress)? onDownloading,
      int max = 10}) async {
    List<List<DownloadInfo>> queueInfos = partition(infos, max).toList();

    for (List<DownloadInfo> infos in queueInfos) {
      await Future.wait(infos.map((e) => e
          .download(onDownloading: (progress) => onDownloading?.call(progress))
          .whenComplete(() => onDone?.call())));
    }
  }

  void add(DownloadInfo value) {
    return infos.add(value);
  }

  @override
  Iterator<DownloadInfo> get iterator => infos.iterator;
}

class DownloadInfo {
  /// [hashCheck] 是否檢查雜湊值檔案完整性
  /// [sh1Hash] Sh1 雜湊值，用於檢測檔案完整性
  /// [mo5Hash] Sh1 雜湊值，用於檢測檔案完整性

  final String? title;
  final String savePath;
  final String downloadUrl;
  final String? description;
  final bool hashCheck;
  final String? sh1Hash;
  final Function? onDownloaded;

  Uri get downloadUri => Uri.parse(downloadUrl);
  File get file => File(savePath);
  double progress = double.nan;

  /// 下載檔案
  Future<void> download({Function(double progress)? onDownloading}) async {
    if (description != null) {
      installingState.nowEvent = description!;
    }
    bool notNeedDownload = hashCheck &&
        file.existsSync() &&
        sh1Hash != null &&
        CheckData.checkSha1Sync(file, sh1Hash!);

    if (!notNeedDownload) {
      try {
        List<int> bytes = (await RPMHttpClient().get(downloadUrl,
                onReceiveProgress: (int count, int total) {
          progress = count / total;
          onDownloading?.call(progress);
        }, options: Options(responseType: ResponseType.bytes)))
            .data as List<int>;
        File file = File(savePath);
        file.createSync(recursive: true);
        file.writeAsBytesSync(bytes);
      } catch (error, stackTrace) {
        logger.error(ErrorType.download, error, stackTrace: stackTrace);
      }
    }
    onDownloaded?.call();
  }

  DownloadInfo(this.downloadUrl,
      {this.title,
      this.hashCheck = false,
      this.sh1Hash,
      this.onDownloaded,
      this.description,
      required this.savePath});
}
