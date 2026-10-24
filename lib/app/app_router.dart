import 'package:flutter/material.dart';
import '../features/auth/presentation/screens/auth_gate.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/customer/presentation/screens/customer_dashboard_screen.dart';
import '../features/customer/presentation/screens/stations_screen.dart';
import '../features/customer/presentation/screens/tokens_screen.dart';
import '../features/customer/presentation/screens/vehicle_screen.dart';
import '../features/customer/presentation/screens/profile_screen.dart';
import '../features/customer/presentation/screens/customer_features_screen.dart';
import '../features/pump_owner/presentation/screens/pump_owner_dashboard_screen.dart';
import '../features/admin/presentation/screens/station_management_screen.dart';
import '../features/admin/presentation/screens/queue_management_screen.dart';
import '../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../features/admin/presentation/screens/pump_owner_applications_screen.dart';
import 'route_names.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final Widget page;
    switch (settings.name) {
      case RouteNames.splash:
        page = const AuthGate();
        break;
      case RouteNames.login:
        page = const LoginScreen();
        break;
      case RouteNames.register:
        page = const RegisterScreen();
        break;
      case RouteNames.forgotPassword:
        page = const ForgotPasswordScreen();
        break;
      case RouteNames.customer:
        page = const CustomerDashboardScreen();
        break;
      case RouteNames.stations:
        page = const StationsScreen();
        break;
      case RouteNames.tokens:
        page = const TokensScreen();
        break;
      case RouteNames.vehicles:
        page = const VehicleScreen();
        break;
      case RouteNames.profile:
        page = const ProfileScreen();
        break;
      case RouteNames.customerFeatures:
        page = const CustomerFeaturesScreen();
        break;
      case RouteNames.pumpOwner:
        page = const PumpOwnerDashboardScreen();
        break;
      case RouteNames.stationManagement:
        page = const StationManagementScreen();
        break;
      case RouteNames.queueManagement:
        page = const QueueManagementScreen();
        break;
      case RouteNames.admin:
        page = const AdminDashboardScreen();
        break;
      case RouteNames.ownerApplications:
        page = const PumpOwnerApplicationsScreen();
        break;
      default:
        page = const _UnknownRouteScreen();
        break;
    }
    return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Page not found')),
    body: Center(child: FilledButton(
      onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(RouteNames.splash, (_) => false),
      child: const Text('Return to CNGPulse'),
    )),
  );
}
