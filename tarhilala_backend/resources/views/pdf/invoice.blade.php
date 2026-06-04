<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
@font-face {
    font-family: 'Jakarta';
    src: url('{{ public_path("fonts/PlusJakartaSans-Regular.ttf") }}') format('truetype');
}

* { box-sizing: border-box; margin: 0; padding: 0; }

body {
    font-family: 'Jakarta', 'Segoe UI', sans-serif;
    font-size: 12px;
    color: #1e2d3d;
    background: #f4f6f9;
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;
}

.page {
    width: 794px;
    min-height: 1123px;
    margin: 0 auto;
    background: #fff;
    padding: 0;
    position: relative;
}

/* TOP ACCENT */
.top-accent {
    height: 5px;
    background: #2e7d6b;
}

/* HEADER */
.header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    padding: 36px 48px 28px;
    border-bottom: 1px solid #e8ecf0;
}

.invoice-title {
    font-size: 28px;
    font-weight: 700;
    letter-spacing: 6px;
    color: #1e2d3d;
    text-transform: uppercase;
}

.invoice-number {
    font-size: 12px;
    color: #6b7f94;
    margin-top: 6px;
    letter-spacing: 0.5px;
}

.right-info {
    text-align: right;
}

.right-info .label {
    font-size: 9px;
    font-weight: 700;
    letter-spacing: 2px;
    text-transform: uppercase;
    color: #2e7d6b;
    margin-bottom: 6px;
}

.right-info .name {
    font-size: 14px;
    font-weight: 700;
    color: #1e2d3d;
}

.right-info .detail {
    font-size: 11px;
    color: #6b7f94;
    margin-top: 3px;
    line-height: 1.7;
}

/* TABLE */
.table-section {
    padding: 32px 48px 0;
}

table.main-table {
    width: 100%;
    border-collapse: collapse;
}

table.main-table thead tr {
    background: #1e2d3d;
}

table.main-table thead th {
    padding: 11px 16px;
    font-size: 9px;
    font-weight: 700;
    letter-spacing: 1.8px;
    text-transform: uppercase;
    color: #8fa5b8;
    text-align: left;
}

table.main-table thead th.text-right {
    text-align: right;
}

table.main-table tbody tr {
    border-bottom: 1px solid #f0f3f6;
}

table.main-table tbody tr:last-child {
    border-bottom: none;
}

table.main-table tbody td {
    padding: 14px 16px;
    vertical-align: middle;
}

.item-name {
    font-weight: 600;
    font-size: 12px;
    color: #1e2d3d;
}

.item-sub {
    font-size: 10px;
    color: #9aafbf;
    margin-top: 2px;
}

.text-right {
    text-align: right;
}

.cell-muted {
    color: #4a6070;
    font-size: 12px;
}

.cell-bold {
    font-weight: 600;
    color: #1e2d3d;
}

.table-border {
    border: 1px solid #e8ecf0;
    border-radius: 8px;
    overflow: hidden;
}

/* SUMMARY */
.summary-section {
    padding: 20px 48px 0;
    display: flex;
    justify-content: flex-end;
}

.summary-box {
    width: 280px;
}

.summary-row {
    display: flex;
    justify-content: space-between;
    padding: 7px 0;
    font-size: 12px;
    color: #4a6070;
    border-bottom: 1px solid #f0f3f6;
}

.summary-row:last-child {
    border-bottom: none;
}

.grand-total-box {
    background: #1e2d3d;
    border-radius: 8px;
    padding: 14px 18px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-top: 10px;
}

.grand-total-box .gt-label {
    font-size: 10px;
    font-weight: 700;
    letter-spacing: 1.5px;
    text-transform: uppercase;
    color: #8fa5b8;
}

.grand-total-box .gt-amount {
    font-size: 18px;
    font-weight: 700;
    color: #4ecba3;
}

/* FOOTER */
.footer {
    padding: 32px 48px 0;
}

.footer-label {
    font-size: 9px;
    font-weight: 700;
    letter-spacing: 2px;
    text-transform: uppercase;
    color: #2e7d6b;
    margin-bottom: 6px;
}

.footer-name {
    font-size: 13px;
    font-weight: 700;
    color: #1e2d3d;
}

.footer-note {
    font-size: 11px;
    color: #9aafbf;
    margin-top: 3px;
}

/* BOTTOM BAR */
.bottom-bar {
    position: absolute;
    bottom: 0;
    left: 0;
    right: 0;
    height: 48px;
    background: #f4f6f9;
    border-top: 1px solid #e8ecf0;
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0 48px;
}

.bottom-bar span {
    font-size: 10px;
    color: #9aafbf;
    letter-spacing: 0.5px;
}

@media print {
    body { background: white; }
    .page { box-shadow: none; }
}
</style>
</head>

<body>
<div class="page">

    <div class="top-accent"></div>

    <!-- HEADER -->
    <div class="header">
        <div>
            <div class="invoice-title">Invoice</div>
            <div class="invoice-number">No. {{ $setoran->invoice->nomor_invoice }}</div>
        </div>
        <div class="right-info">
            <div class="label">Kepada</div>
            <div class="name">{{ strtoupper($setoran->nasabah->nama) }}</div>
            <div class="detail">
                {{ $setoran->nasabah->nomor_telepon ?? '—' }}<br>
                {{ \Carbon\Carbon::parse($setoran->tanggal_pengajuan)->format('d M Y') }}
            </div>
        </div>
    </div>

    <!-- TABLE -->
    <div class="table-section">
        <div class="table-border">
            <table class="main-table">
                <thead>
                    <tr>
                        <th>Deskripsi Barang</th>
                        <th class="text-right">Harga Satuan</th>
                        <th class="text-right">Berat</th>
                        <th class="text-right">Total</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach($setoran->details as $item)
                    <tr>
                        <td>
                            <div class="item-name">{{ strtoupper($item->jenisSampah->nama) }}</div>
                            <div class="item-sub">Setoran sampah</div>
                        </td>
                        <td class="text-right cell-muted">Rp {{ number_format($item->harga_satuan) }}</td>
                        <td class="text-right cell-muted">{{ $item->berat }} kg</td>
                        <td class="text-right cell-bold">Rp {{ number_format($item->subtotal) }}</td>
                    </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    </div>

    <!-- SUMMARY -->
    <div class="summary-section">
        <div class="summary-box">
            <div class="summary-row">
                <span>Total</span>
                <span>Rp {{ number_format($setoran->total_harga) }}</span>
            </div>
            <div class="summary-row">
                <span>Pajak 0%</span>
                <span>Rp 0</span>
            </div>
            <div class="grand-total-box">
                <span class="gt-label">Total Keseluruhan</span>
                <span class="gt-amount">Rp {{ number_format($setoran->total_harga) }}</span>
            </div>
        </div>
    </div>

    <!-- FOOTER -->
    <div class="footer">
        <div class="footer-label">Dibayarkan Oleh</div>
        <div class="footer-name">Bank Sampah Tarhilala</div>
        <div class="footer-note">Pembayaran menggunakan sistem digital</div>
    </div>

    <!-- BOTTOM BAR -->
    <div class="bottom-bar">
        <span>Bank Sampah Tarhilala</span>
        <span>{{ \Carbon\Carbon::parse($setoran->tanggal_pengajuan)->format('d M Y') }}</span>
    </div>

</div>
</body>
</html>
