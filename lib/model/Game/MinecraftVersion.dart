import 'package:dio/dio.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:rpmlauncher/launcher/APIs.dart';
import 'package:rpmlauncher/mod/mod_loader.dart';
import 'package:rpmlauncher/model/Game/MinecraftMeta.dart';
import 'package:rpmlauncher/util/RPMHttpClient.dart';
import 'package:rpmlauncher/util/util.dart';

class MCVersionManifest {
  String latestRelease;

  String? latestSnapshot;

  List<MCVersion> versions;

  MCVersionManifest(this.latestRelease, this.versions, {this.latestSnapshot});

  factory MCVersionManifest.fromJson(Map data) {
    return MCVersionManifest(
        data['latest']['release'],
        (data['versions'] as List<dynamic>)
            .map((d) => MCVersion.fromJson(d))
            // TODO: 支援 Minecraft 遠古版本
            .where((version) => version.comparableVersion >= Version(1, 7, 0))
            .toList(),
        latestSnapshot: data['latest']['snapshot']);
  }

  static Future<MCVersionManifest> getVanilla() async {
    Response response =
        await RPMHttpClient().get("$mojangMetaAPI/version_manifest_v2.json");
    return MCVersionManifest.fromJson(response.data);
  }

  static Future<MCVersionManifest> getForge() async {
    MCVersionManifest vanilla = await getVanilla();
    Response response =
        await RPMHttpClient().get("$forgeFilesMainAPI/maven-metadata.json");

    Map data = response.data;
    List<MCVersion> versions = [];

    data.keys.forEach((key) {
      if (vanilla.versions.any((e) => e.id == key)) {
        versions.add(vanilla.versions.firstWhere((e) => e.id == key));
      }
    });

    return MCVersionManifest(
      data.keys.last,
      versions.reversed.toList(),
    );
  }

  static Future<MCVersionManifest> getFabric() async {
    MCVersionManifest vanilla = await getVanilla();
    Response response = await RPMHttpClient().get("$fabricApi/versions/game");

    List<Map> data = response.data.cast<Map>();
    List<MCVersion> versions = [];

    data.forEach((e) {
      if (vanilla.versions.any((e2) => e2.id == e['version'])) {
        versions
            .add(vanilla.versions.firstWhere((e2) => e2.id == e['version']));
      }
    });

    return MCVersionManifest(
        data.firstWhere((e) => e['stable'] == true)['version'], versions,
        latestSnapshot:
            data.firstWhere((e) => e['stable'] == false)['version']);
  }

  static Future<MCVersionManifest> formLoaderType(ModLoader loader) async {
    switch (loader) {
      case ModLoader.forge:
        return getForge();
      case ModLoader.fabric:
        return getFabric();
      case ModLoader.vanilla:
        return getVanilla();
      default:
        return getVanilla();
    }
  }
}

class MCVersion {
  String id;

  MCVersionType type;

  String url;

  String time;

  String releaseTime;

  String sha1;

  int complianceLevel;

  DateTime get timeDateTime => DateTime.parse(time);

  DateTime get releaseDateTime => DateTime.parse(releaseTime);

  Version get comparableVersion => Util.parseMCComparableVersion(id);

  Future<MinecraftMeta> get meta async =>
      MinecraftMeta((await RPMHttpClient().get(url)).data);

  MCVersion(this.id, this.type, this.url, this.time, this.releaseTime,
      this.sha1, this.complianceLevel);

  factory MCVersion.fromJson(Map json) {
    return MCVersion(
        json['id'],
        MCVersionType.values.firstWhere((_) => _.name == json['type']),
        json['url'],
        json['time'],
        json['releaseTime'],
        json['sha1'],
        json['complianceLevel']);
  }
}

enum MCVersionType {
  release,
  snapshot,
  beta,
  alpha,
}

extension MCVersionTypeExtension on MCVersionType {
  String get name {
    switch (this) {
      case MCVersionType.release:
        return 'release';
      case MCVersionType.snapshot:
        return 'snapshot';
      case MCVersionType.beta:
        return 'old_beta';
      case MCVersionType.alpha:
        return 'old_alpha';
    }
  }
}
