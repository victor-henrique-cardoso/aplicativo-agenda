import 'package:agendaapp/_comum/minhascores.dart';
import 'package:agendaapp/componentes/decoracao_login.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Função que exibe um modal para criar uma nova tarefa no aplicativo.
mostramodalcriaragenda(BuildContext context) {
  showModalBottomSheet(
    context: context, // Contexto atual.
    backgroundColor: Minhascores.Rosapastel, // Define a cor de fundo do modal.
    isDismissible: false, // Impede que o modal seja fechado ao tocar fora dele.
    isScrollControlled: true, // Permite que o modal utilize mais espaço da tela.
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
      top: Radius.circular(34), // Bordas arredondadas no topo.
    )),
    builder: (BuildContext context) {
      return Criaragenda(); // Retorna o widget responsável pelo conteúdo do modal.
    },
  );
}

// Widget Stateful para criar a agenda.
class Criaragenda extends StatefulWidget {
  const Criaragenda({super.key}); // Construtor padrão.

  @override
  State<Criaragenda> createState() => _CriaragendaState(); // Associa o estado.
}

class _CriaragendaState extends State<Criaragenda> {
  final _formKey = GlobalKey<FormState>(); // Chave para gerenciar o formulário.
  final TextEditingController _novaTarefa = TextEditingController(); // Controlador para o campo de texto.
  DateTime? _selectedDate; // Armazena a data selecionada.
  bool isCarregando = false; // Indica se a tarefa está sendo salva.
  TimeOfDay? _selectedTime; // Armazena a hora selecionada.

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32), // Espaçamento interno.
      height: MediaQuery.of(context).size.height * 0.9, // Altura do modal.
      child: Form(
        key: _formKey, // Associa o formulário à sua chave.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho e entrada de dados.
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título e botão de fechar o modal.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Adicionar uma nova\ntarefa", // Título do modal.
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Minhascores.brancosuave,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context); // Fecha o modal.
                      },
                      icon: const Icon(
                        Icons.close, // Ícone de fechar.
                        color: Minhascores.brancosuave,
                      ),
                    ),
                  ],
                ),
                const Divider(), // Linha divisória.
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Campo de entrada para a nova tarefa.
                    TextFormField(
                      controller: _novaTarefa,
                      decoration: getAuthenticationinputDecoration(
                        "Nova tarefa",
                        icons: const Icon(Icons.assignment_add), // Ícone.
                      ),
                      validator: (value) {
                        // Valida se o campo está vazio.
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira uma tarefa';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Botão para selecionar a data.
                    ElevatedButton(
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(), // Data inicial.
                          firstDate: DateTime(2000), // Data mínima.
                          lastDate: DateTime(2100), // Data máxima.
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked; // Armazena a data selecionada.
                          });
                        }
                      },
                      child: Text(
                        _selectedDate == null
                            ? 'Selecione uma data' // Texto padrão.
                            : DateFormat('dd/MM/yyyy').format(_selectedDate!), // Formata a data selecionada.
                      ),
                    ),
                    // Botão para selecionar a hora.
                    ElevatedButton(
                      onPressed: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(), // Hora inicial.
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedTime = picked; // Armazena a hora selecionada.
                          });
                        }
                      },
                      child: Text(
                        _selectedTime == null
                            ? 'Selecione uma hora' // Texto padrão.
                            : '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}', // Formata a hora selecionada.
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Botão de salvar a tarefa.
            ElevatedButton(
              onPressed: isCarregando ? null : _salvarEvento, // Desabilita o botão se estiver carregando.
              child: isCarregando
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        color: Minhascores.rozabaixo, // Indicador de carregamento.
                      ),
                    )
                  : const Text("Salvar"), // Texto do botão.
            ),
          ],
        ),
      ),
    );
  }

  // Função para salvar o evento no Firestore.
  Future<void> _salvarEvento() async {
    // Valida o formulário e verifica se a data foi selecionada.
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      setState(() {
        isCarregando = true; // Define o estado como carregando.
      });

      String userId = FirebaseAuth.instance.currentUser!.uid; // ID do usuário autenticado.

      try {
        DateTime? eventoDataHora;

        // Combina data e hora selecionadas, se disponíveis.
        if (_selectedDate != null && _selectedTime != null) {
          eventoDataHora = DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            _selectedTime!.hour,
            _selectedTime!.minute,
          );
        }

        // Adiciona o evento ao Firestore.
        await FirebaseFirestore.instance.collection('eventos').add({
          'userId': userId,
          'titulo': _novaTarefa.text,
          'dataHora': eventoDataHora?.toIso8601String(), // Data e hora formatadas.
          'concluido': false, // Define o evento como não concluído.
        });

        // Limpa os campos e exibe uma mensagem de sucesso.
        _novaTarefa.clear();
        _selectedDate = null;
        _selectedTime = null;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarefa adicionada com sucesso!'),
          ),
        );
      } catch (e) {
        // Exibe uma mensagem de erro em caso de falha.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao adicionar tarefa.'),
          ),
        );
        print('Erro ao salvar evento: $e');
      } finally {
        setState(() {
          isCarregando = false; // Remove o estado de carregamento.
          Navigator.pop(context); // Fecha o modal.
        });
      }
    }
  }
}
