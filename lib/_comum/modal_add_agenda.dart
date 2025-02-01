import 'package:agendaapp/_comum/minhascores.dart';
import 'package:agendaapp/componentes/decoracao_login.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

void mostramodalcriaragenda(BuildContext context) {
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
      return const Criaragenda();
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
  TimeOfDay? _selectedTime;
  String? _selectedDay;
  bool isCarregando = false;

  final List<String> _diasSemana = [
    'Domingo', 'Segunda-feira', 'Terça-feira', 'Quarta-feira', 
    'Quinta-feira', 'Sexta-feira', 'Sábado'
  ];

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
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Minhascores.brancosuave),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _novaTarefa,
                  decoration: getAuthenticationinputDecoration(
                    "Nova tarefa",
                    icons: const Icon(Icons.assignment_add),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Por favor, insira uma tarefa'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: getAuthenticationinputDecoration(
                    "Dia da semana",
                    icons: const Icon(Icons.calendar_today),
                  ),
                  value: _selectedDay,
                  items: _diasSemana.map((String dia) {
                    return DropdownMenuItem<String>(
                      value: dia,
                      child: Text(dia),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedDay = newValue;
                    });
                  },
                  validator: (value) => value == null
                      ? 'Por favor, selecione um dia da semana'
                      : null,
                ),
                const SizedBox(height: 16),
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
            ElevatedButton(
              onPressed: isCarregando ? null : _salvarEvento,
              child: isCarregando
                  ? const CircularProgressIndicator(color: Minhascores.rozabaixo)
                  : const Text("Salvar"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _salvarEvento() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isCarregando = true;
    });

    String userId = FirebaseAuth.instance.currentUser!.uid;

    try {
      await FirebaseFirestore.instance.collection('eventos').add({
        'userId': userId,
        'titulo': _novaTarefa.text,
        'diaSemana': _selectedDay,
        'dataHora': _selectedDate?.toIso8601String(),
        'terminado': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarefa adicionada com sucesso!'), backgroundColor: Minhascores.Rosapastel),
      );

      _novaTarefa.clear();
      _selectedDate = null;
      _selectedTime = null;
      _selectedDay = null;
    } catch (e) {
      print('Erro ao salvar evento: $e');
    } finally {
      setState(() {
        isCarregando = false;
      });
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}
