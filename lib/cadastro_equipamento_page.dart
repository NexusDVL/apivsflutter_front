import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CadastroEquipamentoPage extends StatefulWidget {
  @override
  _CadastroEquipamentoPageState createState() => _CadastroEquipamentoPageState();
}

class _CadastroEquipamentoPageState extends State<CadastroEquipamentoPage> {
  final TextEditingController nomeController = TextEditingController();
  bool _disponivel = true;

  Future<void> cadastrarEquipamento() async { 
    final String nome = nomeController.text;

    final String dataHora = DateTime.now().toIso8601String();

    final Map<String, dynamic> data = {
      "nome": nome,
      "disponivel": _disponivel,
      "dataHora": dataHora, // Adiciona o campo dataHora
    };
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/equipamentos'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Equipamento cadastrado com sucesso!'),
        ));
        nomeController.clear();
      } else {
        throw Exception('Falha ao cadastrar equipamento');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao cadastrar equipamento'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cadastrar Equipamento')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nomeController,
              decoration: InputDecoration(labelText: 'Nome do Equipamento'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: cadastrarEquipamento,
              child: Text('Cadastrar'),
            ),
          ],
        ),
      ),
    );
  }
}
