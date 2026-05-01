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
    theme: ThemeData(
      primarySwatch: Colors.purple,
      scaffoldBackgroundColor: Colors.grey[50],
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    home: ChoreListScreen(),
  );
}

class ChoreListScreen extends StatefulWidget {
  @override
  _ChoreListScreenState createState() => _ChoreListScreenState();
}

class _ChoreListScreenState extends State<ChoreListScreen> with TickerProviderStateMixin {
  List<String> kids = [];
  late TabController _tabController;
  final TextEditingController _controller = TextEditingController();
  late SharedPreferences prefs;
  final Map<String, Box> kidBoxes = {};
  final Map<String, List<Map<String, dynamic>>> kidChores = {};
  final Map<String, int> kidPoints = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    prefs = await SharedPreferences.getInstance();
    await _loadKids();
    _tabController = TabController(length: kids.length + 1, vsync: this);
    await _loadAllData();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadKids() async {
    kids = prefs.getStringList('kids') ?? ['Kid1', 'Kid2'];
    setState(() {});
  }

  Future<void> _saveKids() async {
    await prefs.setStringList('kids', kids);
  }

  Future<void> _loadAllData() async {
    for (String kid in kids) {
      final box = await Hive.openBox('chores_$kid');
      kidBoxes[kid] = box;
      await _loadKidData(kid);
    }
  }

  Future<void> _loadKidData(String kid) async {
    final box = kidBoxes[kid];
    if (box == null) return;
    final savedChores = box.get('chores', defaultValue: <Map<String, dynamic>>[]);
    final chores = List<Map<String, dynamic>>.from(savedChores);
    int points = 0;
    for (var chore in chores) {
      if (chore['complete'] == true) points += 10;
    }
    setState(() {
      kidChores[kid] = chores;
      kidPoints[kid] = points;
    });
  }

  Future<void> _addKid() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Kid'),
        content: TextField(controller: controller, decoration: InputDecoration(hintText: 'Kid name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: Text('Add')),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.isNotEmpty && !kids.contains(name)) {
      kids.add(name);
      await _saveKids();
      final box = await Hive.openBox('chores_$name');
      kidBoxes[name] = box;
      _tabController.dispose();
      _tabController = TabController(length: kids.length + 1, vsync: this);
      setState(() {});
    }
  }

  Future<void> _editKid(String oldName) async {
    final controller = TextEditingController(text: oldName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Kid'),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (newName != null && newName.isNotEmpty && newName != oldName) {
      final index = kids.indexOf(oldName);
      kids[index] = newName;
      await _saveKids();
      setState(() {});
    }
  }

  Future<void> _addChore(String kid) async {
    if (_controller.text.isNotEmpty) {
      final newChore = {'task': _controller.text, 'complete': false};
      final chores = List<Map<String, dynamic>>.from(kidChores[kid] ?? []);
      chores.add(newChore);
      final box = kidBoxes[kid];
      if (box != null) await box.put('chores', chores);
      await _loadKidData(kid);
      _controller.clear();
    }
  }

  Future<void> _toggleChore(String kid, int index) async {
    final chores = List<Map<String, dynamic>>.from(kidChores[kid] ?? []);
    if (!chores[index]['complete']) {
      chores[index]['complete'] = true;
      final box = kidBoxes[kid];
      if (box != null) await box.put('chores', chores);
      await _loadKidData(kid);
    }
  }

  Future<void> _editChore(String kid, int index) async {
    final controller = TextEditingController(text: kidChores[kid]?[index]['task'] ?? '');
    final newTask = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Chore'),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (newTask != null && newTask.isNotEmpty) {
      final chores = List<Map<String, dynamic>>.from(kidChores[kid] ?? []);
      chores[index]['task'] = newTask;
      final box = kidBoxes[kid];
      if (box != null) await box.put('chores', chores);
      await _loadKidData(kid);
    }
  }

  int _getCompleteCount(String kid) {
    final chores = kidChores[kid] ?? [];
    return chores.where((c) => c['complete'] == true).length;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('ChoreMe'),
      backgroundColor: Colors.purple,
      elevation: 0,
      actions: [
        IconButton(icon: Icon(Icons.person_add), onPressed: _addKid),
      ],
      bottom: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabs: [
          Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
          ...kids.map((kid) => Tab(icon: Icon(Icons.person), text: kid.length > 8 ? '${kid.substring(0,8)}...' : kid)),
        ],
      ),
    ),
    body: _loading
        ? Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildOverview(),
              ...kids.map((kid) => _buildKidTab(kid)),
            ],
          ),
  );

  Widget _buildOverview() => ListView.builder(
    padding: EdgeInsets.all(16),
    itemCount: kids.length,
    itemBuilder: (context, i) {
      final kid = kids[i];
      return Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.purple[100],
            child: Text(kid[0].toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          title: Text(kid, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          subtitle: Text('${_getCompleteCount(kid)} / ${kidChores[kid]?.length ?? 0} chores'),
          trailing: Chip(
            label: Text('${kidPoints[kid] ?? 0} pts'),
            backgroundColor: Colors.orange,
          ),
          onTap: () => _tabController.animateTo(i + 1),
          onLongPress: () => _editKid(kid),
        ),
      );
    },
  );

  Widget _buildKidTab(String kid) => Column(
    children: [
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.purple[400]!, Colors.deepPurple]),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Text(kid, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('${kidPoints[kid] ?? 0} points', style: TextStyle(fontSize: 18, color: Colors.orange[300], fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Add chore for $kid',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              onSubmitted: (_) => _addChore(kid),
            )),
            SizedBox(width: 8),
            FloatingActionButton(
              mini: true,
              child: Icon(Icons.add),
              onPressed: () => _addChore(kid),
            ),
          ],
        ),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: kidChores[kid]?.length ?? 0,
          itemBuilder: (context, i) {
            final chore = kidChores[kid]![i];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                title: Text(chore['task'], style: TextStyle(
                  decoration: chore['complete'] ? TextDecoration.lineThrough : null,
                  fontSize: 16,
                )),
                leading: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  transform: Matrix4.diagonal3Values(
                    chore['complete'] ? 0.8 : 1.0,
                    1.0,
                    1.0,
                  ),
                  child: Checkbox(
                    value: chore['complete'],
                    onChanged: (_) => _toggleChore(kid, i),
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editChore(kid, i),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }
}
