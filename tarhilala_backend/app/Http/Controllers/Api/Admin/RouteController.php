<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Rute;
use Illuminate\Http\Request;

class RouteController extends Controller
{
    /**
     * Menyimpan rute baru via API
     */
    public function store(Request $request)
    {
        $request->validate([
            'nama_rute' => 'required|string|max:100',
            'wilayah' => 'required|string',
        ]);

        $route = Rute::create($request->all());

        return response()->json([
            'status' => 'success',
            'message' => 'Rute berhasil ditambahkan',
            'data' => $route
        ], 201);
    }

    /**
     * Mengupdate data rute via API
     */
    public function update(Request $request, $id)
    {
        $route = Rute::findOrFail($id);

        $request->validate([
            'nama_rute' => 'required|string|max:100',
            'wilayah' => 'required|string',
        ]);

        $route->update($request->all());

        return response()->json([
            'status' => 'success',
            'message' => 'Rute berhasil diperbarui',
            'data' => $route
        ], 200);
    }

    /**
     * Menghapus rute via API
     */
    public function destroy($id)
    {
        $route = Rute::findOrFail($id);
        $route->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Rute berhasil dihapus'
        ], 200);
    }
}
