<?php
namespace App\Exports;

use App\Models\Setoran;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;

class SetoranExport implements FromCollection, WithHeadings, WithMapping
{
    public function collection()
    {
        // Ambil data beserta relasinya agar Excel lengkap
        return Setoran::with(['nasabah', 'jadwal.driver'])->get();
    }

    // Baris Judul Excel
    public function headings(): array
    {
        return ["ID", "Nama Nasabah", "Berat (Kg)", "Harga Total", "Petugas", "Status", "Tanggal"];
    }

    // Mapping data ke kolom
    public function map($setoran): array
    {
        return [
            $setoran->id,
            $setoran->nasabah->nama ?? 'N/A',
            $setoran->berat_final ?? $setoran->estimasi_berat,
            $setoran->total_harga,
            $setoran->jadwal->driver->nama ?? '-',
            $setoran->status,
            $setoran->tanggal_pengajuan,
        ];
    }
}
