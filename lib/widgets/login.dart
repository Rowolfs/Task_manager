import 'package:flutter/material.dart';
import 'package:task_manager/models/credentials.dart';

class LoginSheet extends StatefulWidget {
  const LoginSheet({super.key});

  @override
  State<LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends State<LoginSheet> {
  final _formKey = GlobalKey<FormState>();
  final _login = TextEditingController();
  final _password = TextEditingController();
  bool _remember = true;
  bool _obscure = true;

  AccountType _role = AccountType.engineer;
  List<Credentials> _saved = [];
  Credentials? _selectedSaved;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final list = await Credentials.loadAll();
    if (!mounted) return;
    setState(() => _saved = list);
  }

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Вход', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              if (_saved.isNotEmpty) ...[
                DropdownButtonFormField<Credentials>(
                  value: _selectedSaved,
                  decoration: const InputDecoration(
                    labelText: 'Быстрый выбор учётки',
                    border: OutlineInputBorder(),
                  ),
                  items: _saved.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text('${c.login} — ${c.type.label}'),
                  )).toList(),
                  onChanged: (c) {
                    setState(() {
                      _selectedSaved = c;
                      if (c != null) {
                        _login.text = c.login;
                        _password.text = c.accessToken;
                        _role = c.type;
                        _remember = c.rememberMe;
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
              ],

              TextFormField(
                controller: _login,
                decoration: const InputDecoration(
                  labelText: 'Логин',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Введите логин' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _password,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Токен/Пароль',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => v != null && v.length < 4 ? 'Минимум 4 символа' : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<AccountType>(
                value: _role,
                decoration: const InputDecoration(
                  labelText: 'Роль',
                  border: OutlineInputBorder(),
                ),
                items: AccountType.values.map((t) =>
                    DropdownMenuItem(value: t, child: Text(t.label))
                ).toList(),
                onChanged: (v) => setState(() => _role = v!),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Checkbox(value: _remember, onChanged: (v) => setState(() => _remember = v ?? true)),
                  const Text('Запомнить меня'),
                  const Spacer(),
                  if (_selectedSaved != null)
                    TextButton(
                      onPressed: () async {
                        await Credentials.remove(login: _selectedSaved!.login, type: _selectedSaved!.type);
                        setState(() { _selectedSaved = null; });
                        _loadSaved();
                      },
                      child: const Text('Удалить выбранную'),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              FilledButton(
                onPressed: _submit,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                  child: Text('Войти'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final creds = Credentials(
      login: _login.text.trim(),
      accessToken: _password.text.trim(),
      rememberMe: _remember,
      type: _role,
    );
    Navigator.pop(context, creds); // ВОЗВРАЩАЕМ в main.dart
  }
}
