import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyD14Lb5JO1E6qrMYgIHCkNJVFThJcci-d8",
      appId: "1:240247351295:web:6f14dd0ff15167a28969ca",
      messagingSenderId: "240247351295",
      projectId: "remed-pab-d66ae",
      storageBucket: "remed-pab-d66ae.firebasestorage.app",
    ),
  );
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: SplashScreen()));
}

// 1. SPLASH SCREEN
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegisterPage()));
    });
  }
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.rocket_launch, size: 80, color: Colors.indigo),
      SizedBox(height: 20),
      CircularProgressIndicator(),
    ])),
  );
}

// 2. HALAMAN DAFTAR
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _ig = TextEditingController();

  Future<void> _register() async {
    try {
      UserCredential user = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(), password: _pass.text.trim()
      );
      await FirebaseFirestore.instance.collection('users').doc(user.user!.uid).set({
        'name': _name.text, 'email': _email.text, 'instagram': _ig.text
      });
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(body: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.shopping_bag, size: 80, color: Colors.indigo),
    TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nama Lengkap')),
    TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
    TextField(controller: _pass, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
    TextField(controller: _ig, decoration: const InputDecoration(labelText: 'Username Instagram')),
    const SizedBox(height: 20),
    ElevatedButton(onPressed: _register, child: const Text("Daftar")),
    TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage())), child: const Text("Sudah punya akun? Login")),
  ])));
}

// 4. HALAMAN LOGIN
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  
  @override
  Widget build(BuildContext context) => Scaffold(body: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.shopping_bag, size: 80, color: Colors.indigo),
    TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
    TextField(controller: _pass, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
    ElevatedButton(onPressed: () async {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
      } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
    }, child: const Text("Login")),
  ])));
}

// 6. HOME PAGE
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List articles = [];
  @override
  void initState() { super.initState(); _fetch(); }
  Future<void> _fetch() async {
    try {
      final res = await http.get(Uri.parse("https://api.spaceflightnewsapi.net/v4/articles/?limit=20"));
      if (res.statusCode == 200) setState(() => articles = json.decode(res.body)['results']);
    } catch (e) { debugPrint("Error: $e"); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text("SpaceNews")), body: ListView.builder(itemCount: articles.length, itemBuilder: (context, i) => ListTile(
      leading: Image.network(articles[i]['image_url'] ?? articles[i]['image'] ?? '', width: 50, errorBuilder: (c, e, s) => const Icon(Icons.broken_image)),
      title: Text(articles[i]['title']),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPage(data: articles[i]))),
    )), bottomNavigationBar: BottomNavigationBar(type: BottomNavigationBarType.fixed, items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Fav'),
      BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notif'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ], onTap: (i) {
      if (i == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritePage()));
      if (i == 2) Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPage()));
      if (i == 3) Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
    }));
  }
}

// 7. DETAIL PAGE
class DetailPage extends StatelessWidget {
  final Map data;
  const DetailPage({super.key, required this.data});
  @override
  Widget build(BuildContext context) {
    final imageUrl = data['image_url'] ?? data['image'] ?? '';
    return Scaffold(appBar: AppBar(actions: [IconButton(icon: const Icon(Icons.favorite_border), onPressed: () async {
      await FirebaseFirestore.instance.collection('favorites').doc(data['id'].toString()).set({
        'title': data['title'], 'image_url': imageUrl, 'summary': data['summary']
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ditambahkan ke Favorit")));
    })]), body: SingleChildScrollView(child: Column(children: [
      imageUrl.isNotEmpty ? Image.network(imageUrl, errorBuilder: (c, e, s) => const Icon(Icons.broken_image)) : const Icon(Icons.image_not_supported, size: 100),
      Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        Text(data['title'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(data['summary'] ?? '')
      ]))])));
  }
}

// 8. FAVORITE PAGE
class FavoritePage extends StatelessWidget {
  const FavoritePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Favorites")), body: StreamBuilder(stream: FirebaseFirestore.instance.collection('favorites').snapshots(), builder: (context, snapshot) {
    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
    return ListView(children: snapshot.data!.docs.map((doc) => ListTile(
      leading: Image.network(doc['image_url'] ?? '', width: 50, errorBuilder: (c, e, s) => const Icon(Icons.image)),
      title: Text(doc['title']), 
      trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => doc.reference.delete()))).toList());
  }));
}

// 9. NOTIFICATION PAGE
class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Notifications")), body: const Center(child: Text("Tidak ada notifikasi baru")));
}

// 10. PROFILE PAGE
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(appBar: AppBar(title: const Text("Profile")), body: user == null ? const Center(child: Text("Tidak ada user")) : StreamBuilder(stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(), builder: (context, snapshot) {
      if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: CircularProgressIndicator());
      var data = snapshot.data!;
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircleAvatar(radius: 50, backgroundImage: const AssetImage('assets/foto.jpeg'), onBackgroundImageError: (_, __) => debugPrint("Error loading image")),
        const SizedBox(height: 20),
        Text("Nama: ${data['name']}"), Text("Email: ${data['email']}"), Text("IG: ${data['instagram']}"),
        ElevatedButton(onPressed: () { FirebaseAuth.instance.signOut(); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const RegisterPage()), (route) => false); }, child: const Text("Log Out"))
      ]));
    }));
  }
}