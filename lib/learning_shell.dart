import 'package:flutter/material.dart';
import 'dart:async';
import 'data/learning_audio.dart';
import 'learning_hub_page.dart';
import 'profilePage.dart';
import 'userCollectionDatabase.dart';

/// One canonical Learn destination, with lazy pages retained across tab changes.
class LearningShell extends StatefulWidget {
  const LearningShell(
      {super.key,
      required this.home,
      this.onHomeSelected,
      this.onDestinationChanged,
      this.learnBuilder,
      this.wordsBuilder,
      this.profileBuilder});
  final Widget home;
  final VoidCallback? onHomeSelected;
  final VoidCallback? onDestinationChanged;
  final Widget Function()? learnBuilder, wordsBuilder;
  final Widget Function(VoidCallback home)? profileBuilder;
  @override
  State<LearningShell> createState() => _LearningShellState();
}

class _LearningShellState extends State<LearningShell> {
  int selected = 0;
  final opened = <int>{0};
  void _go(int index) {
    if (selected == index) return;
    unawaited(LearningAudio.instance.play(LearningCue.tap));
    FocusManager.instance.primaryFocus?.unfocus();
    widget.onDestinationChanged?.call();
    setState(() {
      selected = index;
      opened.add(index);
    });
    if (index == 0) widget.onHomeSelected?.call();
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: selected == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && selected != 0) _go(0);
      },
      child: Scaffold(
          body: IndexedStack(index: selected, children: [
            widget.home,
            if (opened.contains(1))
              widget.learnBuilder?.call() ?? const LearningHubPage()
            else
              const SizedBox(),
            if (opened.contains(2))
              widget.wordsBuilder?.call() ??
                  const UserCollectionDatabase(embedded: true)
            else
              const SizedBox(),
            if (opened.contains(3))
              widget.profileBuilder?.call(() => _go(0)) ??
                  ProfilePage(onHome: () => _go(0))
            else
              const SizedBox(),
          ]),
          bottomNavigationBar: NavigationBar(
              selectedIndex: selected,
              onDestinationSelected: _go,
              backgroundColor: const Color(0xfff7f1ff),
              indicatorColor: const Color(0xffe1d0fa),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Home'),
                NavigationDestination(
                    icon: Icon(Icons.explore_outlined),
                    selectedIcon: Icon(Icons.explore),
                    label: 'Learn'),
                NavigationDestination(
                    icon: Icon(Icons.bookmark_border),
                    selectedIcon: Icon(Icons.bookmark),
                    label: 'My words'),
                NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: 'Profile'),
              ])));
}
