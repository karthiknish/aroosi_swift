import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aroosi_flutter/features/profiles/models.dart';
import 'package:aroosi_flutter/features/profiles/list_controller.dart';
import 'package:aroosi_flutter/core/api_client.dart';

import 'package:aroosi_flutter/core/responsive.dart';

enum SwipeDirection { left, right, none }

class SwipeableCard extends ConsumerStatefulWidget {
  const SwipeableCard({
    super.key,
    required this.profile,
    required this.onSwipeComplete,
    required this.compatibilityScore,
    this.isTopCard = true,
    this.icebreakers = const [],
    this.onProfileTap,
    this.showCompatibility = true,
    this.enableHapticFeedback = true,
  });

  final ProfileSummary profile;
  final Function(SwipeDirection) onSwipeComplete;
  final int compatibilityScore;
  final bool isTopCard;
  final List<String> icebreakers;
  final VoidCallback? onProfileTap;
  final bool showCompatibility;
  final bool enableHapticFeedback;

  @override
  ConsumerState<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends ConsumerState<SwipeableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isDragging = false;
  Offset _dragStart = Offset.zero;
  Offset _dragOffset = Offset.zero;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.0, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handlePanStart(DragStartDetails details) {
    if (!widget.isTopCard) return;
    
    setState(() {
      _isDragging = true;
      _dragStart = details.globalPosition;
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!widget.isTopCard || !_isDragging) return;

    setState(() {
      _dragOffset = details.globalPosition - _dragStart;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!widget.isTopCard || !_isDragging) return;

    setState(() {
      _isDragging = false;
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final dragDistance = _dragOffset.dx.abs();
    final velocity = details.primaryVelocity ?? 0;

    // Determine if the card should be swiped
    if (dragDistance > screenWidth * 0.3 || velocity.abs() > 500) {
      if (_dragOffset.dx > 0) {
        _swipeRight();
      } else {
        _swipeLeft();
      }
    } else {
      // Snap back to center
      setState(() {
        _dragOffset = Offset.zero;
      });
    }
  }

  void _swipeRight() async {
    if (_isProcessing) return;
    _isProcessing = true;
    
    // Haptic feedback
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    
    try {
      // Send interest to the backend
      await _sendInterest();
      
      // Play animation
      await _animationController.forward();
      
      // Notify parent
      widget.onSwipeComplete(SwipeDirection.right);
      
      _resetCard();
    } catch (e) {
      // Show error and reset
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send interest'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      _resetCard();
    } finally {
      _isProcessing = false;
    }
  }

  void _swipeLeft() async {
    if (_isProcessing) return;
    _isProcessing = true;
    
    // Haptic feedback
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    
    try {
      // Skip action (mark as skipped in quick picks)
      await _skipProfile();
      
      // Play animation
      await _animationController.forward();
      
      // Notify parent
      widget.onSwipeComplete(SwipeDirection.left);
      
      _resetCard();
    } catch (e) {
      // Show error and reset
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to skip profile'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      _resetCard();
    } finally {
      _isProcessing = false;
    }
  }

  void _resetCard() {
    _animationController.reset();
    setState(() {
      _dragOffset = Offset.zero;
    });
  }

  /// Send interest using the interests API
  Future<void> _sendInterest() async {
    try {
      final response = await ApiClient.dio.post(
        '/interests',
        data: {
          'action': 'send',
          'toUserId': widget.profile.id,
        },
      );
      
      if (response.statusCode == 200) {
        // Success - interests are idempotent so no issue if already sent
        debugPrint('Interest sent to ${widget.profile.id}');
      }
    } catch (e) {
      debugPrint('Error sending interest: $e');
      rethrow; // Let the calling method handle the error
    }
  }

  /// Skip profile using quick-picks API
  Future<void> _skipProfile() async {
    try {
      final response = await ApiClient.dio.post(
        '/engagement/quick-picks',
        data: {
          'toUserId': widget.profile.id,
          'action': 'skip',
        },
      );
      
      if (response.statusCode == 200) {
        debugPrint('Profile ${widget.profile.id} skipped');
      }
    } catch (e) {
      debugPrint('Error skipping profile: $e');
      rethrow; // Let the calling method handle the error
    }
  }

  /// Add/remove from shortlist
  Future<void> _toggleShortlist() async {
    if (_isProcessing) return;
    _isProcessing = true;
    
    try {
      final controller = ref.read(shortlistControllerProvider.notifier);
      final result = await controller.toggleShortlist(widget.profile.id);
      
      if (result['success'] == true) {
        final isShortlisted = result['data']['added'] == true;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isShortlisted ? 'Added to shortlist' : 'Removed from shortlist'),
              backgroundColor: isShortlisted ? Colors.green : Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to update shortlist'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating shortlist: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update shortlist'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      _isProcessing = false;
    }
  }

  Color _getCardColor() {
    if (!widget.isTopCard) return Colors.white;
    
    final dx = _dragOffset.dx;
    final screenWidth = MediaQuery.of(context).size.width;
    final percentage = dx / screenWidth;

    if (percentage > 0) {
      // Green for like
      return Color.lerp(Colors.white, Colors.green.shade50, percentage)!;
    } else if (percentage < 0) {
      // Red for skip
      return Color.lerp(Colors.white, Colors.red.shade50, (-percentage))!;
    }
    
    return Colors.white;
  }

  Widget _buildOverlay() {
    if (!widget.isTopCard || _isProcessing) return const SizedBox.shrink();

    final dx = _dragOffset.dx;
    final screenWidth = MediaQuery.of(context).size.width;
    final percentage = (dx / screenWidth).abs();

    if (percentage < 0.1) return const SizedBox.shrink();

    String actionText = '';
    Color overlayColor = Colors.transparent;
    IconData actionIcon = Icons.arrow_forward;

    if (dx > 0) {
      actionText = 'LIKE';
      overlayColor = Colors.green;
      actionIcon = Icons.favorite;
    } else if (dx < 0) {
      actionText = 'SKIP';
      overlayColor = Colors.red;
      actionIcon = Icons.close;
    }

    return Positioned(
      top: Responsive.isMobile(context) ? 50 : 80,
      left: dx > 0 ? 20 : null,
      right: dx < 0 ? 20 : null,
      child: Transform.rotate(
        angle: dx > 0 ? -0.3 : 0.3,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: overlayColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: overlayColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                actionIcon,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                actionText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardScale = widget.isTopCard ? 1.0 : 0.95;
    final cardOpacity = widget.isTopCard ? 1.0 : 0.8;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: widget.isTopCard ? _dragOffset + _slideAnimation.value * MediaQuery.of(context).size.width : Offset.zero,
          child: Transform.rotate(
            angle: widget.isTopCard ? _dragOffset.dx * 0.01 + _rotationAnimation.value : 0,
            child: Transform.scale(
              scale: cardScale * _scaleAnimation.value,
              child: Opacity(
                opacity: cardOpacity,
                child: GestureDetector(
                  onPanStart: _handlePanStart,
                  onPanUpdate: _handlePanUpdate,
                  onPanEnd: _handlePanEnd,
                  onTap: widget.onProfileTap != null ? () {
                    HapticFeedback.lightImpact();
                    widget.onProfileTap!();
                  } : null,
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: _getCardColor(),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          _buildCard(),
                          _buildOverlay(),
                          if (widget.isTopCard) _buildActionButtons(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Container(
            color: Colors.grey[200],
            child: widget.profile.avatarUrl != null
                ? Image.network(
                    widget.profile.avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.person,
                          size: 80,
                          color: Colors.grey,
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.person,
                      size: 80,
                      color: Colors.grey,
                    ),
                  ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.profile.displayName,
                        style: TextStyle(
                          fontSize: Responsive.isTablet(context) ? 26 : 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (widget.profile.age != null)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Age: ${widget.profile.age}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (widget.compatibilityScore > 0 && widget.showCompatibility)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getCompatibilityColor(widget.compatibilityScore),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.compatibilityScore}% Match',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                if (widget.profile.age != null)
                  Text(
                    '${widget.profile.age} years',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                if (widget.profile.city != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.profile.city!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
                const Spacer(),
                if (widget.icebreakers.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Icebreakers',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            Icon(
                              Icons.lightbulb,
                              size: 16,
                              color: Colors.grey[700],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: widget.icebreakers.map((icebreaker) {
                            final index = widget.icebreakers.indexOf(icebreaker);
                            bool isAnswered = index < 2; // Mock answered state for display
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isAnswered
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isAnswered
                                      ? Colors.green.withValues(alpha: 0.3)
                                      : Colors.grey[300]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isAnswered)
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: Colors.green,
                                    ),
                                  if (isAnswered) const SizedBox(width: 4),
                                  Text(
                                    icebreaker,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isAnswered
                                          ? Colors.green.shade700
                                          : Colors.grey.shade700,
                                      decoration: isAnswered
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Positioned(
      bottom: Responsive.isMobile(context) ? 20 : 30,
      left: Responsive.isMobile(context) ? 20 : 30,
      right: Responsive.isMobile(context) ? 20 : 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Shortlist button
          _ActionButton(
            onPressed: () => _toggleShortlist(),
            icon: Icons.bookmark_border,
            color: Colors.blue,
            label: 'Shortlist',
          ),
          // Skip button
          _ActionButton(
            onPressed: () => _swipeLeft(),
            icon: Icons.close,
            color: Colors.red,
            label: 'Skip',
          ),
          // Like button
          _ActionButton(
            onPressed: () => _swipeRight(),
            icon: Icons.favorite,
            color: Colors.green,
            label: 'Like',
          ),
        ],
      ),
    );
  }

  Color _getCompatibilityColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.grey;
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.color,
    required this.label,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
