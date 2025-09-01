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
      entry.key: entry.value.map((title) => findExerciseByTitle(title)!).toList(),
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
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // 탭바
                TabBar(
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
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  tabs: exerciseData.keys.map((title) => Tab(text: title)).toList(),
                ),
                const SizedBox(height: 20.0),
                // 탭 내용
                Expanded(
                  child: TabBarView(
                    children: exerciseData.entries.map((entry) {
                      final exercises = entry.value;
                      return ListView.builder(
                        itemCount: exercises.length,
                        itemBuilder: (context, index) {
                          final exercise = exercises[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                     _ExerciseDetailScreen(exercise: exercise),
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

            // 하단 이미지
            Positioned(
              bottom: 20.0,
              right: 20.0,
              child: Image.asset(
                'asset/bottom.png',
                width: 60.0,
                height: 60.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


////// 운동 상세페이지 ////////
class _ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;

  const _ExerciseDetailScreen({
    required this.exercise,
    super.key,
  });

  @override
  State<_ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<_ExerciseDetailScreen> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

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
    if (widget.exercise.gifPath.endsWith('.mp4')) {
      _controller = VideoPlayerController.asset(widget.exercise.gifPath);
      _controller!.initialize().then((_) {
        setState(() {});
        _controller!.play();
        _isPlaying = true;    // 상태반영
      }).catchError((error) {
      });

      _controller!.addListener(() {
        if(mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    /// 뒤로가기시 음성 중지
    _audioPlayer.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE4F3E1),
      appBar: AppBar(
        backgroundColor: Color(0xFFE4F3E1),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
        ),
        title: Text(
          widget.exercise.title,
          style: TextStyle(
            color: Colors.black,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,

        // 팝업 형태로 도움말 띄우기
        actions: [
          IconButton(
            onPressed: (){
              showDialog(
                context: context,
                builder: (context) => _HelpDialog(),
              );
            },
            icon: Icon(
              Icons.help_outline,
              color: Colors.black,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: 24.0,
          vertical: 16.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ////// 운동 동영상 위젯 + 버튼 //////////
            Center(
              child: widget.exercise.gifPath.endsWith('.mp4')
                  ? (_controller != null && _controller!.value.isInitialized
                  ? Container(
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),

                    // 컨드롤 바 //
                    Container(
                      // color: Colors.black.withOpacity(0.4),   // 재생버튼,재생바 뒤에 있는 배경색
                      color: Colors.transparent,
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.0, vertical:  6.0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 아이콘 + 시간표시
                          IconButton(
                            onPressed: () {
                              setState(() {
                                if(_controller!.value.isPlaying){
                                  _controller!.pause();
                                  _isPlaying = false;
                                } else {
                                  _controller!.play();
                                  _isPlaying = true;
                                }
                              });
                            },
                            icon: Icon(_isPlaying
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
                              colors: VideoProgressColors(
                                playedColor: Colors.red,
                                bufferedColor: Colors.grey,
                                backgroundColor: Colors.grey,
                              ),
                            ),
                          ),

                          SizedBox(width: 12.0),

                          // 시간표시
                          Text('${_formatDuration(_controller!.value.position)} /'
                              '${_formatDuration(_controller!.value.duration)}',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                  ],
                ),
              )
                  : CircularProgressIndicator())
                  : Image.asset(widget.exercise.gifPath),
            ),
            // 나중에 Image.asset(exercise.gifPath)로 교체

            SizedBox(height: 30.0),

            // 운동 설명
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.exercise.description.asMap().entries.map((e) {
                int idx = e.key + 1;
                String text = e.value;

                // 앞부분 (예: '시작자세 :')과 나머지로 분리
                List<String> parts = text.split(':');
                String title = parts.length > 1 ? parts[0] : '';
                String body = parts.length > 1 ? parts.sublist(1).join(':') : text;

                return Padding(
                  padding: EdgeInsets.only(bottom: 12.0),  // 항목 사이 간격
                  child: RichText(
                    text: TextSpan(
                      children: [
                        if(title.isNotEmpty)
                          TextSpan(
                            text: '$idx. $title: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                              color: Colors.black,
                            ),
                          ),
                        TextSpan(
                          text: body,
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 40.0),

            // 운동하기 버튼
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(200, 50),    // 버튼 넓이
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 12.0,
                ),
              ),
              onPressed: () async {
                try{
                  ///// 운동 기록 저장 //////
                  final today = DateTime.now();
                  final exerciseName = widget.exercise.title;
                  Provider.of<ExerciseLog>(context, listen: false).addExercise(today, exerciseName);

                  //// 나중에 TTS 또는 오디오 재생 /////
                  await _audioPlayer.play(AssetSource('vo1-1.mp3'));
                  print('운동타이머 출력됨!');
                } catch (e) {
                  print('오디오 재생오류:$e');}
              },
              child: Text('운동하기'),
            ),

            const SizedBox(height: 24),
            // 출처 표시
            Text(
              '출처: <목 디스크 환자도 해야하는 목,어깨 강화 운동 – 신경외과 전무의⦁의학박사 고도일 지음>',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
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
      insetPadding: EdgeInsets.all(30.0),  // 팝업 크기 설정
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.0),
          boxShadow: [   // 그림자 효과
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 3.0,
              blurRadius: 3.0,
            ),
          ],
        ),
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '사용 안내',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20.0,),
            Text(
              '1. 운동시작 전에 영상과 운동방법을 보고 숙지해주세요.',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 10.0,),
            Text(
              '2. 숙지한 후에 운동하기 버튼을 눌러주세요.',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 10.0,),
            Text(
              '3. 버튼을 누르면 삐삐- 타이머 소리가 나오니 맞춰서 운동해주세요.',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 10.0,),
            Text(
              '4. 운동 중에는 올바른 자세를 유지하며, 무리하지 않도록 주의해주세요.',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 20.0,),

            //////// 닫기 버튼
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),   // 버튼 둥굴게
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 40.0,
                    vertical: 12.0,
                  ),
                ),
                onPressed: (){
                  Navigator.pop(context);
                },
                child: Text('닫기'),
              ),
            ),
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
    if (_log.containsKey(key)) {
      if (!_log[key]!.contains(exerciseName)) {
        _log[key]!.add(exerciseName);
      }
    } else {
      _log[key] = [exerciseName];
    }
    notifyListeners();
  }

///// 특정 날짜의 운동 목록 반화 //////
  List<String> getExercisesForDay(DateTime date) {
    final key = _formatDate(date);
    return _log[key] ?? [];
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day
        .toString().padLeft(2, '0')}';
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
    return ListView.builder(
      itemCount: widget.exerciseNames.length,
      itemBuilder: (context, index) {
        final exerciseName = widget.exerciseNames[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => _ExerciseDetailScreen(
                  // ⚠️ 여기서 exercise 찾을 때 index 말고 이름 기준으로 찾아야 안전해요
                  exercise: exercises.firstWhere(
                        (ex) => ex.title == exerciseName,
                    orElse: () => Exercise(
                      title: exerciseName,
                      gifPath: '',
                      description: ['운동 설명이 없습니다.'],
                      voiceGuide: '',
                    ),
                  ),
                ),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.0),
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
                SizedBox(width: 16.0),
                Text(
                  exerciseName,
                  style: TextStyle(
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



