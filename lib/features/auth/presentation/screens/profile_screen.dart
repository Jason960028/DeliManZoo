import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/glassmorphic_container.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 프로필'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Header
                GlassmorphicContainer(
                  borderRadius: 20.0,
                  backgroundColorWithOpacity: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    width: 1.0,
                  ),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Profile Avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: currentUser?.photoURL != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Image.network(
                                  currentUser!.photoURL!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: 50,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                      ),
                      const SizedBox(height: 16),
                      
                      // User Info
                      Text(
                        currentUser?.displayName ?? currentUser?.email.split('@').first ?? 'User',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      if (currentUser?.email != null)
                        Text(
                          currentUser!.email,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),

                // Menu Items
                GlassmorphicContainer(
                  borderRadius: 16.0,
                  backgroundColorWithOpacity: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    width: 1.0,
                  ),
                  child: Column(
                    children: [
                      _ProfileMenuItem(
                        icon: Icons.favorite_outline,
                        title: '즐겨찾기',
                        subtitle: '저장한 맛집',
                        onTap: () {
                          // TODO: Navigate to favorites
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('즐겨찾기 기능 구현 예정')),
                          );
                        },
                      ),
                      _ProfileMenuItem(
                        icon: Icons.history,
                        title: '최근 방문',
                        subtitle: '최근 본 맛집',
                        onTap: () {
                          // TODO: Navigate to history
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('최근 방문 기능 구현 예정')),
                          );
                        },
                      ),
                      _ProfileMenuItem(
                        icon: Icons.settings_outlined,
                        title: '설정',
                        subtitle: '앱 설정',
                        onTap: () {
                          // TODO: Navigate to settings
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('설정 기능 구현 예정')),
                          );
                        },
                      ),
                      _ProfileMenuItem(
                        icon: Icons.help_outline,
                        title: '도움말',
                        subtitle: '자주 묻는 질문',
                        onTap: () {
                          // TODO: Navigate to help
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('도움말 기능 구현 예정')),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: authState.isLoading 
                        ? null 
                        : () async {
                            // Show confirmation dialog
                            final shouldLogout = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('로그아웃'),
                                content: const Text('정말 로그아웃 하시겠습니까?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('취소'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text('로그아웃'),
                                  ),
                                ],
                              ),
                            ) ?? false;

                            if (shouldLogout) {
                              await ref.read(authProvider.notifier).signOut();
                              if (!context.mounted) return;
                              Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
                            }
                          },
                    icon: authState.isLoading 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.logout),
                    label: Text(authState.isLoading ? '로그아웃 중...' : '로그아웃'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // App Version (Optional)
                Text(
                  'DeliManZoo v1.0.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper Widget for Profile Menu Items
class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}
