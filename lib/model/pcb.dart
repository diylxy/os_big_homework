import 'dart:math';

import 'package:os_big_homework/model/process.dart';

enum ProcessState { created, ready, block, done } // 不考虑调度中间过程，所以此处没有运行态

extension ProcessStateExtension on ProcessState {
  String toDisplayString() {
    switch (this) {
      case ProcessState.created:
        return '已创建';
      case ProcessState.ready:
        return '就绪';
      case ProcessState.block:
        return '阻塞';
      case ProcessState.done:
        return '完成';
    }
  }
}

const int ioCost = 5;

class PCB {
  final Process process;
  int cpuNeed; // 剩余CPU执行时间
  int cpuSinceIO = 0; // 距离上次IO结束所消耗的CPU时间
  int lastIOTime = -1; // 上次IO开始时间
  ProcessState state = ProcessState.created; // 进程状态
  int startTime = -1; // 开始时间
  int finishTime = -1; // 完成时间
  int ioTotal = 0; // 总IO时间
  int get turnaroundTime =>
      finishTime > 0 ? finishTime - process.arrive : -1; // 周转时间
  int get waitTime =>
      finishTime > 0 ? turnaroundTime - (process.cpuTotal - cpuNeed) : -1; // 等待时间
  double get weightedTurnaroundTime =>
    finishTime > 0 ? turnaroundTime / process.cpuTotal : -1;
  PCB(this.process) : cpuNeed = process.cpuTotal;

  @override
  String toString() {
    return 'PCB: $state';
  }

  int getMaxExecuteTime(int currentTime, int timeSpan) {
    if (state == ProcessState.done) return 0;
    int timeBeforeStart = currentTime - process.arrive; // 距离进程进入剩余时间
    if (timeBeforeStart < 0) return timeBeforeStart; // 进程尚未开始
    if (lastIOTime > 0) {
      // 进程正在阻塞
      final blockTime = ioCost - (currentTime - lastIOTime); // 剩余阻塞时间
      if (blockTime <= 0) {
        lastIOTime = -1; // IO已完成
        cpuSinceIO = 0;
      } else {
        return -blockTime; // 进程阻塞，返回阻塞剩余时间
      }
    }
    int cpuAvail = min(process.ioGap - cpuSinceIO, cpuNeed); // 开始IO，或进程完成，取最小
    int minCPUTime = min(timeSpan, cpuAvail); // 时间片，或进程可以推进的最大CPU时间，取最小
    assert(minCPUTime != 0);
    return minCPUTime;
  }

  int doSchedule(int currentTime, int timeSpan) {
    int currentExec = getMaxExecuteTime(currentTime, timeSpan);
    if (currentExec <= 0) {
      return 0;
    }
    if (state == ProcessState.created) {
      startTime = currentTime;
      state = ProcessState.ready;
    }
    cpuNeed -= currentExec;
    cpuSinceIO += currentExec;
    if (cpuNeed == 0) {
      finishTime = currentTime + currentExec;
      state = ProcessState.done;
      return 0;
    }
    assert(cpuSinceIO <= process.ioGap && cpuSinceIO > 0);
    if (cpuSinceIO == process.ioGap) {
      state = ProcessState.block;
      lastIOTime = currentTime + currentExec;
      ioTotal += ioCost; // 计算IO时间
    } else {
      state = ProcessState.ready;
    }
    return currentExec;
  }
}
