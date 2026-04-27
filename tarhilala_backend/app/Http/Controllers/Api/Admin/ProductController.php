<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\JenisSampah;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\File;

class ProductController extends Controller
{
    /**
     * Menampilkan daftar produk (JSON)
     */
    public function index()
{
    try {
        // Gunakan orderBy ID jika created_at bermasalah
        $products = \App\Models\JenisSampah::orderBy('id', 'desc')->get();

        $products->transform(function ($item) {
            // Pastikan URL gambar benar agar tidak "Failed to decode image"
            if ($item->gambar) {
                $item->gambar = url($item->gambar);
            }
            return $item;
        });

        return response()->json([
            'status' => 'success',
            'data' => $products
        ], 200);
    } catch (\Exception $e) {
        // Kirim error sebagai JSON, bukan HTML
        return response()->json([
            'status' => 'error',
            'message' => $e->getMessage()
        ], 500);
    }
}

    /**
     * Menyimpan produk baru via API
     */
    public function store(Request $request)
    {
        $request->validate([
            'nama' => 'required|string|max:100',
            'kategori' => 'required|string|max:100',
            'harga_per_kg' => 'required|numeric',
            'gambar' => 'sometimes|nullable|image|mimes:jpeg,png,jpg|max:2048',
        ]);

        $data = $request->all();

        if ($request->hasFile('gambar')) {
            $file = $request->file('gambar');
            $nama_file = time() . "." . $file->getClientOriginalExtension();
            $file->move(public_path('assets/img/products'), $nama_file);
            $data['gambar'] = 'assets/img/products/' . $nama_file;
        }

        $product = JenisSampah::create($data);

        return response()->json([
            'status' => 'success',
            'message' => 'Produk berhasil ditambahkan',
            'data' => $product
        ], 201);
    }

    /**
     * Mengupdate produk via API
     */
    public function update(Request $request, $id)
{
    $product = \App\Models\JenisSampah::findOrFail($id);

    $request->validate([
        // Tambahkan ,$id agar Laravel mengabaikan dirinya sendiri saat cek nama unik
        'nama' => "required|string|max:100|unique:jenis_sampah,nama,$id",
        'kategori' => 'required|string|max:100',
        'harga_per_kg' => 'required|numeric',
        'gambar' => 'sometimes|nullable|image|mimes:jpeg,png,jpg|max:2048',
    ]);

    $data = $request->all();

    if ($request->hasFile('gambar')) {
        if ($product->gambar && file_exists(public_path($product->gambar))) {
            unlink(public_path($product->gambar));
        }
        $file = $request->file('gambar');
        $nama_file = time() . "." . $file->getClientOriginalExtension();
        $file->move(public_path('assets/img/products'), $nama_file);
        $data['gambar'] = 'assets/img/products/' . $nama_file;
    } else {
        // PENTING: Jangan update field gambar jika tidak ada file baru
        unset($data['gambar']);
    }

    $product->update($data);

    return response()->json([
        'status' => 'success',
        'message' => 'Produk berhasil diperbarui',
        'data' => $product
    ], 200);
}

    /**
     * Menghapus produk via API
     */
    public function destroy($id)
    {
        $product = JenisSampah::findOrFail($id);

        // Hapus file fisik gambar agar tidak memenuhi penyimpanan
        if ($product->gambar && File::exists(public_path($product->gambar))) {
            File::delete(public_path($product->gambar));
        }

        $product->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Produk berhasil dihapus'
        ], 200);
    }
}
