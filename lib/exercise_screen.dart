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

  // ExerciseScreen의 build 메서드 전체를 이것으로 교체하세요

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: exerciseData.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFE4F3E1),
        appBar: AppBar(
          backgroundColor: const Color(0xFFE4F3E1),
          elevation: 0,
          // 탭 제목이 많으면 자동 스크롤 가능하도록
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
                // 탭 내용
                Expanded(
                  child: TabBarView(
                    children: exerciseData.entries.map((entry) {
                      final tabName = entry.key; // 탭 이름 가져오기
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
                                        exercises: tabExercises, // 해당 탭 전체 리스트
                                        initialIndex: index, // 선택한 인덱스
                                        tabName: tabName, // 탭 이름 전달
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
  final String tabName; // 추가: 탭 이름

  const _ExerciseDetailScreen({
    required this.exercises,
    required this.initialIndex,
    required this.tabName, // 추가
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

  // 클래스 최상단에 상태 변수 추가
  bool _isPlayingVoice = false;

  /// 시간표시 함수 ////
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

    // 오디오 포커스 설정: 영상 방해하지 않게
    _audioPlayer.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: false,
          contentType: AndroidContentType.music,
          audioFocus: AndroidAudioFocus.none, // 포커스 안 가져오게 설정
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers}, // ios도 동시에 재생 허용
        ),
      ),
    );

    _initializeController();
  }

  void _initializeController() {
    final path = _currentExercise.gifPath;
    _controller?.dispose(); // 기존 컨트롤러 정리

    if (path.endsWith('.mp4')) {
      _controller = VideoPlayerController.asset(path)
        ..initialize().then((_) {
          if (!mounted) return;
          setState(() {});
          _controller!.play();
          _isPlaying = true;
        }).catchError((error) {
          // 필요시 로깅
        });

      _controller!.addListener(() {
        if (!mounted) return;

        final isEnded = _controller!.value.position >= _controller!.value.duration;

        if (isEnded && _isPlaying) {
          setState(() {
            _isPlaying = false; // 영상이 끝났을 때 버튼 상태 변경
          });
        }

        // 이건 재생 시간, 진행바 등 계속 갱신용
        setState(() {});
      });
    } else {
      _controller = null;
      setState(() {}); // 이미지 표시 위해 갱신
    }
  }

  void _goToNextExercise() {
    if (_currentIndex < widget.exercises.length - 1) {
      setState(() {
        _currentIndex++;
        _currentExercise = widget.exercises[_currentIndex];
      });
      _initializeController();
    }
  }

  // 🆕 NEW: 오늘의 운동 완료 액션 (간단 팝업)
  void _onCompleteTodayWorkout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("오늘의 운동 완료 🎉"),
        content: const Text("모든 운동을 끝냈습니다! 수고하셨습니다."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // 팝업 닫기
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _audioPlayer.stop(); // 뒤로가기시 음성 중지
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentIndex == widget.exercises.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFE4F3E1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE4F3E1),
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
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

        // 팝업 형태로 도움말 띄우기
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
            ////// 운동 동영상 위젯 + 버튼 //////////
            Center(
              child: _currentExercise.gifPath.endsWith('.mp4')
                  ? (_controller != null && _controller!.value.isInitialized
                  ? Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  ),
                  // 컨트롤 바 //
                  Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6.0,
                      vertical: 6.0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              if (_controller!.value.isPlaying) {
                                _controller!.pause();
                                _isPlaying = false;
                              } else {
                                _controller!.play();
                                _isPlaying = true;
                              }
                            });
                          },
                          icon: Icon(
                            _isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_fill,
                            color: Colors.white,
                            size: 30.0,
                          ),
                        ),
                        // 진행 바
                        Expanded(
                          child: VideoProgressIndicator(
                            _controller!,
                            allowScrubbing: true,
                            colors: const VideoProgressColors(
                              playedColor: Colors.red,
                              bufferedColor: Colors.grey,
                              backgroundColor: Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        // 시간표시
                        Text(
                          '${_formatDuration(_controller!.value.position)} / ${_formatDuration(_controller!.value.duration)}',
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
                  : const CircularProgressIndicator())
                  : Image.asset(_currentExercise.gifPath),
            ),

            const SizedBox(height: 30.0),

            // 운동 설명
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children:
              _currentExercise.description.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final text = entry.value;

                // '시작자세: 팔을...' 형식 분리
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
                    minimumSize: const Size(150, 50),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 12.0,
                    ),
                  ),
                  onPressed: _isPlayingVoice ? null : () async {
                    final today = DateTime.now();
                    final exerciseName = _currentExercise.title;

                    setState(() {
                      _isPlayingVoice =true; // 버튼 비활성화
                    });

                    try {
                      // Firebase에 운동 기록 저장
                      await FirebaseExerciseService.saveIndividualExercise(
                        exerciseName: exerciseName,
                        date: today,
                      );

                      // 음성 재생
                      print('음성 재생 시도 중...');
                      try {
                        await _audioPlayer.play(AssetSource('vo1-1.mp3'));
                        print('음성 재생 성공');

                        // 음성이 끝나면 다시 버튼 활성화
                        _audioPlayer.onPlayerComplete.listen((event) {
                          if (mounted) {
                            setState(() {
                              _isPlayingVoice = false;
                            });
                          }
                        });

                      } catch (audioError) {
                        print('음성 재생 실패: $audioError');

                        // 대체 음성 파일 시도
                        try {
                          await _audioPlayer.play(AssetSource('vo1-1.wav'));
                          print('대체 음성 재생 성공');
                        } catch (altAudioError) {
                          print('대체 음성도 실패: $altAudioError');
                        }
                      }
                    } catch (e) {
                      print('운동 기록 저장 실패: $e');

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.error, color: Colors.white),
                                SizedBox(width: 8),
                                Text('기록 저장에 실패했습니다'),
                              ],
                            ),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }

                      setState(() {
                        _isPlayingVoice = false;
                      });
                    }
                  },
                  child: const Text('운동하기'),
                ),

                const SizedBox(width: 16),

                // 다음 / 오늘의 운동 완료
                // 마지막 운동일 때의 버튼을 다음과 같이 수정
                if (!isLast)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(150, 50),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      _audioPlayer.stop();
                      _goToNextExercise();
                    },
                    child: const Text('다음'),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(150, 50),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      _audioPlayer.stop();

                      // 완료 팝업만 띄우고 Firebase 조작은 하지 않음
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFFE4F3E1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          title: Text(
                            "${widget.tabName} 운동 완료!",
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          content: const Text(
                            "모든 운동을 마쳤습니다!\n각 운동을 더 많이 하면 탭 완료 횟수가 증가합니다.\n\n어디로 이동하시겠어요?",
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
    );
  }
}

/// 도움말 팝업으로 사용안내 띄우기!! ////
class _HelpDialog extends StatelessWidget {
  const _HelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      insetPadding: const EdgeInsets.all(30.0), // 팝업 크기 설정
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.0),
          boxShadow: [
            // 그림자 효과
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

////// 날짜별 운동 기록 저장 //////
class ExerciseLog extends ChangeNotifier {
  final Map<String, List<String>> _log = {};

  //// 운동기록 추가 /////
  void addExercise(DateTime date, String exerciseName) {
    final key = _formatDate(date);

    // 중복 허용
    if (_log.containsKey(key)) {
      _log[key]!.add(exerciseName);
    } else {
      _log[key] = [exerciseName];
    }
    notifyListeners();
  }

  ///// 특정 날짜의 운동 목록 반환 //////
  List<String> getExercisesForDay(DateTime date) {
    final key = _formatDate(date);
    return _log[key] ?? [];
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 오늘 운동 횟수 반환
  int get todayCount {
    final todayKey = _formatDate(DateTime.now());
    return _log[todayKey]?.length ?? 0;
  }

  /// 최근 7일간 운동한 일수 반환
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