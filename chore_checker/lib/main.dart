import 'package:flutter/material.dart';

void main() => runApp(ChoreMeApp());

class ChoreMeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ChoreMe',
    theme: ThemeData(primarySwatch: Colors.purple),
    home: ChoreListScreen(),
  );
}

class Chore {
  String task;
  bool complete;
  Chore(this.task, this.complete);
}

class ChoreListScreen extends StatefulWidget {
  @override
  _ChoreListScreenState createState() => _ChoreListScreenState();
}

class _ChoreListScreenState extends State<ChoreListScreen> {
  final List<Chore> _chores = [];
  final TextEditingController _controller = TextEditingController();
  int _points = 0;

  void _addChore() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _chores.add(Chore(_controller.text, false));
        _controller.clear();
      });
    }
  }

  void _toggleComplete(int index) {
    setState(() {
      if (!_chores[index].complete) {
        _chores[index].complete = true;
        _points += 10;  // Reward points
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('ChoreMe'), backgroundColor: Colors.purple),
    body: Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: TextField(controller: _controller, decoration: InputDecoration(hintText: 'Add chore'))),
              IconButton(icon: Icon(Icons.add), onPressed: _addChore),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _chores.length,
            itemBuilder: (context, i) => ListTile(
              title: Text(_chores[i].task, style: TextStyle(decoration: _chores[i].complete ? TextDecoration.lineThrough : null)),
              leading: Checkbox(value: _chores[i].complete, onChanged: (_) => _toggleComplete(i)),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(16),
          child: Text('Points: $_points', style: Theme.of(context).textTheme.headlineMedium),
        ),
      ],
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
