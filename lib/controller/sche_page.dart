import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:get/get.dart';
import 'package:os_big_homework/controller/scheduler/fcfs_scheduler.dart';
import 'package:os_big_homework/controller/scheduler/mfq_scheduler.dart';
import 'package:os_big_homework/controller/scheduler/rr_scheduler.dart';
import 'package:os_big_homework/controller/scheduler/single_core_scheduler.dart';
import 'package:os_big_homework/model/pcb.dart';
import 'package:os_big_homework/model/process.dart';
import 'package:os_big_homework/model/timeline.dart';
import 'package:file_picker/file_picker.dart';

class SchedulerPageController extends GetxController {
  static SchedulerPageController get to => Get.find<SchedulerPageController>();
  static const idProcessList = 1;
  static const idTimelines = 2;

  static const maxArrive = 500;
  static const minArrive = 0;
  static const maxCPU = 50;
  static const minCPU = 10;
  static const maxIO = 80;
  static const minIO = 1;

  final List<Process> processes = [];

  final randomProcessCount = 20.0.obs;

  regenerateProcess() {
    processes.clear();
    for (var i = 0; i < randomProcessCount.value.toInt(); i++) {
      final random = Random();
      int arrive = random.nextInt(maxArrive) + minArrive;
      int cpuTotal = random.nextInt(maxCPU) + minCPU;
      int ioGap = random.nextInt(maxIO) + minIO;
      processes.add(
        Process(pid: i + 1, arrive: arrive, cpuTotal: cpuTotal, ioGap: ioGap),
      );
    }
    update([idProcessList]);
    doSchedule();
  }

  importFromFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'csv'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String content = file.readAsStringSync();
      List<dynamic> json = jsonDecode(content);
      processes.clear();
      for (var proc in json) {
        processes.add(Process.fromMap(proc as Map<String, dynamic>));
      }
      update([idProcessList]);
      doSchedule();
    }
  }

  exportToFile() async {
    if (totalTime <= 0) return;
    String? result = await FilePicker.platform.saveFile(
      type: FileType.custom,
      fileName: 'out.txt',
      allowedExtensions: ['txt'],
    );

    if (result != null) {
      File file = File(result);
      final sink = file.openWrite();
      sink.write(generateGanttChart());
      sink.write('\n');
      sink.write(generateScheduleDetail());
      sink.close();
    }
  }

  late SingleCoreScheduler scheduler;
  @override
  void onInit() {
    super.onInit();
    scheduler = MFQScheduler([RRScheduler(2), RRScheduler(4), FCFSScheduler()]);
  }

  final List<PCB> pcbs = [];
  final List<List<TimelineData>> _timelines = [];
  int totalTime = 0;
  int idleTime = 0;
  double get cpuUsage =>
      totalTime != 0 ? (totalTime - idleTime) / totalTime : 1.0;
  double get throughput => totalTime != 0 ? pcbs.length / totalTime : -1;
  double avgTurnaroundTime = -1;

  doSchedule() {
    pcbs.clear();
    _timelines.clear();
    totalTime = 0;
    idleTime = 0;
    for (var i = 0; i < 3; i++) {
      _timelines.add([]);
    }
    for (var process in processes) {
      final pcb = PCB(process);
      pcbs.add(pcb);
      scheduler.enqueue(pcb);
    }
    int currentTime = 0;
    while (true) {
      final result = scheduler.schedule(currentTime);
      if (result.pcb == null) {
        if (result.nextTime == -1) {
          break;
        } else {
          // 快进时间到下个调度节点
          idleTime += result.nextTime - currentTime;
          currentTime = result.nextTime;
        }
      } else {
        _timelines[result.queueLevel].add(
          TimelineData(
            currentTime,
            result.nextTime,
            result.pcb!,
            result.pcb!.state,
          ),
        );
        currentTime = result.nextTime;
      }
    }
    totalTime = currentTime;
    avgTurnaroundTime = 0;
    for (var pcb in pcbs) {
      avgTurnaroundTime += pcb.turnaroundTime;
    }
    avgTurnaroundTime /= pcbs.length;
    update([idTimelines]);
  }

  PCB? getPCB(Process process) {
    for (var element in pcbs) {
      if (element.process == process) return element;
    }
    return null;
  }

  int get timelineCount => _timelines.length;

  List<TimelineData>? getTimeline(int row) {
    if (row >= _timelines.length) return null;
    return _timelines[row];
  }

  String generateGanttChart() {
    if (totalTime <= 0) return '';
    final List<String> result = List.filled(totalTime, '');
    for (var timeline in _timelines) {
      for (var event in timeline) {
        for (var i = event.start; i < event.end; i++) {
          if (i + 1 == event.end) {
            if (event.state == ProcessState.block) {
              result[i] = '$i-${i + 1}: PID${event.pcb.process.pid} (BLOCK)';
              break;
            } else if (event.state == ProcessState.done) {
              result[i] = '$i-${i + 1}: PID${event.pcb.process.pid} (DONE)';
              break;
            }
          }
          result[i] = '$i-${i + 1}: PID${event.pcb.process.pid}';
        }
      }
    }
    for (var i = 0; i < totalTime; i++) {
      if (result[i] == '') {
        result[i] = '$i-${i + 1}: IDLE';
      }
    }
    return result.join('\n');
  }

  String generateScheduleDetail() {
    final buffer = StringBuffer();
    for (var pcb in pcbs) {
      final pid = pcb.process.pid;
      final arrive = pcb.process.arrive;
      final finish = pcb.finishTime;
      final turnaround = pcb.turnaroundTime;
      final weighted = (pcb.turnaroundTime / pcb.process.cpuTotal)
          .toStringAsFixed(2);
      final waiting = pcb.waitTime;
      buffer.writeln(
        'PID $pid 到达${arrive}ms  完成${finish}ms  周转$turnaround  带权$weighted  等待$waiting ',
      );
    }
    buffer.writeln('平均周转时间: ${avgTurnaroundTime.toStringAsFixed(2)} ms');
    buffer.writeln('CPU利用率: ${(cpuUsage * 100).toStringAsFixed(2)}%');
    buffer.writeln('吞吐量: ${throughput.toStringAsFixed(2)} 进程/ms');
    return buffer.toString();
  }
}
