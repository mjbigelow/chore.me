import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  List<String> kids = [];
  String? selectedKid;
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    prefs = await SharedPreferences.getInstance();
    _loadKids();
    await _openBox();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadKids() async {
    kids = prefs.getStringList('kids') ?? ['Kid1', 'Kid2'];
    selectedKid = prefs.getString('selectedKid') ?? kids[0];
  }

  Future<void> _saveKids() async {
    await prefs.setStringList('kids', kids);
    await prefs.setString('selectedKid', selectedKid ?? '');
  }

  Future<void> _openBox() async {
    final kidKey = selectedKid ?? 'default';
    _box = await Hive.openBox('chores_$kidKey');
    await _loadChores();
  }

  Future<void> _loadChores() async {
    final savedChores = _box.get('chores', defaultValue: <Map<String, dynamic>>[]);
    _chores = List<Map<String, dynamic>>.from(savedChores);
    _points = 0;
    for (var chore in _chores) {
      if (chore['complete'] == true) _points += 10;
    }
    if (mounted) setState(() {});
  }

  Future<void> _switchKid(String? kid) async {
    if (kid != null && kid != selectedKid) {
      selectedKid = kid;
      await _saveKids();
      await _openBox();
    }
  }

  Future<void> _addKid() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New Kid'),
        content: TextField(decoration: InputDecoration(hintText: 'Kid name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, 'New Kid'), child: Text('Add')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      setState(() => kids.add(name));
      await _saveKids();
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
    appBar: AppBar(
      title: Text('ChoreMe'),
      backgroundColor: Colors.purple,
      actions: [
        PopupMenuButton<String>(
          onSelected: _switchKid,
          itemBuilder: (context) => kids.map((kid) => PopupMenuItem(value: kid, child: Text(kid))).toList(),
        ),
        IconButton(icon: Icon(Icons.person_add), onPressed: _addKid),
      ],
    ),
    body: _loading
        ? Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(selectedKid ?? 'Default', style: Theme.of(context).textTheme.headlineSmall),
                    Row(
                      children: [
                        Expanded(child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(hintText: 'Add chore'),
                          onSubmitted: (_) => _addChore(),
                        )),
                        IconButton(icon: Icon(Icons.add), onPressed: _addChore),
                      ],
                    ),
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
