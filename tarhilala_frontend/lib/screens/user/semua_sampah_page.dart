import 'package:flutter/material.dart';
import '../../services/product_service.dart';
import 'detail_sampah_page.dart';

class SemuaSampahPage extends StatefulWidget {
  const SemuaSampahPage({super.key});

  @override
  State<SemuaSampahPage> createState() => _SemuaSampahPageState();
}

class _SemuaSampahPageState extends State<SemuaSampahPage> {

  List data = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  load() async {
    final result = await ProductService.getHargaSampah();

    setState(() {
      data = result;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Semua Harga Sampah"),
      ),

      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: data.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
        itemBuilder: (context, index) {

          final item = data[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailSampahPage(data: item),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Image.network(item['gambar'], height: 70),

                  const SizedBox(height: 10),

                  Text(
                    item['nama'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  Text(
                    "Rp ${item['harga_per_kg']}/kg",
                    style: const TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}