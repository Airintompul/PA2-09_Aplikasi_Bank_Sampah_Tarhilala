<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\KontenEdukasi;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\File;

class LibraryController extends Controller
{
    /**
     * Menampilkan daftar konten edukasi
     */
    public function index()
    {
        $contents = KontenEdukasi::with('penulis:id,nama')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'status' => 'success',
            'message' => 'Konten edukasi berhasil dimuat',
            'data' => $contents
        ], 200);
    }

    /**
     * Menyimpan konten baru
     */
    public function store(Request $request)
    {
        $request->validate([
            'judul' => 'required|string|max:200',
            'isi' => 'required',
            'thumbnail' => 'nullable|image|mimes:jpeg,png,jpg|max:2048',
            'status' => 'required|in:draft,published,archived'
        ]);

        $data = $request->all();
        $data['slug'] = Str::slug($request->judul) . '-' . time(); // Ditambah time agar slug selalu unik
        $data['penulis_id'] = auth()->id(); // Mengambil ID dari token Sanctum

        // Logika Simpan File Thumbnail
        if ($request->hasFile('thumbnail')) {
            $file = $request->file('thumbnail');
            $nama_file = time() . "_" . $file->getClientOriginalName();
            $file->move(public_path('assets/img/thumbnails'), $nama_file);
            $data['thumbnail'] = 'assets/img/thumbnails/' . $nama_file;
        }

        $content = KontenEdukasi::create($data);

        return response()->json([
            'status' => 'success',
            'message' => 'Konten berhasil diterbitkan',
            'data' => $content
        ], 201);
    }

    /**
     * Mengupdate konten edukasi
     */
    public function update(Request $request, $id)
    {
        $content = KontenEdukasi::findOrFail($id);

        $request->validate([
            'judul' => 'required|string|max:200',
            'isi' => 'required',
            'thumbnail' => 'nullable|image|mimes:jpeg,png,jpg|max:2048',
            'status' => 'required|in:draft,published,archived'
        ]);

        $data = $request->all();
        $data['slug'] = Str::slug($request->judul) . '-' . time();

        // Logika Update File Thumbnail
        if ($request->hasFile('thumbnail')) {
            // Hapus thumbnail lama jika ada di folder
            if ($content->thumbnail && File::exists(public_path($content->thumbnail))) {
                File::delete(public_path($content->thumbnail));
            }

            $file = $request->file('thumbnail');
            $nama_file = time() . "_" . $file->getClientOriginalName();
            $file->move(public_path('assets/img/thumbnails'), $nama_file);
            $data['thumbnail'] = 'assets/img/thumbnails/' . $nama_file;
        }

        $content->update($data);

        return response()->json([
            'status' => 'success',
            'message' => 'Konten berhasil diperbarui',
            'data' => $content
        ], 200);
    }

    /**
     * Menghapus konten edukasi
     */
    public function destroy($id)
    {
        $content = KontenEdukasi::findOrFail($id);

        // Hapus file fisik thumbnail sebelum menghapus data di DB
        if ($content->thumbnail && File::exists(public_path($content->thumbnail))) {
            File::delete(public_path($content->thumbnail));
        }

        $content->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Konten berhasil dihapus'
        ], 200);
    }
}
