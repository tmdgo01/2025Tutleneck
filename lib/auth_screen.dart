import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finalproject/posture_service.dart';
import 'package:finalproject/main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final postureService = PostureService();

      if (isLogin) {
        // 로그인
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // PostureService 사용자 데이터 초기화
        await postureService.initializeUserData();

        // 사용자별 SharedPreferences 키 생성
        final userId = userCredential.user?.uid ?? 'anonymous';

        // 기존 설정값이 없으면 기본값 설정 (사용자별)
        if (!prefs.containsKey('postureTargetScore_$userId')) {
          await prefs.setInt('postureTargetScore_$userId', 80);
        }
        if (!prefs.containsKey('weeklyMeasurementDays_$userId')) {
          await prefs.setInt('weeklyMeasurementDays_$userId', 5);
        }

        if (mounted) {
          // 방법 1: 전체 앱을 MyApp으로 교체 (권장)
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MyApp()),
                (route) => false,
          );

          // 방법 2: 단순히 뒤로가기 (AuthWrapper가 자동으로 HomeScreen 표시)
          // Navigator.of(context).pop();
        }
      } else {
        // 회원가입
        UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final user = userCredential.user;
        if (user != null) {
          // Firestore에 사용자 추가 정보 저장
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
          });

          // Firebase Auth에 사용자 이름 업데이트
          await user.updateDisplayName(_nameController.text.trim());

          // PostureService 새 사용자 데이터 초기화
          await postureService.initializeUserData();
        }

        // 새 사용자 SharedPreferences 초기값 저장 (사용자별)
        final userId = user?.uid ?? 'anonymous';
        await prefs.setInt('postureTargetScore_$userId', 80);
        await prefs.setInt('weeklyMeasurementDays_$userId', 5);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('회원가입이 완료되었습니다!'),
              backgroundColor: Colors.green,
            ),
          );

          // 회원가입 후에도 동일하게 MyApp으로 이동
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MyApp()),
                (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = '오류가 발생했습니다.';
      if (e.code == 'weak-password') {
        errorMessage = '비밀번호가 너무 약합니다.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = '이미 사용 중인 이메일입니다.';
      } else if (e.code == 'user-not-found') {
        errorMessage = '등록되지 않은 이메일입니다.';
      } else if (e.code == 'wrong-password') {
        errorMessage = '비밀번호가 잘못되었습니다.';
      } else if (e.code == 'invalid-email') {
        errorMessage = '올바르지 않은 이메일 형식입니다.';
      } else if (e.code == 'network-request-failed') {
        errorMessage = '네트워크 연결을 확인해주세요.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    } catch (e) {
      debugPrint('로그인/회원가입 중 상세 오류: $e');
      debugPrint('에러 타입: ${e.runtimeType}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류 발생: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4F3E1),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 로고 및 타이틀
                  Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.green[300],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.pets,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'tutle neck',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // 입력 필드
                  if (!isLogin) ...[
                    _buildInputField(
                      controller: _nameController,
                      hintText: '이름을 입력하세요',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '이름을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildInputField(
                    controller: _emailController,
                    hintText: '아이디를 입력하세요',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '아이디를 입력해주세요';
                      }
                      if (!value.contains('@')) {
                        return '올바른 이메일 형식을 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    controller: _passwordController,
                    hintText: '비밀번호를 입력하세요',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '비밀번호를 입력해주세요';
                      }
                      if (value.length < 6) {
                        return '비밀번호는 6자 이상이어야 합니다';
                      }
                      return null;
                    },
                  ),
                  if (!isLogin) ...[
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _confirmPasswordController,
                      hintText: '비밀번호를 다시 입력하세요',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '비밀번호 확인을 입력해주세요';
                        }
                        if (value != _passwordController.text) {
                          return '비밀번호가 일치하지 않습니다';
                        }
                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD2F0DC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                        color: Colors.black54,
                      )
                          : Text(
                        isLogin ? '로그인' : '회원가입',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 전환 링크
                  Column(
                    children: [
                      if (isLogin) ...[
                        GestureDetector(
                          onTap: _showForgotPasswordDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '계정을 잊으셨나요?',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isLogin = !isLogin;
                            _formKey.currentState?.reset();
                            _emailController.clear();
                            _passwordController.clear();
                            _confirmPasswordController.clear();
                            _nameController.clear();
                          });
                        },
                        child: Text(
                          isLogin
                              ? '계정이 없으신가요? 회원가입'
                              : '이미 계정이 있으신가요? 로그인',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        validator: validator,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('비밀번호 찾기'),
        content: const Text('비밀번호 재설정 기능은 준비 중입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}