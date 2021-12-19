import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
import 'package:rpmlauncher/Model/Game/Instance.dart';
import 'package:rpmlauncher/Model/Game/JvmArgs.dart';
import 'package:rpmlauncher/Model/UI/ViewOptions.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/Theme.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/View/Edit/WorldView.dart';
import 'package:rpmlauncher/View/RowScrollView.dart';
import 'package:rpmlauncher/Widget/Dialog/CheckDialog.dart';
import 'package:rpmlauncher/Widget/DeleteFileWidget.dart';
import 'package:rpmlauncher/Widget/FileSwitchBox.dart';
import 'package:rpmlauncher/View/Edit/ModListView.dart';
import 'package:rpmlauncher/Widget/RPMTW-Design/OkClose.dart';
import 'package:rpmlauncher/View/OptionsView.dart';
import 'package:rpmlauncher/Widget/RPMTW-Design/RPMTextField.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';
import 'package:rpmlauncher/Widget/ShaderpackSourceSelection.dart';
import 'package:rpmlauncher/Widget/WIPWidget.dart';
import 'package:rpmlauncher/Utility/Data.dart';
import 'package:window_size/window_size.dart';

import '../Utility/Utility.dart';
import 'Settings.dart';

class EditInstance extends StatefulWidget {
  final String instanceUUID;
  final bool newWindow;

  const EditInstance({required this.instanceUUID, this.newWindow = false});

  @override
  _EditInstanceState createState() => _EditInstanceState();
}

class _EditInstanceState extends State<EditInstance> {
  late Instance instance;

  String get instanceUUID => widget.instanceUUID;
  Directory get instanceDir => instance.directory;
  InstanceConfig get instanceConfig => instance.config;

  late Directory screenshotDir;
  late Directory resourcePackDir;
  late Directory shaderpackDir;
  late Directory modRootDir;
  late Directory worldRootDir;

  int selectedIndex = 0;

  late int chooseIndex;
  late int javaVersion = instanceConfig.javaVersion;

  TextEditingController nameController = TextEditingController();
  TextEditingController jvmArgsController = TextEditingController();

  late StreamSubscription<FileSystemEvent> screenshotDirEvent;

  late ThemeData theme;
  late Color primaryColor;

  @override
  void initState() {
    instance = Instance.fromUUID(instanceUUID)!;
    setWindowTitle("RPMLauncher - ${instance.name}");
    chooseIndex = 0;
    screenshotDir = InstanceRepository.getScreenshotRootDir(instanceUUID);
    resourcePackDir = InstanceRepository.getResourcePackRootDir(instanceUUID);
    worldRootDir = InstanceRepository.getWorldRootDir(instanceUUID);
    modRootDir = InstanceRepository.getModRootDir(instanceUUID);
    nameController.text = instanceConfig.name;
    shaderpackDir = InstanceRepository.getShaderpackRootDir(instanceUUID);
    if (instanceConfig.javaJvmArgs != null) {
      jvmArgsController.text =
          JvmArgs.fromList(instanceConfig.javaJvmArgs!).args;
    } else {
      jvmArgsController.text = "";
    }

    primaryColor = ThemeUtility.getTheme().colorScheme.primary;

    super.initState();

    Uttily.createFolderOptimization(screenshotDir);
    Uttily.createFolderOptimization(worldRootDir);
    Uttily.createFolderOptimization(resourcePackDir);
    Uttily.createFolderOptimization(shaderpackDir);
    Uttily.createFolderOptimization(modRootDir);

    screenshotDirEvent = screenshotDir.watch().listen((event) {
      if (!screenshotDir.existsSync()) screenshotDirEvent.cancel();
      setState(() {});
    });
  }

  @override
  void dispose() {
    screenshotDirEvent.cancel();
    nameController.dispose();
    jvmArgsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(I18n.format("edit.instance.title")),
          centerTitle: true,
          leading: Builder(builder: (context) {
            if (widget.newWindow) {
              return IconButton(
                icon: Icon(Icons.close),
                tooltip: I18n.format("gui.close"),
                onPressed: () {
                  exit(0);
                },
              );
            } else {
              return IconButton(
                icon: Icon(Icons.arrow_back),
                tooltip: I18n.format("gui.back"),
                onPressed: () {
                  screenshotDirEvent.cancel();
                  navigator.pop();
                },
              );
            }
          }),
        ),
        body: OptionsView(
            gripSize: 3,
            optionWidgets: (_setState) {
              return [
                ListView(
                  children: [
                    SizedBox(
                      height: 150,
                      child: instance.imageWidget,
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                            onPressed: () async {
                              final file = await FileSelectorPlatform.instance
                                  .openFile(acceptedTypeGroups: [
                                XTypeGroup(
                                    label: I18n.format(
                                        "edit.instance.homepage.instance.image.file"),
                                    extensions: ['jpg', 'png', "gif"])
                              ]);
                              if (file == null) return;
                              File(file.path).copySync(
                                  join(instanceDir.absolute.path, "icon.png"));
                            },
                            child: Text(
                              I18n.format(
                                  "edit.instance.homepage.instance.image"),
                              style: TextStyle(fontSize: 18),
                            )),
                      ],
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 12,
                        ),
                        Text(
                          I18n.format("edit.instance.homepage.instance.name"),
                          style: TextStyle(fontSize: 18),
                        ),
                        Expanded(
                          child: RPMTextField(
                            controller: nameController,
                            textAlign: TextAlign.center,
                            hintText: I18n.format(
                                "edit.instance.homepage.instance.enter"),
                            onChanged: (value) {
                              _setState(() {});
                            },
                          ),
                        ),
                        SizedBox(
                          width: 12,
                        ),
                        ElevatedButton(
                            onPressed: () {
                              if (nameController.text.isNotEmpty) {
                                instanceConfig.name = nameController.text;
                              } else {
                                ScaffoldMessenger.of(navigator.context)
                                    .showSnackBar(SnackBar(
                                        behavior: SnackBarBehavior.floating,
                                        margin: EdgeInsets.all(50),
                                        content: I18nText(
                                          "edit.instance.homepage.instance.name.empty",
                                          style: TextStyle(fontFamily: 'font'),
                                        )));
                              }
                              _setState(() {});
                            },
                            child: Text(
                              I18n.format("gui.save"),
                              style: TextStyle(fontSize: 18),
                            )),
                        SizedBox(
                          width: 12,
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Text(
                      I18n.format('edit.instance.homepage.info.title'),
                      style: TextStyle(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    RowScrollView(
                      child: Row(
                        children: [
                          infoCard(I18n.format("game.version"),
                              instanceConfig.version),
                          infoCard(I18n.format("version.list.mod.loader"),
                              instanceConfig.loaderEnum.i18nString),
                          Stack(
                            children: [
                              infoCard(
                                  I18n.format(
                                      'edit.instance.homepage.info.loader.version'),
                                  instanceConfig.loaderVersion ?? "",
                                  show: instanceConfig.loaderEnum !=
                                      ModLoader.vanilla),
                              Positioned(
                                child: IconButton(
                                  onPressed: () {
                                    showDialog(
                                        context: context,
                                        builder: (context) => WiPWidget());
                                  },
                                  icon: Icon(Icons.settings),
                                  iconSize: 25,
                                  tooltip: I18n.format(
                                      'edit.instance.homepage.info.loader.version.change'),
                                ),
                                top: 5,
                                right: 10,
                                // bottom: 10,
                              )
                            ],
                          ),
                          infoCard(
                              I18n.format(
                                  'edit.instance.homepage.info.mod.count'),
                              modRootDir
                                  .listSync()
                                  .where((file) =>
                                      extension(file.path, 2)
                                          .contains('.jar') &&
                                      file is File)
                                  .length
                                  .toString(),
                              show: instanceConfig.loaderEnum !=
                                  ModLoader.vanilla),
                          infoCard(
                              I18n.format(
                                  'edit.instance.homepage.info.play.last'),
                              instanceConfig.lastPlayLocalString),
                          infoCard(
                              I18n.format(
                                  'edit.instance.homepage.info.play.time'),
                              Uttily.formatDuration(Duration(
                                  milliseconds: instanceConfig.playTime))),
                        ],
                      ),
                    )
                  ],
                ),
                ModListView(Instance.fromUUID(instanceUUID)!),
                WorldView(worldRootDir: worldRootDir),
                OptionPage(
                  mainWidget: FutureBuilder(
                    future: screenshotDir.list().toList(),
                    builder: (context,
                        AsyncSnapshot<List<FileSystemEntity>> snapshot) {
                      if (snapshot.hasData) {
                        if (snapshot.data!.isEmpty) {
                          return Center(
                              child: Text(
                            I18n.format('edit.instance.screenshot.found'),
                            style: TextStyle(fontSize: 30),
                          ));
                        }
                        return GridView.builder(
                          itemCount: snapshot.data!.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 5),
                          controller: ScrollController(),
                          itemBuilder: (context, index) {
                            Widget imageWidget = Icon(Icons.image);
                            File imageFile = File(snapshot.data![index].path);
                            try {
                              if (imageFile.existsSync()) {
                                imageWidget = Image.file(imageFile);
                              }
                            } on TypeError {
                              return Container();
                            }
                            return Card(
                              child: InkWell(
                                onTap: () {},
                                onDoubleTap: () {
                                  Uttily.openFileManager(imageFile);
                                  chooseIndex = index;
                                  _setState(() {});
                                },
                                child: GridTile(
                                  child: Column(
                                    children: [
                                      Expanded(child: imageWidget),
                                      Text(imageFile.path
                                          .toString()
                                          .split(Platform.pathSeparator)
                                          .last),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      } else if (snapshot.hasError) {
                        return Center(child: Text("No snapshot found"));
                      } else {
                        return Center(child: RWLLoading());
                      }
                    },
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.folder),
                      onPressed: () {
                        Uttily.openFileManager(screenshotDir);
                      },
                      tooltip: I18n.format('edit.instance.screenshot.folder'),
                    ),
                  ],
                ),
                OptionPage(
                  mainWidget: FutureBuilder(
                    future: shaderpackDir
                        .list()
                        .where(
                            (file) => extension(file.path, 2).contains('.zip'))
                        .toList(),
                    builder: (context,
                        AsyncSnapshot<List<FileSystemEntity>> snapshot) {
                      if (snapshot.hasData) {
                        if (snapshot.data!.isEmpty) {
                          return Center(
                              child: I18nText(
                            "edit.instance.shaderpack.found.not",
                            style: TextStyle(fontSize: 30),
                          ));
                        }
                        return ListView.builder(
                          itemCount: snapshot.data!.length,
                          controller: ScrollController(),
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(basename(snapshot.data![index].path)
                                  .replaceAll('.zip', "")
                                  .replaceAll('.disable', "")),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FileSwitchBox(
                                      file: File(snapshot.data![index].path)),
                                  DeleteFileWidget(
                                      tooltip: I18n.format(
                                          'edit.instance.shaderpack.delete'),
                                      message: I18n.format(
                                          'edit.instance.shaderpack.delete.message'),
                                      onDeleted: () {
                                        setState(() {});
                                      },
                                      fileSystemEntity: snapshot.data![index])
                                ],
                              ),
                            );
                          },
                        );
                      } else if (snapshot.hasError) {
                        return Center(child: Text(snapshot.error.toString()));
                      } else {
                        return Center(child: RWLLoading());
                      }
                    },
                  ),
                  actions: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            showDialog(
                                context: context,
                                builder: (context) =>
                                    ShaderpackSourceSelection(instanceUUID));
                          },
                          tooltip: I18n.format('edit.instance.shaderpack.add'),
                        ),
                        IconButton(
                          icon: Icon(Icons.folder),
                          onPressed: () {
                            Uttily.openFileManager(shaderpackDir);
                          },
                          tooltip:
                              I18n.format('edit.instance.shaderpack.folder'),
                        ),
                      ],
                    )
                  ],
                ),
                Stack(
                  children: [
                    FutureBuilder(
                      future: resourcePackDir
                          .list()
                          .where((file) =>
                              extension(file.path, 2).contains('.zip'))
                          .toList(),
                      builder: (context,
                          AsyncSnapshot<List<FileSystemEntity>> snapshot) {
                        if (snapshot.hasData) {
                          if (snapshot.data!.isEmpty) {
                            return Center(
                                child: I18nText(
                              "edit.instance.resourcepack.found.not",
                              style: TextStyle(fontSize: 30),
                            ));
                          }
                          return ListView.builder(
                            itemCount: snapshot.data!.length,
                            controller: ScrollController(),
                            itemBuilder: (context, index) {
                              File file = File(snapshot.data![index].path);

                              Future<Archive> unzip() async {
                                final bytes = await file.readAsBytes();
                                return ZipDecoder().decodeBytes(bytes);
                              }

                              return FutureBuilder(
                                  future: unzip(),
                                  builder: (context,
                                      AsyncSnapshot<Archive> snapshot) {
                                    if (snapshot.hasData) {
                                      if (snapshot.data!.files.any((_file) =>
                                          _file
                                              .toString()
                                              .startsWith("pack.mcmeta"))) {
                                        Map? packMeta;

                                        try {
                                          packMeta = json.decode(utf8.decode(
                                              snapshot.data!
                                                  .findFile('pack.mcmeta')
                                                  ?.content));
                                        } on FormatException {}

                                        ArchiveFile? packImage =
                                            snapshot.data!.findFile('pack.png');
                                        return DecoratedBox(
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.white12)),
                                          child: InkWell(
                                            onTap: () {
                                              showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    if (packMeta != null) {
                                                      return AlertDialog(
                                                        title: I18nText(
                                                            "edit.instance.resourcepack.info.title",
                                                            textAlign: TextAlign
                                                                .center),
                                                        content: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            I18nText(
                                                              "edit.instance.resourcepack.info.description",
                                                              args: {
                                                                "description":
                                                                    packMeta['pack']
                                                                            [
                                                                            'description'] ??
                                                                        ""
                                                              },
                                                            ),
                                                            I18nText(
                                                              "edit.instance.resourcepack.info.format",
                                                              args: {
                                                                "format": packMeta[
                                                                            'pack']
                                                                        [
                                                                        'pack_format']
                                                                    .toString()
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                        actions: [OkClose()],
                                                      );
                                                    } else {
                                                      return AlertDialog(
                                                          title: I18nText(
                                                              "edit.instance.resourcepack.info.title"),
                                                          content: I18nText(
                                                              "edit.instance.resourcepack.info.none"));
                                                    }
                                                  });
                                            },
                                            child: Column(
                                              children: [
                                                SizedBox(
                                                  height: 8,
                                                ),
                                                ListTile(
                                                  leading: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            50),
                                                    child: packImage == null
                                                        ? Icon(Icons.image)
                                                        : Image.memory(
                                                            packImage.content),
                                                  ),
                                                  title: Text(
                                                      basename(file.path)
                                                          .replaceAll(
                                                              '.zip', "")
                                                          .replaceAll(
                                                              '.disable', "")),
                                                  subtitle: Builder(
                                                      builder: (context) {
                                                    if (packMeta?['pack']
                                                            ['description'] !=
                                                        null) {
                                                      return Text(packMeta![
                                                                  'pack']
                                                              ['description']
                                                          .toString());
                                                    } else {
                                                      return SizedBox();
                                                    }
                                                  }),
                                                  trailing: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      FileSwitchBox(file: file),
                                                      DeleteFileWidget(
                                                          tooltip: I18n.format(
                                                              'edit.instance.resourcepack.info.delete'),
                                                          message: I18n.format(
                                                              'edit.instance.resourcepack.info.delete.message'),
                                                          onDeleted: () {
                                                            setState(() {});
                                                          },
                                                          fileSystemEntity:
                                                              file)
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 8,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      } else {
                                        return Container();
                                      }
                                    } else {
                                      return RWLLoading();
                                    }
                                  });
                            },
                          );
                        } else if (snapshot.hasError) {
                          return Center(child: Text(snapshot.error.toString()));
                        } else {
                          return Center(child: RWLLoading());
                        }
                      },
                    ),
                    Positioned(
                      child: IconButton(
                        icon: Icon(Icons.folder),
                        onPressed: () {
                          Uttily.openFileManager(resourcePackDir);
                        },
                        tooltip: I18n.format(
                            'edit.instance.resourcepack.info.folder'),
                      ),
                      bottom: 10,
                      right: 10,
                    )
                  ],
                ),
                instanceSettings(context),
              ];
            },
            options: () {
              return ViewOptions([
                ViewOption(
                    title: I18n.format("homepage"),
                    icon: Icon(
                      Icons.home_outlined,
                    ),
                    description:
                        I18n.format('edit.instance.homepage.description')),
                ViewOption(
                    title: I18n.format("edit.instance.mods.title"),
                    icon: Icon(
                      Icons.add_box_outlined,
                    ),
                    description: I18n.format('edit.instance.mods.description'),
                    empty: instanceConfig.loaderEnum == ModLoader.vanilla),
                ViewOption(
                  title: I18n.format("edit.instance.world.title"),
                  icon: Icon(
                    Icons.public_outlined,
                  ),
                  description: I18n.format('edit.instance.world.description'),
                ),
                ViewOption(
                    title: I18n.format("edit.instance.screenshot.title"),
                    icon: Icon(
                      Icons.screenshot_outlined,
                    ),
                    description:
                        I18n.format('edit.instance.screenshot.description')),
                ViewOption(
                    title: I18n.format('edit.instance.shaderpack.title'),
                    icon: Icon(
                      Icons.hd,
                    ),
                    description:
                        I18n.format('edit.instance.shaderpack.description')),
                ViewOption(
                    title: I18n.format('edit.instance.resourcepack.title'),
                    icon: Icon(LineIcons.penSquare),
                    description:
                        I18n.format('edit.instance.resourcepack.description')),
                ViewOption(
                    title: I18n.format('edit.instance.settings.title'),
                    icon: Icon(Icons.settings),
                    description:
                        I18n.format('edit.instance.settings.description')),
              ]);
            }));
  }

  ListTile instanceSettings(context) {
    double nowMaxRamMB =
        instanceConfig.javaMaxRam ?? Config.getValue('java_max_ram');
    String? javaPath = instanceConfig.storage["java_path_$javaVersion"];

    TextStyle title_ = TextStyle(
      fontSize: 20.0,
      color: Colors.lightBlue,
    );

    return ListTile(
        title: Column(children: [
      SizedBox(
        height: 20,
      ),
      Row(mainAxisSize: MainAxisSize.min, children: [
        ElevatedButton(
          child: I18nText(
            "edit.instance.settings.global",
            style: TextStyle(fontSize: 20),
          ),
          onPressed: () {
            navigator.pushNamed(SettingScreen.route);
          },
        ),
        SizedBox(
          width: 20,
        ),
        ElevatedButton(
          child: I18nText(
            "edit.instance.settings.reset",
            style: TextStyle(fontSize: 18),
          ),
          onPressed: () {
            showDialog(
                context: context,
                builder: (context) {
                  return CheckDialog(
                    title: I18n.format('edit.instance.settings.reset'),
                    message:
                        I18n.format('edit.instance.settings.reset.message'),
                    onPressedOK: () {
                      instanceConfig.storage
                          .removeItem("java_path_$javaVersion");
                      instanceConfig.javaMaxRam = null;
                      instanceConfig.javaJvmArgs = null;
                      nowMaxRamMB = Config.getValue('java_max_ram');
                      jvmArgsController.text = "";
                      setState(() {});
                      Navigator.pop(context);
                    },
                  );
                });
          },
        ),
      ]),
      SizedBox(
        height: 20,
      ),
      I18nText(
        "edit.instance.settings.title",
        style: TextStyle(color: Colors.red, fontSize: 30),
      ),
      SizedBox(
        height: 25,
      ),
      Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
            ),
            Column(
              children: [
                I18nText(
                  "settings.java.path",
                  style: TextStyle(
                    fontSize: 20.0,
                    color: Colors.lightBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(javaPath ?? I18n.format("gui.default")),
              ],
            ),
            SizedBox(
              width: 12,
            ),
            ElevatedButton(
                onPressed: () {
                  Uttily.openJavaSelectScreen(context).then((value) {
                    if (value[0]) {
                      instanceConfig.storage
                          .setItem("java_path_$javaVersion", value[1]);
                      javaPath = value[1];
                      setState(() {});
                    }
                  });
                },
                child: Text(
                  I18n.format("settings.java.path.select"),
                  style: TextStyle(fontSize: 18),
                )),
          ]),
      FutureBuilder<int>(
          future: Uttily.getTotalPhysicalMemory(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              double ramMB = snapshot.data!.toDouble();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    I18n.format("settings.java.ram.max"),
                    style: title_,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    "${I18n.format("settings.java.ram.physical")} ${ramMB.toStringAsFixed(0)} MB",
                  ),
                  Slider(
                    value: nowMaxRamMB,
                    onChanged: (double value) {
                      instanceConfig.javaMaxRam = value;
                      nowMaxRamMB = value;
                      setState(() {});
                    },
                    min: 1024,
                    max: ramMB,
                    divisions: (ramMB ~/ 1024) - 1,
                    label: "${nowMaxRamMB.toInt()} MB",
                  ),
                ],
              );
            } else {
              return RWLLoading();
            }
          }),
      Text(
        I18n.format('settings.java.jvm.args'),
        style: title_,
        textAlign: TextAlign.center,
      ),
      ListTile(
        title: RPMTextField(
          textAlign: TextAlign.center,
          controller: jvmArgsController,
          onChanged: (value) async {
            instanceConfig.javaJvmArgs = JvmArgs(args: value).toList();
            setState(() {});
          },
        ),
      ),
    ]));
  }

  Widget infoCard(String title, String values, {bool show = true}) {
    if (show) {
      return Stack(children: [
        Card(
          margin: EdgeInsets.all(8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          color: Colors.deepPurpleAccent,
          child: Row(
            children: [
              SizedBox(width: 20),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 20),
                  Text(title,
                      style: TextStyle(fontSize: 20, color: Colors.greenAccent),
                      textAlign: TextAlign.center),
                  Text(values,
                      style: TextStyle(fontSize: 30),
                      textAlign: TextAlign.center),
                  SizedBox(height: 20),
                ],
              ),
              SizedBox(width: 20),
            ],
          ),
        ),
      ]);
    } else {
      return SizedBox.shrink();
    }
  }
}
