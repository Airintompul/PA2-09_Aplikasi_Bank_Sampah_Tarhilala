<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">

<style>
@font-face {
    font-family: 'Jakarta';
    src: url('{{ public_path("fonts/PlusJakartaSans-Regular.ttf") }}') format('truetype');
}

body {
    font-family: 'Jakarta', sans-serif;
    font-size: 12px;
    color: #333;
    margin: 0;
    padding: 0;
    background: #f9fbfc;
}

/* CONTAINER */
.container {
    padding: 40px;
    position: relative;
}

/* HEADER */
.header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
}

.invoice-title {
    font-size: 32px;
    letter-spacing: 5px;
    font-weight: bold;
}

.invoice-number {
    color: #777;
    margin-top: 5px;
}

/* RIGHT INFO */
.right-info {
    text-align: right;
}

.right-info h4 {
    margin-bottom: 5px;
    font-size: 10px;
    color: #777;
    letter-spacing: 1px;
}

.right-info p {
    margin: 2px 0;
}

/* TABLE */
.table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 40px;
}

.table thead {
    background: #cfe3ea;
}

.table th {
    padding: 12px;
    font-size: 11px;
    text-align: left;
    letter-spacing: 1px;
}

.table td {
    padding: 12px;
    border-bottom: 1px solid #eee;
}

.text-right {
    text-align: right;
}

/* ITEM DESCRIPTION */
.desc-title {
    font-weight: bold;
}

.desc-sub {
    font-size: 10px;
    color: #888;
}

/* TOTAL */
.summary {
    width: 100%;
    margin-top: 20px;
}

.summary-table {
    width: 40%;
    float: right;
}

.summary-table td {
    padding: 8px;
}

.grand-total {
    background: #cfe3ea;
    font-weight: bold;
}

/* FOOTER */
.footer {
    margin-top: 80px;
}

.footer small {
    color: #777;
}

/* BACKGROUND WAVE (SIMPLIFIED) */
.bg-wave {
    position: absolute;
    bottom: 0;
    left: 0;
    opacity: 0.08;
    width: 100%;
}

</style>
</head>

<body>

<div class="container">

    <!-- HEADER -->
    <div class="header">
        <div>
            <div class="invoice-title">INVOICE</div>
            <div class="invoice-number">
                No. {{ $setoran->invoice->nomor_invoice }}
            </div>
        </div>

        <div class="right-info">
            <h4>KEPADA</h4>
            <p><strong>{{ strtoupper($setoran->nasabah->nama) }}</strong></p>
            <p>{{ $setoran->nasabah->nomor_telepon ?? '-' }}</p>
            <p>{{ \Carbon\Carbon::parse($setoran->tanggal_pengajuan)->format('d M Y') }}</p>
        </div>
    </div>

    <!-- TABLE -->
    <table class="table">
        <thead>
        <tr>
            <th>DESKRIPSI BARANG</th>
            <th class="text-right">HARGA</th>
            <th class="text-right">JUMLAH</th>
            <th class="text-right">TOTAL</th>
        </tr>
        </thead>

        <tbody>
        @foreach($setoran->details as $item)
        <tr>
            <td>
                <div class="desc-title">{{ strtoupper($item->jenisSampah->nama) }}</div>
                <div class="desc-sub">Setoran sampah</div>
            </td>
            <td class="text-right">Rp {{ number_format($item->harga_satuan) }}</td>
            <td class="text-right">{{ $item->berat }}</td>
            <td class="text-right">Rp {{ number_format($item->subtotal) }}</td>
        </tr>
        @endforeach
        </tbody>
    </table>

    <!-- SUMMARY -->
    <div class="summary">
        <table class="summary-table">
            <tr>
                <td>TOTAL</td>
                <td class="text-right">Rp {{ number_format($setoran->total_harga) }}</td>
            </tr>
            <tr>
                <td>PAJAK 0%</td>
                <td class="text-right">Rp 0</td>
            </tr>
            <tr class="grand-total">
                <td>TOTAL KESELURUHAN</td>
                <td class="text-right">Rp {{ number_format($setoran->total_harga) }}</td>
            </tr>
        </table>
    </div>

    <div style="clear: both;"></div>

    <!-- FOOTER -->
    <div class="footer">
        <small>Dibayarkan kepada:</small>
        <p><strong>Bank Sampah Tarhilala</strong></p>
        <small>Pembayaran menggunakan sistem digital</small>
    </div>

</div>

</body>
</html>
