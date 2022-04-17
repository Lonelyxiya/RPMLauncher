import 'dart:io';

import 'package:rpmlauncher/launcher/InstanceRepository.dart';
import 'package:rpmlauncher/mod/CurseForge/Handler.dart';
import 'package:rpmlauncher/model/Game/Instance.dart';
import 'package:rpmlauncher/model/Game/ModInfo.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:rpmlauncher/util/util.dart';
import 'package:rpmlauncher/widget/CurseForgeModVersion.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/widget/rpmtw_design/RPMTextField.dart';
import 'package:rpmlauncher/widget/RWLLoading.dart';

class _CurseForgeModState extends State<CurseForgeMod> {
  late TextEditingController searchController;
  late ScrollController modScrollController;

  List beforeModList = [];
  bool isReset = true;
  int index = 20;

  Directory get modDir => InstanceRepository.getModRootDir(widget.instanceUUID);
  late InstanceConfig instanceConfig;
  List<String> sortItems = [
    I18n.format("edit.instance.mods.sort.curseforge.featured"),
    I18n.format("edit.instance.mods.sort.curseforge.popularity"),
    I18n.format("edit.instance.mods.sort.curseforge.update"),
    I18n.format("edit.instance.mods.sort.curseforge.name"),
    I18n.format("edit.instance.mods.sort.curseforge.author"),
    I18n.format("edit.instance.mods.sort.curseforge.downloads")
  ];
  String sortItem =
      I18n.format("edit.instance.mods.sort.curseforge.popularity");

  @override
  void initState() {
    searchController = TextEditingController();
    modScrollController = ScrollController();
    instanceConfig = InstanceRepository.instanceConfig(widget.instanceUUID)!;

    super.initState();

    modScrollController.addListener(() {
      if ((modScrollController.position.maxScrollExtent -
              modScrollController.position.pixels) <
          50) {
        //如果快要滑動到底部
        index = index + 20;
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Column(
        children: [
          Text(I18n.format("edit.instance.mods.download.curseforge"),
              textAlign: TextAlign.center),
          const SizedBox(
            height: 20,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(I18n.format("edit.instance.mods.download.search")),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                  child: RPMTextField(
                textAlign: TextAlign.center,
                controller: searchController,
                hintText:
                    I18n.format("edit.instance.mods.download.search.hint"),
              )),
              const SizedBox(
                width: 12,
              ),
              ElevatedButton(
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(Colors.deepPurpleAccent)),
                onPressed: () {
                  setState(() {
                    isReset = true;
                    beforeModList = [];
                  });
                },
                child: Text(I18n.format("gui.search")),
              ),
              const SizedBox(
                width: 12,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(I18n.format("edit.instance.mods.sort")),
                  DropdownButton<String>(
                    value: sortItem,
                    onChanged: (String? newValue) {
                      setState(() {
                        sortItem = newValue!;
                        isReset = true;
                        beforeModList = [];
                      });
                    },
                    items:
                        sortItems.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          textAlign: TextAlign.center,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
      content: SizedBox(
        height: MediaQuery.of(context).size.height / 2,
        width: MediaQuery.of(context).size.width / 2,
        child: FutureBuilder(
            future: CurseForgeHandler.getModList(
                instanceConfig.version,
                instanceConfig.loader,
                searchController,
                beforeModList,
                isReset ? 0 : index,
                sortItems.indexOf(sortItem)),
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                isReset = false;
                if (snapshot.data.isEmpty) {
                  return I18nText("mods.filter.notfound",
                      style: const TextStyle(fontSize: 30),
                      textAlign: TextAlign.center);
                }
                beforeModList = snapshot.data;
                return ListView.builder(
                  controller: modScrollController,
                  shrinkWrap: true,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (BuildContext context, int index) {
                    Map data = snapshot.data[index];
                    String modName = data["name"];
                    String modDescription = data["summary"];
                    int curseID = data["id"];
                    String pageUrl = data["websiteUrl"];

                    return ListTile(
                      leading: CurseForgeHandler.getAddonIconWidget(
                          data['attachments']),
                      title: Text(modName),
                      subtitle: Text(modDescription),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () async {
                              Util.openUri(pageUrl);
                            },
                            icon: const Icon(Icons.open_in_browser),
                            tooltip:
                                I18n.format("edit.instance.mods.page.open"),
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return CurseForgeModVersion(
                                    curseID: curseID,
                                    modDir: modDir,
                                    instanceConfig: instanceConfig,
                                    modInfos: widget.modInfos,
                                  );
                                },
                              );
                            },
                            child: Text(I18n.format("gui.install")),
                          ),
                        ],
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(
                                  I18n.format("edit.instance.mods.list.name") +
                                      modName,
                                  textAlign: TextAlign.center),
                              content: Text(
                                  I18n.format(
                                          "edit.instance.mods.list.description") +
                                      modDescription,
                                  textAlign: TextAlign.center),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              } else {
                return const Center(child: RWLLoading());
              }
            }),
      ),
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.close_sharp),
          tooltip: I18n.format("gui.close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class CurseForgeMod extends StatefulWidget {
  final String instanceUUID;
  final List<ModInfo> modInfos;

  const CurseForgeMod(this.instanceUUID, this.modInfos);
  @override
  State<CurseForgeMod> createState() => _CurseForgeModState();
}