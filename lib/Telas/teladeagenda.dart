import 'package:agendaapp/_comum/minhascores.dart';
import 'package:agendaapp/_comum/modal_add_agenda.dart';
import 'package:agendaapp/serivco/altenticacao_serivco.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Widget principal da página inicial da agenda, que recebe o usuário autenticado.
class AgendaHomePage extends StatefulWidget {
  final User user; // Representa o usuário atualmente autenticado.

  AgendaHomePage(
      {super.key, required this.user}); // Construtor que exige o usuário.

  @override
  _AgendaHomePageState createState() =>
      _AgendaHomePageState(); // Cria o estado do widget.
}

class _AgendaHomePageState extends State<AgendaHomePage> {
  // Stream para monitorar mudanças na coleção 'eventos' do Firestore.
  final Stream<QuerySnapshot> _eventosStream =
      FirebaseFirestore.instance.collection('eventos').snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Agenda'), // Título da barra superior.
        centerTitle: true, // Centraliza o título.
        backgroundColor:
            Minhascores.Rosapastel, // Define a cor de fundo da AppBar.
      ),
      drawer: Drawer(
        backgroundColor:
            Minhascores.brancosuave, // Cor de fundo do menu lateral.
        child: ListView(
          children: [
            // Cabeçalho do menu lateral com informações do usuário.
            UserAccountsDrawerHeader(
              currentAccountPicture: const CircleAvatar(
                backgroundImage: AssetImage("assets/imagem/logoagenda.png"),
              ),
              accountName: Text((widget.user.displayName != null)
                  ? widget.user
                      .displayName! // Exibe o nome do usuário, se disponível.
                  : ""),
              accountEmail:
                  Text(widget.user.email!), // Exibe o e-mail do usuário.
            ),
            // Opção de logout no menu lateral.
            ListTile(
              leading: const Icon(Icons.logout_sharp),
              onTap: () {
                AutenticacaoServico().deslogar(); // Chama o serviço de logout.
              },
              title: const Text("Deslogar"), // Texto da opção.
              dense: true,
            ),
          ],
        ),
      ),
      // Botão flutuante para adicionar novas tarefas.
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add_box_outlined), // Ícone do botão.
        onPressed: () {
          mostramodalcriaragenda(context); // Abre o modal para criar tarefas.
        },
      ),
      backgroundColor: Minhascores.begeclaro, // Cor de fundo da tela.
      body: StreamBuilder<QuerySnapshot>(
        stream: _eventosStream, // Monitora mudanças na coleção 'eventos'.
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            // Exibe mensagem de erro se houver problema na stream.
            return const Center(child: Text('Algo deu errado'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            // Exibe indicador de carregamento enquanto aguarda os dados.
            return const Center(child: CircularProgressIndicator());
          }

          // Filtra e ordena os eventos com base na proximidade da data.
          List<Map<String, dynamic>> eventosOrdenados = snapshot.data!.docs
              .map((DocumentSnapshot document) {
                Map<String, dynamic> data = document.data()!
                    as Map<String, dynamic>; // Converte o documento para Map.

                // Adiciona apenas eventos do usuário atual.
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
              .where((evento) => evento != null) // Remove os nulos.
              .cast<Map<String, dynamic>>()
              .toList();

          // Ordena pela data e hora mais próximas.
          eventosOrdenados.sort((a, b) {
            final dataHoraA = a['dataHora'];
            final dataHoraB = b['dataHora'];

            if (dataHoraA == null && dataHoraB == null) return 0;
            if (dataHoraA == null)
              return 1; // Eventos sem data vão para o final.
            if (dataHoraB == null) return -1;
            return dataHoraA.compareTo(dataHoraB); // Ordem crescente.
          });

          // Constrói a lista de tarefas ordenadas.
          return ListView.builder(
            itemCount: eventosOrdenados.length,
            itemBuilder: (context, index) {
              final evento = eventosOrdenados[index];

              String dataHoraFormatada = "Sem data";
              if (evento['dataHora'] != null) {
                dataHoraFormatada =
                    DateFormat('dd/MM/yyyy HH:mm').format(evento['dataHora']);
              }

              return Dismissible(
                key: Key(evento['id']),
                onDismissed: (direction) async {
                  await FirebaseFirestore.instance
                      .collection('eventos')
                      .doc(evento['id'])
                      .delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Tarefa excluída com sucesso!'),backgroundColor: Minhascores.Rosapastel),
                  );
                },
                confirmDismiss: (DismissDirection direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Confirmar exclusão'),
                        content:
                            const Text('Deseja realmente excluir esta tarefa?'),
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
                  title: Text(evento['titulo']),
                  subtitle: Text(dataHoraFormatada),
                  trailing: Checkbox(
                    value: evento['concluido'],
                    onChanged: (value) async {
                      await FirebaseFirestore.instance
                          .collection('eventos')
                          .doc(evento['id'])
                          .update({'concluido': value});
                    },
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
