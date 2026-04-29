<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Reward;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\File;

class RewardController extends Controller
{
    public function index()
    {
        $rewards = Reward::orderBy('id', 'desc')->get();

        $rewards->transform(function ($item) {
            if ($item->gambar) {
                // Menghasilkan URL lengkap untuk gambar
                $item->gambar = url($item->gambar);
            }
            return $item;
        });

        return response()->json(['status' => 'success', 'data' => $rewards], 200);
    }

    public function store(Request $request)
    {
        $request->validate([
            'nama_reward'     => 'required|string|max:200|unique:reward,nama_reward',
            'poin_dibutuhkan' => 'required|numeric',
            'stok'            => 'required|numeric',
            'deskripsi'       => 'nullable|string',
            'gambar'          => 'nullable|image|mimes:jpeg,png,jpg|max:2048',
        ]);

        $data = $request->only(['nama_reward', 'poin_dibutuhkan', 'stok', 'deskripsi']);

        if ($request->hasFile('gambar')) {
            $file = $request->file('gambar');
            $nama_file = time() . "_" . str_replace(' ', '_', $file->getClientOriginalName());
            $file->move(public_path('assets/img/rewards'), $nama_file);
            $data['gambar'] = 'assets/img/rewards/' . $nama_file;
        }

        $reward = Reward::create($data);
        return response()->json(['status' => 'success', 'data' => $reward], 201);
    }

    public function update(Request $request, $id)
    {
        $reward = Reward::findOrFail($id);

        // LOGIKA PENTING: Jika Frontend mengirim field 'poin', kita petakan ke 'poin_dibutuhkan'
        if ($request->has('poin') && !$request->has('poin_dibutuhkan')) {
            $request->merge(['poin_dibutuhkan' => $request->poin]);
        }

        $request->validate([
            'nama_reward'     => "required|string|max:200|unique:reward,nama_reward,$id",
            'poin_dibutuhkan' => 'required|numeric',
            'stok'            => 'required|numeric',
            'deskripsi'       => 'nullable|string',
            'gambar'          => 'sometimes|nullable|image|mimes:jpeg,png,jpg|max:2048',
        ]);

        $data = $request->only(['nama_reward', 'poin_dibutuhkan', 'stok', 'deskripsi']);

        if ($request->hasFile('gambar')) {
            // Hapus foto lama jika ada file baru yang diupload
            if ($reward->getRawOriginal('gambar') && File::exists(public_path($reward->getRawOriginal('gambar')))) {
                File::delete(public_path($reward->getRawOriginal('gambar')));
            }

            $file = $request->file('gambar');
            $nama_file = time() . "_" . str_replace(' ', '_', $file->getClientOriginalName());
            $file->move(public_path('assets/img/rewards'), $nama_file);
            $data['gambar'] = 'assets/img/rewards/' . $nama_file;
        }

        $reward->update($data);

        return response()->json([
            'status' => 'success',
            'message' => 'Data reward berhasil diperbarui',
            'data' => $reward
        ], 200);
    }

    public function destroy($id)
    {
        $reward = Reward::findOrFail($id);
        if ($reward->gambar && File::exists(public_path($reward->gambar))) {
            File::delete(public_path($reward->gambar));
        }
        $reward->delete();
        return response()->json(['status' => 'success', 'message' => 'Reward berhasil dihapus'], 200);
    }
}
