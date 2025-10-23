import 'package:flutter/material.dart';
import 'package:task_manager/models/credentials.dart';
import 'package:task_manager/widgets/login.dart';
import 'package:task_manager/widgets/engineer_home.dart';
import 'package:task_manager/widgets/exec_customer_home.dart';
import 'package:task_manager/widgets/manager_home.dart';


// Очень важное изменение


void main() {
  // демо-аккаунт просто добавим в список для “быстрого выбора”
  Credentials.addOrUpdate(const Credentials(
    login: "admin",
    accessToken: "123",
    rememberMe: true,
    type: AccountType.manager,
  ));
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: TaskManagerApp()));
}

class TaskManagerApp extends StatefulWidget {
  const TaskManagerApp({super.key});
  @override
  State<TaskManagerApp> createState() => _TaskManagerAppState();
}

class _TaskManagerAppState extends State<TaskManagerApp> {
  Credentials? me;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final cur = await Credentials.current();
    if (mounted) setState(() => me = cur);
  }

  Future<void> _openLogin() async {
    final creds = await showModalBottomSheet<Credentials>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const LoginSheet(),
    );
    if (creds != null) {
      await Credentials.setCurrent(creds);
      if (mounted) setState(() => me = creds);
    }
  }

  Future<void> _logout() async {
    await Credentials.clearCurrent();
    if (mounted) setState(() => me = null);
  }

  @override
  Widget build(BuildContext context) {
    final title = 'Строительные проекты';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (me != null) Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('${me!.login} — ${me!.type.label}'),
            ),
          ),
          if (me != null)
            IconButton(onPressed: _logout, tooltip: 'Выйти', icon: const Icon(Icons.logout)),
        ],
      ),
      body: me == null
          ? _LoginCallToAction(onLogin: _openLogin)            // кнопка “Войти”
          : RoleHomeSwitcher(account: me!),                    // разные виджеты по роли
      floatingActionButton: me == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _logout,
              icon: const Icon(Icons.switch_account),
              label: const Text('Сменить учётку'),
            ),
    );
  }
}

/// экран до входа
class _LoginCallToAction extends StatelessWidget {
  final VoidCallback onLogin;
  const _LoginCallToAction({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Добро пожаловать в Building Task Manager!', style: TextStyle(fontSize: 20)),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: onLogin,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            child: Text('Войти'),
          ),
        ),
      ]),
    );
  }
}

/// выбираем виджет по типу учётки
class RoleHomeSwitcher extends StatelessWidget {
  final Credentials account;
  const RoleHomeSwitcher({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    switch (account.type) {
      case AccountType.engineer:
        return const EngineerHome();
      case AccountType.manager:
        return const ManagerHome();
      case AccountType.executive:
      case AccountType.customer:
        return const ExecCustomerHome();
    }
  }
}

