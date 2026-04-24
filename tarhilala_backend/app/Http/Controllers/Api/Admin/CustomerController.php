<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class CustomerController extends Controller
{
    /**
     * Menampilkan data nasabah (JSON)
     */
    public function index()
    {
        $customers = User::where('role', 'nasabah')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'status' => 'success',
            'message' => 'Daftar nasabah berhasil dimuat',
            'data' => $customers
        ], 200);
    }

    /**
     * Menyimpan data nasabah baru via API
     */
    public function store(Request $request)
    {
        $request->validate([
            'nama' => 'required|string|max:100',
            'email' => 'required|email|unique:users,email',
            'nomor_telepon' => 'nullable|string|max:20',
            'password' => 'required|string|min:6',
        ]);

        $customer = User::create([
            'nama' => $request->nama,
            'email' => $request->email,
            'nomor_telepon' => $request->nomor_telepon,
            'password' => Hash::make($request->password),
            'role' => 'nasabah',
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Nasabah berhasil ditambahkan',
            'data' => $customer
        ], 201);
    }

    /**
     * Mengupdate data nasabah via API
     */
    public function update(Request $request, $id)
    {
        // Cari user, pastikan dia adalah nasabah
        $customer = User::where('id', $id)->where('role', 'nasabah')->first();

        if (!$customer) {
            return response()->json([
                'status' => 'error',
                'message' => 'Nasabah tidak ditemukan'
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

        $customer->update($data);

        return response()->json([
            'status' => 'success',
            'message' => 'Data nasabah berhasil diperbarui',
            'data' => $customer
        ], 200);
    }

    /**
     * Menghapus data nasabah via API
     */
    public function destroy($id)
    {
        $customer = User::where('id', $id)->where('role', 'nasabah')->first();

        if (!$customer) {
            return response()->json([
                'status' => 'error',
                'message' => 'Nasabah tidak ditemukan'
            ], 404);
        }

        $customer->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Nasabah berhasil dihapus'
        ], 200);
    }
}
