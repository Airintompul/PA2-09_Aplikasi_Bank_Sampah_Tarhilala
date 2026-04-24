<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\JadwalPenjemputan;
use Illuminate\Http\Request;

class ScheduleController extends Controller
{
    /**
     * Menyimpan jadwal penjemputan baru via API
     */
    public function store(Request $request)
    {
        $request->validate([
            'rute_id' => 'required|exists:rute,id',
            'driver_id' => 'required|exists:users,id',
            'hari' => 'required|in:senin,selasa,rabu,kamis,jumat,sabtu,minggu',
            'jam_mulai' => 'required',
            'jam_selesai' => 'required',
        ]);

        $schedule = JadwalPenjemputan::create($request->all());

        return response()->json([
            'status' => 'success',
            'message' => 'Jadwal penjemputan berhasil ditambahkan',
            'data' => $schedule->load(['rute', 'driver:id,nama']) // Load relasi agar frontend bisa langsung update UI
        ], 201);
    }

    /**
     * Mengupdate jadwal via API
     */
    public function update(Request $request, $id)
    {
        $schedule = JadwalPenjemputan::findOrFail($id);

        $request->validate([
            'rute_id' => 'required|exists:rute,id',
            'driver_id' => 'required|exists:users,id',
            'hari' => 'required|in:senin,selasa,rabu,kamis,jumat,sabtu,minggu',
            'jam_mulai' => 'required',
            'jam_selesai' => 'required',
        ]);

        $schedule->update($request->all());

        return response()->json([
            'status' => 'success',
            'message' => 'Jadwal berhasil diperbarui',
            'data' => $schedule->load(['rute', 'driver:id,nama'])
        ], 200);
    }

    /**
     * Menghapus jadwal via API
     */
    public function destroy($id)
    {
        $schedule = JadwalPenjemputan::findOrFail($id);
        $schedule->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Jadwal berhasil dihapus'
        ], 200);
    }
}
