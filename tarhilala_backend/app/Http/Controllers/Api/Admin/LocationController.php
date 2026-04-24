<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Rute;
use App\Models\JadwalPenjemputan;
use App\Models\User;
use Illuminate\Http\Request;

class LocationController extends Controller
{
    /**
     * Memuat semua data untuk halaman Location (Rute, Jadwal, dan List Driver)
     */
    public function index()
    {
        $routes = Rute::all();

        $schedules = JadwalPenjemputan::with(['rute', 'driver:id,nama'])
            ->orderBy('hari', 'asc')
            ->get();

        // List driver untuk keperluan dropdown saat tambah/edit jadwal
        $drivers = User::where('role', 'petugas')
            ->select('id', 'nama')
            ->get();

        return response()->json([
            'status' => 'success',
            'message' => 'Data lokasi dan jadwal berhasil dimuat',
            'data' => [
                'routes' => $routes,
                'schedules' => $schedules,
                'drivers' => $drivers
            ]
        ], 200);
    }

    /**
     * CRUD RUTE
     */
    public function storeRoute(Request $request)
    {
        $request->validate([
            'nama_rute' => 'required|string|max:100',
            'wilayah' => 'required|string'
        ]);

        $route = Rute::create($request->all());
        return response()->json(['status' => 'success', 'data' => $route], 201);
    }

    public function updateRoute(Request $request, $id)
    {
        $route = Rute::findOrFail($id);
        $route->update($request->all());
        return response()->json(['status' => 'success', 'data' => $route], 200);
    }

    public function destroyRoute($id)
    {
        Rute::findOrFail($id)->delete();
        return response()->json(['status' => 'success', 'message' => 'Rute berhasil dihapus'], 200);
    }

    /**
     * CRUD JADWAL
     */
    public function storeSchedule(Request $request)
    {
        $request->validate([
            'rute_id' => 'required|exists:rute,id',
            'driver_id' => 'required|exists:users,id',
            'hari' => 'required|in:senin,selasa,rabu,kamis,jumat,sabtu,minggu',
            'jam_mulai' => 'required',
            'jam_selesai' => 'required'
        ]);

        $schedule = JadwalPenjemputan::create($request->all());
        return response()->json(['status' => 'success', 'data' => $schedule], 201);
    }

    public function updateSchedule(Request $request, $id)
    {
        $schedule = JadwalPenjemputan::findOrFail($id);
        $schedule->update($request->all());
        return response()->json(['status' => 'success', 'data' => $schedule], 200);
    }

    public function destroySchedule($id)
    {
        JadwalPenjemputan::findOrFail($id)->delete();
        return response()->json(['status' => 'success', 'message' => 'Jadwal berhasil dihapus'], 200);
    }
}
