import 'package:flutter/material.dart';

class DetailSampahPage extends StatelessWidget {

  final Map data;

  const DetailSampahPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(data['nama']),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            Image.network(
              data['gambar'],
              height: 200,
            ),

            const SizedBox(height: 20),

            Text(
              data['nama'],
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Kategori : ${data['kategori']}",
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 10),

            Text(
              "Harga : Rp ${data['harga_per_kg']} /kg",
              style: const TextStyle(
                fontSize: 18,
                color: Colors.blue,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              data['deskripsi'] ?? "Tidak ada deskripsi",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}