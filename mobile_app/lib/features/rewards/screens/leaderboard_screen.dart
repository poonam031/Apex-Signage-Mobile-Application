import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool _isLoading = true;
  List<dynamic> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() => _isLoading = true);
    final response = await ApiClient.get('/rewards/leaderboard');
    if (response.success && response.data != null) {
      setState(() {
        _leaderboard = response.data;
        _isLoading = false;
      });
    } else {
      // Demo mock leaderboard
      setState(() {
        _leaderboard = [
          {
            'rank': 1,
            'totalPoints': 250,
            'totalProductionSqFt': 665.0,
            'isEmployeeOfMonth': true,
            'rewardBonusAmount': 3000.0,
            'user': {'name': 'Amit Verma', 'role': 'DESIGNER_OPERATOR'},
          },
          {
            'rank': 2,
            'totalPoints': 150,
            'totalProductionSqFt': 0.0,
            'isEmployeeOfMonth': false,
            'user': {'name': 'Vikram Singh', 'role': 'INSTALLATION_TEAM'},
          },
          {
            'rank': 3,
            'totalPoints': 80,
            'totalProductionSqFt': 0.0,
            'isEmployeeOfMonth': false,
            'user': {'name': 'Rahul Sharma', 'role': 'FIELD_BOY'},
          },
        ];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final topUser = _leaderboard.isNotEmpty ? _leaderboard.first : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards & Monthly Leaderboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Employee of the Month Highlight Podium Card
            if (topUser != null) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF854D0E), Color(0xFFEAB308)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_events, color: Colors.white, size: 28),
                        SizedBox(width: 8),
                        Text(
                          'EMPLOYEE OF THE MONTH',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      topUser['user']?['name'] ?? 'Winner',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                    ),
                    Text(
                      '${topUser['user']?['role']?.toString().replaceAll('_', ' ')}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '🏆 ${topUser['totalPoints']} Points • ₹${topUser['rewardBonusAmount'] ?? 3000} Salary Bonus Added',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            const Text(
              'August 2026 Rankings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _leaderboard.length,
              itemBuilder: (context, index) {
                final item = _leaderboard[index];
                final user = item['user'] ?? {};
                final rank = item['rank'] ?? (index + 1);

                Color medalColor = AppColors.textSecondary;
                if (rank == 1) medalColor = AppColors.gold;
                if (rank == 2) medalColor = AppColors.silver;
                if (rank == 3) medalColor = AppColors.bronze;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: medalColor.withOpacity(0.2),
                      child: Text(
                        '#$rank',
                        style: TextStyle(fontWeight: FontWeight.bold, color: medalColor == AppColors.gold ? const Color(0xFFB45309) : medalColor),
                      ),
                    ),
                    title: Text(user['name'] ?? 'Staff', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(user['role']?.toString().replaceAll('_', ' ') ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item['totalPoints']} Pts',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary),
                        ),
                        if ((item['totalProductionSqFt'] ?? 0) > 0)
                          Text(
                            '${item['totalProductionSqFt']} Sq.Ft',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Point Rules Legend Box
            const Text('Gamification Points Rules:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _buildRuleRow('Every 100 Sq.Ft printed/produced', '+50 Points'),
                    _buildRuleRow('Zero / low waste production batch', '+100 Points'),
                    _buildRuleRow('Timely on-site installation', '+80 Points'),
                    _buildRuleRow('5-Star verified customer feedback', '+150 Points'),
                    _buildRuleRow('100% monthly on-time attendance', '+200 Points'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleRow(String rule, String pts) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(rule, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
          Text(pts, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success)),
        ],
      ),
    );
  }
}
