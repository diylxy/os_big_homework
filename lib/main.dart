import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:os_big_homework/controller/sche_page.dart';
import 'package:os_big_homework/page/sche_page.dart';

void main() {
  Get.lazyPut<SchedulerPageController>(() => SchedulerPageController());
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorSchemeSeed: Colors.brown,
        fontFamily: 'MiSans',
        brightness: Brightness.dark,
      ),
      home: SchedulerPage(),
      scrollBehavior: ScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.trackpad,
        },
        scrollbars: false,
        physics: BouncingScrollPhysics(),
      ),
    );
  }
}
