import 'package:agendaapp/_comum/minhascores.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TelaAgendaEscolar extends StatefulWidget {
  final User user;

  const TelaAgendaEscolar({Key? key, required this.user}) : super(key: key);

  @override
  _TelaAgendaEscolarState createState() => _TelaAgendaEscolarState();
}

class _TelaAgendaEscolarState extends State<TelaAgendaEscolar> {
  final _firestore = FirebaseFirestore.instance;

  // Controladores para o modal de adicionar tarefa
  final TextEditingController _tituloController = TextEditingController();
  DateTime? _dataHoraSelecionada;

  // Função para abrir o modal de criação de tarefas
  void _mostrarModalAdicionarTarefa(BuildContext context) {
    showModalBottomSheet(
      context: context,
         backgroundColor: Minhascores.Rosapastel,
         isDismissible: false,
    isScrollControlled: true,
      shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(34),
      ),
    ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título da Tarefa',
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  final dataHoraEscolhida = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );

                  if (dataHoraEscolhida != null) {
                    final horaEscolhida = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );

                    if (horaEscolhida != null) {
                      setState(() {
                        _dataHoraSelecionada = DateTime(
                          dataHoraEscolhida.year,
                          dataHoraEscolhida.month,
                          dataHoraEscolhida.day,
                          horaEscolhida.hour,
                          horaEscolhida.minute,
                        );
                      });
                    }
                  }
                },
                child: const Text('Selecionar Data e Hora'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_tituloController.text.isNotEmpty &&
                      _dataHoraSelecionada != null) {
                    await _firestore.collection('tarefas_escolares').add({
                      'titulo': _tituloController.text,
                      'dataHora': _dataHoraSelecionada,
                      'userId': widget.user.uid,
                      'concluido': false,
                    });

                    _tituloController.clear();
                    _dataHoraSelecionada = null;
                    Navigator.pop(context);
                  }
                },
                child: const Text('Salvar Tarefa'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Minhascores.begeclaro, // Cor de fundo da tela.
      appBar: AppBar(
        title: const Text('Agenda Escolar'),
        centerTitle: true,
        backgroundColor: Minhascores.Rosapastel,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarModalAdicionarTarefa(context),
        child: const Icon(Icons.add_box_outlined),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('tarefas_escolares')
            .where('userId', isEqualTo: widget.user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar tarefas.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tarefas = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              ...data,
            };
          }).toList();

          return ListView.builder(
            itemCount: tarefas.length,
            itemBuilder: (context, index) {
              final tarefa = tarefas[index];
              final dataHora = (tarefa['dataHora'] as Timestamp).toDate();
              final formatada = DateFormat('dd/MM/yyyy HH:mm').format(dataHora);

              return ListTile(
                title: Text(tarefa['titulo']),
                subtitle: Text(formatada),
                trailing: Checkbox(
                  value: tarefa['concluido'],
                  onChanged: (bool? valor) {
                    _firestore
                        .collection('tarefas_escolares')
                        .doc(tarefa['id'])
                        .update({'concluido': valor});
                  },
                ),
                onLongPress: () async {
                  await _firestore
                      .collection('tarefas_escolares')
                      .doc(tarefa['id'])
                      .delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tarefa excluída.'),backgroundColor: Minhascores.Rosapastel),

                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
