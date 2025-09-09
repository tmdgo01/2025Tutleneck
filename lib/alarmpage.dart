import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'exercise_screen.dart';
import 'dart:async';

class AlarmPage extends StatefulWidget {
  final String alarmLabel;
  final String alarmTime;
  final VoidCallback? onDismiss;

  const AlarmPage({
    super.key,
    required this.alarmLabel,
    required this.alarmTime,
    this.onDismiss,
  });

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _bounceController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;
  Timer? _vibrationTimer;

  @override
  void initState() {
    super.initState();

    // 펄스 애니메이션 (거북이 주변 원)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // 바운스 애니메이션 (거북이)
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticInOut,
    ));

    // 애니메이션 시작
    _pulseController.repeat(reverse: true);
    _bounceController.repeat(reverse: true);

    // 주기적 진동
    _startVibration();

    // 시스템 UI 숨기기 (전체화면)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bounceController.dispose();
    _vibrationTimer?.cancel();

    // 시스템 UI 복원
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);

    super.dispose();
  }

  void _startVibration() {
    // 즉시 진동
    HapticFeedback.vibrate();

    // 3초마다 진동 반복
    _vibrationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      HapticFeedback.vibrate();
    });
  }

  void _dismissAlarm() {
    _vibrationTimer?.cancel();
    widget.onDismiss?.call();
    Navigator.of(context).pop();
  }

  void _acceptAlarm() {
    _vibrationTimer?.cancel();
    widget.onDismiss?.call();

    // 운동 화면으로 이동
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ExerciseScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4F3E1), // 연한 초록색 배경
      body: SafeArea(
        child: Column(
          children: [
            // 상단 제목
            const SizedBox(height: 80),
            const Text(
              '운동해',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E7D32),
                letterSpacing: 2.0,
              ),
            ),

            // 중앙 거북이 영역
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _bounceAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _bounceAnimation.value,
                                child: Image.asset(
                                  'asset/stand.png',
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    // 이미지 로드 실패 시 대체 아이콘
                                    return Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4CAF50).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(60),
                                      ),
                                      child: const Icon(
                                        Icons.directions_run,
                                        size: 60,
                                        color: Color(0xFF4CAF50),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // 하단 버튼들
            Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 거절 버튼 (빨간색 X)
                  GestureDetector(
                    onTap: _dismissAlarm,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE57373), // 부드러운 빨간색
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE57373).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),

                  // 수락 버튼 (초록색 전화)
                  GestureDetector(
                    onTap: _acceptAlarm,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF66BB6A), // 부드러운 초록색
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF66BB6A).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.call,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}