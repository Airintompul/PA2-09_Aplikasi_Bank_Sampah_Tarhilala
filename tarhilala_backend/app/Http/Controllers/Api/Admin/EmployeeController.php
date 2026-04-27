<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\ChatMessage;
use App\Models\ChatRoom;
use App\Models\KontenEdukasi;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;

class EmployeeController extends Controller
{
    /**
     * Menampilkan data petugas & admin
     */
    public function index()
    {
        $employees = User::whereIn('role', ['petugas', 'admin'])
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'status' => 'success',
            'message' => 'Daftar petugas berhasil dimuat',
            'data' => $employees
        ], 200);
    }

    /**
     * Menyimpan data petugas baru
     */
    public function store(Request $request)
    {
        $request->validate([
            'nama' => 'required|string|max:100',
            'email' => 'required|email|unique:users,email',
            'nomor_telepon' => 'nullable|string|max:20',
            'password' => 'required|string|min:6',
        ]);

        $employee = User::create([
            'nama' => $request->nama,
            'email' => $request->email,
            'nomor_telepon' => $request->nomor_telepon,
            'password' => Hash::make($request->password),
            'role' => 'petugas', // Default petugas, admin dibuat manual via DB/Seeder
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Petugas berhasil ditambahkan',
            'data' => $employee
        ], 201);
    }

    /**
     * Mengupdate data petugas
     */
    public function update(Request $request, $id)
    {
        // Pastikan yang diupdate adalah petugas atau admin
        $employee = User::where('id', $id)
            ->whereIn('role', ['petugas', 'admin'])
            ->first();

        if (!$employee) {
            return response()->json([
                'status' => 'error',
                'message' => 'Data petugas tidak ditemukan'
            ], 404);
        }

        $request->validate([
            'nama' => 'required|string|max:100',
            'email' => "required|email|unique:users,email,$id",
            'nomor_telepon' => 'nullable|string|max:20',
        ]);

        $data = [
            'nama' => $request->nama,
            'email' => $request->email,
            'nomor_telepon' => $request->nomor_telepon,
        ];

        if ($request->password) {
            $data['password'] = Hash::make($request->password);
        }

        $employee->update($data);

        return response()->json([
            'status' => 'success',
            'message' => 'Data petugas berhasil diperbarui',
            'data' => $employee
        ], 200);
    }

    /**
     * Menghapus data petugas dan membersihkan relasi terkait
     */
    public function destroy($id)
    {
        $employee = User::where('id', $id)
            ->whereIn('role', ['petugas', 'admin'])
            ->first();

        if (!$employee) {
            return response()->json([
                'status' => 'error',
                'message' => 'Data petugas tidak ditemukan'
            ], 404);
        }

        try {
            DB::transaction(function () use ($id, $employee) {
                // 1. Ambil semua chat room terkait user ini
                $rooms = ChatRoom::where('admin_id', $id)
                    ->orWhere('nasabah_id', $id)
                    ->get();

                foreach ($rooms as $room) {
                    // Hapus pesan di dalam room tersebut
                    ChatMessage::where('chat_room_id', $room->id)->delete();
                }

                // 2. Hapus chat room
                ChatRoom::where('admin_id', $id)->delete();
                ChatRoom::where('nasabah_id', $id)->delete();

                // 3. Hapus pesan langsung dari user
                ChatMessage::where('pengirim_id', $id)->delete();

                // 4. Hapus konten edukasi yang ditulis user ini
                KontenEdukasi::where('penulis_id', $id)->delete();

                // 5. Hapus user utama
                $employee->delete();
            });

            return response()->json([
                'status' => 'success',
                'message' => 'Petugas dan seluruh data terkait berhasil dihapus'
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Gagal menghapus data: ' . $e->getMessage()
            ], 500);
        }
    }
}
