import 'package:agendaapp/_comum/meu_snackbar.dart';
import 'package:agendaapp/componentes/decoracao_login.dart';
import 'package:agendaapp/serivco/altenticacao_serivco.dart';

import 'package:flutter/material.dart';
import '../_comum/minhascores.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  bool queroentrar = true;
  final _formkey = GlobalKey<FormState>();

  final TextEditingController _emailcontroller = TextEditingController();
  final TextEditingController _senhacontroller = TextEditingController();
  final TextEditingController _nomecontroller = TextEditingController();

  final AutenticacaoServico _outenservico = AutenticacaoServico();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFC1CC), // Rosa intermediário
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: _formkey,
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      const SizedBox(height: 5), // Adicionado espaçamento no topo
                      const Text(
                        "Agenda\ndigital",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Minhascores.brancosuave, // Roxo claro
                          fontFamily: 'Raleway', // Nova fonte
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _emailcontroller,
                        decoration: getAuthenticationinputDecoration("E-mail"),
                        validator: (String? value) {
                          if (value == null) {
                            return "O e-mail não pode ser vazio";
                          }
                          if (value.length < 5) {
                            return "O email é muito curto";
                          }
                          if (!value.contains("@")) {
                            return "O e-mail não é válido";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _senhacontroller,
                        decoration: getAuthenticationinputDecoration("Senha"),
                        obscureText: true,
                        validator: (String? value) {
                          if (value == null) {
                            return "Informe uma senha...";
                          }
                          if (value.length < 5) {
                            return "Senha muito curta...";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Visibility(
                        visible: !queroentrar,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nomecontroller,
                              decoration:
                                  getAuthenticationinputDecoration("Nome"),
                              validator: (String? value) {
                                if (value == null) {
                                  return "Informe um nome...";
                                }
                                if (value.length < 5) {
                                  return "O nome é muito curto";
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: () {
                          botaopricipalclicado();
                        },
                        child: Text((queroentrar) ? "Entrar" : "Cadastrar"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Minhascores.brancosuave,
                          foregroundColor: const Color.fromARGB(255, 0, 0, 0), // Texto branco no botão
                          textStyle: const TextStyle(fontSize: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            queroentrar = !queroentrar;
                          });
                        },
                        child: Text(
                          (queroentrar)
                              ? "Ainda não tem uma conta? Cadastre-se!"
                              : "Já tenho uma conta",
                          style: const TextStyle(
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  botaopricipalclicado() {
    String nome = _nomecontroller.text;
    String email = _emailcontroller.text;
    String senha = _senhacontroller.text;
    if (_formkey.currentState!.validate()) {
      if (queroentrar) {
        print('entradavalidada');
        _outenservico.logarusuarios(email: email, senha: senha).then(
          (String? erro) {
            if (erro != null) {
              mostrarsnackbar(context: context, texto: erro);
            }
          },
        );
      } else {
        print('cadastro validado');
        print(_emailcontroller.text);
        print(_senhacontroller.text);
        print(_nomecontroller.text);
        _outenservico
            .cadastrarUsuario(nome: nome, senha: senha, email: email)
            .then(
          (String? erro) {
            //voltou com erro
            if (erro != null) {
              mostrarsnackbar(context: context, texto: erro);
            }
          },
        );
      }
    } else {
      print("Erro na validação!");
    }
  }
}
