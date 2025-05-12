import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/transacao_model.dart';

class ListPage extends StatefulWidget {
  const ListPage({super.key});

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  List<Transacao> _transacoes = [];
  String _filtroTipo = 'Todos';

  double _totalGeral = 0.0;
  double _totalAvista = 0.0;
  double _totalFiado = 0.0;

  @override
  void initState() {
    super.initState();
    _carregarTransacoes();
  }

  Future<void> _carregarTransacoes() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'transacoes',
      orderBy: 'data DESC',
    );

    final todas = maps.map((map) => Transacao.fromMap(map)).toList();

    setState(() {
      _transacoes = _filtroTipo == 'Todos'
          ? todas
          : todas.where((t) => t.tipo == _filtroTipo).toList();

      _totalGeral = todas.fold(0.0, (soma, t) => soma + t.valor);
      _totalAvista = todas
          .where((t) => t.tipo == 'À vista')
          .fold(0.0, (soma, t) => soma + t.valor);
      _totalFiado = todas
          .where((t) => t.tipo == 'Fiado')
          .fold(0.0, (soma, t) => soma + t.valor);
    });
  }

  void _alterarFiltro(String? tipo) {
    if (tipo != null) {
      setState(() {
        _filtroTipo = tipo;
      });
      _carregarTransacoes();
    }
  }

  Future<void> _editarTransacao(Transacao t) async {
    final _formKey = GlobalKey<FormState>();
    String novaDescricao = t.descricao;
    String novoValor = t.valor.toString();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar Transação'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: novaDescricao,
                decoration: const InputDecoration(labelText: 'Descrição'),
                onChanged: (v) => novaDescricao = v,
              ),
              TextFormField(
                initialValue: novoValor,
                decoration: const InputDecoration(labelText: 'Valor'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) => novoValor = v,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final valorConvertido = double.tryParse(novoValor.replaceAll(',', '.')) ?? t.valor;
              final atualizada = Transacao(
                id: t.id,
                tipo: t.tipo,
                descricao: novaDescricao,
                valor: valorConvertido,
                data: t.data,
              );
              await DatabaseHelper.instance.atualizarTransacao(atualizada);
              Navigator.pop(context);
              await _carregarTransacoes();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _excluirTransacao(int id) async {
    await DatabaseHelper.instance.excluirTransacao(id);
    await _carregarTransacoes();
  }

  String _formatarData(String iso) {
    final data = DateTime.parse(iso);
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório de Vendas'),
        actions: [
          DropdownButton<String>(
            value: _filtroTipo,
            items: const [
              DropdownMenuItem(value: 'Todos', child: Text('Todos')),
              DropdownMenuItem(value: 'À vista', child: Text('À vista')),
              DropdownMenuItem(value: 'Fiado', child: Text('Fiado')),
            ],
            onChanged: _alterarFiltro,
            underline: const SizedBox(),
            dropdownColor: Theme.of(context).cardColor,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildResumoLinha('Total geral', _totalGeral, Colors.blue),
                  const SizedBox(height: 8),
                  _buildResumoLinha('À vista', _totalAvista, Colors.green),
                  const SizedBox(height: 8),
                  _buildResumoLinha('Fiado', _totalFiado, Colors.orange),
                ],
              ),
            ),
          ),
          Expanded(
            child: _transacoes.isEmpty
                ? const Center(child: Text('Nenhuma transação encontrada.'))
                : ListView.builder(
                    itemCount: _transacoes.length,
                    itemBuilder: (context, index) {
                      final t = _transacoes[index];
                      return Dismissible(
                        key: Key(t.id.toString()),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          color: Colors.orange,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(Icons.edit, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            await _excluirTransacao(t.id!);
                            return true;
                          } else {
                            await _editarTransacao(t);
                            return false;
                          }
                        },
                        child: ListTile(
                          leading: Icon(
                            t.tipo == 'Fiado'
                                ? Icons.warning_amber
                                : Icons.attach_money,
                            color: t.tipo == 'Fiado'
                                ? Colors.orange
                                : Colors.green,
                          ),
                          title: Text(t.descricao),
                          subtitle: Text(_formatarData(t.data)),
                          trailing: Text(
                            'R\$ ${t.valor.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoLinha(String label, double valor, Color cor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: cor, fontSize: 16)),
        Text(
          'R\$ ${valor.toStringAsFixed(2)}',
          style: TextStyle(
              color: cor, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
