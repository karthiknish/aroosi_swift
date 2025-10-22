import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';

import 'package:aroosi_flutter/core/api_client.dart';
import 'package:aroosi_flutter/core/api_error_handler.dart';
import 'package:aroosi_flutter/theme/colors.dart';

class FamilyApprovalScreen extends ConsumerStatefulWidget {
  const FamilyApprovalScreen({super.key});

  @override
  ConsumerState<FamilyApprovalScreen> createState() =>
      _FamilyApprovalScreenState();
}

class _FamilyApprovalScreenState extends ConsumerState<FamilyApprovalScreen> {
  bool _isLoading = false;
  List<FamilyApprovalRequest> _pendingRequests = [];
  List<FamilyApprovalRequest> _sentRequests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load pending requests (requests where user is family member)
      final pendingResponse = await ApiClient.dio.get(
        '/api/cultural/family-approval/received',
      );

      // Load sent requests (requests user created)
      final sentResponse = await ApiClient.dio.get(
        '/api/cultural/family-approval/requests',
      );

      if (mounted) {
        setState(() {
          _pendingRequests =
              (pendingResponse.data['requests'] as List<dynamic>?)
                  ?.map((json) => FamilyApprovalRequest.fromJson(json))
                  .toList() ??
              [];
          _sentRequests =
              (sentResponse.data['requests'] as List<dynamic>?)
                  ?.map((json) => FamilyApprovalRequest.fromJson(json))
                  .toList() ??
              [];
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ApiErrorHandler.logError(e, 'Load family approval requests');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiErrorHandler.getErrorMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Family Approval',
          style: GoogleFonts.nunitoSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surfaceSecondary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateRequestDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    labelStyle: GoogleFonts.nunitoSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    indicatorColor: AppColors.primary,
                    tabs: const [
                      Tab(text: 'Pending (Received)'),
                      Tab(text: 'Sent Requests'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [_buildPendingRequests(), _buildSentRequests()],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPendingRequests() {
    if (_pendingRequests.isEmpty) {
      return _buildEmptyState(
        'No Pending Requests',
        'You haven\'t received any family approval requests yet',
        Icons.inbox_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        final request = _pendingRequests[index];
        return _FamilyRequestCard(
          request: request,
          isReceived: true,
          onResponse: (decision) => _respondToRequest(request, decision),
        );
      },
    );
  }

  Widget _buildSentRequests() {
    if (_sentRequests.isEmpty) {
      return _buildEmptyState(
        'No Sent Requests',
        'You haven\'t sent any family approval requests yet',
        Icons.send_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sentRequests.length,
      itemBuilder: (context, index) {
        final request = _sentRequests[index];
        return _FamilyRequestCard(request: request, isReceived: false);
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.nunitoSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.nunitoSans(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateRequestDialog,
            icon: const Icon(Icons.add),
            label: Text(
              'Create Request',
              style: GoogleFonts.nunitoSans(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }

  void _showCreateRequestDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => const CreateFamilyApprovalDialog(),
    );
  }

  Future<void> _respondToRequest(
    FamilyApprovalRequest request,
    String decision,
  ) async {
    try {
      final response = await ApiClient.dio.post(
        '/api/cultural/family-approval/respond',
        data: {'requestId': request.id, 'decision': decision},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Response submitted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadRequests(); // Refresh the list
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting response: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _FamilyRequestCard extends StatelessWidget {
  final FamilyApprovalRequest request;
  final bool isReceived;
  final Function(String)? onResponse;

  const _FamilyRequestCard({
    required this.request,
    required this.isReceived,
    this.onResponse,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isReceived
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isReceived ? Icons.family_restroom : Icons.send,
                    color: isReceived ? AppColors.primary : AppColors.secondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isReceived
                            ? 'Request for Approval'
                            : 'Approval Request Sent',
                        style: GoogleFonts.nunitoSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Relationship: ${request.relationship}',
                        style: GoogleFonts.nunitoSans(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: request.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(request.message, style: GoogleFonts.nunitoSans(fontSize: 14)),
            const SizedBox(height: 12),
            Text(
              'Sent ${_formatDate(request.createdAt)}',
              style: GoogleFonts.nunitoSans(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            if (isReceived && request.status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => onResponse?.call('approved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                      child: Text(
                        'Approve',
                        style: GoogleFonts.nunitoSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onResponse?.call('declined'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.error),
                      ),
                      child: Text(
                        'Decline',
                        style: GoogleFonts.nunitoSans(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case 'approved':
        color = AppColors.success;
        text = 'Approved';
        break;
      case 'declined':
        color = AppColors.error;
        text = 'Declined';
        break;
      case 'pending':
        color = AppColors.warning;
        text = 'Pending';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.nunitoSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class CreateFamilyApprovalDialog extends ConsumerStatefulWidget {
  const CreateFamilyApprovalDialog({super.key});

  @override
  ConsumerState<CreateFamilyApprovalDialog> createState() =>
      _CreateFamilyApprovalDialogState();
}

class _CreateFamilyApprovalDialogState
    extends ConsumerState<CreateFamilyApprovalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _familyMemberController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _familyMemberController.dispose();
    _relationshipController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  BoxDecoration cupertinoDecoration(
    BuildContext context, {
    bool hasError = false,
  }) {
    return BoxDecoration(
      color: CupertinoTheme.of(context).scaffoldBackgroundColor,
      border: Border.all(
        color: hasError ? CupertinoColors.destructiveRed : AppColors.primary,
        width: 1.5,
      ),
      borderRadius: BorderRadius.circular(10.0),
    );
  }

  Padding cupertinoFieldPadding(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request Family Approval',
              style: GoogleFonts.nunitoSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Send a request to a family member for their approval of your potential match.',
              style: GoogleFonts.nunitoSans(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    decoration: cupertinoDecoration(context),
                    child: cupertinoFieldPadding(
                      CupertinoTextField(
                        controller: _familyMemberController,
                        placeholder: 'Family Member ID or Email',
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: Colors.transparent),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: cupertinoDecoration(context),
                    child: cupertinoFieldPadding(
                      CupertinoTextField(
                        controller: _relationshipController,
                        placeholder: 'Relationship',
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: Colors.transparent),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: cupertinoDecoration(context),
                    child: cupertinoFieldPadding(
                      CupertinoTextField(
                        controller: _messageController,
                        placeholder: 'Why you\'re seeking their approval...',
                        maxLines: 3,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: Colors.transparent),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.nunitoSans(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Send Request',
                            style: GoogleFonts.nunitoSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRequest() async {
    // Manual validation
    final familyMember = _familyMemberController.text.trim();
    if (familyMember.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter family member ID or email')),
      );
      return;
    }

    final relationship = _relationshipController.text.trim();
    if (relationship.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter relationship')),
      );
      return;
    }

    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a message')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiClient.dio.post(
        '/api/cultural/family-approval/request',
        data: {
          'familyMemberId': familyMember,
          'relationship': relationship,
          'message': message,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Family approval request sent successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        ApiErrorHandler.logError(e, 'Submit family approval request');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiErrorHandler.getErrorMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
            backgroundColor: AppColors.error,
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
}

class FamilyApprovalRequest {
  final String id;
  final String requesterId;
  final String familyMemberId;
  final String relationship;
  final String message;
  final String status;
  final int createdAt;
  final int updatedAt;

  FamilyApprovalRequest({
    required this.id,
    required this.requesterId,
    required this.familyMemberId,
    required this.relationship,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FamilyApprovalRequest.fromJson(Map<String, dynamic> json) {
    return FamilyApprovalRequest(
      id: json['_id'] ?? json['id'],
      requesterId: json['requesterId'],
      familyMemberId: json['familyMemberId'],
      relationship: json['relationship'],
      message: json['message'],
      status: json['status'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }
}
