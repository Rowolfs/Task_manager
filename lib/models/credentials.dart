// credentials.dart
import 'dart:convert';
import 'package:task_manager/config.dart'; // const storage = FlutterSecureStorage();

/// Типы аккаунтов
enum AccountType { engineer, manager, executive, customer }

extension AccountTypeX on AccountType {
  String get key => switch (this) {
        AccountType.engineer  => 'engineer',
        AccountType.manager   => 'manager',
        AccountType.executive => 'executive',
        AccountType.customer  => 'customer',
      };

  String get label => switch (this) {
        AccountType.engineer  => 'Инженер',
        AccountType.manager   => 'Менеджер',
        AccountType.executive => 'Руководитель',
        AccountType.customer  => 'Заказчик',
      };

  static AccountType fromKey(String? k) {
    return switch (k) {
      'manager'   => AccountType.manager,
      'executive' => AccountType.executive,
      'customer'  => AccountType.customer,
      _           => AccountType.engineer,
    };
  }
}

/// Данные учётной записи с токенами
class Credentials {
  final String login;
  final String accessToken;
  final String? refreshToken;
  final bool rememberMe;
  final AccountType type;

  const Credentials({
    required this.login,
    required this.accessToken,
    this.refreshToken,
    required this.rememberMe,
    required this.type,
  });

  // -------- Сериализация --------

  Map<String, dynamic> toJson() => {
        'login'        : login,
        'accessToken'  : accessToken,
        'refreshToken' : refreshToken,
        'rememberMe'   : rememberMe,
        'type'         : type.key,
      };

  factory Credentials.fromJson(Map<String, dynamic> json) {
    // миграция: если старый ключ password — считаем его accessToken
    final token = (json['accessToken'] ??
        json['password']) as String? ??
        '';

    return Credentials(
      login        : json['login'] as String,
      accessToken  : token,
      refreshToken : json['refreshToken'] as String?,
      rememberMe   : (json['rememberMe'] as bool?) ?? false,
      type         : AccountTypeX.fromKey(json['type'] as String?),
    );
  }

  Credentials copyWith({
    String? login,
    String? accessToken,
    String? refreshToken,
    bool? rememberMe,
    AccountType? type,
  }) =>
      Credentials(
        login        : login        ?? this.login,
        accessToken  : accessToken  ?? this.accessToken,
        refreshToken : refreshToken ?? this.refreshToken,
        rememberMe   : rememberMe   ?? this.rememberMe,
        type         : type         ?? this.type,
      );

  // -------- Хранилище (список учёток) --------

  static const _kCurrent = 'current_account';
  static const _k = 'accounts';

/// Сохранить текущую сессию
static Future<void> setCurrent(Credentials acc) async {
  await storage.write(key: _kCurrent, value: jsonEncode(acc.toJson()));
  if (acc.rememberMe) {
    await addOrUpdate(acc); // держим в списке известных аккаунтов
  }
}

/// Прочитать текущую сессию
static Future<Credentials?> current() async {
  final raw = await storage.read(key: _kCurrent);
  if (raw == null) return null;
  return Credentials.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

/// Разлогиниться
static Future<void> clearCurrent() async {
  await storage.delete(key: _kCurrent);
}


  /// Загрузить все аккаунты
  static Future<List<Credentials>> loadAll() async {
    final jsonStr = await storage.read(key: _k);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    final list = (jsonDecode(jsonStr) as List).cast<Map<String, dynamic>>();
    return list.map(Credentials.fromJson).toList();
  }

  /// Сохранить весь список
  static Future<void> saveAll(List<Credentials> accounts) async {
    final jsonStr = jsonEncode(accounts.map((e) => e.toJson()).toList());
    await storage.write(key: _k, value: jsonStr);
  }

  /// Добавить или обновить (по login+type)
  static Future<void> addOrUpdate(Credentials acc) async {
    final list = await loadAll();
    final i = list.indexWhere((e) => e.login == acc.login && e.type == acc.type);
    if (i >= 0) {
      list[i] = acc;
    } else {
      list.add(acc);
    }
    await saveAll(list);
  }

  /// Удалить конкретный аккаунт
  static Future<void> remove({
    required String login,
    required AccountType type,
  }) async {
    final list = await loadAll();
    list.removeWhere((e) => e.login == login && e.type == type);
    await saveAll(list);
  }

  /// Очистить всё хранилище
  static Future<void> clearAll() async => storage.delete(key: _k);

  /// Получить аккаунты заданного типа
  static Future<List<Credentials>> byType(AccountType t) async =>
      (await loadAll()).where((e) => e.type == t).toList();
}
