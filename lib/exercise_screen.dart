import 'package:flutter/material.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen>
with TickerProviderStateMixin {
  late final TabController _tabController;

  /// 운동 데이터(이름 + 이미지) ///
  final List<Map<String, dynamic>> exercises = [
    {'name': '턱 당기기','image': 'asset/ex1.jpg',
      'exp':['바른 자세로 앉는다.',
      '턱을 살짝 당겨 목을 곧게 펴준다.',
        '10초간 유지 후 천천히 돌아온다.']
    },
    {'name': '벽 밀기','image': 'asset/ex2.jpg',
      'exp':['양손을 벽에 어깨너비로 댄다.',
        '팔을 펴며 천천히 벽을 민다.',
        '가슴과 어깨가 늘어나는 걸 느끼며 10초 유지']
    },
    {'name': '목 늘리기','image': 'asset/ex3.jpg',
      'exp':['바른 자세로 앉는다.',
        '턱을 살짝 당겨 목을 곧게 펴준다.',
        '10초간 유지 후 천천히 돌아온다.']
    },
    {'name': '턱 당기기','image': 'asset/ex4.jpg',
      'exp':['양손을 벽에 어깨너비로 댄다.',
        '팔을 펴며 천천히 벽을 민다.',
        '가슴과 어깨가 늘어나는 걸 느끼며 10초 유지']
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: exercises.length,
        vsync: this,
    );
    _tabController.addListener((){
      setState(() {});  // 버튼 상태 갱신
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE4F3E1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black),
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
          tabs: exercises.map(
                  (e)=> Tab(
                    icon: Icon(
                     Icons.fitness_center,
                     size: 30.0,
                    ),
                    child: Text(
                      e['name']!,
                      style: const TextStyle(
                        fontSize: 12.0,
                      ),
                    ),
                  )
          ).toList(),
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
                                  Icon(  /// 체크박스 아이콘///
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 20.0,
                                  ),
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
                            ElevatedButton(
                                onPressed: (){
                                  _tabController.animateTo(_tabController.index - 1);
                                },
                                child: const Text('이전'),
                            ),
                          SizedBox(width: 16.0),
                          if(_tabController.index != exercises.length -1)
                            ElevatedButton(
                                onPressed: (){
                                  _tabController.animateTo(_tabController.index + 1);
                                },
                                child: Text('다음'),
                            ),
                        ],
                      ),
                    ],
                  );
                }
        ).toList(),
      ),
    );
  }
}


///////// 설명에 애니메이션 효과 넣기 //////////
class _ExerciseStep extends StatefulWidget {
  final String text;
  final int index;

  const _ExerciseStep({
    required this.text,
    required this.index,
    super.key});

  @override
  State<_ExerciseStep> createState() => _ExerciseStepState();
}

class _ExerciseStepState extends State<_ExerciseStep>
with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this,
    duration: Duration(milliseconds: 500),
    );
    _opacity = CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
    );

    // 약간씩 딜레이 주기
    Future.delayed(
      Duration(milliseconds: 100 * widget.index),
        () {
        if (mounted) _controller.forward();
        }
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20.0,
            ),
            SizedBox(width: 8.0),
            Expanded(
              child: Text(
                '${widget.index + 1}. ${widget.text}',
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
