<?php

namespace App\Exports;

use App\Models\Penarikan;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;

class PenarikanExport implements FromCollection, WithHeadings, WithMapping
{
    public function collection()
    {
        // Mengambil data penarikan terbaru
        return Penarikan::orderBy('tanggal_pengajuan', 'desc')->get();
    }

    public function headings(): array
    {
        return [
            'ID Transaksi',
            'User ID',
            'Jumlah (IDR)',
            'Metode Transfer',
            'Nomor Tujuan',
            'Nama Penerima',
            'Status',
            'Tanggal Pengajuan'
        ];
    }

    public function map($wd): array
    {
        return [
            '#WD-' . $wd->id,
            $wd->user_id,
            $wd->jumlah,
            strtoupper($wd->metode),
            " " . $wd->nomor_tujuan, 
            $wd->nama_penerima,
            strtoupper($wd->status),
            $wd->tanggal_pengajuan,
        ];
    }
}
