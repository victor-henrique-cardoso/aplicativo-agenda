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

class _AgendaHomePageState extends State<AgendaHomePage> {
  final Stream<QuerySnapshot> _eventosStream =
      FirebaseFirestore.instance.collection('eventos').snapshots();

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
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add_box_outlined),
        onPressed: () {
          mostramodalcriaragenda(context);
        },
      ),
      backgroundColor: Minhascores.begeclaro,
      body: StreamBuilder<QuerySnapshot>(
        stream: _eventosStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Algo deu errado'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          List<Map<String, dynamic>> eventosOrdenados = snapshot.data!.docs
              .map((DocumentSnapshot document) {
                Map<String, dynamic> data = document.data() as Map<String, dynamic>;

                if (data['userId'] == widget.user.uid) {
                  DateTime? dataHora;
                  if (data['dataHora'] != null) {
                    if (data['dataHora'] is Timestamp) {
                      dataHora = (data['dataHora'] as Timestamp).toDate();
                    } else {
                      dataHora = DateTime.parse(data['dataHora']);
                    }
                  }
                  return {
                    'id': document.id,
                    'titulo': data['titulo'] ?? "Sem título",
                    'dataHora': dataHora,
                    'concluido': data['concluido'] ?? false,
                  };
                }
                return null;
              })
              .where((evento) => evento != null)
              .cast<Map<String, dynamic>>()
              .toList();

          eventosOrdenados.sort((a, b) {
            final dataHoraA = a['dataHora'];
            final dataHoraB = b['dataHora'];

            if (dataHoraA == null && dataHoraB == null) return 0;
            if (dataHoraA == null) return 1;
            if (dataHoraB == null) return -1;
            return dataHoraA.compareTo(dataHoraB);
          });

          return ListView.builder(
            itemCount: eventosOrdenados.length,
            itemBuilder: (context, index) {
              final evento = eventosOrdenados[index];

              String dataHoraFormatada = "Sem data";
              if (evento['dataHora'] != null) {
                dataHoraFormatada =
                    DateFormat('dd/MM/yyyy HH:mm').format(evento['dataHora']);
              }

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
                      const SizedBox(height: 8.0),
                      Text(
                        dataHoraFormatada,
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.grey[700],
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
                              color: evento['concluido']
                                  ? Colors.green
                                  : Colors.red,
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
                              // Exibe o botão de exclusão apenas se o evento estiver concluído.
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
      ),
    );
  }
}
