import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpmlauncher/Screen/About.dart';
import 'package:rpmlauncher/Screen/Account.dart';
import 'package:rpmlauncher/Screen/CurseForgeModPack.dart';
import 'package:rpmlauncher/Screen/FTBModPack.dart';
import 'package:rpmlauncher/Screen/Settings.dart';
import 'package:rpmlauncher/Screen/VersionSelection.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/LauncherInfo.dart';

import 'TestUttily.dart';

void main() async {
  setUpAll(() => TestUttily.init());

  group("RPMLauncher Screen Test -", () {
    testWidgets('Settings Screen', (WidgetTester tester) async {
      await TestUttily.baseTestWidget(tester, SettingScreen());

      expect(find.text(I18n.format("settings.title")), findsOneWidget);

      final Finder appearancePage =
          find.text(I18n.format("settings.appearance.title"));

      await tester.tap(appearancePage);
      await tester.pumpAndSettle();

      expect(
          find.text(I18n.format("settings.appearance.theme")), findsOneWidget);
    }, variant: TestUttily.targetPlatformVariant);
    testWidgets('About Screen', (WidgetTester tester) async {
      await TestUttily.baseTestWidget(tester, AboutScreen());

      final Finder showLicense = find.byIcon(Icons.book_outlined);

      await tester.tap(showLicense);
      await tester.pumpAndSettle();

      expect(find.text(LauncherInfo.getUpperCaseName()), findsOneWidget);
      expect(find.text(LauncherInfo.getVersion()), findsOneWidget);
      expect(find.text("Powered by Flutter"), findsOneWidget);
    }, variant: TestUttily.targetPlatformVariant);
    testWidgets('Account Screen', (WidgetTester tester) async {
      await TestUttily.baseTestWidget(tester, AccountScreen(), async: true);
      await tester.pumpAndSettle();

      final Finder mojangLogin =
          find.text(I18n.format('account.add.mojang.title'));

      expect(mojangLogin, findsOneWidget);

      await tester.tap(mojangLogin);
      await tester.pumpAndSettle();

      expect(find.text(I18n.format('account.mojang.title')), findsOneWidget);
    }, variant: TestUttily.targetPlatformVariant);
    testWidgets('VersionSelection Screen', (WidgetTester tester) async {
      await TestUttily.baseTestWidget(tester, VersionSelection(), async: true);
      expect(find.text("1.17.1"), findsOneWidget);
    }, variant: TestUttily.targetPlatformVariant);
    testWidgets('CurseForge ModPack Screen', (WidgetTester tester) async {
      await TestUttily.baseTestWidget(tester, CurseForgeModPack(), async: true);

      final Finder modPack = find.text("SkyFactory 4");

      expect(modPack, findsOneWidget);

      await tester.tap(modPack);
      await tester.pumpAndSettle();

      expect(
          find.text(
              "The ultimate skyblock modpack! Watch development at: darkosto.tv/SkyFactoryLive"),
          findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      final Finder installButton = find.text(I18n.format("gui.install"));
      expect(installButton, findsWidgets);
      await tester.tap(installButton.first);

      /// TODO: Install ModPack
    }, variant: TestUttily.targetPlatformVariant);

    testWidgets('Add Vanilla 1.17.1 Instance', (WidgetTester tester) async {
      await TestUttily.baseTestWidget(tester, VersionSelection(), async: true);

      final Finder versionText = find.text("1.17.1");

      await tester.tap(versionText);

      await tester.pumpAndSettle();

      final Finder confirm = find.text(I18n.format("gui.confirm"));
      expect(confirm, findsOneWidget);
      expect(find.text(I18n.format("gui.cancel")), findsOneWidget);

      await tester.tap(confirm);

      // TODO: Add Vanilla 1.17.1 Instance

      // await TestUttily.pumpAndSettle(tester);
    }, variant: TestUttily.targetPlatformVariant, skip: true);

    testWidgets('FTB ModPack Screen', (WidgetTester tester) async {
      await TestUttily.baseTestWidget(tester, FTBModPack(), async: true);

      expect(find.text("FTB Presents Direwolf20 1.16"), findsOneWidget);
    }, variant: TestUttily.targetPlatformVariant, skip: true);
  });
}