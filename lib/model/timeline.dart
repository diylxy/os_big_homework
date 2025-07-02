import 'package:os_big_homework/model/pcb.dart';

class TimelineData {
  final int start;
  final int end;
  final PCB pcb;
  final ProcessState state;
  TimelineData(this.start, this.end, this.pcb, this.state);
}
