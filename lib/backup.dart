import 'package:flutter/material.dart';
import 'dart:async';   // 타이머를 위해 필요
import 'package:audioplayers/audioplayers.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  List<bool> isCompleted = [];
  List<int> remainingSeconds = [];
  List<Timer?> timers = [];


  /// 운동 데이터(이름 + 이미지) ///
  final List<Map<String, dynamic>> exercises = [
    {'name': '턱 당기기',
      'image': 'asset/ex1.jpg',
      'exp':['바른 자세로 앉는다.',
        '턱을 살짝 당겨 목을 곧게 펴준다.',
        '10초간 유지 후 천천히 돌아온다.',
      ],
      'duration': 5,   // 운동 타이머
    },
    {'name': '벽 밀기',
      'image': 'asset/ex2.jpg',
      'exp':['양손을 벽에 어깨너비로 댄다.',
        '팔을 펴며 천천히 벽을 민다.',
        '가슴과 어깨가 늘어나는 걸 느끼며 10초 유지'],
      'duration': 5,
    },
    {'name': '맥켄지',
      'image': 'asset/ex3.jpg',
      'exp':['바른 자세로 앉는다.',
        '턱을 살짝 당겨 목을 곧게 펴준다.',
        '10초간 유지 후 천천히 돌아온다.'],
      'duration': 5,
    },
    {'name': '흉부 스트레칭',
      'image': 'asset/ex4.jpg',
      'exp':['양손을 벽에 어깨너비로 댄다.',
        '팔을 펴며 천천히 벽을 민다.',
        '가슴과 어깨가 늘어나는 걸 느끼며 10초 유지'],
      'duration': 5,
    },
    {'name': '날개뼈 모으기',
      'image': 'asset/ex3.jpg',
      'exp':['바른 자세로 앉는다.',
        '턱을 살짝 당겨 목을 곧게 펴준다.',
        '10초간 유지 후 천천히 돌아온다.'],
      'duration': 5,
    },
    {'name': '상부 승모근',
      'image': 'asset/ex4.jpg',
      'exp':['양손을 벽에 어깨너비로 댄다.',
        '팔을 펴며 천천히 벽을 민다.',
        '가슴과 어깨가 늘어나는 걸 느끼며 10초 유지'],
      'duration': 5,
    },
  ];

  // 팝업 //
  Future<void> _showCompletionDialog(int exerciseIndex) async {
    await showDialog(
      context: context,
      barrierDismissible: false,   // 외부 터치로 닫기 방지
      builder: (context) =>
          AlertDialog(
            title: Text('운동 완료!'),
            content: Text('${exercises[exerciseIndex]['name']} 운동을 완료했습니다!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // 팝업 닫기

                  // 해당 운동만 초기화 (완료 상태는 유지)
                  _resetExerciseTimer(exerciseIndex);
                },
                child: Text('확인'),
              ),
            ],
          ),
    );
  }

  // 개별 운동 타이머만 초기화 //
  void _resetExerciseTimer(int index) {
    setState(() {
      remainingSeconds[index] = exercises[index]['duration'];
      // isCompleted[index]는 그대로 유지 (완료 표시 유지)
    });
  }

  // 특정 운동의 완료 상태만 리셋하는 함수
  void _resetExerciseCompletion(int index) {
    setState(() {
      isCompleted[index] = false;
      remainingSeconds[index] = exercises[index]['duration'];
      timers[index]?.cancel();
      timers[index] = null;
    });
  }


  // 초기화 //
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: exercises.length,
      vsync: this,
    );
    // _tabController.addListener((){
    //   resetState();  // 탭 변경시 초기화
    // });
    resetState();  // 최초 초기화
  }

  void resetState() {
    setState(() {
      timers.forEach((t) => t?.cancel());
      timers = List.generate(exercises.length, (_) => null);
      remainingSeconds = List.generate(exercises.length, (i) => exercises[i]['duration']);
      isCompleted = List.generate(exercises.length, (_) => false);
    });
  }

  // 타이머 사용할 때 앱 닫히거나 탭 바뀌면 메모리 누수 방지를 위해 타이머를 모두 취소
  @override
  void dispose() {
    for (var timer in timers) {
      timer?.cancel();
    }
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE4F3E1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          color: Colors.black,
          // 뒤로가기 버튼 눌렀을 때만 초기화
          onPressed: () {
            resetState();
            Navigator.of(context).pop();
          },
        ),
        title: const Text('운동 탭',
          style: TextStyle(color: Colors.black),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.green,
          labelStyle: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w700,
              color: Colors.green
          ),
          unselectedLabelStyle: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w200,
              color: Colors.grey
          ),
          tabs: List.generate(
              exercises.length,
                  (i) {
                return Tab(
                  icon: Icon(
                    Icons.fitness_center,
                    size: 30.0,
                  ),
                  child: Text(
                    isCompleted[i] ? '${exercises[i]['name']} ✅'
                        : exercises[i]['name'],   // 타이머 완료되면 체크표시
                    style: TextStyle(
                      fontSize: 12.0,
                    ),
                  ),
                );
              }
          ),
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: exercises.map(
                (e){
              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 10.0,),
                  Text(
                    e['name']!,
                    style: const TextStyle(
                      fontSize: 24.0,
                    ),
                  ),
                  Image.asset(e['image']!,
                    width: 200,
                    height: 200,
                  ),
                  const SizedBox(height: 16.0),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                      List.generate(
                          e['exp'].length,
                              (index) {
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 4.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(width: 8.0),
                                  Expanded(
                                    child: Text('${index + 1}.${e['exp'][index]}',
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                      ),
                    ),
                  ),

                  const SizedBox(height: 32.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if(_tabController.index !=0)
                        ElevatedButton.icon(
                          onPressed: (){
                            _tabController.animateTo(_tabController.index - 1);
                          },
                          icon: Icon(Icons.arrow_back),
                          label: Text('이전'),
                        ),
                      SizedBox(width: 16.0),
                      if(_tabController.index != exercises.length -1)
                        ElevatedButton.icon(
                          onPressed: (){
                            _tabController.animateTo(_tabController.index + 1);
                          },
                          icon: Icon(Icons.arrow_forward),
                          label: Text('다음'),
                        ),
                    ],
                  ),
                  SizedBox(height: 16.0),

                  ElevatedButton(
                    onPressed: (){
                      final int currentIndex = _tabController.index;

                      if(timers[currentIndex] != null) return;  // 이미 동작 중이면 무시
                      setState(() {
                        remainingSeconds[currentIndex] = exercises[currentIndex]['duration'];   // 60 초 타이머
                      });

                      timers[currentIndex] = Timer.periodic(
                        Duration(seconds: 1),
                            (timer) async {
                          if (remainingSeconds[currentIndex] > 1 ) {
                            setState(() {
                              remainingSeconds[currentIndex]--;
                            });
                          } else {
                            // 타이머 종료
                            timer.cancel();
                            timers[currentIndex] = null;
                            setState(() {
                              isCompleted[currentIndex] = true;   // 탭바용 완료 표시
                              remainingSeconds[currentIndex] = 0;

                            });

                            await _showCompletionDialog(currentIndex);  // 팝업

                            // 팝업 닫은 뒤 타이머만 초기화 (완료표시는 유지!)
                            setState(() {
                              // isCompleted[currentIndex] = false;
                              remainingSeconds[currentIndex] = exercises[currentIndex]['duration'];
                            });
                          }
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCompleted[_tabController.index]
                          ? Colors.orange
                          : Colors.red,
                    ),
                    child: Text(
                      isCompleted[_tabController.index]
                          ? '완료됨 ✅'
                          : (timers[_tabController.index] != null
                          ? '${remainingSeconds[_tabController.index]}초'
                          : '${exercises[_tabController.index]['duration']}초'),
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            }
        ).toList(),
      ),
    );
  }
}



