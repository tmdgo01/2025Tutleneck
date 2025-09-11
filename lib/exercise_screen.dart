import 'package:finalproject/daily_screen.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'exercise_data.dart';
import 'firebase_exercise_service.dart';

class ExerciseScreen extends StatelessWidget {
  ExerciseScreen({super.key});

  // 탭별 운동 이름
  final Map<String, List<String>> rawExerciseData = {
    '일상 스트레칭': [
      '턱 당기기',
      '목 강화 운동1(선 자세)',
      '목 강화 운동2',
      '목 스트레칭1(앉은 자세)',
      '목 스트레칭2(앉은 자세)',
      '좌,우 목 돌리기',
      '원 방향 목 돌리기',
    ],
    '증상 완화 운동': [
      '벽 밀기',
      '가슴 스트레칭',
      '목 강화 운동1',
      'WYT 자세 운동',
      '척추 가동성 운동',
    ],
    '폼롤러 운동': [
      '척추기립근 스트레칭',
      '뒤통수 아래 스트레칭',
      '폼롤러 체스트 오픈',
      '목 스트레칭',
      '등 전체 폼롤러 스트레칭',
      '소흉근 스트레칭',
    ],
  };

  // 운동 이름으로 Exercise 객체 찾기
  Exercise? findExerciseByTitle(String title) {
    return exercises.firstWhere(
          (exercise) => exercise.title == title,
      orElse: () =>
          Exercise(
            title: title,
            gifPath: 'asset/placeholder.png',
            description: ['설명 없음'],
            voiceGuide: '',
            source: '',
          ),
    );
  }

  // 운동 이름 Map → 운동 객체 Map 변환
  late final Map<String, List<Exercise>> exerciseData = {
    for (final entry in rawExerciseData.entries)
      entry.key:
      entry.value.map((title) => findExerciseByTitle(title)!).toList(),
  };

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: exerciseData.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFE4F3E1),
        appBar: AppBar(
          backgroundColor: const Color(0xFFE4F3E1),
          elevation: 0,
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.red,
            indicatorWeight: 4.0,
            labelColor: Colors.green,
            labelStyle: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelColor: Colors.grey,
            unselectedLabelStyle: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w300,
            ),
            tabs: exerciseData.keys.map((title) => Tab(text: title)).toList(),
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 12.0),
                Expanded(
                  child: TabBarView(
                    children: exerciseData.entries.map((entry) {
                      final tabName = entry.key;
                      final tabExercises = entry.value;
                      return ListView.builder(
                        itemCount: tabExercises.length,
                        itemBuilder: (context, index) {
                          final exercise = tabExercises[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      _ExerciseDetailScreen(
                                        exercises: tabExercises,
                                        initialIndex: index,
                                        tabName: tabName,
                                      ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10.0),
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                      width: 60.0,
                                      height: 60.0,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.white,
                                      ),
                                      child: Center(
                                        child: Image.asset(
                                          'asset/1.png',
                                          width: 40.0,
                                          height: 40.0,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16.0),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Text(
                                        exercise.title,
                                        style: const TextStyle(
                                            fontSize: 20.0,
                                            fontWeight: FontWeight.w600,
                                            overflow: TextOverflow.ellipsis
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

////// 운동 상세페이지 ////////
class _ExerciseDetailScreen extends StatefulWidget {
  final List<Exercise> exercises;
  final int initialIndex;
  final String tabName;

  const _ExerciseDetailScreen({
    required this.exercises,
    required this.initialIndex,
    required this.tabName,
    super.key,
  });

  @override
  State<_ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<_ExerciseDetailScreen> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  late int _currentIndex;
  late Exercise _currentExercise;

  // 상태 변수들
  bool _isPlayingVoice = false;        // 음성 재생 중인지
  bool _isExerciseCompleted = false;   // 운동 완료 여부
  bool _hasStartedExercise = false;    // 운동을 시작했는지

  /// 시간표시 함수
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _currentExercise = widget.exercises[_currentIndex];

    print('Current exercise: ${_currentExercise.title}');
    print('Voice guide path: ${_currentExercise.voiceGuide}');

    // 오디오 설정
    _audioPlayer.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: false,
          contentType: AndroidContentType.music,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
      ),
    );

    // 음성 완료 리스너
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        print('Audio playback completed');
        setState(() {
          _isPlayingVoice = false;
          _isExerciseCompleted = true;
        });

        // Firebase에 개별 운동 완료 기록 저장
        _saveIndividualExerciseToFirebase();
      }
    });

    // 오디오 상태 변화 리스너
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      print('Audio player state changed: $state');
      if (mounted && state == PlayerState.stopped) {
        setState(() {
          _isPlayingVoice = false;
        });
      }
    });

    // 비디오 컨트롤러 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _initializeController();
      } catch (e) {
        print('Initial video controller setup error: $e');
      }
    });
  }

  Future<void> _initializeController() async {
    final path = _currentExercise.gifPath;

    // 기존 컨트롤러 정리
    if (_controller != null) {
      _controller!.removeListener(_videoListener);
      await _controller!.pause();
      await _controller!.dispose();
      _controller = null;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (path.endsWith('.mp4')) {
      try {
        _controller = VideoPlayerController.asset(
          path,
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: true,
            allowBackgroundPlayback: false,
          ),
        );

        await _controller!.initialize();

        if (!mounted) {
          await _controller!.dispose();
          return;
        }

        _controller!.addListener(_videoListener);
        await _controller!.setLooping(true);
        setState(() {});

        await _controller!.play();
        _isPlaying = true;

      } catch (error) {
        print('Video initialization error: $error');
        _controller = null;
        if (mounted) {
          setState(() {});
        }
      }
    } else {
      _controller = null;
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _videoListener() {
    if (!mounted || _controller == null || !_controller!.value.isInitialized) return;

    final wasPlaying = _controller!.value.isPlaying;
    if (wasPlaying != _isPlaying) {
      if (mounted) {
        setState(() {
          _isPlaying = wasPlaying;
        });
      }
    }
  }

  // 운동하기 버튼 로직
  Future<void> _handleExerciseButton() async {
    try {
      if (!_hasStartedExercise) {
        // 처음 시작하는 경우
        String voiceGuidePath = _currentExercise.voiceGuide?.trim() ?? '';

        print('Original voiceGuide: "$voiceGuidePath"');

        if (voiceGuidePath.isEmpty || voiceGuidePath == '') {
          // 음성 가이드가 없는 경우 즉시 완료 처리
          print('No voice guide available for: ${_currentExercise.title}');
          setState(() {
            _hasStartedExercise = true;
            _isExerciseCompleted = true;
          });

          // Firebase에 개별 운동 완료 기록 저장
          _saveIndividualExerciseToFirebase();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${_currentExercise.title}: 음성 가이드가 없어 즉시 완료 처리됩니다.'),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.blue,
              ),
            );
          }
          return;
        }

        // 경로 정리: assets/vo1-1.mp3 -> vo1-1.mp3
        String cleanPath = voiceGuidePath;
        if (cleanPath.startsWith('assets/')) {
          cleanPath = cleanPath.substring(7); // 'assets/' 제거
        }

        print('Cleaned audio path for AssetSource: "$cleanPath"');

        try {
          await _audioPlayer.play(AssetSource(cleanPath));
          setState(() {
            _isPlayingVoice = true;
            _hasStartedExercise = true;
          });
          print('Audio playback started successfully with: $cleanPath');
        } catch (audioError) {
          print('Failed to play audio: $audioError');

          // 즉시 완료 처리
          setState(() {
            _isPlayingVoice = false;
            _isExerciseCompleted = true;
            _hasStartedExercise = true;
          });

          // Firebase에 개별 운동 완료 기록 저장
          _saveIndividualExerciseToFirebase();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${_currentExercise.title}: 음성 파일을 재생할 수 없어 완료 처리됩니다.'),
                duration: const Duration(seconds: 3),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        // 이미 시작한 경우 (일시정지/재개)
        if (_isPlayingVoice) {
          await _audioPlayer.pause();
          setState(() {
            _isPlayingVoice = false;
          });
          print('Audio paused');
        } else {
          await _audioPlayer.resume();
          setState(() {
            _isPlayingVoice = true;
          });
          print('Audio resumed');
        }
      }
    } catch (error) {
      print('Exercise button error: $error');
      if (mounted) {
        setState(() {
          _isPlayingVoice = false;
          _isExerciseCompleted = true;
          _hasStartedExercise = true;
        });
      }
    }
  }

  // Firebase에 개별 운동 완료 기록 저장
  Future<void> _saveIndividualExerciseToFirebase() async {
    try {
      await FirebaseExerciseService.saveIndividualExercise(
        exerciseName: _currentExercise.title,
        date: DateTime.now(),
      );
      print('Firebase에 개별 운동 완료 기록 저장 성공: ${_currentExercise.title}');
    } catch (e) {
      print('Firebase에 개별 운동 완료 기록 저장 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('운동 기록 저장에 실패했습니다. 네트워크를 확인해주세요.'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _goToNextExercise() async {
    if (_currentIndex < widget.exercises.length - 1) {
      try {
        await _audioPlayer.stop();

        setState(() {
          _currentIndex++;
          _currentExercise = widget.exercises[_currentIndex];
          _isPlayingVoice = false;
          _isExerciseCompleted = false;
          _hasStartedExercise = false;
        });

        print('Moving to next exercise: ${_currentExercise.title}');
        print('Next exercise voice guide: ${_currentExercise.voiceGuide}');

        await Future.delayed(const Duration(milliseconds: 100));
        await _initializeController();
      } catch (e) {
        print('Error going to next exercise: $e');
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_hasStartedExercise && !_isExerciseCompleted) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('운동 미완료'),
          content: const Text('아직 운동을 완료하지 않으셨습니다.\n정말 나가시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('계속하기'),
            ),
            TextButton(
              onPressed: () async {
                await _audioPlayer.stop();
                Navigator.of(context).pop(true);
              },
              child: const Text('나가기'),
            ),
          ],
        ),
      );
      return result ?? false;
    }
    await _audioPlayer.stop();
    return true;
  }

  @override
  Future<void> dispose() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.dispose();
    } catch (e) {
      print('Audio dispose error: $e');
    }

    try {
      if (_controller != null) {
        _controller!.removeListener(_videoListener);
        if (_controller!.value.isPlaying) {
          await _controller!.pause();
        }
        await _controller!.dispose();
        _controller = null;
      }
    } catch (e) {
      print('Video dispose error: $e');
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentIndex == widget.exercises.length - 1;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFE4F3E1),
        appBar: AppBar(
          backgroundColor: const Color(0xFFE4F3E1),
          elevation: 0,
          leading: IconButton(
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                await _audioPlayer.stop();
                Navigator.pop(context);
              }
            },
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.black,
            ),
          ),
          title: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              _currentExercise.title,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => _HelpDialog(),
                );
              },
              icon: const Icon(
                Icons.help_outline,
                color: Colors.black,
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24.0,
            vertical: 16.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 운동 동영상/이미지
              Center(
                child: _currentExercise.gifPath.endsWith('.mp4')
                    ? (_controller != null && _controller!.value.isInitialized
                    ? Container(
                  constraints: const BoxConstraints(
                    maxHeight: 400,
                    maxWidth: double.infinity,
                  ),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      ),
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6.0,
                          vertical: 6.0,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () async {
                                try {
                                  if (_controller!.value.isPlaying) {
                                    await _controller!.pause();
                                    setState(() {
                                      _isPlaying = false;
                                    });
                                  } else {
                                    await _controller!.play();
                                    setState(() {
                                      _isPlaying = true;
                                    });
                                  }
                                } catch (e) {
                                  print('Video control error: $e');
                                }
                              },
                              icon: Icon(
                                _isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_fill,
                                color: Colors.white,
                                size: 30.0,
                              ),
                            ),
                            Expanded(
                              child: VideoProgressIndicator(
                                _controller!,
                                allowScrubbing: true,
                                colors: const VideoProgressColors(
                                  playedColor: Colors.red,
                                  bufferedColor: Colors.grey,
                                  backgroundColor: Colors.white24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            StreamBuilder(
                              stream: Stream.periodic(const Duration(seconds: 1)),
                              builder: (context, snapshot) {
                                if (_controller == null || !_controller!.value.isInitialized) {
                                  return const Text('00:00 / 00:00', style: TextStyle(color: Colors.white));
                                }
                                return Text(
                                  '${_formatDuration(_controller!.value.position)} / ${_formatDuration(_controller!.value.duration)}',
                                  style: const TextStyle(color: Colors.white),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                    : const Center(child: CircularProgressIndicator()))
                    : Container(
                  constraints: const BoxConstraints(
                    maxHeight: 400,
                    maxWidth: double.infinity,
                  ),
                  child: Image.asset(
                    _currentExercise.gifPath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 30.0),

              // 운동 설명
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children:
                _currentExercise.description.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final text = entry.value;

                  final parts = text.split(':');
                  final title =
                  parts.length > 1 ? parts[0].trim() : '설명';
                  final body = parts.length > 1
                      ? parts.sublist(1).join(':').trim()
                      : text;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$idx. $title',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          body,
                          style: const TextStyle(
                            fontSize: 15.0,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 40.0),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 운동하기 버튼
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 50),
                      backgroundColor: _isPlayingVoice ? Colors.orange : Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _handleExerciseButton,
                    child: Text(_isPlayingVoice ? '일시정지' : '운동하기'),
                  ),

                  const SizedBox(width: 16),

                  // 다음 / 운동 마무리 버튼
                  if (!isLast)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(120, 50),
                        backgroundColor: _isExerciseCompleted ? Colors.green : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isExerciseCompleted ? () async {
                        await _goToNextExercise();
                      } : null,
                      child: const Text('다음'),
                    )
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(120, 50),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        await _audioPlayer.stop();

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFFE4F3E1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            title: Text(
                              "${widget.tabName} 운동 세션 완료!",
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            content: const Text(
                              "이번 운동 세션을 마쳤습니다!\n완료한 개별 운동들이 일지에 기록되었습니다.\n\n어디로 이동하시겠어요?",
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                            actions: [
                              TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.grey[300],
                                  foregroundColor: Colors.black87,
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text("운동 계속하기"),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) => const DailyScreen()),
                                  );
                                },
                                child: const Text("일지 보기"),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text('운동 마무리'),
                    ),
                ],
              ),

              const SizedBox(height: 24),

              // 출처 표시
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _currentExercise.source,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 도움말 팝업
class _HelpDialog extends StatelessWidget {
  const _HelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      insetPadding: const EdgeInsets.all(30.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 3.0,
              blurRadius: 3.0,
            ),
          ],
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              '사용 안내',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20.0),
            Text('1. 운동시작 전에 영상과 운동방법을 보고 숙지해주세요.',
                style: TextStyle(fontSize: 16.0)),
            SizedBox(height: 10.0),
            Text('2. 숙지한 후에 운동하기 버튼을 눌러주세요.',
                style: TextStyle(fontSize: 16.0)),
            SizedBox(height: 10.0),
            Text('3. 버튼을 누르면 삐삐- 타이머 소리가 나오니 맞춰서 운동해주세요.',
                style: TextStyle(fontSize: 16.0)),
            SizedBox(height: 10.0),
            Text('4. 운동 중에는 올바른 자세를 유지하며, 무리하지 않도록 주의해주세요.',
                style: TextStyle(fontSize: 16.0)),
            SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }
}

// 기존 클래스들
class ExerciseLog extends ChangeNotifier {
  final Map<String, List<String>> _log = {};

  void addExercise(DateTime date, String exerciseName) {
    final key = _formatDate(date);

    if (_log.containsKey(key)) {
      _log[key]!.add(exerciseName);
    } else {
      _log[key] = [exerciseName];
    }
    notifyListeners();
  }

  List<String> getExercisesForDay(DateTime date) {
    final key = _formatDate(date);
    return _log[key] ?? [];
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  int get todayCount {
    final todayKey = _formatDate(DateTime.now());
    return _log[todayKey]?.length ?? 0;
  }

  int get weeklyExerciseDays {
    final now = DateTime.now();
    int count = 0;
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      final key = _formatDate(day);
      if (_log.containsKey(key) && (_log[key]?.isNotEmpty ?? false)) {
        count++;
      }
    }
    return count;
  }
}

class ExerciseTab extends StatefulWidget {
  final List<String> exerciseNames;
  final String tabName;

  const ExerciseTab({super.key, required this.exerciseNames, required this.tabName,});

  @override
  State<ExerciseTab> createState() => _ExerciseTabState();
}

class _ExerciseTabState extends State<ExerciseTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final exercisesForTab = widget.exerciseNames.map((name) {
      return exercises.firstWhere(
            (ex) => ex.title == name,
        orElse: () => Exercise(
          title: name,
          gifPath: 'asset/placeholder.png',
          description: const ['운동 설명이 없습니다.'],
          voiceGuide: '',
          source: '',
        ),
      );
    }).toList();

    return ListView.builder(
      itemCount: exercisesForTab.length,
      itemBuilder: (context, index) {
        final exercise = exercisesForTab[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => _ExerciseDetailScreen(
                  exercises: exercisesForTab,
                  initialIndex: index,
                  tabName: widget.tabName,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    width: 60.0,
                    height: 60.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: Center(
                      child: Image.asset(
                        'asset/1.png',
                        width: 40.0,
                        height: 40.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Text(
                  exercise.title,
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}