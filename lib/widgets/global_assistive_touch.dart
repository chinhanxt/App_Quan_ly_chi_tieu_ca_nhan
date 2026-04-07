import 'dart:math' as math;
import 'dart:ui';

import 'package:app/screens/add_transaction_screen.dart';
import 'package:app/screens/ai_input_screen.dart';
import 'package:app/screens/dashboard.dart';
import 'package:app/screens/search_screen.dart';
import 'package:app/screens/saving_goals_screen.dart';
import 'package:app/utils/app_colors.dart';
import 'package:app/utils/app_navigation.dart';
import 'package:flutter/material.dart';

class GlobalAssistiveTouch extends StatefulWidget {
  const GlobalAssistiveTouch({super.key});

  @override
  State<GlobalAssistiveTouch> createState() => _GlobalAssistiveTouchState();
}

class _GlobalAssistiveTouchState extends State<GlobalAssistiveTouch>
    with SingleTickerProviderStateMixin {
  static const double _buttonSize = 58;
  static const double _menuSize = 332;
  static const double _orbitRadius = 114;
  static const double _actionBubbleSize = 72;

  late final AnimationController _glowController;
  Offset? _position;
  bool _isPressed = false;
  bool _isMenuOpen = false;
  bool _wasDragging = false;
  String? _previewLabel;
  String? _activeActionLabel;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      lowerBound: 0,
      upperBound: 1,
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _ensureInitialPosition(Size size, EdgeInsets padding) {
    _position ??= Offset(
      size.width - _buttonSize - 14,
      size.height - _buttonSize - padding.bottom - 124,
    );
  }

  Offset _clampPosition(Offset desired, Size size, EdgeInsets padding) {
    final minX = 10.0;
    final maxX = size.width - _buttonSize - 10;
    final minY = padding.top + 12;
    final maxY = size.height - _buttonSize - padding.bottom - 14;

    return Offset(
      desired.dx.clamp(minX, maxX),
      desired.dy.clamp(minY, maxY),
    );
  }

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() {
      _isPressed = value;
    });
    if (value) {
      _glowController.forward();
    } else {
      _glowController.reverse();
    }
  }

  Future<void> _pushScreen(Widget screen) async {
    setState(() {
      _isMenuOpen = false;
      _previewLabel = null;
    });
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;
    await navigator.push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _openDashboardTab(int index) async {
    setState(() {
      _isMenuOpen = false;
      _previewLabel = null;
    });
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;
    await navigator.push(MaterialPageRoute(builder: (_) => Dashboard(initialIndex: index)));
  }

  List<_AssistiveAction> _actions() {
    return <_AssistiveAction>[
      _AssistiveAction(
        label: 'Home',
        icon: Icons.home_rounded,
        gradient: const [Color(0xFF5DAE8B), Color(0xFF2F6A58)],
        onTap: () => _openDashboardTab(0),
      ),
      _AssistiveAction(
        label: 'AI',
        icon: Icons.auto_awesome_rounded,
        gradient: const [AppColors.gold, AppColors.accentStrong],
        onTap: () => _pushScreen(const AIInputScreen()),
      ),
      _AssistiveAction(
        label: 'Thêm',
        icon: Icons.add_rounded,
        gradient: const [AppColors.primary, AppColors.primaryDark],
        onTap: () => _pushScreen(const AddTransactionScreen()),
      ),
      _AssistiveAction(
        label: 'Tiết kiệm',
        icon: Icons.savings_outlined,
        gradient: const [Color(0xFF75C89A), Color(0xFF4C9B70)],
        onTap: () => _pushScreen(const SavingGoalsScreen()),
      ),
      _AssistiveAction(
        label: 'Tìm kiếm',
        icon: Icons.search_rounded,
        gradient: const [Color(0xFF81C7D4), Color(0xFF4C8EA0)],
        onTap: () => _pushScreen(const SearchScreen()),
      ),
      _AssistiveAction(
        label: 'Giao dịch',
        icon: Icons.receipt_long_rounded,
        gradient: const [Color(0xFFF1C27D), Color(0xFFD69E4B)],
        onTap: () => _openDashboardTab(1),
      ),
      _AssistiveAction(
        label: 'Ngân sách',
        icon: Icons.account_balance_wallet_rounded,
        gradient: const [Color(0xFF8CB8FF), Color(0xFF4F7DDB)],
        onTap: () => _openDashboardTab(2),
      ),
      _AssistiveAction(
        label: 'Báo cáo',
        icon: Icons.bar_chart_rounded,
        gradient: const [Color(0xFFDF9D74), Color(0xFFB96C4B)],
        onTap: () => _openDashboardTab(3),
      ),
      _AssistiveAction(
        label: 'Cài đặt',
        icon: Icons.tune_rounded,
        gradient: const [Color(0xFF9D9CCF), Color(0xFF67659A)],
        onTap: () => _openDashboardTab(4),
      ),
    ];
  }

  Widget _buildRadialAction({
    required _AssistiveAction action,
    required Offset offset,
  }) {
    final isActive = _activeActionLabel == action.label;

    return Transform.translate(
      offset: offset,
      child: SizedBox(
        width: 98,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MouseRegion(
              onEnter: (_) {
                setState(() {
                  _previewLabel = action.label;
                });
              },
              onExit: (_) {
                setState(() {
                  if (_previewLabel == action.label) {
                    _previewLabel = null;
                  }
                });
              },
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) {
                    setState(() {
                      _previewLabel = action.label;
                      _activeActionLabel = action.label;
                    });
                  },
                  onTapCancel: () {
                    setState(() {
                      if (_previewLabel == action.label) {
                        _previewLabel = null;
                      }
                      if (_activeActionLabel == action.label) {
                        _activeActionLabel = null;
                      }
                    });
                  },
                  onLongPressDown: (_) {
                    setState(() {
                      _previewLabel = action.label;
                      _activeActionLabel = action.label;
                    });
                  },
                  onLongPressCancel: () {
                    setState(() {
                      if (_previewLabel == action.label) {
                        _previewLabel = null;
                      }
                      if (_activeActionLabel == action.label) {
                        _activeActionLabel = null;
                      }
                    });
                  },
                  onTap: action.onTap,
                  child: AnimatedScale(
                    scale: isActive ? 1.07 : 1,
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOut,
                    child: Container(
                      width: _actionBubbleSize,
                      height: _actionBubbleSize,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: action.gradient,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: isActive ? 0.24 : 0.16,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isActive ? 0.14 : 0.10,
                            ),
                            blurRadius: isActive ? 20 : 16,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Icon(
                        action.icon,
                        color: Colors.white.withValues(alpha: isActive ? 1 : 0.96),
                        size: isActive ? 29 : 27,
                        shadows: [
                          Shadow(
                            color: Colors.white.withValues(
                              alpha: isActive ? 0.48 : 0.22,
                            ),
                            blurRadius: isActive ? 14 : 6,
                            offset: const Offset(0, 0),
                          ),
                          Shadow(
                            color: Colors.white.withValues(
                              alpha: isActive ? 0.18 : 0,
                            ),
                            blurRadius: isActive ? 24 : 0,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularMenu() {
    final actions = _actions();
    final step = (2 * math.pi) / actions.length;
    const startAngle = -math.pi / 2;

    return SizedBox(
      width: _menuSize,
      height: _menuSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                width: _menuSize,
                height: _menuSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.16),
                      AppColors.primary.withValues(alpha: 0.10),
                      const Color(0xFF140A35).withValues(alpha: 0.18),
                    ],
                    stops: const [0, 0.5, 1],
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 1),
                    ),
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.10),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          for (var i = 0; i < actions.length; i++)
            Builder(
              builder: (context) {
                final angle = startAngle + (step * i);
                final dx = math.cos(angle) * _orbitRadius;
                final dy = math.sin(angle) * _orbitRadius;
                return _buildRadialAction(
                  action: actions[i],
                  offset: Offset(dx, dy),
                );
              },
            ),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.24),
                  Colors.white.withValues(alpha: 0.14),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  _previewLabel ?? 'Menu',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _previewLabel == null
                        ? AppColors.primaryDark.withValues(alpha: 0.78)
                        : const Color(0xFF102320),
                    fontSize: _previewLabel == null ? 13 : 14.5,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                    decoration: TextDecoration.none,
                    letterSpacing: -0.15,
                    shadows: [
                      Shadow(
                        color: Colors.white.withValues(
                          alpha: _previewLabel == null ? 0.26 : 0.42,
                        ),
                        blurRadius: _previewLabel == null ? 12 : 18,
                        offset: const Offset(0, 1),
                      ),
                      Shadow(
                        color: Colors.white.withValues(
                          alpha: _previewLabel == null ? 0.08 : 0.22,
                        ),
                        blurRadius: _previewLabel == null ? 3 : 8,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _ensureInitialPosition(size, mediaQuery.padding);
        final position = _clampPosition(
          _position ?? Offset.zero,
          size,
          mediaQuery.padding,
        );
        _position = position;
        final menuLeft = ((size.width - _menuSize) / 2).clamp(
          8.0,
          size.width - _menuSize - 8,
        );
        final menuTop = ((size.height - _menuSize) / 2).clamp(
          mediaQuery.padding.top + 8,
          size.height - _menuSize - mediaQuery.padding.bottom - 8,
        );

        return Stack(
          children: [
            if (_isMenuOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isMenuOpen = false;
                      _previewLabel = null;
                      _activeActionLabel = null;
                    });
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),
            if (_isMenuOpen)
              Positioned(
                left: menuLeft,
                top: menuTop,
                child: AnimatedOpacity(
                  opacity: _isMenuOpen ? 1 : 0,
                  duration: const Duration(milliseconds: 160),
                  child: AnimatedScale(
                    scale: _isMenuOpen ? 1 : 0.92,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutBack,
                    child: _buildCircularMenu(),
                  ),
                ),
              ),
            Positioned(
              left: position.dx,
              top: position.dy,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (_) {
                  _wasDragging = false;
                  _setPressed(true);
                  if (_isMenuOpen) {
                    setState(() {
                      _isMenuOpen = false;
                      _previewLabel = null;
                      _activeActionLabel = null;
                    });
                  }
                },
                onPanUpdate: (details) {
                  _wasDragging = true;
                  setState(() {
                    _position = _clampPosition(
                      (_position ?? position) + details.delta,
                      size,
                      mediaQuery.padding,
                    );
                  });
                },
                onPanEnd: (_) {
                  _setPressed(false);
                  _wasDragging = false;
                },
                onTapDown: (_) {
                  _wasDragging = false;
                  _setPressed(true);
                },
                onTapCancel: () {
                  _setPressed(false);
                  _wasDragging = false;
                },
                onTapUp: (_) {
                  _setPressed(false);
                  if (_wasDragging) {
                    _wasDragging = false;
                    return;
                  }
                  setState(() {
                    _isMenuOpen = !_isMenuOpen;
                    if (!_isMenuOpen) {
                      _previewLabel = null;
                      _activeActionLabel = null;
                    }
                  });
                },
                child: AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    final activeOpacity = _isPressed ? 0.42 : 0.24;
                    return AnimatedScale(
                      scale: _isPressed ? 1.05 : 1,
                      duration: const Duration(milliseconds: 90),
                      child: Container(
                        width: _buttonSize,
                        height: _buttonSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF17332D).withValues(
                            alpha: activeOpacity,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: 0.10 + (_glowController.value * 0.10),
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(
                                alpha: 0.08 + (_glowController.value * 0.10),
                              ),
                              blurRadius: 16 + (_glowController.value * 10),
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isMenuOpen
                              ? Icons.close_rounded
                              : Icons.dashboard_customize_rounded,
                          color: Colors.white.withValues(
                            alpha: 0.88 + (_glowController.value * 0.12),
                          ),
                          size: 24,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AssistiveAction {
  const _AssistiveAction({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;
}
