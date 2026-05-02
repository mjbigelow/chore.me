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

class _ChoreScreenState extends State<ChoreScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> _chores = [];
  final _controller = TextEditingController();
  int _points = 0;

  @override
  void initState() {
    super.initState();
    _loadChores();
  }

  Future<void> _loadChores() async {
    final userId = supabase.auth.currentUser!.id;
    final response = await supabase.from('chores').select().eq('user_id', userId);
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
        'kid': 'default',
        'task': _controller.text,
        'complete': false,
        'points': 10,
      });
      _controller.clear();
      _loadChores();
    }
  }

  Future<void> _toggle(int index) async {
    if (!_chores[index]['complete']) {
      await supabase.from('chores').update({'complete': true}).eq('id', _chores[index]['id']);
      _loadChores();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Chores'),
      actions: [
        IconButton(
          icon: Icon(Icons.logout),
          onPressed: () => supabase.auth.signOut(),
        ),
      ],
    ),
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
              title: Text(_chores[i]['task']),
              leading: Checkbox(
                value: _chores[i]['complete'],
                onChanged: (_) => _toggle(i),
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
}
