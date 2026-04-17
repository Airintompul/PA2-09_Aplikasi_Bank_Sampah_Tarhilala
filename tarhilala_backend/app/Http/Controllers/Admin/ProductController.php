<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\JenisSampah;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\File;

class ProductController extends Controller
{
    public function index()
    {
        $products = JenisSampah::orderBy('created_at', 'desc')->get();
        return view('admin.product.index', compact('products'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'nama' => 'required|string|max:100',
            'kategori' => 'required|string|max:100',
            'harga_per_kg' => 'required|numeric',
            'gambar' => 'nullable|image|mimes:jpeg,png,jpg|max:2048',
        ]);

        $data = $request->all();

        if ($request->hasFile('gambar')) {
            $file = $request->file('gambar');
            $nama_file = time() . "." . $file->getClientOriginalExtension();
            $file->move(public_path('assets/img/products'), $nama_file);
            $data['gambar'] = 'assets/img/products/' . $nama_file;
        }

        JenisSampah::create($data);

        return redirect()->back()->with('success', 'Produk berhasil ditambahkan!');
    }

    public function update(Request $request, $id)
    {
        $request->validate([
            'nama' => 'required|string|max:100',
            'kategori' => 'required|string|max:100',
            'harga_per_kg' => 'required|numeric',
            'gambar' => 'nullable|image|mimes:jpeg,png,jpg|max:2048',
        ]);

        $product = JenisSampah::findOrFail($id);
        $data = $request->all();

        if ($request->hasFile('gambar')) {
            // Hapus gambar lama jika ada
            if ($product->gambar && File::exists(public_path($product->gambar))) {
                File::delete(public_path($product->gambar));
            }

            $file = $request->file('gambar');
            $nama_file = time() . "." . $file->getClientOriginalExtension();
            $file->move(public_path('assets/img/products'), $nama_file);
            $data['gambar'] = 'assets/img/products/' . $nama_file;
        }

        $product->update($data);

        return redirect()->back()->with('success', 'Produk berhasil diperbarui!');
    }

    public function destroy($id)
    {
        $product = JenisSampah::findOrFail($id);

        // Hapus file fisik gambar dari folder
        if ($product->gambar && File::exists(public_path($product->gambar))) {
            File::delete(public_path($product->gambar));
        }

        $product->delete();

        return redirect()->back()->with('success', 'Produk berhasil dihapus!');
    }

    public function apiIndex()
    {
        $products = JenisSampah::orderBy('created_at', 'desc')->get();

        foreach ($products as $item) {
            if ($item->gambar) {
                $item->gambar = url($item->gambar);
            }
        }

        return response()->json([
            'success' => true,
            'data' => $products
        ]);
    }
}
