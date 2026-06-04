import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'login_screen.dart';
import 'update_password_screen.dart';
import 'verify_email_screen.dart';
import 'admin_mfa_screen.dart';
import 'pending_approval_screen.dart';
import '../marketplace/marketplace_service.dart';
import '../marketplace/customer/customer_shell.dart';
import '../marketplace/vendor/vendor_shell.dart';
import '../marketplace/rider/rider_shell.dart';
import '../marketplace/admin/admin_shell.dart';
import '../core/theme/app_colors.dart';

/// Role-aware auth gate.  Routes to the correct shell based on user role.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  /// Static flag: set true before calling signUp() to suppress the
  /// automatic signedIn event from immediately routing to home.
  static bool _suppressNextSignIn = false;

  /// Call this from SignupScreen before calling supabase.auth.signUp()
  /// to prevent the AuthGate from reacting to the automatic signedIn event.
  static void suppressNextSignIn() {
    _suppressNextSignIn = true;
  }

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<Uri>? _linkSub;
  String? _role;
  bool _loadingRole = false;
  bool _needsMfa = false;
  bool _isPendingApproval = false;

  bool _recoveryHandled = false;

  void _handleRecovery() {
    if (_recoveryHandled) return;
    _recoveryHandled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const UpdatePasswordScreen()),
        ).then((_) => _recoveryHandled = false);
      }
    });
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Raw Deep Link Received: $uri');
    final fragment = uri.fragment;
    if (fragment.contains('error=')) {
      final params = Uri.splitQueryString(fragment);
      final desc = params['error_description']?.replaceAll('+', ' ') ?? 'Unknown Auth Error';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Link Error: $desc'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } else if (fragment.contains('type=recovery')) {
      _handleRecovery();
    }
  }

  Future<void> _checkInitialLink() async {
    try {
      final uri = await AppLinks().getInitialLink();
      if (uri != null) _handleDeepLink(uri);
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }
  }


  @override
  void initState() {
    super.initState();

    _checkInitialLink();

    // Listen for raw deep links to catch Supabase auth errors or recovery
    _linkSub = AppLinks().uriLinkStream.listen(_handleDeepLink);

    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        _handleRecovery();
        return;
      }

      // If we're suppressing the next signedIn (e.g. right after signup),
      // consume it and don't reset state.
      if (data.event == AuthChangeEvent.signedIn && AuthGate._suppressNextSignIn) {
        AuthGate._suppressNextSignIn = false;
        return;
      }

      // Only reset role and MFA on meaningful auth transitions
      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.signedOut) {
        if (mounted) {
          setState(() {
            _role = null;
            _loadingRole = false;
            _needsMfa = false;
            _isPendingApproval = false;
          });
        }
      }
    });
    _initFcm();
  }

  Future<void> _initFcm() async {
    await FirebaseMessaging.instance.requestPermission();
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await MarketplaceService.saveFcmToken(token);
    }
  }

  Future<String> _fetchRole() async {
    final r = await MarketplaceService.getUserRole();
    final approved = await MarketplaceService.isUserApproved();
    final aal = Supabase.instance.client.auth.mfa.getAuthenticatorAssuranceLevel();
    if (mounted) {
      setState(() { 
        _role = r; 
        if (r == 'admin' && aal.currentLevel == AuthenticatorAssuranceLevels.aal1) {
          _needsMfa = true;
        } else {
          _needsMfa = false;
        }

        if ((r == 'vendor' || r == 'rider') && !approved) {
          _isPendingApproval = true;
        } else {
          _isPendingApproval = false;
        }

        _loadingRole = false; 
      });
    }
    return r;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }

        final session = snapshot.data?.session
            ?? Supabase.instance.client.auth.currentSession;

        if (session == null) {
          _needsMfa = false;
          _isPendingApproval = false;
          return const LoginScreen();
        }

        // If email is not confirmed, always show verify screen.
        // This is the primary guard against the signup bypass.
        if (session.user.emailConfirmedAt == null) {
          return VerifyEmailScreen(email: session.user.email ?? '');
        }

        // User is logged in – fetch role once
        if (_role == null && !_loadingRole) {
          _loadingRole = true; // Set directly to avoid setState during build
          _fetchRole();
          return const _Splash(); // show spinner while role loads
        }
        if (_loadingRole) return const _Splash();

        if (_role == 'admin' && _needsMfa) {
          return const AdminMfaScreen();
        }

        if (_isPendingApproval) {
          return PendingApprovalScreen(
            role: _role,
            onCheckStatus: () {
              if (mounted) {
                setState(() {
                  _role = null;
                  _loadingRole = false;
                });
              }
            },
          );
        }

        switch (_role) {
          case 'vendor': return const VendorShell();
          case 'rider':  return const RiderShell();
          case 'admin':  return const AdminShell();
          default:       return const CustomerShell();
        }
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: AppColors.background,
    body: Center(child: CircularProgressIndicator(color: AppColors.cyan)),
  );
}
