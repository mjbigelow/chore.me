import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String SUPABASE_URL = 'https://knyyeyjxdscaokyywzap.supabase.co';
const String SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtueXlleWp4ZHNjYW9reXl3emFwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc2NDc5MTAsImV4cCI6MjA5MzIyMzkxMH0.IlzXCj9Jl1WQyBg4Mm7oM5b9GFNMFzvPBi6a90QShQw';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ChoreMe',
    theme: ThemeData(primarySwatch: Colors.purple),
    home: AuthWrapper(),
  );
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
    stream: Supabase.instance.client.auth.onAuthStateChange,
    builder: (context, snapshot) => snapshot.data?.session != null ? ChoreScreen() : LoginScreen(),
  );
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  String _message = '';

  Future<void> _auth() async {
    final supabase = Supabase.instance.client;
    try {
      if (_isLogin) {
        await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } catch (e) {
      setState(() => _message = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('ChoreMe Login')),
    body: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          SizedBox(height: 20),
          ElevatedButton(onPressed: _auth, child: Text(_isLogin ? 'Login' : 'Sign Up')),
          TextButton(
            onPressed: () => setState(() => _isLogin = !_isLogin),
            child: Text(_isLogin ? 'Sign Up' : 'Login'),
          ),
          if (_message.isNotEmpty) Text(_message, style: TextStyle(color: Colors.red)),
        ],
      ),
    ),
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class ChoreScreen extends StatefulWidget {
  @override
  _ChoreScreenState createState() => _ChoreScreenState();
}

class _ChoreScreenState extends State<ChoreScreen> with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  List<dynamic> _chores = [];
  final _controller = TextEditingController();
  int _points = 0;
  String? selectedKid;
  late TabController _tabController;
  List<String> _kids = ['default'];
  final _kidController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadChores();
  }

  Future<void> _loadChores() async {
    final userId = supabase.auth.currentUser!.id;
    var query = supabase.from('chores').select().eq('user_id', userId);
    if (selectedKid != null) {
      query = query.eq('kid', selectedKid!);
    }
    final response = await query;
    setState(() => _chores = response);
    _calculatePoints();
  }

  void _calculatePoints() {
    _points = 0;
    for (var chore in _chores) {
      if (chore['complete']) _points += (chore['points'] as int? ?? 10);
    }
  }

  Future<void> _addChore() async {
    if (_controller.text.isNotEmpty) {
      await supabase.from('chores').insert({
        'user_id': supabase.auth.currentUser!.id,
        'kid': selectedKid ?? 'default',
        'task': _controller.text,
        'complete': false,
        'points': 10,
      });
      _controller.clear();
      _loadChores();
    }
  }

  Future<void> _addKid() async {
    if (_kidController.text.isNotEmpty) {
      setState(() {
        _kids.add(_kidController.text.trim());
      });
      _kidController.clear();
    }
  }

  Future<void> _toggle(int index) async {
    if (!_chores[index]['complete']) {
      await supabase.from('chores').update({'complete': true}).eq('id', _chores[index]['id']);
      _loadChores();
    }
  }

  Future<void> _editChore(int index) async {
    final chore = _chores[index];
    showDialog(
      context: context,
      builder: (BuildContext context) => EditChoreDialog(
        chore: chore,
        onUpdate: (String task, int points) async {
          await supabase.from('chores')
              .update({'task': task, 'points': points})
              .eq('id', chore['id']);
          _loadChores();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Chores'),
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Kids'),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.logout),
          onPressed: () => supabase.auth.signOut(),
        ),
      ],
    ),
    body: TabBarView(
      controller: _tabController,
      children: [
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Total Chores: ${_chores.length}', style: Theme.of(context).textTheme.headlineSmall),
              Text('Points: $_points', style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        ),
        Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _kidController,
                      decoration: InputDecoration(hintText: 'Add kid'),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: _addKid,
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 150,
              child: ListView.builder(
                itemCount: _kids.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(_kids[index]),
                  trailing: Radio<String>(
                    value: _kids[index],
                    groupValue: selectedKid,
                    onChanged: (value) {
                      setState(() {
                        selectedKid = value;
                      });
                      _loadChores();
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(hintText: 'Add chore'),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: _addChore,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _chores.length,
                itemBuilder: (context, i) => GestureDetector(
                  onLongPress: () => _editChore(i),
                  child: ListTile(
                    title: Text(_chores[i]['task']),
                    subtitle: Text('Kid: ${_chores[i]['kid'] ?? 'unknown'}'),
                    leading: Checkbox(
                      value: _chores[i]['complete'],
                      onChanged: (_) => _toggle(i),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Points: $_points', style: Theme.of(context).textTheme.headlineMedium),
            ),
          ],
        ),
      ],
    ),
  );
}

class EditChoreDialog extends StatefulWidget {
  final Map<String, dynamic> chore;
  final void Function(String, int) onUpdate;

  const EditChoreDialog({
    super.key,
    required this.chore,
    required this.onUpdate,
  });

  @override
  State<EditChoreDialog> createState() => _EditChoreDialogState();
}

class _EditChoreDialogState extends State<EditChoreDialog> {
  late final TextEditingController _taskController;
  late final TextEditingController _pointsController;

  @override
  void initState() {
    super.initState();
    _taskController = TextEditingController(text: widget.chore['task']);
    _pointsController = TextEditingController(text: widget.chore['points'].toString());
  }

  @override
  void dispose() {
    _taskController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Chore'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _taskController,
            decoration: const InputDecoration(labelText: 'Task'),
          ),
          TextField(
            controller: _pointsController,
            decoration: const InputDecoration(labelText: 'Points'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            widget.onUpdate(_taskController.text, int.parse(_pointsController.text));
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}
