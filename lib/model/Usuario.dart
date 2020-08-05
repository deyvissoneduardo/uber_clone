class Usuario {
  /** atributos **/
  String _idUsuario;
  String _nome;
  String _email;
  String _senha;
  String _tipoUsuario;

  /** contrutor **/
  Usuario();

  /** retorna o tipo de usuario **/
  String verificaTipoUsuario(bool tipoUsuario) {
    return tipoUsuario ? 'motorista' : 'passageiro';
  }

  /** cria ToMap para salvar no firebase **/
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      "nome": this.nome,
      "email": this.email,
      "tipoUsuario": this.tipoUsuario
    };
    return map;
  }

  /** getrs e setrs **/
  String get tipoUsuario => _tipoUsuario;

  set tipoUsuario(String value) {
    _tipoUsuario = value;
  }

  String get senha => _senha;

  set senha(String value) {
    _senha = value;
  }

  String get email => _email;

  set email(String value) {
    _email = value;
  }

  String get nome => _nome;

  set nome(String value) {
    _nome = value;
  }

  String get idUsuario => _idUsuario;

  set idUsuario(String value) {
    _idUsuario = value;
  }
}
