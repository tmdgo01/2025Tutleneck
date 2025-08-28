import 'package:flutter/material.dart';

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

// 운동 상세페이지
class _ExerciseDetailScreen extends StatelessWidget {
  final Exercise exercise;

  const _ExerciseDetailScreen({
    required this.exercise,
    super.key,
  });

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
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 24.0,
          vertical: 16.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 운동 이미지 or gif
            Container(
              height: 200.0,
              color: Colors.grey[300],
              child: Center(
                child: Text('GIF: ${exercise.gifPath}'),
                // 나중에 Image.asset(exercise.gifPath)로 교체
              ),
            ),
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
                print('Play voice: ${exercise.voiceGuide}');
              },
              child: Text('음성 안내'),
            ),

            SizedBox(height: 24.0),

            // 운동 설명
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: exercise.description.asMap().entries.map((e) {
                int idx = e.key + 1;
                return Text('$idx. ${e.value}');
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
