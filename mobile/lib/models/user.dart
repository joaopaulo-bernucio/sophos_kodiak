class User {
  final String cnpj;
  final String senha;
  final String? nomePreferido;
  final DateTime? ultimoLogin;

  const User({
    required this.cnpj,
    required this.senha,
    this.nomePreferido,
    this.ultimoLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('cnpj') || !json.containsKey('senha')) {
      throw const FormatException(
        'Campos obrigatórios ausentes no JSON do usuário',
      );
    }

    final cnpj = json['cnpj'];
    final senha = json['senha'];

    if (cnpj is! String || senha is! String) {
      throw const FormatException('Campos cnpj e senha devem ser strings');
    }

    return User(
      cnpj: cnpj,
      senha: senha,
      nomePreferido: json['nomePreferido'] as String?,
      ultimoLogin: json['ultimoLogin'] != null
          ? DateTime.parse(json['ultimoLogin'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cnpj': cnpj,
      'senha': senha,
      'nomePreferido': nomePreferido,
      'ultimoLogin': ultimoLogin?.toIso8601String(),
    };
  }

  User copyWith({
    String? cnpj,
    String? senha,
    String? nomePreferido,
    DateTime? ultimoLogin,
  }) {
    return User(
      cnpj: cnpj ?? this.cnpj,
      senha: senha ?? this.senha,
      nomePreferido: nomePreferido ?? this.nomePreferido,
      ultimoLogin: ultimoLogin ?? this.ultimoLogin,
    );
  }

  @override
  String toString() {
    return 'User(cnpj: $cnpj, nomePreferido: $nomePreferido, ultimoLogin: $ultimoLogin)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.cnpj == cnpj &&
        other.senha == senha &&
        other.nomePreferido == nomePreferido &&
        other.ultimoLogin == ultimoLogin;
  }

  @override
  int get hashCode {
    return cnpj.hashCode ^
        senha.hashCode ^
        nomePreferido.hashCode ^
        ultimoLogin.hashCode;
  }
}
