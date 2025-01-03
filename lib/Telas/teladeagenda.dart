import 'package:agendaapp/_comum/minhascores.dart';
import 'package:agendaapp/_comum/modal_add_agenda.dart';
import 'package:agendaapp/serivco/altenticacao_serivco.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Agenda'),
        centerTitle: true,
        backgroundColor: Minhascores.Rosapastel,
      ),
      drawer: Drawer(
        backgroundColor: Minhascores.brancosuave,
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              currentAccountPicture: const CircleAvatar(
                backgroundImage: AssetImage("assets/imagem/logoagenda.png"),
              ),
              accountName: Text((widget.user.displayName != null)
                  ? widget.user.displayName!
                  : ""),
              accountEmail: Text(widget.user.email!),
            ),
            ListTile(
              leading: const Icon(Icons.logout_sharp),
              onTap: () {
                AutenticacaoServico().deslogar();
              },
              title: const Text("Deslogar"),
              dense: true,
            ),
          ],
        ),
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

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data()! as Map<String, dynamic>;

              // Verifica se o evento pertence ao usuário atual
              if (data['userId'] == widget.user.uid) {
                // Extrai a data e a hora do campo 'dataHora'
                String dataHoraFormatada = "Sem data";
                if (data['dataHora'] != null) {
                  DateTime dateTime;
                  if (data['dataHora'] is Timestamp) {
                    dateTime = (data['dataHora'] as Timestamp).toDate();
                  } else {
                    dateTime = DateTime.parse(data['dataHora']);
                  }
                  dataHoraFormatada =
                      DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
                }

                return Dismissible(
                  key: Key(document.id),
                  onDismissed: (direction) async {
                    await document.reference.delete();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tarefa excluída com sucesso!'),
                      ),
                    );
                  },
                  confirmDismiss: (DismissDirection direction) async {
                    return await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Confirmar exclusão'),
                          content: const Text(
                              'Deseja realmente excluir esta tarefa?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Excluir'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20.0),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    title: Text(data['titulo'] ?? "Sem título"),
                    subtitle: Text(dataHoraFormatada),
                    trailing: Checkbox(
                      value: data['concluido'] ?? false,
                      onChanged: (value) async {
                        await document.reference.update({'concluido': value});
                      },
                    ),
                  ),
                );
              } else {
                return const SizedBox();
              }
            }).toList(),
          );
        },
      ),
    );
  }
}
