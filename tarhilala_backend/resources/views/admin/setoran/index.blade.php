@extends('layouts.admin')

@section('content')
<!-- Container Utama x-data Alpine.js -->
<div x-data="{
    openEdit: false,
    currSetoran: { id: '', nasabah: '', status: '', berat_final: '', catatan: '', lat: '', lng: '' }
}">

    <div class="flex justify-between items-center mb-8">
        <h2 class="text-4xl font-bold text-gray-900">Pick-up Request</h2>
        <button class="flex items-center space-x-3 bg-[#41D3BD] hover:bg-opacity-80 text-black px-6 py-3 rounded-2xl transition-all shadow-sm">
            <i class="fa-solid fa-file-export text-xl font-bold"></i>
            <span class="text-lg font-bold">Export Report</span>
        </button>
    </div>

    @if(session('success'))
        <div class="mb-4 p-4 bg-green-100 text-green-700 rounded-2xl font-bold border border-green-200">
            {{ session('success') }}
        </div>
    @endif

    <!-- Table Container -->
    <div class="bg-white rounded-[2.5rem] shadow-sm border border-gray-100 relative overflow-hidden">
        <table class="w-full text-left">
            <thead class="bg-[#41D3BD]">
                <tr>
                    <th class="pl-20 py-6 text-black font-medium text-lg rounded-tl-[2.5rem]">Nasabah</th>
                    <th class="px-6 py-6 text-black font-medium text-lg text-center">Tgl Pengajuan</th>
                    <th class="px-6 py-6 text-black font-medium text-lg text-center">Estimasi</th>
                    <th class="px-6 py-6 text-black font-medium text-lg text-center">Metode</th>
                    <th class="px-6 py-6 text-black font-medium text-lg text-center">Status</th>
                    <th class="px-8 py-6 text-center rounded-tr-[2.5rem]">
                        <span class="bg-[#ffffff] px-5 py-1 rounded-lg text-xs font-bold text-black uppercase">Action</span>
                    </th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-100 text-black font-medium">
                @forelse($requests as $req)
                <tr class="hover:bg-gray-50/50 transition-all">
                    <td class="pl-20 py-6">
                        <div class="flex flex-col">
                            <span class="font-bold uppercase text-blue-600">{{ $req->nasabah->nama ?? 'User Terhapus' }}</span>
                            <span class="text-xs text-gray-400 font-normal">#ID-{{ $req->id }}</span>
                        </div>
                    </td>
                    <td class="px-6 py-6 text-center text-sm">
                        {{ \Carbon\Carbon::parse($req->tanggal_pengajuan)->format('d M Y') }}
                        <div class="text-[10px] text-gray-400 font-bold uppercase">{{ \Carbon\Carbon::parse($req->tanggal_pengajuan)->format('H:i') }} WIB</div>
                    </td>
                    <td class="px-6 py-6 text-center font-bold">{{ $req->estimasi_berat }} Kg</td>
                    <td class="px-6 py-6 text-center uppercase text-xs font-black">{{ $req->metode_pembayaran }}</td>
                    <td class="px-6 py-6 text-center">
                        <span class="px-4 py-1 rounded-full text-[10px] font-black uppercase
                            {{ $req->status == 'menunggu' ? 'bg-yellow-100 text-yellow-700' :
                               ($req->status == 'selesai' ? 'bg-green-100 text-green-700' :
                               ($req->status == 'dibatalkan' ? 'bg-red-100 text-red-700' : 'bg-blue-100 text-blue-700')) }}">
                            {{ str_replace('_', ' ', $req->status) }}
                        </span>
                    </td>
                    <td class="px-8 py-6 text-center relative" x-data="{ dropdown: false }">
                        <button @click="dropdown = !dropdown" class="text-blue-600 hover:text-blue-800 focus:outline-none">
                            <i class="fa-solid fa-ellipsis text-3xl"></i>
                        </button>
                        <!-- Dropdown Menu -->
                        <div x-show="dropdown" @click.away="dropdown = false" x-transition class="absolute right-0 mt-2 w-48 bg-white border border-gray-100 rounded-2xl shadow-xl z-[100] overflow-hidden text-left">
                            <button @click="currSetoran = {
                                id: '{{ $req->id }}',
                                nasabah: '{{ $req->nasabah->nama ?? 'Unknown' }}',
                                status: '{{ $req->status }}',
                                berat_final: '{{ $req->berat_final }}',
                                catatan: '{{ $req->catatan }}',
                                lat: '{{ $req->lokasi_lat }}',
                                lng: '{{ $req->lokasi_lng }}'
                            }; openEdit = true; dropdown = false" class="w-full text-left px-5 py-3 text-sm hover:bg-blue-50 flex items-center space-x-3">
                                <i class="fa-solid fa-pen-to-square text-blue-500"></i>
                                <span class="font-bold">Update Status</span>
                            </button>
                            <a href="https://www.google.com/maps?q={{ $req->lokasi_lat }},{{ $req->lokasi_lng }}" target="_blank" class="w-full block px-5 py-3 text-sm hover:bg-gray-50 flex items-center space-x-3 border-t">
                                <i class="fa-solid fa-map-location-dot text-red-500"></i>
                                <span class="font-bold">Lihat Lokasi</span>
                            </a>
                        </div>
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="6" class="py-20 text-center text-gray-400 font-bold italic">Belum ada request masuk hari ini.</td>
                </tr>
                @endforelse
            </tbody>
        </table>
        <div class="h-6"></div>
    </div>

    <!-- MODAL UPDATE STATUS SETORAN (DINAMIS) -->
    <div x-show="openEdit" class="fixed inset-0 z-[150] flex items-center justify-center bg-black bg-opacity-50 px-4" x-cloak>
        <div class="bg-white rounded-[2rem] max-w-lg w-full p-8 shadow-2xl" @click.away="openEdit = false">
            <h3 class="text-2xl font-bold mb-6 text-black uppercase tracking-tight">Update Request</h3>

            <form :action="'/admin/setoran/update/' + currSetoran.id" method="POST" class="space-y-4">
                @csrf
                @method('PUT')

                <div class="bg-gray-50 p-4 rounded-2xl border mb-2">
                    <p class="text-[10px] font-black text-gray-400 uppercase">Nama Nasabah</p>
                    <p class="text-blue-600 font-bold text-lg" x-text="currSetoran.nasabah"></p>
                    <p class="text-xs mt-2"><a :href="'https://www.google.com/maps?q=' + currSetoran.lat + ',' + currSetoran.lng" target="_blank" class="text-red-500 font-bold underline">Buka di Google Maps</a></p>
                </div>

                <div>
                    <label class="block text-xs font-black text-gray-400 uppercase mb-1">Status Penjemputan</label>
                    <select name="status" x-model="currSetoran.status" class="w-full px-4 py-2 border rounded-xl outline-none focus:ring-2 focus:ring-[#41D3BD] font-bold">
                        <option value="menunggu">MENUNGGU</option>
                        <option value="dijadwalkan">DIJADWALKAN</option>
                        <option value="dalam_penjemputan">DALAM PENJEMPUTAN</option>
                        <option value="selesai">SELESAI</option>
                        <option value="dibatalkan">DIBATALKAN</option>
                    </select>
                </div>

                <div>
                    <label class="block text-xs font-black text-gray-400 uppercase mb-1">Berat Final (Kg) - Isi Saat Selesai</label>
                    <input name="berat_final" type="number" step="0.01" x-model="currSetoran.berat_final" class="w-full px-4 py-2 border rounded-xl outline-none focus:ring-2 focus:ring-blue-400 font-bold">
                </div>

                <div>
                    <label class="block text-xs font-black text-gray-400 uppercase mb-1">Catatan Admin/Driver</label>
                    <textarea name="catatan" x-model="currSetoran.catatan" rows="3" class="w-full px-4 py-2 border rounded-xl outline-none focus:ring-2 focus:ring-blue-400"></textarea>
                </div>

                <div class="flex justify-end space-x-3 pt-4 border-t">
                    <button @click="openEdit = false" type="button" class="px-6 py-2 bg-gray-200 rounded-xl font-bold text-gray-700">Batal</button>
                    <button type="submit" class="px-6 py-2 bg-blue-600 rounded-xl font-bold text-white shadow-lg shadow-blue-200">Simpan Perubahan</button>
                </div>
            </form>
        </div>
    </div>
</div>

<style> [x-cloak] { display: none !important; } </style>
@endsection
