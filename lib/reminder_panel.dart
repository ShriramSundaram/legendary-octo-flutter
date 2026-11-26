import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/content_catalog.dart';
import 'data/offline_vocabulary_loader.dart';
import 'data/reminder_controller.dart';
import 'reminder_runtime.dart';

class ReminderPanel extends StatefulWidget {
  const ReminderPanel(
      {super.key,
      required this.level,
      this.itemId,
      this.word,
      this.controller});
  final String level;
  final String? itemId, word;
  final ReminderController? controller;
  @override
  State<ReminderPanel> createState() => _ReminderPanelState();
}

class _ReminderPanelState extends State<ReminderPanel>
    with WidgetsBindingObserver {
  ReminderController? controller;
  Timer? ticker;
  Duration duration = const Duration(minutes: 10);
  bool failed = false, enabled = false;
  int hour = 18, minute = 0;
  Set<int> days = {1, 2, 3, 4, 5, 6, 7};
  String level = 'A1', savedWord = '';
  String? _resolvedId;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && controller?.settings.hasTimer == true) setState(() {});
    });
  }

  Future<void> _load() async {
    try {
      final value = widget.controller ?? await ReminderRuntime.current();
      if (!mounted) return;
      final settings = value.settings;
      setState(() {
        controller = value;
        failed = false;
        enabled = settings.enabled;
        hour = settings.hour;
        minute = settings.minute;
        days = settings.days.toSet();
        level = settings.level;
      });
      _resolveWord();
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
  }

  Future<void> _resolveWord() async {
    final id = controller?.settings.itemId;
    if (id == _resolvedId) return;
    _resolvedId = id;
    if (mounted)
      setState(
          () => savedWord = id == widget.itemId ? (widget.word ?? '') : '');
    if (id == null) return;
    try {
      final vocabulary = await loadOfflineVocabulary();
      final found = vocabulary.words.where((w) => w.id == id).toList();
      if (mounted && controller?.settings.itemId == id)
        setState(() => savedWord =
            found.isEmpty ? 'Saved vocabulary' : found.first.display);
    } catch (_) {
      if (mounted) setState(() => savedWord = 'Saved vocabulary');
    }
  }

  Future<void> _act(Future<void> Function() action) async {
    try {
      await action();
      _resolveWord();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Reminder update was not confirmed. Check permission and try again.')));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && controller != null)
      unawaited(_act(controller!.refresh));
  }

  @override
  void dispose() {
    ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c == null)
      return Card(
          child: Padding(
              padding: const EdgeInsets.all(20),
              child: failed
                  ? Column(children: [
                      const Text(
                          'Could not open reminders. Your saved settings have not been reset.'),
                      TextButton(onPressed: _load, child: const Text('Retry'))
                    ])
                  : const Center(child: CircularProgressIndicator())));
    return AnimatedBuilder(
        animation: c,
        builder: (context, _) {
          final s = c.settings;
          final remaining = s.hasTimer ? s.remaining(c.clock()) : duration;
          final seconds = (remaining.inMilliseconds + 999) ~/ 1000;
          final text =
              '${(seconds ~/ 3600).toString().padLeft(2, '0')}:${((seconds % 3600) ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
          final status = c.error.isNotEmpty
              ? 'Needs attention'
              : !c.permissionGranted && (s.enabled || s.hasTimer)
                  ? 'Notifications off'
                  : s.paused
                      ? 'Paused'
                      : s.hasTimer && remaining == Duration.zero
                          ? 'Reminder window reached'
                          : s.hasTimer
                              ? 'Counting down'
                              : 'Ready when you are';
          final theme = Theme.of(context);
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xff4939a5),
                              Color(0xff30266c),
                              Color(0xff185a70)
                            ])),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(children: [
                            Icon(Icons.hourglass_bottom_rounded,
                                color: Color(0xffa6f0dc)),
                            SizedBox(width: 10),
                            Expanded(
                                child: Text('A moment for German',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 21,
                                        fontWeight: FontWeight.w700)))
                          ]),
                          const SizedBox(height: 12),
                          Text(status,
                              style: const TextStyle(
                                  color: Color(0xffa6f0dc),
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 20),
                          LayoutBuilder(builder: (context, constraints) {
                            final clock = Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(text,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 27,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          fontFeatures: [
                                            FontFeature.tabularFigures()
                                          ])),
                                  const SizedBox(height: 8),
                                  Text(
                                      s.paused
                                          ? 'PAUSED'
                                          : 'REMINDER COUNTDOWN',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: Color(0xffdddafa),
                                          fontSize: 11,
                                          letterSpacing: 1.2)),
                                ]);
                            if (constraints.maxWidth < 210 ||
                                MediaQuery.textScalerOf(context).scale(18) > 25)
                              return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 20),
                                  child: Semantics(
                                      label: 'Time remaining $text',
                                      child: ExcludeSemantics(
                                          child: Wrap(
                                              alignment: WrapAlignment.center,
                                              spacing: 12,
                                              runSpacing: 12,
                                              children: [
                                            for (var index = 0;
                                                index < 3;
                                                index++)
                                              Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(text.split(':')[index],
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 30,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w700)),
                                                    Text(
                                                        [
                                                          'HRS',
                                                          'MIN',
                                                          'SEC'
                                                        ][index],
                                                        style: const TextStyle(
                                                            color: Color(
                                                                0xffdddafa),
                                                            fontSize: 11)),
                                                  ]),
                                          ]))));
                            return Center(
                                child: SizedBox(
                                    width: 200,
                                    height: 200,
                                    child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          SizedBox.expand(
                                              child: CircularProgressIndicator(
                                                  value: s.hasTimer
                                                      ? (remaining.inMilliseconds /
                                                              (s.totalMs == 0
                                                                  ? 1
                                                                  : s.totalMs))
                                                          .clamp(0.0, 1.0)
                                                      : 1,
                                                  strokeWidth: 7,
                                                  color:
                                                      const Color(0xffa6f0dc),
                                                  backgroundColor: Colors.white
                                                      .withAlpha(28),
                                                  semanticsLabel:
                                                      'Time remaining')),
                                          Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: clock),
                                        ])));
                          }),
                          const SizedBox(height: 20),
                          Text(
                              s.hasTimer
                                  ? (savedWord.isEmpty
                                      ? 'Review ${s.timerLevel} vocabulary'
                                      : savedWord)
                                  : (widget.word ??
                                      'Review ${widget.level} vocabulary'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          const Text(
                              'Android may deliver the notification after this countdown.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Color(0xffdddafa), fontSize: 12)),
                          const SizedBox(height: 20),
                          if (!s.hasTimer) ...[
                            Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final minutes in [1, 5, 10, 25])
                                    ChoiceChip(
                                        label: Text('$minutes min'),
                                        selected: duration ==
                                            Duration(minutes: minutes),
                                        onSelected: c.busy
                                            ? null
                                            : (_) => setState(() => duration =
                                                Duration(minutes: minutes))),
                                  ActionChip(
                                      label: const Text('Custom'),
                                      onPressed: c.busy
                                          ? null
                                          : () async {
                                              final picked =
                                                  await showDialog<Duration>(
                                                      context: context,
                                                      builder: (_) =>
                                                          _DurationDialog(
                                                              initial:
                                                                  duration));
                                              if (picked != null && mounted)
                                                setState(
                                                    () => duration = picked);
                                            }),
                                ]),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                                onPressed: c.busy
                                    ? null
                                    : () => _act(() => c.startTimer(duration,
                                        level: widget.level,
                                        itemId: widget.itemId)),
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: Text(c.busy ? 'Saving…' : 'Start timer'),
                                style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xffa6f0dc),
                                    foregroundColor: const Color(0xff173d37))),
                          ] else
                            Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 10,
                                runSpacing: 8,
                                children: [
                                  if (remaining > Duration.zero)
                                    FilledButton.icon(
                                        onPressed: c.busy
                                            ? null
                                            : () => _act(s.paused
                                                ? c.resumeTimer
                                                : c.pauseTimer),
                                        icon: Icon(s.paused
                                            ? Icons.play_arrow_rounded
                                            : Icons.pause_rounded),
                                        label:
                                            Text(s.paused ? 'Resume' : 'Pause'),
                                        style: FilledButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xffa6f0dc),
                                            foregroundColor:
                                                const Color(0xff173d37))),
                                  OutlinedButton.icon(
                                      onPressed: c.busy
                                          ? null
                                          : () => _act(c.cancelTimer),
                                      icon: const Icon(Icons.close_rounded),
                                      label: const Text('Cancel timer'),
                                      style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          side: const BorderSide(
                                              color: Color(0xffdddafa)))),
                                ]),
                        ])),
                const SizedBox(height: 16),
                Card(
                    clipBehavior: Clip.antiAlias,
                    child: ExpansionTile(
                        leading: Icon(Icons.notifications_active_outlined,
                            color: theme.colorScheme.primary),
                        title: const Text('Make it a habit'),
                        subtitle: Text(s.enabled && c.permissionGranted
                            ? 'Study reminders on • ${TimeOfDay(hour: s.hour, minute: s.minute).format(context)}'
                            : 'Optional reminders • choose your days'),
                        childrenPadding: const EdgeInsets.all(20),
                        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Repeat study reminders'),
                              value: enabled,
                              onChanged: c.busy
                                  ? null
                                  : (v) => setState(() => enabled = v)),
                          const Text('Changes apply when you save.'),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                              onPressed: c.busy
                                  ? null
                                  : () async {
                                      final time = await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay(
                                              hour: hour, minute: minute));
                                      if (time != null && mounted)
                                        setState(() {
                                          hour = time.hour;
                                          minute = time.minute;
                                        });
                                    },
                              icon: const Icon(Icons.schedule),
                              label: Text(TimeOfDay(hour: hour, minute: minute)
                                  .format(context))),
                          const SizedBox(height: 12),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            for (var day = 1; day <= 7; day++)
                              FilterChip(
                                  label: Text([
                                    'Mon',
                                    'Tue',
                                    'Wed',
                                    'Thu',
                                    'Fri',
                                    'Sat',
                                    'Sun'
                                  ][day - 1]),
                                  selected: days.contains(day),
                                  onSelected: c.busy
                                      ? null
                                      : (selected) => setState(() {
                                            if (selected) {
                                              days.add(day);
                                            } else {
                                              days.remove(day);
                                            }
                                          }))
                          ]),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                              value: level,
                              decoration: const InputDecoration(
                                  labelText: 'Review level',
                                  border: OutlineInputBorder()),
                              items: contentLevels
                                  .map((l) => DropdownMenuItem(
                                      value: l, child: Text(l)))
                                  .toList(),
                              onChanged: c.busy
                                  ? null
                                  : (v) => setState(() => level = v!)),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                              onPressed: c.busy || enabled && days.isEmpty
                                  ? null
                                  : () => _act(() => c.saveDaily(
                                      enabled: enabled,
                                      hour: hour,
                                      minute: minute,
                                      days: days,
                                      level: level)),
                              icon: const Icon(Icons.check),
                              label: const Text('Save schedule')),
                          if (enabled && days.isEmpty)
                            const Text('Choose at least one day.'),
                          const SizedBox(height: 12),
                          Text(
                              'Device timezone: ${c.timezoneName.isEmpty ? 'checking…' : c.timezoneName}',
                              style: theme.textTheme.bodySmall),
                          const SizedBox(height: 8),
                          const Text(
                              'Android may delay study reminders. They can work after normal app closure and reboot. Explicit Force stop blocks delivery until you reopen the app; phone battery restrictions can also delay reminders.'),
                        ])),
                if (c.error.isNotEmpty)
                  Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(c.error,
                          style: TextStyle(color: theme.colorScheme.error))),
              ]);
        });
  }
}

class _DurationDialog extends StatefulWidget {
  const _DurationDialog({required this.initial});
  final Duration initial;
  @override
  State<_DurationDialog> createState() => _DurationDialogState();
}

class _DurationDialogState extends State<_DurationDialog> {
  late final List<TextEditingController> inputs;
  String? error;
  @override
  void initState() {
    super.initState();
    inputs = [
      widget.initial.inHours,
      (widget.initial.inMinutes % 60),
      widget.initial.inSeconds % 60
    ].map((n) => TextEditingController(text: '$n')).toList();
  }

  @override
  void dispose() {
    for (final c in inputs) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: const Text('Your reminder timer'),
          content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < 3; i++)
              Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                      controller: inputs[i],
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2)
                      ],
                      decoration: InputDecoration(
                          labelText: ['Hours', 'Minutes', 'Seconds'][i],
                          border: const OutlineInputBorder()))),
            if (error != null) Text(error!),
          ])),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back')),
            FilledButton(
                onPressed: () {
                  final values =
                      inputs.map((c) => int.tryParse(c.text) ?? 0).toList();
                  final duration = Duration(
                      hours: values[0], minutes: values[1], seconds: values[2]);
                  if (values[1] > 59 ||
                      values[2] > 59 ||
                      duration.inSeconds < 5 ||
                      duration.inMilliseconds > 86400000) {
                    setState(() => error =
                        'Choose 5 seconds to 24 hours; minutes and seconds must be 0–59.');
                    return;
                  }
                  Navigator.pop(context, duration);
                },
                child: const Text('Use timer'))
          ]);
}
