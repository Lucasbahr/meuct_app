import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/api/dio_unauthorized.dart';
import '../../../core/auth/session_service.dart';
import '../../../core/branding/app_branding.dart';
import '../../../core/storage/gym_context_storage.dart';
import '../../../core/storage/token_storage.dart';
import '../../../shared/components/primary_button.dart';
import '../../../shared/themes/app_tokens.dart';
import '../../../widgets/password_field_with_visibility.dart';
import '../../gyms/screens/gym_select_page.dart';
import '../../student/services/student_service.dart';
import '../repositories/auth_repository.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final authRepository = AuthRepository();
  bool _isLoggingIn = false;
  bool _checkingSession = true;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryResumeSession());
  }

  Future<void> _tryResumeSession() async {
    var openedHome = false;
    try {
      final token = await TokenStorage().getToken();
      if (!mounted) return;
      if (token == null || token.isEmpty) return;

      try {
        await GymContextStorage.instance.syncFromAccessToken(token);
        final session = SessionService();
        final sysAdmin = await session.isSystemAdmin();
        if (sysAdmin) {
          var gid = await GymContextStorage.instance.getGymId();
          final fromToken = await session.getGymIdFromToken();
          if (gid == null && fromToken != null) {
            await GymContextStorage.instance.setGymId(fromToken);
            gid = fromToken;
          }
          if (gid == null) {
            if (!mounted) return;
            await Navigator.of(context).push<int>(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => const GymSelectPage(barrierDismissible: false),
              ),
            );
            if (!mounted) return;
          }
        }
        await AppBrandingController.instance.refreshFromApi();
        if (!mounted) return;
        try {
          await StudentService()
              .getMe()
              .timeout(const Duration(seconds: 25));
        } catch (e) {
          if (!dioIsNotFound(e) || !sysAdmin) rethrow;
        }
        if (!mounted) return;
        openedHome = true;
        Navigator.pushReplacementNamed(context, "/home");
      } catch (_) {
        try {
          await authRepository.logout();
        } catch (_) {
          await TokenStorage().clearToken();
        }
      }
    } finally {
      if (mounted && !openedHome) {
        setState(() => _checkingSession = false);
      }
    }
  }

  Future<void> login() async {
    if (_isLoggingIn) return;
    setState(() => _isLoggingIn = true);
    try {
      await authRepository.login(
        emailController.text,
        passwordController.text,
      );

      if (!mounted) return;
      final session = SessionService();
      if (await session.isSystemAdmin()) {
        var gid = await GymContextStorage.instance.getGymId();
        final fromToken = await session.getGymIdFromToken();
        if (gid == null && fromToken != null) {
          await GymContextStorage.instance.setGymId(fromToken);
          gid = fromToken;
        }
        if (gid == null) {
          if (!mounted) return;
          await Navigator.of(context).push<int>(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => const GymSelectPage(barrierDismissible: false),
            ),
          );
          if (!mounted) return;
        }
      }
      await AppBrandingController.instance.refreshFromApi();
      if (!mounted) return;
      Navigator.pushNamed(context, "/home");
    } catch (e) {
      final message = e.toString().replaceFirst("Exception: ", "");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            message.isEmpty
                ? "Falha no login. Verifique email/senha e tente novamente."
                : message,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_checkingSession) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: cs.tertiary),
        ),
      );
    }

    final primary = cs.primary;
    final screenW = MediaQuery.sizeOf(context).width;
    final logoWidth = (screenW * 0.82).clamp(240.0, 400.0);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primary.withValues(alpha: 0.12),
                  cs.surfaceContainerLowest,
                  cs.surfaceContainerLowest,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            width: logoWidth,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            isAntiAlias: true,
                            semanticLabel: 'Logo MeuCT',
                          ),
                          const SizedBox(height: AppSpacing.lg + 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Entrar',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Acesse sua conta da academia',
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(AppRadii.card + 4),
                              boxShadow: [
                                BoxShadow(
                                  color: cs.shadow.withValues(alpha: 0.1),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              border: Border.all(
                                color: cs.outline.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'E-mail',
                                    hintText: 'voce@email.com',
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                PasswordFieldWithVisibility(
                                  controller: passwordController,
                                  hintText: 'Senha',
                                  labelText: 'Senha',
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                PrimaryButton(
                                  label: 'Entrar',
                                  loading: _isLoggingIn,
                                  onPressed: _isLoggingIn ? null : login,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, "/register");
                                  },
                                  child: const Text('Criar conta'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      "/forgot-password",
                                    );
                                  },
                                  child: const Text('Esqueci minha senha'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      "/resend-verification",
                                    );
                                  },
                                  child: const Text(
                                    'Não recebeu o e-mail? Reenviar',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
