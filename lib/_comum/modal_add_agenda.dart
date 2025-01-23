import 'package:agendaapp/_comum/minhascores.dart';
import 'package:agendaapp/componentes/decoracao_login.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart'; // Importando o permission_handler

// Função que exibe um modal para criar uma nova tarefa no aplicativo.
mostramodalcriaragenda(BuildContext context) {
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

// Função para inicializar notificações.
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _initNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> criarCanalNotificacao() async {
  const AndroidNotificationChannel canal = AndroidNotificationChannel(
    'agenda_channel',
    'Agenda Notificações',
    description: 'Notificações para tarefas agendadas',
    importance: Importance.high,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(canal);
}

// Função para criar o canal de notificações.

// Função para solicitar permissão de notificações utilizando permission_handler.
Future<void> solicitarPermissaoNotificacao() async {
  final status = await Permission.notification.request();

  if (status.isGranted) {
    print("Permissão de notificação concedida!");
  } else if (status.isDenied) {
    print("Permissão de notificação negada!");
  } else if (status.isPermanentlyDenied) {
    // Caso o usuário tenha negado permanentemente, abre as configurações do aplicativo
    print("Permissão de notificação permanentemente negada!");
    openAppSettings(); // Isso abrirá a tela de configurações para o usuário conceder a permissão manualmente
  }
}

// Widget Stateful para criar a agenda.
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
  bool isCarregando = false;

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
                const SizedBox(height: 16),
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
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isCarregando = true;
    });

    String userId = FirebaseAuth.instance.currentUser!.uid;

    try {
      // Caso o usuário não tenha escolhido data e hora
      if (_selectedDate == null || _selectedTime == null) {
        // Salvar a tarefa sem data e hora
        await FirebaseFirestore.instance.collection('eventos').add({
          'userId': userId,
          'titulo': _novaTarefa.text,
          'terminado': false,
        });
      } else {
        // Caso o usuário tenha escolhido data e hora
        final eventoDataHora = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );

        await FirebaseFirestore.instance.collection('eventos').add({
          'userId': userId,
          'titulo': _novaTarefa.text,
          'dataHora': eventoDataHora.toIso8601String(),
          'terminado': false,
        });

        // Definir a hora da notificação (um lembrete antes da tarefa)
        final tz.TZDateTime scheduleTime = tz.TZDateTime.from(
          eventoDataHora.subtract(const Duration(hours: 1)),
          tz.local,
        );

        if (scheduleTime.isBefore(tz.TZDateTime.now(tz.local))) {
          print('Erro: O horário agendado já passou.');
          return;
        }

        // Agendar a notificação
        await flutterLocalNotificationsPlugin.zonedSchedule(
          0,
          'Lembrete de Tarefa',
          'Você tem uma tarefa agendada para ${DateFormat('HH:mm').format(eventoDataHora)}',
          scheduleTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'canal_agenda',
              'Agenda Notificações',
              channelDescription: 'Notificações para tarefas agendadas',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.wallClockTime,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarefa adicionada com sucesso!' ),
         backgroundColor: Minhascores.Rosapastel),
      );

      _novaTarefa.clear();
      _selectedDate = null;
      _selectedTime = null;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarefa adicionada com sucesso!' ),
         backgroundColor: Minhascores.Rosapastel),
      );
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