import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Home());
  }
}

class Home extends StatefulWidget {
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final name = TextEditingController();
  final pan = TextEditingController();
  final amt = TextEditingController();

  void add() async {
    double a = double.parse(amt.text);
    double t = a * 0.01;

    await FirebaseFirestore.instance.collection("txns").add({
      "name": name.text,
      "pan": pan.text,
      "amount": a,
      "tds": t,
      "net": a - t,
      "date": DateFormat('dd-MM-yyyy').format(DateTime.now()),
      "history": []
    });

    name.clear(); pan.clear(); amt.clear();
  }

  void edit(String id, Map old) {
    name.text = old['name'];
    pan.text = old['pan'];
    amt.text = old['amount'].toString();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Edit"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name),
          TextField(controller: pan),
          TextField(controller: amt),
        ]),
        actions: [
          TextButton(
            onPressed: () async {
              double a = double.parse(amt.text);
              double t = a * 0.01;

              await FirebaseFirestore.instance
                  .collection("txns").doc(id).update({
                "name": name.text,
                "pan": pan.text,
                "amount": a,
                "tds": t,
                "net": a - t,
                "history": FieldValue.arrayUnion([
                  {"old": old, "time": DateTime.now().toString()}
                ])
              });

              Navigator.pop(context);
            },
            child: Text("UPDATE"),
          )
        ],
      ),
    );
  }

  void delete(String id) {
    FirebaseFirestore.instance.collection("txns").doc(id).delete();
  }

  void share(Map t) {
    Share.share(
        "Name: ${t['name']}\nPAN: ${t['pan']}\nAmount: ₹${t['amount']}\nTDS: ₹${t['tds']}\nNet: ₹${t['net']}\n\n1% TDS u/s 194S. Claim in ITR.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("TDS FINAL APP")),
      body: Column(
        children: [
          TextField(controller: name, decoration: InputDecoration(labelText: "Name")),
          TextField(controller: pan, decoration: InputDecoration(labelText: "PAN")),
          TextField(controller: amt, decoration: InputDecoration(labelText: "Amount")),
          ElevatedButton(onPressed: add, child: Text("SAVE")),

          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection("txns").snapshots(),
              builder: (c, s) {
                if (!s.hasData) return CircularProgressIndicator();

                var docs = s.data!.docs;

                return ListView(
                  children: docs.map((e) {
                    var t = e.data();
                    return Card(
                      child: ListTile(
                        title: Text("${t['name']} ₹${t['amount']}"),
                        subtitle: Text(
                            "PAN: ${t['pan']}\nTDS: ₹${t['tds']} | Net: ₹${t['net']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: Icon(Icons.edit), onPressed: () => edit(e.id, t)),
                            IconButton(icon: Icon(Icons.delete), onPressed: () => delete(e.id)),
                            IconButton(icon: Icon(Icons.share), onPressed: () => share(t)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
