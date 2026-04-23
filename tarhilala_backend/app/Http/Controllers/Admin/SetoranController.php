<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class SetoranController extends Controller
{
    public function index()
{
    // Ambil data terbaru berdasarkan tanggal pengajuan
    $requests = \App\Models\Setoran::with('nasabah')
                ->orderBy('tanggal_pengajuan', 'desc')
                ->get();

    return view('admin.setoran.index', compact('requests'));
}
}
