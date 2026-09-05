import 'package:flutter/material.dart';

import '../../infrastructure/reminders/reminder_service.dart';

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});
  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage>
    with WidgetsBindingObserver {
  final service = ReminderService();
  bool enabled = false, allowed = false, busy = true, supported = true;
  TimeOfDay time = const TimeOfDay(hour: 20, minute: 0);
  String? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !busy) load();
  }

  Future<void> load() async {
    try {
      final data = await service.load();
      if (mounted) {
        setState(() {
          enabled = data['enabled'] == true;
          allowed = data['allowed'] == true;
          time = TimeOfDay(
            hour: data['hour'] as int? ?? 20,
            minute: data['minute'] as int? ?? 0,
          );
          busy = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          supported = false;
          busy = false;
          error = '此平台暂不支持系统学习提醒，当前支持 Android。';
        });
      }
    }
  }

  Future<void> run(Future<void> Function() action) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
      await load();
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          error = '操作未完成，请检查通知权限后重试。';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('学习提醒')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('每天留一点时间，复习学过的表达。'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('每日提醒'),
          value: enabled,
          onChanged: busy || !supported
              ? null
              : (value) =>
                    run(() => service.save(value, time.hour, time.minute)),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('提醒时间'),
          trailing: Text(time.format(context)),
          onTap: busy || !supported
              ? null
              : () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: time,
                  );
                  if (picked != null && mounted) {
                    await run(
                      () => service.save(enabled, picked.hour, picked.minute),
                    );
                  }
                },
        ),
        if (supported) Text(allowed ? '系统通知权限已开启' : '系统通知未开启，请允许 Vocab 发送通知。'),
        if (supported && !allowed)
          TextButton(
            onPressed: busy ? null : () => run(service.settings),
            child: const Text('打开系统通知设置'),
          ),
        const SizedBox(height: 16),
        const Text('提醒按设备本地时间每天发送。系统省电策略可能延迟送达；强行停止应用后需重新打开。通知不包含私人词汇内容。'),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: busy || !supported || !allowed
              ? null
              : () => run(service.test),
          child: const Text('发送测试通知'),
        ),
        if (busy) const LinearProgressIndicator(),
        if (error != null)
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    ),
  );
}
