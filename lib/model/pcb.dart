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
  int lastIOTime = -1; // 上次IO开始的时间戳，用于计算在某一时刻IO是否完成
  ProcessState state = ProcessState.created; // 进程状态
  int startTime = -1; // 开始时间戳
  int finishTime = -1; // 完成时间戳
  int ioTotal = 0; // 总IO时间
  int get turnaroundTime =>
      finishTime > 0 ? finishTime - process.arrive : -1; // 周转时间
  int get waitTime =>
      finishTime > 0 ? turnaroundTime - process.cpuTotal : -1; // 等待时间
  double get weightedTurnaroundTime =>
      finishTime > 0 ? turnaroundTime / process.cpuTotal : -1;
  PCB(this.process) : cpuNeed = process.cpuTotal;

  @override
  String toString() {
    return 'PCB: $state';
  }

  /// 计算进程在当前时间点和给定时间片内最多可执行的CPU时间。
  ///
  /// - [currentTime] 当前的系统时间。
  /// - [timeSpan] 分配给进程的时间片长度。
  ///
  /// 返回值：
  /// - 如果进程已完成，返回0。
  /// - 如果进程尚未到达，返回距离到达的剩余时间（为负数）。
  /// - 如果进程处于阻塞状态，返回负的剩余阻塞时间。
  /// - 否则，返回进程在本次调度中最多可执行的CPU时间（不超过时间片和进程可用CPU时间的最小值）。
  ///
  /// 注意：该方法会根据IO完成情况更新进程的IO状态。
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

  /// 执行调度操作，根据当前时间和时间片长度执行进程。
  ///
  /// - [currentTime]：当前的系统时间。
  /// - [timeSpan]：本次调度允许的最大执行时间（时间片）。
  ///
  /// 返回值为本次实际执行的时间（currentExec）。
  ///
  /// 断言保证执行时间大于0，且自上次IO以来的CPU时间在合理范围内。
  int doSchedule(int currentTime, int timeSpan) {
    int currentExec = getMaxExecuteTime(currentTime, timeSpan);
    assert(currentExec > 0);
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
    // 断言保证本次由getMaxExecuteTime计算得来的时间不超过进程IO间隔
    assert(cpuSinceIO <= process.ioGap && cpuSinceIO > 0);
    if (cpuSinceIO == process.ioGap) {
      state = ProcessState.block;
      lastIOTime = currentTime + currentExec; // 存储本次IO开始时间
      ioTotal += ioCost; // 计算IO总消耗
    } else {
      state = ProcessState.ready;
    }
    return currentExec;
  }
}
