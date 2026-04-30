<!DOCTYPE html>
<html>
<head>
    <title>Invoice Tarhilala</title>
    <style>
        body { font-family: sans-serif; color: #333; }
        .header { text-align: center; border-bottom: 2px solid #41D3BD; padding-bottom: 10px; }
        .invoice-box { padding: 20px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th { background: #f2f2f2; padding: 10px; text-align: left; }
        td { padding: 10px; border-bottom: 1px solid #eee; }
        .total-box { margin-top: 30px; text-align: right; }
        .footer { margin-top: 50px; font-size: 10px; text-align: center; color: #999; }
    </style>
</head>
<body>
    <div class="header">
        <h1>INVOICE SETORAN</h1>
        <p>Bank Sampah Tarhilala</p>
    </div>

    <div class="invoice-box">
        <p><strong>No. Invoice:</strong> {{ $setoran->invoice->nomor_invoice }}</p>
        <p><strong>Nama Nasabah:</strong> {{ $setoran->nasabah->nama }}</p>
        <p><strong>Tanggal:</strong> {{ $setoran->tanggal_pengajuan }}</p>
        <p><strong>Metode:</strong> {{ strtoupper($setoran->metode_pembayaran) }}</p>

        <table>
            <thead>
                <tr>
                    <th>Jenis Sampah</th>
                    <th>Berat (Kg)</th>
                    <th>Harga/Kg</th>
                    <th>Subtotal</th>
                </tr>
            </thead>
            <tbody>
                @foreach($setoran->details as $item)
                <tr>
                    <td>{{ $item->jenisSampah->nama }}</td>
                    <td>{{ $item->berat }}</td>
                    <td>Rp {{ number_format($item->harga_satuan) }}</td>
                    <td>Rp {{ number_format($item->subtotal) }}</td>
                </tr>
                @endforeach
            </tbody>
        </table>

        <div class="total-box">
            <h3>Total Berat: {{ $setoran->berat_final }} Kg</h3>
            <h2>Total Diterima: Rp {{ number_format($setoran->total_harga) }}</h2>
        </div>
    </div>

    <div class="footer">
        Terima kasih telah berkontribusi menjaga kebersihan lingkungan bersama Tarhilala.
    </div>
</body>
</html>
