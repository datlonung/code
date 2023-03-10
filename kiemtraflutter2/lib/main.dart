// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      // Remove the debug banner
      debugShowCheckedModeBanner: false,
      title: 'Hướng dẫn CRUD Firebase',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // text fields' controllers
  final TextEditingController _MaSVController = TextEditingController();
  final TextEditingController _NgaySinhController = TextEditingController();
  final TextEditingController _GioiTinhController = TextEditingController();
  final TextEditingController _QueQuanController = TextEditingController();

  final CollectionReference _productss =
  FirebaseFirestore.instance.collection('products');

  // This function is triggered when the floatting button or one of the edit buttons is pressed
  // Adding a product if no documentSnapshot is passed
  // If documentSnapshot != null then update an existing product
  Future<void> _createOrUpdate([DocumentSnapshot? documentSnapshot]) async {
    String action = 'create';
    if (documentSnapshot != null) {
      action = 'update';
      _MaSVController.text = documentSnapshot['MaSV'].toString();
      _NgaySinhController.text = documentSnapshot['NgaySinh'].toString();
      _GioiTinhController.text = documentSnapshot['GioiTinh'].toString();
      _QueQuanController.text = documentSnapshot['QueQuan'].toString();
    }

    await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext ctx) {
          return Padding(
            padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                // prevent the soft keyboard from covering text fields
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  controller: _MaSVController,
                  decoration: const InputDecoration(labelText: 'MaSV'),
                ),
                TextField(
                  // keyboardType:
                  // const TextInputType.numberWithOptions(decimal: true),
                  controller: _NgaySinhController,
                  decoration: const InputDecoration(labelText: 'NgaySinh',
                  ),
                ),
                TextField(
                  // keyboardType:
                  // const TextInputType.numberWithOptions(decimal: true),
                  controller: _GioiTinhController,
                  decoration: const InputDecoration(labelText: 'GioiTinh',
                  ),
                ),
                TextField(
                  // keyboardType:
                  // const TextInputType.numberWithOptions(decimal: true),
                  controller: _QueQuanController,
                  decoration: const InputDecoration(labelText: 'QueQuan',
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  child: Text(action == 'create' ? 'Create' : 'Update'),
                  onPressed: () async {
                    final double? MaSV = double.tryParse(_MaSVController.text);
                    final String? NgaySinh = _NgaySinhController.text;
                    final String? GioiTinh = _GioiTinhController.text;
                    final String? QueQuan = _QueQuanController.text;

                    if (MaSV != null && NgaySinh != null && GioiTinh != null && QueQuan != null) {
                      if (action == 'create') {
                        // Persist a new product to Firestore
                        await _productss.add({"MaSV": MaSV, "NgaySinh": NgaySinh, "GioiTinh": GioiTinh,"QueQuan": QueQuan});
                      }

                      if (action == 'update') {
                        // Update the product
                        await _productss
                            .doc(documentSnapshot!.id)
                            .update({"MaSV": MaSV, "NgaySinh": NgaySinh, "GioiTinh": GioiTinh,"QueQuan": QueQuan});
                      }

                      // Clear the text fields
                      _MaSVController.text = '';
                      _NgaySinhController.text = '';
                      _GioiTinhController.text = '';
                      _QueQuanController.text = '';

                      // Hide the bottom sheet
                      Navigator.of(context).pop();
                    }
                  },
                )
              ],
            ),
          );
        });
  }

  // Deleteing a product by id
  Future<void> _deleteProduct(String productId) async {
    await _productss.doc(productId).delete();

    // Show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You have successfully deleted a product')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('crud.com'),
      ),
      // Using StreamBuilder to display all products from Firestore in real-time
      body: StreamBuilder(
        stream: _productss.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder(
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documentSnapshot =
                streamSnapshot.data!.docs[index];

                return Card(
                  margin: const EdgeInsets.all(5),
                  child: ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text(documentSnapshot['MaSV'].toString()),
                         Text(documentSnapshot['NgaySinh'].toString()),
                        Text(documentSnapshot['GioiTinh'].toString()),
                        Text(documentSnapshot['QueQuan'].toString()),
                      ],
                    ),
                    trailing: SizedBox(
                      width: 100,
                      child: Row(
                        children: [
                          // Press this button to edit a single product
                          IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () =>
                                  _createOrUpdate(documentSnapshot)),
                          // This icon button is used to delete a single product
                          IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () =>
                                  _deleteProduct(documentSnapshot.id)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }

          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
      // Add new product
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createOrUpdate(),
        child: const Icon(Icons.add),
      ),
    );
  }
}