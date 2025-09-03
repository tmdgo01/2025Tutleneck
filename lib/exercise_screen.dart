import 'package:finalproject/daily_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'exercise_data.dart';

class ExerciseScreen extends StatelessWidget {
  ExerciseScreen({super.key});

  // 탭별 운동 이름
  final Map<String, List<String>> rawExerciseData = {
    '풀 운동': [
      '상하 호흡운동',
      '목 정렬 운동',
      '목 스트레칭:전방',
      '목 스트레칭:후방',
      '목 스트레칭:외측',
      '목 스트레칭:외측2',
      '목 돌리기',
      '목 돌리기2',
      '어깨 돌리기',
      '어깨 스트레칭',
      '어깨, 가슴, 등 스트레칭',
    ],
    '간편 운동1': [
      '상하 호흡운동',
      '목 정렬 운동',
      '목 돌리기',
      '목 돌리기2',
      '어깨 돌리기',
      '어깨 스트레칭',
      '어깨, 가슴, 등 스트레칭',
    ],
    '간편 운동2': [
      '목 정렬 운동',
      '목 스트레칭:전방',
      '목 스트레칭:후방',
      '목 스트레칭:외측',
      '목 스트레칭:외측2',
      '어깨 스트레칭',
      '어깨, 가슴, 등 스트레칭',
    ],
  };

  // 운동 이름으로 Exercise 객체 찾기
  Exercise? findExerciseByTitle(String title) {
    return exercises.firstWhere(
          (exercise) => exercise.title == title,
      orElse: () => Exercise(
        title: title,
        gifPath: 'asset/placeholder.png',
        description: ['설명 없음'],
        voiceGuide: '',
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
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.black),
          ),
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
                                  builder: (context) => _ExerciseDetailScreen(
                                    exercises: tabExercises, // 해당 탭 전체 리스트
                                    initialIndex: index, // 선택한 인덱스
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

  const _ExerciseDetailScreen({
    required this.exercises,
    required this.initialIndex,
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
        if (mounted) setState(() {});
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
        content: const Text("모든 운동을 끝냈습니다! 수고하셨어요."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // 팝업 닫기
            child: const Text("확인"),
          ),
          // 필요하면 홈/이전 화면으로 이동:
          // TextButton(
          //   onPressed: () {
          //     Navigator.pop(context); // 팝업
          //     Navigator.pop(context); // 상세 → 리스트로
          //   },
          //   child: const Text("뒤로"),
          // )
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
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
        ),
        title: Text(
          _currentExercise.title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,

        // 팝업 형태로 도움말 띄우기
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const _HelpDialog(),
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

            // 🔧"운동하기" + "다음/오늘의 운동 완료" 버튼을 나란히 배치
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
                  onPressed: () async {
                    try {
                      // 운동 기록 저장
                      final today = DateTime.now();
                      final exerciseName = _currentExercise.title;
                      Provider.of<ExerciseLog>(context, listen: false)
                          .addExercise(today, exerciseName);

                      // 오디오 재생
                      await _audioPlayer.play(AssetSource('vo1-1.mp3'));
                      // print('운동타이머 출력됨!');
                    } catch (e) {
                      // print('오디오 재생오류:$e');
                    }
                  },
                  child: const Text('운동하기'),
                ),

                const SizedBox(width: 16),

                // 다음 / 오늘의 운동 완료
                if (!isLast)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(150, 50),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _goToNextExercise,
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
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: Color(0xFFE4F3E1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          title: const Text(
                              "오늘의 운동 완료 🎉",
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: const Text(
                              "모든 운동을 끝냈습니다! 수고하셨어요.",
                            style: TextStyle(
                              color: Colors.black87,
                            ),
                          ),
                          actions: [
                            TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                // 팝업 닫기
                                Navigator.pop(context);
                                // 메인 화면(첫 화면)까지 이동
                                Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (context) => const DailyScreen()),
                                    (route) => route.isFirst,
                                );
                              },
                              child: const Text("확인"),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('오늘의 운동 완료'),
                  ),
              ],
            ),

            const SizedBox(height: 24),

            // 출처 표시
            const Text(
              '출처: <목 디스크 환자도 해야하는 목,어깨 강화 운동 – 신경외과 전무의⦁의학박사 고도일 지음>',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
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
}

///// 탭 상태 /////
class ExerciseTab extends StatefulWidget {
  final List<String> exerciseNames;
  const ExerciseTab({super.key, required this.exerciseNames});

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
