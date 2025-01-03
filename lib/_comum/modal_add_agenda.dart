import 'package:agendaapp/_comum/minhascores.dart';
import 'package:agendaapp/componentes/decoracao_login.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

mostramodalcriaragenda(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Minhascores.Rosapastel,
    isDismissible: false,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
      top: Radius.circular(34),
    )),
    builder: (BuildContext context) {
      return Criaragenda();
    },
  );
}

class Criaragenda extends StatefulWidget {
  const Criaragenda({super.key});

  @override
  State<Criaragenda> createState() => _CriaragendaState();
}

class _CriaragendaState extends State<Criaragenda> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _novaTarefa = TextEditingController();
  DateTime? _selectedDate;
  bool isCarregando = false;
  TimeOfDay? _selectedTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      height: MediaQuery.of(context).size.height * 0.9,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Adicionar uma nova\ntarefa",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Minhascores.brancosuave,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.close,
                        color: Minhascores.brancosuave,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 16,
                    ),
                    TextFormField(
                      controller: _novaTarefa,
                      decoration: getAuthenticationinputDecoration(
                        "Nova tarefa",
                        icons: const Icon(Icons.assignment_add),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira uma tarefa';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                      child: Text(
                        _selectedDate == null
                            ? 'Selecione uma data'
                            : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                      ),
                    ),

                    // Botão para selecionar a hora
                    ElevatedButton(
                      onPressed: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedTime = picked;
                          });
                        }
                      },
                      child: Text(
                        _selectedTime == null
                            ? 'Selecione uma hora'
                            : '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ElevatedButton(
              onPressed: isCarregando ? null : _salvarEvento,
              child: isCarregando
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        color: Minhascores.rozabaixo,
                      ),
                    )
                  : const Text("Salvar"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _salvarEvento() async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      setState(() {
        isCarregando = true;
      });

      
      String userId = FirebaseAuth.instance.currentUser!.uid;

      try {
        DateTime? eventoDataHora;

        if (_selectedDate != null && _selectedTime != null) {
          eventoDataHora = DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            _selectedTime!.hour,
            _selectedTime!.minute,
          );
        }


        await FirebaseFirestore.instance.collection('eventos').add({
          'userId': userId,
          'titulo': _novaTarefa.text,
          'dataHora': eventoDataHora?.toIso8601String(),
          'concluido': false,
        });

        _novaTarefa.clear();
        _selectedDate = null;
        _selectedTime = null;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarefa adicionada com sucesso!'),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao adicionar tarefa.'),
          ),
        );
        print('Erro ao salvar evento: $e');
      } finally {
        setState(() {
          isCarregando = false;
          Navigator.pop(context);
        });
      }
    }
  }
}
