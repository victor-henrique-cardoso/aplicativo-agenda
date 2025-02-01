import 'package:agendaapp/Telas/TelaEscola.dart';
import 'package:agendaapp/Telas/teladeagenda.dart';
import 'package:agendaapp/_comum/minhascores.dart';
import 'package:agendaapp/serivco/altenticacao_serivco.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import necessário para o User
import 'package:flutter/material.dart';
import 'Diario.dart';
class TelaDeEscolha extends StatelessWidget {
  final User user; // Parâmetro do usuário autenticado

  const TelaDeEscolha({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Minhascores.begeclaro, // Cor de fundo da tela.
     
      appBar: AppBar(
        title: const Text('Tipo de Agendamento'),
        centerTitle: true,
        backgroundColor: Minhascores.Rosapastel,
      ),
      drawer: Drawer(
        backgroundColor: Minhascores.brancosuave, // Cor de fundo do menu lateral
        child: ListView(
          children: [
            // Cabeçalho do menu lateral com informações do usuário
            UserAccountsDrawerHeader(
              currentAccountPicture: const CircleAvatar(
                backgroundImage: AssetImage("assets/imagem/logoagenda.png"),
              ),
              accountName: Text(user.displayName ?? ""), // Usando 'user' diretamente
              accountEmail: Text(user.email ?? ""), // Usando 'user' diretamente
            ),
            // Opção de logout no menu lateral
            ListTile(
              leading: const Icon(Icons.logout_sharp),
              onTap: () {
                // Serviço de logout (implementar conforme seu código)
                AutenticacaoServico().deslogar();
              },
              title: const Text("Deslogar"),
              dense: true,
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Navegar para a tela de agendamento do Dia a Dia
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AgendaHomePage(user: user),
                  ),
                );
              },
              child: const Text('Dia a Dia'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navegar para a tela de agendamento da Escola
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TelaAgendaEscolar(user: user),
                  ),
                );
              },
              child: const Text('Escola'),
            ),
              const SizedBox(height: 20),
                  ElevatedButton(
              onPressed: () {
                // Navegar para a tela de agendamento da Escola
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Diario(),
                  ),
                );
              },
              child: const Text('Diario'),
            ),
          ],
        ),
      ),
    );
  }
}
