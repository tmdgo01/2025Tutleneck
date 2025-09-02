import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ExerciseScreen extends StatelessWidget {
  final Map<String, List<String>> exerciseData = {
    '목': ['턱 당기기', '벽 밀기', '맥켄지'],
    '어깨': ['흉부 스트레칭', '날개뼈 모으기', '상부 승모근'],
    '등': ['이두근 스트레칭', '삼두근 스트레칭', '팔 돌리기'],
  };

  ExerciseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // 탭 개수
      child: Scaffold(
        backgroundColor: Color(0xFFE4F3E1),
        appBar: AppBar(
          backgroundColor: Color(0xFFE4F3E1),
          elevation: 0,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context); // 뒤로 가기
            },
            icon: Icon(
              Icons.arrow_back,
              color: Colors.black,
            ),
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // 뒤로가기 버튼 바로 아래 탭바
                TabBar(
                  indicatorColor: Colors.red,
                  indicatorWeight: 4.0,
                  labelColor: Colors.green,
                  labelStyle: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelColor: Colors.grey,
                  unselectedLabelStyle: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w300,
                  ),
                  // 탭바에 적용하는 패딩
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  tabs: [
                    Tab(text: '목'),
                    Tab(text: '어깨'),
                    Tab(text: '등'),
                  ],
                ),
                SizedBox(height: 20.0),
                // 운동 리스트
                Expanded(
                  child: TabBarView(
                    children: exerciseData.entries.map(
                          (e) {
                        return ListView.builder(
                          itemCount: e.value.length,
                          itemBuilder: (context, index) {
                            final exerciseName = e.value[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => _ExerciseDetailScreen(
                                      exercise: exercises[index],
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10.0),
                                child: Row(
                                  children: [
                                    // 거북이 등껍질 이미지
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
                                      e.value[index],
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
                      },
                    ).toList(),
                  ),
                ),
              ],
            ),

            // 하단 이미지
            Positioned(
              bottom: 20.0,
              right: 20.0,
              child: Image.asset(
                'asset/sit.png',
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
        print('🔥 Video initialize error: $error');
      });

      _controller!.addListener(() {
        if(mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
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
        title: Text(widget.exercise.title,
          style: TextStyle(
            color: Colors.black,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
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
                                playedColor: Colors.green,
                                bufferedColor: Colors.grey,
                                backgroundColor: Colors.white,
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

            SizedBox(height: 16.0),

            // 음성 안내 버튼
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                padding: EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 12.0,
                ),
              ),
              onPressed: () {
                // 나중에 TTS 또는 오디오 재생
                print('Play voice: ${widget.exercise.voiceGuide}');
              },
              child: Text('음성 안내'),
            ),

            SizedBox(height: 24.0),

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
          ],
        ),
      ),
    );
  }
}

// 운동 정보
class Exercise {
  final String title;
  final String gifPath;
  final List<String> description;
  final String voiceGuide;

  Exercise({
    required this.title,
    required this.gifPath,
    required this.description,
    required this.voiceGuide,
  });
}

// 운동 리스트 정의
final List<Exercise> exercises = [
  Exercise(
    title: '목 스트레칭',
    gifPath: 'asset/ex1-1.mp4', // 실제 gif 경로 or 임시
    description: [
      '시작자세 : 상체와 어깨를 이완시켜 놓고 양손의 엄지를 턱 아래 부위에 둔다.',
      '동작 : 양손을 모아 두 엄지를 턱의 아래 부위에 대고 서서히 머리를 뒤로 젖힌다.'
          '한계점에 왔을 때 두 엄지에 힘을 가해 머리를 뒤로 좀 더 젖혀 10초간 유지한다.',
      '주의사항 : 목 디스크가 심한경우는 증상을 악화시킬 수 있으므로 목을 뒤로 했을 때'
          '어깨 쪽이나 등쪽에 통증이나 저림이 있는 경우 이 운동을 피한다.',
      '효과: 목 앞의 근육을 스트레칭 시켜주어 그 기능을 원활히 해주는 효과가 있다.'
          '특히 목 코어근육인 경장근을 활성화 시켜 준다.'
    ],
    voiceGuide: 'assets/voice/tuck.mp3', // 실제 음성 파일 경로
  ),
  Exercise(
    title: '턱 당기기',
    gifPath: 'assets/gif/tuck.gif', // 실제 gif 경로 or 임시
    description: [
      '정면을 바라본다.',
      '턱을 당긴다.',
      '5초간 지속한다.',
      '10회 3set 실시'
    ],
    voiceGuide: 'assets/voice/tuck.mp3', // 실제 음성 파일 경로
  ),
  // 다른 운동도 동일하게 추가
];


