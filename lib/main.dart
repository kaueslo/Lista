import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    title: "agenda",
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    //Sempre que inicializamos a tela, chama por esse cara
    super.initState();

    _lerData().then((data) {
      //Solicita os dados pela função lerData e após solicitar, retorna os dados do then, no caso no then é uma função anônima,
      setState(() {
        _coisasFazer = json.decode(data);
      });
    });
  }

  final _coisasController = TextEditingController();

  List _coisasFazer = [];
  Map<String, dynamic>
      _ultimoRemovido; //Aq vamos conseguir fazer voltar o ultimo que removemos
  int _ultimoRemovidoPos; //Aq fazemos ele voltar quando é removido, por exemplo, foi removido na posição 2,ele volta nela

  void _addCoisas() {
    //Função que vai adicionar coisas na nossa lista
    setState(() {
      Map<String, dynamic> novaCoisa = Map();
      novaCoisa["title"] = _coisasController.text;
      _coisasController.text = "";
      novaCoisa["ok"] = false;
      _coisasFazer.add(
          novaCoisa); //Aq estamos adicionando um novo item na lista, que devemos fazer
      saveData(); //Para salvar os itens permanentemente no seu app
    });
  }

  Future<Null> _refresh() async{//Função refresh, pra aparecer os itens não feitos em primeiro, quando arrastamos pra baixo
    await Future.delayed(Duration(seconds: 1));//Demora um segundo pra fazer o refresh, com esse código
    setState(() {
      _coisasFazer.sort((a, b){//Função que vai ficar comparando os itens, para ver qual deles que podemos fazer
        if(a["ok"] && !b["ok"]) return 1;
        else if(!a["ok"] && b["ok"]) return -1;
        else return 0;
      });

      saveData();
    });

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de tarefas"),
        backgroundColor: Colors.black12,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 7, 1),
            child: Row(
              children: <Widget>[
                Expanded(
                  //Para definir o tamanho, sem o Expanded, ele fica levando até o infinito
                  child: TextField(
                    controller: _coisasController,
                    decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(color: Colors.black)),
                  ),
                ),
                RaisedButton(
                  color: Colors.black12,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: _addCoisas,
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(//Para Deixar os itens não marcados acima e os itens marcados abaixo
              onRefresh: _refresh,

              child: ListView.builder(
                  //Aq que vamos criar a lista, para salvar os dados
                  padding: EdgeInsets.only(top: 10),
                  //Inserir uma margem apenas no topo, com esse código no padding
                  itemCount: _coisasFazer.length,
                  //Aq tá contando a quantidade de itens na lista
                  itemBuilder: builItem),
            ),
          )
        ],
      ),
    );
  }

  Widget builItem(context, index) {
    //Vai ter que criar uma função
    return Dismissible(
      //Widget que excluí o item arrastando ele pra direita
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      //Key que é obrigatório ter no Dismissible
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0), //Alinhando o ícona da lixeira
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      //Direção que vai iniciar o item de exclusão
      child: CheckboxListTile(
        //Por padrão, o Flutteer tem esse listtile, que retorna o que tem na lista, se quiser colocar o box, tem que ser Checkbox
        title: Text(_coisasFazer[index]["title"]),
        value: _coisasFazer[index]["ok"],
        //Aq que vai marcar se a caixa foi ticada ou não
        secondary: CircleAvatar(
          child: Icon(
            _coisasFazer[index]["ok"] ? Icons.check : Icons.error,
          ),
        ),
        onChanged: (c) {
          //Vai chamar uma função, quando o status de true ou false muda, ou seja, quando é ticado ou não
          setState(() {
            //Para atualizar a página
            _coisasFazer[index]["ok"] =
                c; //Se eu marcar o quadradinho, vai armazenas através dessa formula
            saveData(); //Salvar os itens no app permanentemente
          });
        },
      ),
      onDismissed: (diretion) {
        //Função que sempre vai ser chamada quando remover algum item
        setState(() {
          _ultimoRemovido = Map.from(_coisasFazer[
              index]); //Oq vai remover, no caso o index informado lá em cima, e essa linha serve pra duplicar o item antes de remover, caso queira restaurar
          _ultimoRemovidoPos =
              index; //Aq estou declarando para duplicar, antes de remover o item
          _coisasFazer
              .removeAt(index); //Aq tá removendo da posição definitivamente

          saveData();

          final snack = SnackBar(
            //Oq vai aparecer para desfazer a remoção, caso desejado
            content: Text("Tarefa ${_ultimoRemovido["title"]} removida!"),
            //Informando qual foi a tarefa removida
            action: SnackBarAction(
                label: "Desfazer", //Aq é pra desfazer, caso desejado
                onPressed: () {
                  setState(() {
                    _coisasFazer.insert(_ultimoRemovidoPos,
                        _ultimoRemovido); //Aq para incluir novamente, caso deseje
                    saveData(); //Aq para salvar, caso seje desejado não remover
                  });
                }),
            duration: Duration(seconds: 5), //Duração do SnackBar
          );

          Scaffold.of(context).removeCurrentSnackBar();//Para não sobrescrever a SnackBar
          Scaffold.of(context).showSnackBar(snack); //Para mostrar o SnackBar
        });
      },
    );
  }

  Future<File> _getFile() async {
    //Onde vamos armazenar os dados
    final directory =
        await getApplicationDocumentsDirectory(); //Declarando um diretório para armazenar os documentos do app
    return File(
        "${directory.path}/data.json"); //Retornando o arquivo que vai tá com as informações salvas
  }

  Future<File> saveData() async {
    //Onde vamos salvar os dados
    String data = json.encode(_coisasFazer);
    final file = await _getFile();
    return file.writeAsString(data); //Convertendo os dados para String
  }

  Future<String> _lerData() async {
    //Retornando os dados como String
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
