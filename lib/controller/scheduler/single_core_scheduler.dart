import 'package:os_big_homework/model/pcb.dart';

abstract class SingleCoreScheduler {
  // 入队函数：将PCB加入调度队列
  void enqueue(PCB pcb);

  /// 调度函数：输入当前时间，返回被调度的PCB和调度后的当前时间。如果[nextTime]等于-1，
  /// 代表调度器已完成全部已入队进程的调度。如果[pcb]等于null，代表全部进程阻塞，此时
  /// [nextTime]代表队列中最近一个进程转为就绪态的时间
  ({PCB? pcb, int nextTime, int queueLevel}) schedule(int currentTime);

  // 出队函数：将某一PCB从队列中移除，若存在这个实例则返回true，否则为false
  bool dequeue(PCB pcb);
}
