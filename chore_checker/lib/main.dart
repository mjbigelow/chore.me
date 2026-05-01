import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(ChoreMeApp());
}

class ChoreMeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ChoreMe',
    theme: ThemeData(primarySwatch: Colors.purple),
    home: ChoreListScreen(),
  );
}

class ChoreListScreen extends StatefulWidget {
  @override
  _ChoreListScreenState createState() => _ChoreListScreenState();
}

class _ChoreListScreenState extends State<ChoreListScreen> {
  List<Map<String, dynamic>> _chores = [];
  final TextEditingController _controller = TextEditingController();
  int _points = 0;
  late Box _box;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _openBox();
  }

  Future<void> _openBox() async {
    _box = await Hive.openBox('chores');
    await _loadChores();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadChores() async {
    final savedChores = _box.get('chores', defaultValue: <Map<String, dynamic>>[]);
    _chores = List<Map<String, dynamic>>.from(savedChores);
    _points = 0;
    for (var chore in _chores) {
      if (chore['complete'] == true) _points += 10;
    }
  }

  Future<void> _addChore() async {
    if (_controller.text.isNotEmpty) {
      final newChore = {'task': _controller.text, 'complete': false};
      setState(() {
        _chores.add(newChore);
        _controller.clear();
      });
      await _box.put('chores', _chores);
    }
  }

  Future<void> _toggleComplete(int index) async {
    if (!_chores[index]['complete']) {
      setState(() {
        _chores[index]['complete'] = true;
        _points += 10;
      });
      await _box.put('chores', _chores);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('ChoreMe'), backgroundColor: Colors.purple),
    body: _loading
        ? Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(hintText: 'Add chore'),
                      onSubmitted: (_) => _addChore(),
                    )),
                    IconButton(icon: Icon(Icons.add), onPressed: _addChore),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _chores.length,
                  itemBuilder: (context, i) => ListTile(
                    title: Text(_chores[i]['task'], style: TextStyle(
                      decoration: _chores[i]['complete'] ? TextDecoration.lineThrough : null,
                    )),
                    leading: Checkbox(
                      value: _chores[i]['complete'],
                      onChanged: (_) => _toggleComplete(i),
                    ),
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
