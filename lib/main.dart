import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Database _database;
  List<Dog> _dogs = [];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'dogs_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE dogs(id INTEGER PRIMARY KEY, name TEXT, age INTEGER)',
        );
      },
      version: 1,
    );

    _loadDogs();
  }

  Future<void> _loadDogs() async {
    final List<Map<String, dynamic>> dogs = await _database.query('dogs');

    setState(() {
      _dogs = dogs.map((data) => Dog.fromMap(data)).toList();
    });
  }

  Future<void> _addDog() async {
    final String name = _nameController.text;
    final int age = int.tryParse(_ageController.text) ?? 0;

    if (name.isNotEmpty && age > 0) {
      await _database.insert(
        'dogs',
        Dog(id: _dogs.length + 1, name: name, age: age).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _loadDogs();

      // Clear the text fields after adding a dog
      _nameController.clear();
      _ageController.clear();
    }
  }

  Future<void> _deleteDog(int dogId) async {
    await _database.delete('dogs', where: 'id = ?', whereArgs: [dogId]);

    _loadDogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dog List'),
      ),
      body: Container(
        color: Colors.lightBlue[100],
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Age',
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _addDog,
                    child: Text('Add Dog'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildDogList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDogList() {
    return ListView.builder(
      itemCount: _dogs.length,
      itemBuilder: (context, index) {
        final dog = _dogs[index];
        return ListTile(
          title: Text(dog.name),
          subtitle: Text('Age: ${dog.age}'),
          leading: const Icon(Icons.pets),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteDog(dog.id),
          ),
          onTap: () {
            // Hier kannst du eine Aktion ausführen, wenn auf einen Hund getippt wird.
          },
        );
      },
    );
  }
}

class Dog {
  final int id;
  final String name;
  final int age;

  Dog({
    required this.id,
    required this.name,
    required this.age,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
    };
  }

  factory Dog.fromMap(Map<String, dynamic> map) {
    return Dog(
      id: map['id'],
      name: map['name'],
      age: map['age'],
    );
  }
}
