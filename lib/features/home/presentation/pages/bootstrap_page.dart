import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/runtime_service.dart';
import '../../../../core/services/workspace_service.dart';

class BootstrapPage extends ConsumerStatefulWidget {
  const BootstrapPage({super.key});

  @override
  ConsumerState<BootstrapPage> createState() => _BootstrapPageState();
}

class _BootstrapPageState extends ConsumerState<BootstrapPage> {
  static const bg = Color(0xFF03040A);
  static const pink = Color(0xFFFF20D9);
  static const purple = Color(0xFF9B35FF);
  static const blue = Color(0xFF405CFF);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkReady();
      _startInit();
    });
  }

  void _checkReady() {
    if (ref.read(runtimeServiceProvider).isInitialized) {
      context.go('/');
    }
  }

  Future<void> _startInit() async {
    final runtime = ref.read(runtimeServiceProvider);
    final router = GoRouter.of(context);
    await runtime.init();
    if (runtime.isInitialized) {
      try {
        await ref.read(workspaceProvider.notifier).restoreLastWorkspace();
      } catch (e) {
        debugPrint('Failed to restore last workspace: $e');
      }
      if (mounted) router.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final runtime = ref.watch(runtimeServiceProvider);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          Positioned(
            left: -130, top: 250,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [purple.withValues(alpha: .12), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            right: -150, bottom: 180,
            child: Container(
              width: 330, height: 330,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [blue.withValues(alpha: .10), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 44),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 92, height: 92,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          colors: [pink, purple, blue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(color: pink.withValues(alpha: .20), blurRadius: 34),
                        ],
                      ),
                      child: const Icon(
                        Icons.code_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      'X-core IDE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'CODE  •  BUILD  •  DEPLOY',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.8,
                      ),
                    ),
                    const SizedBox(height: 42),
                    Text(
                      runtime.status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 17),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 7,
                        color: Colors.white.withValues(alpha: .08),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: runtime.progress.clamp(0.0, 1.0),
                            child: DecoratedBox(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [pink, purple, blue]),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (runtime.status.startsWith('Error')) ...[
                      const SizedBox(height: 22),
                      ElevatedButton(
                        onPressed: () => runtime.init(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pink,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: () => runtime.reset(),
                      child: const Text(
                        'Clean Reinstall',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
