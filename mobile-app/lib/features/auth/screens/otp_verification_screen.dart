import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OtpVerificationScreen extends StatefulWidget {
  final Map<String, dynamic>? extra;
  
  const OtpVerificationScreen({super.key, this.extra});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  String _otpCode = '';
  int _resendTimer = 55;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _onDigitChanged(String value, int index) {
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
    
    _updateOtpCode();
  }

  void _onDigitBackspace(int index) {
    if (index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
    
    _updateOtpCode();
  }

  void _updateOtpCode() {
    _otpCode = _controllers.map((controller) => controller.text).join();
    setState(() {});
  }

  void _handleVerify() {
    if (_otpCode.length == 4) {
      // Navigate to create new password screen
      context.push('/create-new-password');
    }
  }

  void _handleResend() {
    if (_resendTimer == 0) {
      setState(() {
        _resendTimer = 55;
      });
      _startTimer();
      // TODO: Implement resend logic
    }
  }

  void _addDigit(String digit) {
    for (int i = 0; i < _controllers.length; i++) {
      if (_controllers[i].text.isEmpty) {
        _controllers[i].text = digit;
        if (i < 3) {
          _focusNodes[i + 1].requestFocus();
        }
        break;
      }
    }
    _updateOtpCode();
  }

  void _removeDigit() {
    for (int i = _controllers.length - 1; i >= 0; i--) {
      if (_controllers[i].text.isNotEmpty) {
        _controllers[i].clear();
        if (i > 0) {
          _focusNodes[i - 1].requestFocus();
        }
        break;
      }
    }
    _updateOtpCode();
  }

  @override
  Widget build(BuildContext context) {
    final contact = widget.extra?['contact'] ?? '+1 111 ******99';
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'OTP Code Verification',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  
                  // Instructions
                  Text(
                    'Code has been send to $contact',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF212121),
                    ),
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // OTP Input Fields
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(4, (index) => _buildOtpField(index)),
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // Resend timer
                  Text(
                    _resendTimer > 0 
                        ? 'Resend code in ${_resendTimer}s'
                        : 'Resend code',
                    style: TextStyle(
                      fontSize: 16,
                      color: _resendTimer > 0 ? Colors.grey.shade600 : const Color(0xFF6C5CE7),
                      fontWeight: _resendTimer > 0 ? FontWeight.normal : FontWeight.w600,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Verify Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _otpCode.length == 4 ? _handleVerify : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: const Text(
                        'Verify',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // Custom Keypad
          _buildKeypad(),
        ],
      ),
    );
  }

  Widget _buildOtpField(int index) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(
          color: _controllers[index].text.isNotEmpty 
              ? const Color(0xFF6C5CE7) 
              : Colors.grey.shade300,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF212121),
        ),
        keyboardType: TextInputType.none, // Disable default keyboard
        maxLength: 1,
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
        ),
        onChanged: (value) => _onDigitChanged(value, index),
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // First row: 1, 2, 3
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('1'),
              _buildKeypadButton('2'),
              _buildKeypadButton('3'),
            ],
          ),
          const SizedBox(height: 16),
          
          // Second row: 4, 5, 6
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('4'),
              _buildKeypadButton('5'),
              _buildKeypadButton('6'),
            ],
          ),
          const SizedBox(height: 16),
          
          // Third row: 7, 8, 9
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('7'),
              _buildKeypadButton('8'),
              _buildKeypadButton('9'),
            ],
          ),
          const SizedBox(height: 16),
          
          // Fourth row: *, 0, X
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('*'),
              _buildKeypadButton('0'),
              _buildKeypadButton('⌫', isDelete: true),
            ],
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String value, {bool isDelete = false}) {
    return GestureDetector(
      onTap: () {
        if (isDelete) {
          _removeDigit();
        } else {
          _addDigit(value);
        }
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Center(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isDelete ? 24 : 28,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF212121),
            ),
          ),
        ),
      ),
    );
  }
}
