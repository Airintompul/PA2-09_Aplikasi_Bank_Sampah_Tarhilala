<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Reward;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\File;

class RewardController extends Controller
{
    public function index() {
        $rewards = Reward::latest('id')->get();
        return view('admin.reward.index', compact('rewards'));
    }

    public function store(Request $request) {
        $request->validate([
            'nama_reward' => 'required',
            'poin_dibutuhkan' => 'required|numeric',
            'stok' => 'required|numeric',
            'gambar' => 'nullable|image|mimes:jpeg,png,jpg|max:2048',
        ]);

        $data = $request->all();

        if ($request->hasFile('gambar')) {
            $file = $request->file('gambar');
            $nama_file = time() . "_" . $file->getClientOriginalName();
            $file->move(public_path('assets/img/rewards'), $nama_file);
            $data['gambar'] = 'assets/img/rewards/' . $nama_file;
        }

        Reward::create($data);
        return back()->with('success', 'Reward berhasil ditambahkan');
    }

    public function update(Request $request, $id) {
        $request->validate([
            'nama_reward' => 'required',
            'poin_dibutuhkan' => 'required|numeric',
            'stok' => 'required|numeric',
            'gambar' => 'nullable|image|mimes:jpeg,png,jpg|max:2048',
        ]);

        $reward = Reward::findOrFail($id);
        $data = $request->all();

        if ($request->hasFile('gambar')) {
            // Hapus file lama
            if ($reward->gambar && File::exists(public_path($reward->gambar))) {
                File::delete(public_path($reward->gambar));
            }

            $file = $request->file('gambar');
            $nama_file = time() . "_" . $file->getClientOriginalName();
            $file->move(public_path('assets/img/rewards'), $nama_file);
            $data['gambar'] = 'assets/img/rewards/' . $nama_file;
        }

        $reward->update($data);
        return back()->with('success', 'Reward diperbarui');
    }

    public function destroy($id) {
        $reward = Reward::findOrFail($id);

        if ($reward->gambar && File::exists(public_path($reward->gambar))) {
            File::delete(public_path($reward->gambar));
        }

        $reward->delete();
        return back()->with('success', 'Reward dihapus');
    }

    public function apiRewards()
    {
        $rewards = Reward::latest()->get();
        return response()->json($rewards);
    }
}
