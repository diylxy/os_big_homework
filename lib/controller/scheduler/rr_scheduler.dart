import 'package:os_big_homework/model/pcb.dart';
import 'package:os_big_homework/controller/scheduler/single_core_scheduler.dart';
import 'dart:collection';

class RRScheduler extends SingleCoreScheduler {
  final int timeSpan;
  RRScheduler(this.timeSpan);

  final queue = Queue<PCB>();
  final List<PCB> blockedQueue = [];
  @override
  void enqueue(PCB pcb) {
    queue.add(pcb);
  }

  @override
  bool dequeue(PCB pcb) {
    if (blockedQueue.remove(pcb)) return true; // 首先尝试移除阻塞对列中的PCB
    return queue.remove(pcb);
  }

  @override
  ({PCB? pcb, int nextTime, int queueLevel}) schedule(int currentTime) {
    if (queue.isEmpty && blockedQueue.isEmpty) {
      return (pcb: null, nextTime: -1, queueLevel: -1);
    }
    // 检查阻塞队列
    for (int i = blockedQueue.length - 1; i >= 0; i--) {
      var pcb = blockedQueue[i];
      if (pcb.getMaxExecuteTime(currentTime, timeSpan) > 0) {
        blockedQueue.removeAt(i);
        queue.add(pcb);
      }
    }
    PCB? currentPCB;
    int exeTime = 0;
    while (queue.isNotEmpty) {
      currentPCB = queue.removeFirst();
      exeTime = currentPCB.getMaxExecuteTime(currentTime, timeSpan);
      if (exeTime > 0) {
        break;
      } else if (exeTime <= 0) {
        if (currentPCB.state == ProcessState.block ||
            currentPCB.state == ProcessState.created) {
          blockedQueue.add(currentPCB);
          currentPCB = null;
        } else if (currentPCB.state != ProcessState.done) {
          throw Exception('当前PCB状态异常：${currentPCB.state}');
        }
      }
    }
    if (currentPCB != null) {
      currentPCB.doSchedule(currentTime, timeSpan);
      if (currentPCB.state != ProcessState.done) {
        queue.add(currentPCB);
      }
      return (pcb: currentPCB, nextTime: currentTime + exeTime, queueLevel: 0);
    }
    if (queue.isEmpty) {
      if (blockedQueue.isEmpty) {
        return (pcb: null, nextTime: -1, queueLevel: -1);
      }
      // 再次检查阻塞队列，查找最近结束IO的进程
      int minBlockTime = 2147483647;
      for (var pcb in blockedQueue) {
        int blockTime = -pcb.getMaxExecuteTime(currentTime, timeSpan);
        assert(blockTime > 0);
        if (minBlockTime > blockTime) minBlockTime = blockTime;
      }
      return (pcb: null, nextTime: currentTime + minBlockTime, queueLevel: -1);
    }
    throw Exception('就绪队列非空，但找不到当前PCB');
  }
}
