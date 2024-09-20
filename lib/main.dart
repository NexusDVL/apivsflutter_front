import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Para formatar data e hora
import 'cadastro_equipamento_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: EquipamentosPage(),
    );
  }
}

class EquipamentosPage extends StatefulWidget {
  @override
  _EquipamentosPageState createState() => _EquipamentosPageState();
}

class _EquipamentosPageState extends State<EquipamentosPage> {
  List<dynamic> equipamentos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchEquipamentos();
  }

  Future<void> fetchEquipamentos() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:8080/equipamentos'));

      if (response.statusCode == 200) {
        setState(() {
          equipamentos = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Falha ao carregar equipamentos');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print(e);
    }
  }

  Future<void> reservarEquipamento(int equipamentoId) async {
    final equipamento = equipamentos.firstWhere((e) => e['id'] == equipamentoId);
    if (!equipamento['disponivel']) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Equipamento já está reservado!'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    // Verificar se já existe uma reserva para o equipamento hoje
    DateTime hoje = DateTime.now();
    String dataHoje = DateFormat('yyyy-MM-dd').format(hoje);
    
    // Verifica se há reservas para o dia atual
    if (equipamento['reservas'] != null) {
      for (var reserva in equipamento['reservas']) {
        if (reserva['data'].substring(0, 10) == dataHoje) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Equipamento já reservado para hoje!'),
            backgroundColor: Colors.red,
          ));
          return;
        }
      }
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/equipamentos/$equipamentoId/reservar'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        setState(() {
          final index = equipamentos.indexWhere((e) => e['id'] == equipamentoId);
          if (index != -1) {
            equipamentos[index]['disponivel'] = false;
            equipamentos[index]['data_retirada'] = DateTime.now().toIso8601String(); // Atualiza a data de retirada localmente
            
            // Adiciona a nova reserva à lista de reservas
            if (equipamentos[index]['reservas'] == null) {
              equipamentos[index]['reservas'] = [];
            }
            equipamentos[index]['reservas'].add({'data': DateTime.now().toIso8601String()});
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Equipamento reservado com sucesso!'),
          backgroundColor: Colors.green,
        ));
      } else {
        throw Exception('Falha ao reservar equipamento');
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao reservar equipamento'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> liberarEquipamento(int equipamentoId) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/equipamentos/$equipamentoId/liberar'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        setState(() {
          final index = equipamentos.indexWhere((e) => e['id'] == equipamentoId);
          if (index != -1) {
            equipamentos[index]['disponivel'] = true;
            equipamentos[index]['data_retirada'] = null; // Limpa a data de retirada ao liberar
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Reserva liberada com sucesso!'),
          backgroundColor: Colors.green,
        ));
      } else {
        throw Exception('Falha ao liberar reserva');
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao liberar reserva'),
        backgroundColor: Colors.red,
      ));
    }
  }

  // Função para formatar a data e hora de maneira legível
  String formatarData(String dataHora) {
    final DateTime dateTime = DateTime.parse(dataHora);
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Equipamentos'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
              decoration: BoxDecoration(color: Colors.blueAccent),
            ),
            ListTile(
              leading: Icon(Icons.view_list),
              title: Text('Consulta de Equipamentos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => EquipamentosPage()));
              },
            ),
            ListTile(
              leading: Icon(Icons.add_circle),
              title: Text('Cadastro de Equipamentos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => CadastroEquipamentoPage()));
              },
            ),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchEquipamentos,
              child: ListView.builder(
                itemCount: equipamentos.length,
                itemBuilder: (context, index) {
                  final equipamento = equipamentos[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(15),
                      leading: CircleAvatar(
                        backgroundColor: equipamento['disponivel'] ? Colors.green : Colors.red,
                        child: Icon(
                          equipamento['disponivel'] ? Icons.check_circle : Icons.cancel,
                          color: Colors.white,
                        ),
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                equipamento['nome'],
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              Text(
                                equipamento['disponivel'] ? 'Disponível' : 'Reservado',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          // Mostrando a data de retirada, se disponível
                          if (equipamento['data_retirada'] != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                formatarData(equipamento['data_retirada']),
                                style: TextStyle(fontSize: 14, color: Colors.black),
                              ),
                            ),
                          // Botão de reservar/liberar alinhado
                          equipamento['disponivel']
                              ? ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  onPressed: () {
                                    reservarEquipamento(equipamento['id']);
                                  },
                                  child: Text('Reservar'),
                                )
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  onPressed: () {
                                    liberarEquipamento(equipamento['id']);
                                  },
                                  child: Text('Liberar'),
                                ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
