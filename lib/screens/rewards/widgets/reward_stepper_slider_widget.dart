import 'package:flutter/material.dart';
import '../../../game/models/reward_step_models.dart';

class RewardStepperSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final List<RewardStep> rewardSteps;
  final Color progressColor;
  final double height;

  const RewardStepperSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.rewardSteps,
    this.progressColor = Colors.orange,
    this.height = 100,
  });

  @override
  State<RewardStepperSlider> createState() => RewardStepperSliderState();
}

class RewardStepperSliderState extends State<RewardStepperSlider> {
  final List<GlobalKey<TooltipState>> _tooltipKeys = [];

  @override
  void initState() {
    super.initState();
    // Initialize tooltip keys for each reward step
    for (int i = 0; i < widget.rewardSteps.length; i++) {
      _tooltipKeys.add(GlobalKey<TooltipState>());
    }
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      child: Column(
        children: [
          _buildRewardIconsRow(),
          const SizedBox(height: 8),
          _buildProgressSlider(),
          const SizedBox(height: 8),
          _buildPointLabels(),
        ],
      ),
    );
  }

  Widget _buildRewardIconsRow() {
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: widget.rewardSteps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isUnlocked = widget.value >= step.pointValue;
          return _buildRewardIcon(step, isUnlocked, index);
        }).toList(),
      ),
    );
  }

  Widget _buildRewardIcon(RewardStep step, bool isUnlocked, int index) {
    return Tooltip(
      key: _tooltipKeys[index],
      message: '${step.description}\n${step.quantity > 1 ? '${step.quantity} ' : ''}Unlocked at ${step.pointValue.toInt()} points',
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: TextStyle(
        color: Colors.white,
        fontSize: 12,
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      waitDuration: Duration(milliseconds: 300),
      triggerMode: TooltipTriggerMode.tap,
      enableFeedback: true,
      child: GestureDetector(
        onTap: () {
          // Force tooltip to show on tap for mobile devices
          _tooltipKeys[index].currentState?.ensureTooltipVisible();
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isUnlocked ? step.backgroundColor : Colors.grey[400],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isUnlocked ? Colors.orange[300]! : Colors.grey[500]!,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    step.icon,
                    color: isUnlocked ? Colors.white : Colors.grey[600],
                    size: 24,
                  ),
                ),
              ),
              if (step.quantity > 1)
                Positioned(
                  right: -8,
                  top: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      '${step.quantity}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ),
              if (isUnlocked && widget.value > step.pointValue)
                Positioned(
                  right: -5,
                  bottom: -5,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSlider() {
    final maxValue = widget.rewardSteps.last.pointValue.toDouble();

    return Container(
      height: 20,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 8,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
          thumbColor: widget.progressColor,
          activeTrackColor: widget.progressColor,
          inactiveTrackColor: Colors.grey[300],
          overlayShape: SliderComponentShape.noOverlay,
          tickMarkShape: SliderTickMarkShape.noTickMark,
        ),
        child: Slider(
          value: widget.value.clamp(0, maxValue),
          min: 0,
          max: maxValue,
          onChanged: widget.onChanged,
        ),
      ),
    );
  }

  Widget _buildPointLabels() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: widget.rewardSteps.map((step) {
        final isActive = widget.value >= step.pointValue;
        return Text(
          '${step.pointValue.toInt()}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? widget.progressColor : Colors.grey[600],
          ),
        );
      }).toList(),
    );
  }
}
