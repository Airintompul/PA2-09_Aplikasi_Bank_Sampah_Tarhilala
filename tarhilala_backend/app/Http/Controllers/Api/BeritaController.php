<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\KontenEdukasi;

class BeritaController extends Controller
{
    public function index()
    {
        $berita = KontenEdukasi::latest()->take(5)->get();

        return response()->json([
            'status' => true,
            'data' => $berita
        ]);
    }
}
