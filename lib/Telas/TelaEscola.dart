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

  final TextEditingController _tituloController = TextEditingController();
  DateTime? _dataHoraSelecionada;
  String _prioridadeSelecionada = "Média";
  String _diaSemanaSelecionado = 'Segunda-feira';

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
              DropdownButton<String>(
                value: _prioridadeSelecionada,
                items: ['Alta', 'Média', 'Baixa'].map((String prioridade) {
                  return DropdownMenuItem<String>(
                    value: prioridade,
                    child: Text(prioridade),
                  );
                }).toList(),
                onChanged: (String? novaPrioridade) {
                  setState(() {
                    _prioridadeSelecionada = novaPrioridade ?? "Média";
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: _diaSemanaSelecionado,
                items: ['Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado', 'Domingo'].map((String dia) {
                  return DropdownMenuItem<String>(
                    value: dia,
                    child: Text(dia),
                  );
                }).toList(),
                onChanged: (String? novoDia) {
                  setState(() {
                    _diaSemanaSelecionado = novoDia ?? 'Segunda-feira';
                  });
                },
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
                  if (_tituloController.text.isNotEmpty) {
                    final tarefaData = {
                      'titulo': _tituloController.text,
                      'prioridade': _prioridadeSelecionada,
                      'diaSemana': _diaSemanaSelecionado,
                      'userId': widget.user.uid,
                      'concluido': false,
                    };

                    if (_dataHoraSelecionada != null) {
                      tarefaData['dataHora'] = _dataHoraSelecionada as Object;
                    }

                    await _firestore.collection('tarefas_escolares').add(tarefaData);

                    _tituloController.clear();
                    _dataHoraSelecionada = null;
                    _prioridadeSelecionada = "Média";
                    _diaSemanaSelecionado = 'Segunda-feira';
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
      backgroundColor: Minhascores.begeclaro,
      appBar: AppBar(
        title: const Text('Agenda Escolar'),
        centerTitle: true,
        backgroundColor: Minhascores.Rosapastel,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () => _mostrarModalAdicionarTarefa(context),
          ),
        ],
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

          tarefas.sort((a, b) {
            const prioridades = {'Alta': 0, 'Média': 1, 'Baixa': 2};
            final prioridadeA = prioridades[a['prioridade']] ?? 2;
            final prioridadeB = prioridades[b['prioridade']] ?? 2;

            if (prioridadeA == prioridadeB) {
              return (a['dataHora'] as Timestamp)
                  .toDate()
                  .compareTo((b['dataHora'] as Timestamp).toDate());
            }
            return prioridadeA.compareTo(prioridadeB);
          });

          return ListView.builder(
            itemCount: tarefas.length,
            itemBuilder: (context, index) {
              final tarefa = tarefas[index];
              final dataHora = tarefa['dataHora'] != null
                  ? (tarefa['dataHora'] as Timestamp).toDate()
                  : null;
              final formatada = dataHora != null
                  ? DateFormat('dd/MM/yyyy').format(dataHora)
                  : 'Sem data definida';

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
                        tarefa['titulo'],
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Minhascores.Rosapastel,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        formatada,
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Prioridade: ${tarefa['prioridade']}',
                        style: const TextStyle(
                          fontSize: 14.0,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Dia da semana: ${tarefa['diaSemana']}',
                        style: const TextStyle(
                          fontSize: 14.0,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tarefa['concluido'] ? 'Concluído' : 'Pendente',
                            style: TextStyle(
                              fontSize: 14.0,
                              color: tarefa['concluido']
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          Row(
                            children: [
                              if (tarefa['concluido'])
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    await _firestore
                                        .collection('tarefas_escolares')
                                        .doc(tarefa['id'])
                                        .delete();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Tarefa excluída com sucesso!'),
                                        backgroundColor: Minhascores.Rosapastel,
                                      ),
                                    );
                                  },
                                ),
                              Checkbox(
                                value: tarefa['concluido'],
                                onChanged: (bool? valor) {
                                  _firestore
                                      .collection('tarefas_escolares')
                                      .doc(tarefa['id'])
                                      .update({'concluido': valor});
                                },
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
