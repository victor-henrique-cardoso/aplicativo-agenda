import 'package:agendaapp/_comum/minhascores.dart';
import 'package:agendaapp/_comum/modal_add_agenda.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AgendaHomePage extends StatefulWidget {
  final User user;

  AgendaHomePage({super.key, required this.user});

  @override
  _AgendaHomePageState createState() => _AgendaHomePageState();
}

class _AgendaHomePageState extends State<AgendaHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _diasSemana = [
    'Domingo', 'Segunda-feira', 'Terça-feira', 'Quarta-feira', 
    'Quinta-feira', 'Sexta-feira', 'Sábado'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _diasSemana.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _excluirEvento(String id) async {
    try {
      await FirebaseFirestore.instance.collection('eventos').doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento excluído com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao excluir o evento.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Agenda'),
        centerTitle: true,
        backgroundColor: Minhascores.Rosapastel,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () {
              mostramodalcriaragenda(context);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          tabs: _diasSemana.map((dia) => Tab(text: dia)).toList(),
        ),
      ),
      backgroundColor: Minhascores.begeclaro,
      body: TabBarView(
        controller: _tabController,
        children: _diasSemana.map((diaSelecionado) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('eventos').snapshots(),
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Algo deu errado'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              List<Map<String, dynamic>> eventosFiltrados = snapshot.data!.docs
                  .map((DocumentSnapshot document) {
                    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                    if (data['userId'] == widget.user.uid && data['diaSemana'] == diaSelecionado) {
                      return {
                        'id': document.id,
                        'titulo': data['titulo'] ?? "Sem título",
                        'concluido': data['concluido'] ?? false,
                      };
                    }
                    return null;
                  })
                  .where((evento) => evento != null)
                  .cast<Map<String, dynamic>>()
                  .toList();

              return ListView.builder(
                itemCount: eventosFiltrados.length,
                itemBuilder: (context, index) {
                  final evento = eventosFiltrados[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            evento['titulo'],
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Minhascores.Rosapastel,
                            ),
                          ),
                          const SizedBox(height: 12.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                evento['concluido'] ? 'Concluído' : 'Pendente',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  color: evento['concluido'] ? Colors.green : Colors.red,
                                ),
                              ),
                              Row(
                                children: [
                                  Checkbox(
                                    value: evento['concluido'],
                                    onChanged: (value) async {
                                      await FirebaseFirestore.instance
                                          .collection('eventos')
                                          .doc(evento['id'])
                                          .update({'concluido': value});
                                    },
                                  ),
                                  if (evento['concluido'])
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _excluirEvento(evento['id']),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
