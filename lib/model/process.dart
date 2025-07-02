// ignore_for_file: public_member_api_docs, sort_constructors_first, unnecessary_this
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_randomcolor/flutter_randomcolor.dart';

class Process {
  final int pid;
  final int arrive;
  final int cpuTotal;
  final int ioGap;
  final Color color;
  String get name => '进程 $pid';

  Process({
    required this.pid,
    required this.arrive,
    required this.cpuTotal,
    required this.ioGap,
  }) : color = RandomColor.getColorObject(
         Options(luminosity: Luminosity.light),
       );

  Process copyWith({int? pid, int? arrive, int? cpuTotal, int? ioGap}) {
    return Process(
      pid: pid ?? this.pid,
      arrive: arrive ?? this.arrive,
      cpuTotal: cpuTotal ?? this.cpuTotal,
      ioGap: ioGap ?? this.ioGap,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'pid': pid,
      'arrive': arrive,
      'cpu_total': cpuTotal,
      'io_gap': ioGap,
    };
  }

  factory Process.fromMap(Map<String, dynamic> map) {
    return Process(
      pid: map['pid'] as int,
      arrive: map['arrive'] as int,
      cpuTotal: map['cpu_total'] as int,
      ioGap: map['io_gap'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory Process.fromJson(String source) =>
      Process.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Process(pid: $pid, arrive: $arrive, cpu_total: $cpuTotal, io_gap: $ioGap)';
  }

  @override
  bool operator ==(covariant Process other) {
    if (identical(this, other)) return true;

    return other.pid == pid &&
        other.arrive == arrive &&
        other.cpuTotal == cpuTotal &&
        other.ioGap == ioGap;
  }

  @override
  int get hashCode {
    return pid.hashCode ^ arrive.hashCode ^ cpuTotal.hashCode ^ ioGap.hashCode;
  }
}
