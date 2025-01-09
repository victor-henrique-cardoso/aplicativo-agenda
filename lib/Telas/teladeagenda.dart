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

  AgendaHomePage({super.key, required this.user}); // Construtor que exige o usuário.

  @override
  _AgendaHomePageState createState() => _AgendaHomePageState(); // Cria o estado do widget.
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
        backgroundColor: Minhascores.Rosapastel, // Define a cor de fundo da AppBar.
      ),
      drawer: Drawer(
        backgroundColor: Minhascores.brancosuave, // Cor de fundo do menu lateral.
        child: ListView(
          children: [
            // Cabeçalho do menu lateral com informações do usuário.
            UserAccountsDrawerHeader(
              currentAccountPicture: const CircleAvatar(
                backgroundImage: AssetImage("assets/imagem/logoagenda.png"),
              ),
              accountName: Text((widget.user.displayName != null)
                  ? widget.user.displayName! // Exibe o nome do usuário, se disponível.
                  : ""),
              accountEmail: Text(widget.user.email!), // Exibe o e-mail do usuário.
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

          // Lista de eventos com base nos dados recebidos do Firestore.
          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data()! as Map<String, dynamic>; // Converte o documento para Map.

              // Exibe apenas os eventos do usuário atual.
              if (data['userId'] == widget.user.uid) {
                // Formata a data e a hora do evento, se disponíveis.
                String dataHoraFormatada = "Sem data";
                if (data['dataHora'] != null) {
                  DateTime dateTime;
                  if (data['dataHora'] is Timestamp) {
                    dateTime = (data['dataHora'] as Timestamp).toDate();
                  } else {
                    dateTime = DateTime.parse(data['dataHora']);
                  }
                  dataHoraFormatada =
                      DateFormat('dd/MM/yyyy HH:mm').format(dateTime); // Formata a data.
                }

                // Permite excluir tarefas deslizando para a direita.
                return Dismissible(
                  key: Key(document.id), // Identificador único do item.
                  onDismissed: (direction) async {
                    await document.reference.delete(); // Remove o evento do Firestore.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tarefa excluída com sucesso!'),
                      ),
                    );
                  },
                  // Confirmação antes de excluir a tarefa.
                  confirmDismiss: (DismissDirection direction) async {
                    return await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Confirmar exclusão'),
                          content: const Text(
                              'Deseja realmente excluir esta tarefa?'),
                          actions: <Widget>[
                            // Botão para cancelar a exclusão.
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            // Botão para confirmar a exclusão.
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Excluir'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  // Fundo vermelho com ícone de lixeira ao deslizar.
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20.0),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  // Exibição do evento na lista.
                  child: ListTile(
                    title: Text(data['titulo'] ?? "Sem título"), // Título do evento.
                    subtitle: Text(dataHoraFormatada), // Data e hora do evento.
                    trailing: Checkbox(
                      value: data['concluido'] ?? false, // Status de conclusão.
                      onChanged: (value) async {
                        // Atualiza o status de conclusão no Firestore.
                        await document.reference.update({'concluido': value});
                      },
                    ),
                  ),
                );
              } else {
                // Retorna um widget vazio se o evento não pertence ao usuário.
                return const SizedBox();
              }
            }).toList(),
          );
        },
      ),
    );
  }
}
