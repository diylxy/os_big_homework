import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:os_big_homework/controller/sche_page.dart';
import 'package:os_big_homework/model/pcb.dart';
import 'package:os_big_homework/model/timeline.dart';

class SchedulerPage extends StatelessWidget {
  const SchedulerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("多级反馈队列调度算法"),
        forceMaterialTransparency: true,
        actions: [IconButton(onPressed: () {}, icon: Icon(Icons.settings))],
      ),
      body: Column(
        spacing: 8.0,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: GetBuilder<SchedulerPageController>(
              id: SchedulerPageController.idTimelines,
              assignId: true,
              builder: (controller) {
                return Column(
                  spacing: 8.0,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                    controller.timelineCount,
                    (index) => Timeline(controller.getTimeline(index)),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Flexible(flex: 3, child: Operations()),
                // Flexible(flex: 5, child: XTermCard()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Operations extends StatelessWidget {
  const Operations({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: GetBuilder<SchedulerPageController>(
              assignId: true,
              id: SchedulerPageController.idProcessList,
              builder: (controller) {
                return ListView.builder(
                  itemCount: controller.processes.length,
                  itemBuilder: (context, index) => ListTile(
                    title: Text(controller.processes[index].name),
                    leading: CircleAvatar(
                      backgroundColor: controller.processes[index].color,
                    ),
                    subtitle: Text(
                      '到达时间：${controller.processes[index].arrive} ms\n'
                      'CPU时间：${controller.processes[index].cpuTotal} ms\n'
                      'I/O区间：${controller.processes[index].ioGap} ms',
                    ),
                    onTap: () {
                      final pcb = controller.getPCB(
                        controller.processes[index],
                      );
                      if (pcb != null) {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            opaque: false,
                            barrierDismissible: true,
                            barrierColor: Colors.black12,
                            pageBuilder:
                                (
                                  BuildContext context,
                                  Animation<double> animation,
                                  Animation<double> secondaryAnimation,
                                ) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: ProcessDetailAlert(pcb),
                                  );
                                },
                            transitionDuration: Duration(milliseconds: 0),
                            reverseTransitionDuration: Duration(
                              milliseconds: 200,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),
          Card(
            elevation: 3.0,
            child: Padding(
              padding: EdgeInsetsGeometry.all(8.0),
              child: Column(
                children: [
                  Text("数量", style: TextStyle(fontSize: 16.0)),
                  Obx(
                    () => Slider(
                      min: 5,
                      max: 50,
                      divisions: 45,
                      value:
                          SchedulerPageController.to.randomProcessCount.value,
                      onChanged: (value) {
                        SchedulerPageController.to.randomProcessCount.value =
                            value;
                      },
                    ),
                  ),
                  Row(
                    spacing: 16.0,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton.extended(
                        heroTag: UniqueKey(),
                        onPressed: () {
                          SchedulerPageController.to.regenerateProcess();
                        },
                        icon: Icon(Icons.refresh),
                        label: Text("重新生成"),
                      ),
                      FloatingActionButton.extended(
                        heroTag: UniqueKey(),
                        onPressed: () {
                          SchedulerPageController.to.importFromFile();
                        },
                        icon: Icon(Icons.open_in_browser),
                        label: Text("从文件读入"),
                      ),
                      FloatingActionButton.extended(
                        heroTag: UniqueKey(),
                        onPressed: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              opaque: false,
                              barrierDismissible: true,
                              barrierColor: Colors.black12,
                              pageBuilder:
                                  (
                                    BuildContext context,
                                    Animation<double> animation,
                                    Animation<double> secondaryAnimation,
                                  ) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SchedulerDetailAlert(),
                                    );
                                  },
                              transitionDuration: Duration(milliseconds: 0),
                              reverseTransitionDuration: Duration(
                                milliseconds: 200,
                              ),
                            ),
                          );
                        },
                        icon: Icon(Icons.schedule),
                        label: Text("调度结果"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Timeline extends StatelessWidget {
  const Timeline(this.timeline, {super.key});

  final List<TimelineData>? timeline;
  @override
  Widget build(BuildContext context) {
    if (timeline == null || timeline!.isEmpty) {
      return SizedBox(height: 80, child: Center(child: Text('队列为空')));
    }
    return SizedBox(
      height: 80,
      width: timeline!.last.end * 16 + 2 + 5,
      child: Stack(
        children: [
          Positioned(
            left: 2,
            top: 0,
            child: Tooltip(
              message: '0 ms',
              child: Container(height: 80, width: 3, color: Colors.white),
            ),
          ),
          ...timeline!.map(
            (element) => Positioned(
              left: element.start * 16 + 5,
              top: 0,
              child: Card(
                clipBehavior: Clip.antiAlias,
                color: element.pcb.process.color,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        barrierDismissible: true,
                        barrierColor: Colors.black12,
                        pageBuilder:
                            (
                              BuildContext context,
                              Animation<double> animation,
                              Animation<double> secondaryAnimation,
                            ) {
                              return FadeTransition(
                                opacity: animation,
                                child: TimelineDetailAlert(element),
                              );
                            },
                        transitionDuration: Duration(milliseconds: 0),
                        reverseTransitionDuration: Duration(milliseconds: 200),
                      ),
                    );
                  },
                  child: SizedBox(
                    width: (element.end - element.start) * 16.0 - 2,
                    height: 70,
                    child: Tooltip(
                      message:
                          '${element.pcb.process.name}: ${element.end - element.start} ms${element.state == ProcessState.done ? ' 已完成' : ''}',
                      child: Center(
                        child: Text(
                          element.pcb.process.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.black87, fontSize: 24),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProcessDetailAlert extends StatelessWidget {
  const ProcessDetailAlert(this.pcb, {super.key});
  final PCB pcb;
  @override
  Widget build(BuildContext context) {
    return Dialog(
          backgroundColor: Color.lerp(pcb.process.color, Colors.black, 0.8),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 8.0,
              children: [
                Text(
                  pcb.process.name,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                Table(
                  columnWidths: const {
                    0: IntrinsicColumnWidth(),
                    1: IntrinsicColumnWidth(),
                  },
                  children: [
                    _tableRow(context, '到达时刻  ', '${pcb.process.arrive} ms'),
                    _tableRow(context, '开始时刻  ', '${pcb.startTime} ms'),
                    _tableRow(context, '完成时刻  ', '${pcb.finishTime} ms'),
                    _tableRow(context, '剩余CPU时间  ', '${pcb.cpuNeed} ms'),
                    _tableRow(
                      context,
                      '总CPU时间  ',
                      '${pcb.process.cpuTotal} ms',
                    ),
                    _tableRow(context, '总IO时间  ', '${pcb.ioTotal} ms'),
                    _tableRow(context, 'IO间隔  ', '${pcb.process.ioGap} ms'),
                    _tableRow(context, '等待时间  ', '${pcb.waitTime} ms'),
                    _tableRow(context, '周转时间  ', '${pcb.turnaroundTime} ms'),
                    _tableRow(
                      context,
                      '带权周转时间  ',
                      pcb.weightedTurnaroundTime.toStringAsFixed(2),
                    ),
                    _tableRow(context, '进程状态  ', pcb.state.toDisplayString()),
                  ],
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms, curve: Curves.easeOutCirc)
        .moveY(begin: -200, end: 0, duration: 300.ms, curve: Curves.easeOutCirc)
        .flipV(duration: 300.ms, curve: Curves.easeOutCirc);
  }

  TableRow _tableRow(BuildContext context, String key, String value) {
    return TableRow(
      children: [
        Text(
          key,
          style: Theme.of(
            context,
          ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class TimelineDetailAlert extends StatelessWidget {
  const TimelineDetailAlert(this.event, {super.key});
  final TimelineData event;
  @override
  Widget build(BuildContext context) {
    return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 8.0,
              children: [
                Text(
                  event.pcb.process.name,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                Text(
                  '起始时间戳：${event.start} ms\n'
                  '结束时间戳：${event.end} ms\n'
                  '时间片长度：${event.end - event.start} ms\n'
                  '结束时状态：${event.state.toDisplayString()}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                FloatingActionButton.extended(
                  heroTag: UniqueKey(),
                  onPressed: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        barrierDismissible: true,
                        barrierColor: Colors.black12,
                        pageBuilder:
                            (
                              BuildContext context,
                              Animation<double> animation,
                              Animation<double> secondaryAnimation,
                            ) {
                              return FadeTransition(
                                opacity: animation,
                                child: ProcessDetailAlert(event.pcb),
                              );
                            },
                        transitionDuration: Duration(milliseconds: 0),
                        reverseTransitionDuration: Duration(milliseconds: 200),
                      ),
                    );
                  },
                  icon: Icon(Icons.open_in_full),
                  label: Text("打开进程"),
                  backgroundColor: event.pcb.process.color,
                  foregroundColor: Colors.black87,
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms, curve: Curves.easeOutCirc)
        .moveY(begin: -200, end: 0, duration: 300.ms, curve: Curves.easeOutCirc)
        .flipV(duration: 300.ms, curve: Curves.easeOutCirc);
  }
}

class SchedulerDetailAlert extends StatelessWidget {
  const SchedulerDetailAlert({super.key});
  @override
  Widget build(BuildContext context) {
    return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 8.0,
              children: [
                Text(
                  '全局调度结果',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                Text(
                  '总时间：${SchedulerPageController.to.totalTime} ms\n'
                  'CPU利用率：${(SchedulerPageController.to.cpuUsage * 100).toStringAsFixed(2)} %\n'
                  '吞吐量：${SchedulerPageController.to.throughput} 进程/ms\n'
                  '平均周转时间：${SchedulerPageController.to.avgTurnaroundTime} ms',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                FloatingActionButton.extended(
                  heroTag: UniqueKey(),
                  onPressed: () {
                    SchedulerPageController.to.exportToFile();
                  },
                  icon: Icon(Icons.open_in_browser),
                  label: Text("保存到文件"),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms, curve: Curves.easeOutCirc)
        .moveY(begin: -200, end: 0, duration: 300.ms, curve: Curves.easeOutCirc)
        .flipV(duration: 300.ms, curve: Curves.easeOutCirc);
  }
}
