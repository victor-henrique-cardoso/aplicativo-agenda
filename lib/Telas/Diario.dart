import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:agendaapp/_comum/minhascores.dart';

class Diario extends StatefulWidget {
  const Diario({super.key});

  @override
  State<Diario> createState() => _DiarioState();
}

class _DiarioState extends State<Diario> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _abrirModal(BuildContext context) {
    final TextEditingController tituloController = TextEditingController();
    final TextEditingController descricaoController = TextEditingController();
    DateTime? dataSelecionada;
    TimeOfDay? horaSelecionada;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que o modal tenha um tamanho personalizado
      backgroundColor: Colors.transparent, // Fundo transparente
      isDismissible: true, // Pode ser fechado tocando fora
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(34),
        ),
      ),

      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Container(
              padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ), 
            decoration: const BoxDecoration(
              color: Minhascores.Rosapastel,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Adicionar",
                  style: TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20.0),
                // Título da tarefa
                Row(
                  children: [
                    const Icon(Icons.note_add, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: tituloController,
                        decoration: InputDecoration(
                          hintText: "Título da tarefa",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                // Descrição da tarefa
                Row(
                  children: [
                    const Icon(Icons.description, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: descricaoController,
                        decoration: InputDecoration(
                          hintText: "Descrição (opcional)",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                // Seletor de data
                OutlinedButton(
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        dataSelecionada = picked;
                      });
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    side: const BorderSide(color: Colors.white),
                    backgroundColor: Colors.white,
                  ),
                  child: Text(
                    dataSelecionada == null
                        ? "Selecione uma data"
                        : DateFormat('dd/MM/yyyy').format(dataSelecionada!),
                    style: const TextStyle(color: Minhascores.Rosapastel),
                  ),
                ),
                const SizedBox(height: 10.0),
                // Seletor de hora
                OutlinedButton(
                  onPressed: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        horaSelecionada = picked;
                      });
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    side: const BorderSide(color: Colors.white),
                    backgroundColor: Colors.white,
                  ),
                  child: Text(
                    horaSelecionada == null
                        ? "Selecione uma hora"
                        : "${horaSelecionada!.hour}:${horaSelecionada!.minute.toString().padLeft(2, '0')}",
                    style: const TextStyle(color: Minhascores.Rosapastel),
                  ),
                ),
                const SizedBox(height: 20.0),
                // Botão salvar
                ElevatedButton(
                  onPressed: () async {
                    if (tituloController.text.isNotEmpty) {
                      // Salvando no Firebase
                      try {
                        final userId = FirebaseAuth.instance.currentUser?.uid;

                        if (userId == null) {
                          throw Exception("Usuário não autenticado.");
                        }

                        final Map<String, dynamic> tarefa = {
                          "userId": userId,
                          "titulo": tituloController.text,
                          "descricao": descricaoController.text,
                          "data": dataSelecionada?.toIso8601String(),
                          "hora": horaSelecionada != null
                              ? "${horaSelecionada!.hour}:${horaSelecionada!.minute}"
                              : null,
                          "criadoEm": DateTime.now().toIso8601String(),
                        };

                        await _firestore.collection("diario").add(tarefa);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Tarefa adicionada com sucesso!"),
                            backgroundColor: Minhascores.Rosapastel,
                          ),
                        );

                        Navigator.pop(context);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Erro ao salvar tarefa: $e"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("O título da tarefa é obrigatório."),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                  ),
                  child: const Text(
                    "Salvar",
                    style: TextStyle(
                      color: Minhascores.Rosapastel,
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ],
            ),
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
        backgroundColor: Minhascores.Rosapastel,
        title: const Text("Diário"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: "Adicionar entrada",
            onPressed: () => _abrirModal(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection("diario")
              .where("userId", isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text('Erro ao carregar entradas.'));
            }

            final diarioItens = snapshot.data?.docs
                    .map((doc) => doc.data() as Map<String, dynamic>?)
                    .toList() ?? 
                [];

            if (diarioItens.isEmpty) {
              return const Center(
                child: Text(
                  "Nenhuma entrada no diário.",
                  style: TextStyle(fontSize: 16.0, color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              itemCount: diarioItens.length,
              itemBuilder: (context, index) {
                final item = diarioItens[index] ?? {};
                return Card(
                  elevation: 10,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item["titulo"] ?? "",
                              style: const TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                // Deletando o item ao clicar na lixeira
                                await _firestore
                                    .collection("diario")
                                    .doc(snapshot.data!.docs[index].id)
                                    .delete();
                              },
                            ),
                          ],
                        ),
                        if (item["data"] != null || item["hora"] != null)
                          const SizedBox(height: 8.0),
                        if (item["data"] != null)
                          Text("Data: ${item["data"]}"),
                        if (item["hora"] != null)
                          Text("Hora: ${item["hora"]}"),
                        const SizedBox(height: 8.0),
                        if (item["descricao"] != null)
                          Text("Descrição: ${item["descricao"]}"),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
