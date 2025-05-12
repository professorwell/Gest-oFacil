// lib/models/transacao_model.dart

class Transacao {
  final int? id;
  final String tipo;
  final String descricao;
  final double valor;
  final String data;

  Transacao({
    this.id,
    required this.tipo,
    required this.descricao,
    required this.valor,
    required this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo': tipo,
      'descricao': descricao,
      'valor': valor,
      'data': data,
    };
  }

  factory Transacao.fromMap(Map<String, dynamic> map) {
    return Transacao(
      id: map['id'],
      tipo: map['tipo'],
      descricao: map['descricao'],
      valor: map['valor'],
      data: map['data'],
    );
  }
}
