/// Classe que representa um usuário do sistema Sophos Kodiak
///
/// Esta classe é responsável por estruturar os dados do usuário
/// e fornecer métodos para conversão de/para JSON para persistência.
class User {
  /// CNPJ do usuário (identificador único)
  final String cnpj;

  /// Senha do usuário
  final String senha;

  /// Nome preferido do usuário (opcional)
  final String? nomePreferido;

  /// Data do último login (opcional)
  final DateTime? ultimoLogin;

  /// Construtor da classe User
  const User({
    required this.cnpj,
    required this.senha,
    this.nomePreferido,
    this.ultimoLogin,
  });

  /// Cria uma instância de User a partir de um Map JSON
  ///
  /// Este método é usado para deserializar dados vindos do SharedPreferences
  /// ou de APIs. É útil para reconstruir o objeto User a partir de dados salvos.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      cnpj: json['cnpj'] as String,
      senha: json['senha'] as String,
      nomePreferido: json['nomePreferido'] as String?,
      ultimoLogin: json['ultimoLogin'] != null
          ? DateTime.parse(json['ultimoLogin'] as String)
          : null,
    );
  }

  /// Converte a instância atual de User para um Map JSON
  ///
  /// Este método é usado para serializar o objeto antes de salvar
  /// no SharedPreferences ou enviar para APIs.
  Map<String, dynamic> toJson() {
    return {
      'cnpj': cnpj,
      'senha': senha,
      'nomePreferido': nomePreferido,
      'ultimoLogin': ultimoLogin?.toIso8601String(),
    };
  }

  /// Cria uma nova instância de User com alguns campos alterados
  ///
  /// Este método é útil para atualizar informações específicas do usuário
  /// mantendo os outros dados inalterados.
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

  /// Retorna uma representação em string do objeto User
  ///
  /// Útil para debug e logs (não inclui a senha por segurança)
  @override
  String toString() {
    return 'User(cnpj: $cnpj, nomePreferido: $nomePreferido, ultimoLogin: $ultimoLogin)';
  }

  /// Compara duas instâncias de User
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.cnpj == cnpj &&
        other.senha == senha &&
        other.nomePreferido == nomePreferido &&
        other.ultimoLogin == ultimoLogin;
  }

  /// Gera um hash code para a instância
  @override
  int get hashCode {
    return cnpj.hashCode ^
        senha.hashCode ^
        nomePreferido.hashCode ^
        ultimoLogin.hashCode;
  }
}
