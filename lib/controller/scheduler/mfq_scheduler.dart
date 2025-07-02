import 'dart:math';

import 'package:os_big_homework/model/pcb.dart';
import 'package:os_big_homework/controller/scheduler/single_core_scheduler.dart';

class MFQScheduler extends SingleCoreScheduler {
  MFQScheduler(this.schedulers);
  final List<SingleCoreScheduler> schedulers;
  @override
  void enqueue(PCB pcb) {
    schedulers[0].enqueue(pcb);
  }

  @override
  bool dequeue(PCB pcb) {
    for (var scheduler in schedulers) {
      if (scheduler.dequeue(pcb)) return true;
    }
    return false;
  }

  @override
  ({PCB? pcb, int nextTime, int queueLevel}) schedule(int currentTime) {
    final queueCount = schedulers.length;
    int minWaitTime = -1;
    for (var i = 0; i < queueCount; i++) {
      final result = schedulers[i].schedule(currentTime);
      if (result.pcb == null) {
        // 这次调度无可用进程，记录最小等待时间，并继续判断下个队列
        if (result.nextTime > 0) {
          if (minWaitTime == -1) {
            minWaitTime = result.nextTime;
          } else {
            minWaitTime = min(result.nextTime, minWaitTime);
          }
        }
      } else {
        // 这一队列调度成功，检查是否需要跳过
        if (result.pcb!.state == ProcessState.ready) {
          // 时间片用完，没有阻塞，降入下一级队列（如果有）
          if (i + 1 < queueCount) {
            schedulers[i].dequeue(result.pcb!);
            schedulers[i + 1].enqueue(result.pcb!);
          }
        }
        return (pcb: result.pcb, nextTime: result.nextTime, queueLevel: i);
      }
    }
    return (pcb: null, nextTime: minWaitTime, queueLevel: -1);
  }
}
