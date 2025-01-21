import 'package:agendaapp/Telas/Tela_de_escolha.dart';
import 'package:agendaapp/Telas/Tela_login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:agendaapp/Telas/teladeagenda.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  
  // Inicializa o Firebase com as configurações do arquivo firebase_options.dart.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicia o aplicativo com o widget raiz "Agenda".
  runApp(const Agenda());
}

// Classe principal do aplicativo, que define o widget raiz.
class Agenda extends StatefulWidget {
  const Agenda({super.key}); // Construtor com chave super.

  @override
  State<Agenda> createState() => _AgendaState(); // Associa o estado ao widget.
}

// Estado associado ao widget "Agenda".
class _AgendaState extends State<Agenda> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false, // Remove a bandeira de "debug" na interface.
      home: Roteadortela(), // Define "Roteadortela" como a tela inicial do app.
    );
  }
}

// Classe responsável por determinar qual tela será exibida com base no estado do usuário.
class Roteadortela extends StatelessWidget {
  const Roteadortela({super.key}); // Construtor com chave super.

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>( // Escuta mudanças no estado de autenticação do Firebase.
      stream: FirebaseAuth.instance.userChanges(), // Fluxo que notifica alterações no usuário autenticado.
      builder: (context, snapshot) {
        if (snapshot.hasData) { // Verifica se há um usuário autenticado.
          return TelaDeEscolha( // Exibe a tela principal da agenda se o usuário estiver autenticado.
            user: snapshot.data!, // Passa os dados do usuário para a tela.
          );
        } else { // Caso contrário, exibe a tela de login.
          return const TelaLogin();
        }
      },
    );
  }
}
