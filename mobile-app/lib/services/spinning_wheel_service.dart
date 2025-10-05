import 'dart:convert';
import 'package:http/http.dart' as http;

class SpinningWheelService {
  static const String baseUrl = 'http://10.0.2.2:3001'; // Android emulator
  // static const String baseUrl = 'http://localhost:3001'; // iOS simulator

  // Get user's current game stats
  static Future<UserGameStats?> getUserGameStats(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/games/stats/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserGameStats.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error fetching user game stats: $e');
      return null;
    }
  }

  // Perform a spin and get result
  static Future<SpinResult?> performSpin(String userId, String spinType) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/games/spin'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'spinType': spinType, // 'free', 'purchased', 'bonus'
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SpinResult.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error performing spin: $e');
      return null;
    }
  }

  // Get wheel configuration
  static Future<WheelConfig?> getWheelConfiguration() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/games/wheel-config'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WheelConfig.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error fetching wheel config: $e');
      return null;
    }
  }

  // Get user's spin history
  static Future<List<SpinHistory>> getSpinHistory(String userId,
      {int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/games/history/$userId?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => SpinHistory.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching spin history: $e');
      return [];
    }
  }

  // Check if user can spin (cooldown check)
  static Future<SpinAvailability?> checkSpinAvailability(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/games/spin-availability/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SpinAvailability.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error checking spin availability: $e');
      return null;
    }
  }

  // Get daily challenges
  static Future<List<DailyChallenge>> getDailyChallenges(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/games/challenges/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => DailyChallenge.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching daily challenges: $e');
      return [];
    }
  }

  // Claim daily challenge reward
  static Future<bool> claimChallengeReward(
      String userId, String challengeId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/games/claim-challenge'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'challengeId': challengeId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error claiming challenge reward: $e');
      return false;
    }
  }
}

// Data Models
class UserGameStats {
  final int totalSpins;
  final int totalWins;
  final int totalCoinsWon;
  final int totalFreespinsWon;
  final int currentCoins;
  final int currentFreespins;
  final DateTime? lastFreeSpinDate;
  final int consecutiveDays;
  final int level;
  final int experiencePoints;

  UserGameStats({
    required this.totalSpins,
    required this.totalWins,
    required this.totalCoinsWon,
    required this.totalFreespinsWon,
    required this.currentCoins,
    required this.currentFreespins,
    this.lastFreeSpinDate,
    required this.consecutiveDays,
    required this.level,
    required this.experiencePoints,
  });

  factory UserGameStats.fromJson(Map<String, dynamic> json) {
    return UserGameStats(
      totalSpins: json['total_spins'] ?? 0,
      totalWins: json['total_wins'] ?? 0,
      totalCoinsWon: json['total_coins_won'] ?? 0,
      totalFreespinsWon: json['total_freespins_won'] ?? 0,
      currentCoins: json['current_coins'] ?? 0,
      currentFreespins: json['current_freespins'] ?? 3,
      lastFreeSpinDate: json['last_free_spin_date'] != null
          ? DateTime.parse(json['last_free_spin_date'])
          : null,
      consecutiveDays: json['consecutive_days'] ?? 0,
      level: json['level'] ?? 1,
      experiencePoints: json['experience_points'] ?? 0,
    );
  }
}

class SpinResult {
  final String prizeType;
  final int prizeValue;
  final String prizeLabel;
  final double spinResultAngle;
  final bool isBigWin;
  final int segmentIndex;
  final String segmentColor;

  SpinResult({
    required this.prizeType,
    required this.prizeValue,
    required this.prizeLabel,
    required this.spinResultAngle,
    required this.isBigWin,
    required this.segmentIndex,
    required this.segmentColor,
  });

  factory SpinResult.fromJson(Map<String, dynamic> json) {
    return SpinResult(
      prizeType: json['prize_type'] ?? '',
      prizeValue: json['prize_value'] ?? 0,
      prizeLabel: json['prize_label'] ?? '',
      spinResultAngle: (json['spin_result_angle'] ?? 0.0).toDouble(),
      isBigWin: json['is_big_win'] ?? false,
      segmentIndex: json['segment_index'] ?? 0,
      segmentColor: json['segment_color'] ?? '#FF6B6B',
    );
  }
}

class WheelConfig {
  final String wheelName;
  final String wheelType;
  final List<WheelSegmentData> segments;

  WheelConfig({
    required this.wheelName,
    required this.wheelType,
    required this.segments,
  });

  factory WheelConfig.fromJson(Map<String, dynamic> json) {
    return WheelConfig(
      wheelName: json['wheel_name'] ?? 'Lucky Wheel',
      wheelType: json['wheel_type'] ?? 'daily_spin',
      segments: (json['segments'] as List<dynamic>?)
              ?.map((segment) => WheelSegmentData.fromJson(segment))
              .toList() ??
          [],
    );
  }
}

class WheelSegmentData {
  final int segmentOrder;
  final String prizeType;
  final int prizeValue;
  final String prizeLabel;
  final double winProbability;
  final String segmentColor;
  final String? iconName;

  WheelSegmentData({
    required this.segmentOrder,
    required this.prizeType,
    required this.prizeValue,
    required this.prizeLabel,
    required this.winProbability,
    required this.segmentColor,
    this.iconName,
  });

  factory WheelSegmentData.fromJson(Map<String, dynamic> json) {
    return WheelSegmentData(
      segmentOrder: json['segment_order'] ?? 0,
      prizeType: json['prize_type'] ?? '',
      prizeValue: json['prize_value'] ?? 0,
      prizeLabel: json['prize_label'] ?? '',
      winProbability: (json['win_probability'] ?? 0.0).toDouble(),
      segmentColor: json['segment_color'] ?? '#FF6B6B',
      iconName: json['icon_name'],
    );
  }
}

class SpinHistory {
  final String prizeType;
  final int prizeValue;
  final String prizeLabel;
  final String spinType;
  final bool isBigWin;
  final DateTime createdAt;

  SpinHistory({
    required this.prizeType,
    required this.prizeValue,
    required this.prizeLabel,
    required this.spinType,
    required this.isBigWin,
    required this.createdAt,
  });

  factory SpinHistory.fromJson(Map<String, dynamic> json) {
    return SpinHistory(
      prizeType: json['prize_type'] ?? '',
      prizeValue: json['prize_value'] ?? 0,
      prizeLabel: json['prize_label'] ?? '',
      spinType: json['spin_type'] ?? 'free',
      isBigWin: json['is_big_win'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class SpinAvailability {
  final bool canSpin;
  final int freeSpinsLeft;
  final DateTime? nextFreeSpinAt;
  final String? cooldownMessage;

  SpinAvailability({
    required this.canSpin,
    required this.freeSpinsLeft,
    this.nextFreeSpinAt,
    this.cooldownMessage,
  });

  factory SpinAvailability.fromJson(Map<String, dynamic> json) {
    return SpinAvailability(
      canSpin: json['can_spin'] ?? false,
      freeSpinsLeft: json['free_spins_left'] ?? 0,
      nextFreeSpinAt: json['next_free_spin_at'] != null
          ? DateTime.parse(json['next_free_spin_at'])
          : null,
      cooldownMessage: json['cooldown_message'],
    );
  }
}

class DailyChallenge {
  final String id;
  final String challengeName;
  final String challengeDescription;
  final String challengeType;
  final int requiredCount;
  final String rewardType;
  final int rewardAmount;
  final int currentProgress;
  final bool isCompleted;
  final bool rewardClaimed;

  DailyChallenge({
    required this.id,
    required this.challengeName,
    required this.challengeDescription,
    required this.challengeType,
    required this.requiredCount,
    required this.rewardType,
    required this.rewardAmount,
    required this.currentProgress,
    required this.isCompleted,
    required this.rewardClaimed,
  });

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      id: json['id'] ?? '',
      challengeName: json['challenge_name'] ?? '',
      challengeDescription: json['challenge_description'] ?? '',
      challengeType: json['challenge_type'] ?? '',
      requiredCount: json['required_count'] ?? 1,
      rewardType: json['reward_type'] ?? 'freespins',
      rewardAmount: json['reward_amount'] ?? 1,
      currentProgress: json['current_progress'] ?? 0,
      isCompleted: json['is_completed'] ?? false,
      rewardClaimed: json['reward_claimed'] ?? false,
    );
  }

  double get progressPercentage => currentProgress / requiredCount;
  bool get canClaim => isCompleted && !rewardClaimed;
}
