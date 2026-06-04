<script setup>
import AdminLayout from '@/Layouts/AdminLayout.vue';
import { ref, onMounted, computed } from 'vue';
import api from '@/api';

// --- STATE DATA ---
const requests = ref([]);
const jadwalList = ref([]);
const isLoading = ref(true);
const successMessage = ref('');
const openEdit = ref(false);

const currSetoran = ref({
    id: '', nasabah: '', status: '', jadwal_id: '', berat_final: '', catatan: '',
    ai: { class: '', confidence: 0, image: '', is_correct: null, admin_class: '' }
});

// --- LOGIC HIDE NAVBAR (TAMBAHAN) ---
const isAnyModalOpen = computed(() => {
    return openEdit.value;
});

// --- COMPUTED ---
const isLocked = computed(() => {
    return currSetoran.value.status === 'selesai' || currSetoran.value.status === 'dibatalkan';
});

// --- LOGIC (TETAP SAMA) ---
const fetchRequests = async () => {
    try {
        const response = await api.get('/setoran');
        requests.value = response.data.data;
    } catch (error) { console.error("Gagal ambil data"); }
    finally { isLoading.value = false; }
};

const fetchJadwal = async () => {
    try {
        const response = await api.get('/location');
        jadwalList.value = response.data.data.schedules;
    } catch (error) { console.error("Gagal muat jadwal"); }
};

const downloadInvoice = async (id) => {
    try {
        const response = await api.get(`/setoran/${id}/invoice`, { responseType: 'blob' });
        const url = window.URL.createObjectURL(new Blob([response.data]));
        const link = document.createElement('a');
        link.href = url;
        link.setAttribute('download', `Invoice-SET-${id}.pdf`);
        document.body.appendChild(link);
        link.click();
        link.remove();
    } catch (error) { alert("Invoice belum tersedia."); }
};

const handleUpdate = async () => {
    if (isLocked.value) return;
    try {
        await api.put(`/setoran/${currSetoran.value.id}`, {
            status: currSetoran.value.status,
            jadwal_id: currSetoran.value.jadwal_id,
            berat_final: currSetoran.value.berat_final,
            catatan: currSetoran.value.catatan
        });
        if (currSetoran.value.ai.is_correct !== null) {
            await api.post(`/setoran/${currSetoran.value.id}/verify-ai`, {
                is_correct: currSetoran.value.ai.is_correct,
                admin_class: currSetoran.value.ai.admin_class
            });
        }
        openEdit.value = false;
        showSuccess("Data Berhasil Diperbarui!");
        fetchRequests();
    } catch (error) { alert("Terjadi kesalahan."); }
};

const openEditModal = (req) => {
    currSetoran.value = {
        id: req.id, nasabah: req.nasabah?.nama || 'N/A', status: req.status,
        jadwal_id: req.jadwal_id || '', berat_final: req.berat_final, catatan: req.catatan,
        ai: {
            class: req.ai_validation?.ai_class || 'N/A',
            confidence: req.ai_validation?.ai_confidence || 0,
            image: req.ai_validation?.image_path || '',
            is_correct: req.ai_validation?.is_correct,
            admin_class: req.ai_validation?.admin_class || ''
        }
    };
    openEdit.value = true;
};

const showSuccess = (msg) => {
    successMessage.value = msg;
    setTimeout(() => successMessage.value = '', 3000);
};

const formatDateTime = (dateTime) => {
    if (!dateTime) return { d: '-', t: '-' };
    const date = new Date(dateTime);
    return {
        d: date.toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' }),
        t: date.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })
    };
};

// Tambahkan ref isExporting di bagian atas bersama state lainnya
const isExporting = ref(false);

// Tambahkan fungsi ini untuk menangani download Excel
const handleExportExcel = async () => {
    isExporting.value = true;
    try {
        const response = await api.get('/setoran/export', {
            responseType: 'blob' // Wajib untuk mendownload file binary
        });

        // Membuat URL sementara untuk file Excel
        const url = window.URL.createObjectURL(new Blob([response.data]));
        const link = document.createElement('a');
        link.href = url;

        // Penamaan file yang akan diunduh
        link.setAttribute('download', `Laporan_Penjemputan_${new Date().toLocaleDateString()}.xlsx`);

        document.body.appendChild(link);
        link.click();
        link.remove();

        showSuccess("Laporan Excel berhasil diunduh!");
    } catch (error) {
        console.error("Gagal export excel:", error);
        alert("Gagal mengunduh laporan Excel.");
    } finally {
        isExporting.value = false;
    }
};

onMounted(() => { fetchRequests(); fetchJadwal(); });
</script>

<template>
    <AdminLayout :hideNavbar="isAnyModalOpen">
        <!-- Header Page -->
        <div :class="{'blur-sm pointer-events-none': isAnyModalOpen}" class="transition-all duration-300 flex flex-col md:flex-row justify-between items-start md:items-center mb-8 gap-4 px-2 md:px-0">
            <h2 class="text-2xl md:text-4xl font-black text-gray-900 uppercase tracking-tight leading-none">Daftar <span class="text-[#41D3BD]">Penjemputan</span></h2>
            <button
                @click="handleExportExcel"
                :disabled="isExporting"
                class="w-full md:w-auto flex items-center justify-center space-x-3 bg-[#41D3BD] hover:opacity-80 text-black px-8 py-4 rounded-2xl md:rounded-[2rem] transition-all shadow-lg font-black uppercase text-xs md:text-sm tracking-widest disabled:opacity-50 disabled:cursor-not-allowed"
            >
                <!-- Icon berubah jadi spinner saat loading -->
                <i v-if="!isExporting" class="fa-solid fa-file-excel text-lg"></i>
                <i v-else class="fa-solid fa-circle-notch animate-spin text-lg"></i>

                <!-- Teks berubah saat loading -->
                <span>{{ isExporting ? 'Memproses...' : 'Ekspor Laporan' }}</span>
            </button>
        </div>

        <!-- Alert -->
        <div v-if="successMessage && !isAnyModalOpen" class="mx-2 md:mx-0 mb-6 p-4 md:p-5 bg-black text-[#41D3BD] rounded-2xl md:rounded-3xl font-black shadow-xl flex items-center border-l-8 border-[#41D3BD] text-xs md:text-sm">
            <i class="fa-solid fa-circle-check text-xl md:text-2xl mr-4"></i> {{ successMessage }}
        </div>

        <!-- 1. VIEW DESKTOP: TABEL (TETAP SAMA) -->
        <div :class="{'blur-sm pointer-events-none': isAnyModalOpen}" class="hidden lg:block bg-white rounded-[2.5rem] shadow-sm border border-gray-100 relative overflow-hidden transition-all duration-300">
            <table class="w-full text-left border-collapse">
                <thead class="bg-[#41D3BD]">
                    <tr class="text-black font-black uppercase text-[11px] tracking-widest">
                        <th class="pl-12 py-7">Nasabah</th>
                        <th class="px-6 py-7 text-center">Hasil AI</th>
                        <th class="px-6 py-7 text-center">Tgl Pengajuan</th>
                        <th class="px-6 py-7 text-center">Estimasi</th>
                        <th class="px-6 py-7 text-center">Petugas</th>
                        <th class="px-6 py-7 text-center">Status</th>
                        <th class="pr-12 py-7 text-right">Aksi</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-50">
                    <tr v-for="req in requests" :key="req.id" class="hover:bg-gray-50/50 transition-all">
                        <td class="pl-12 py-6">
                            <div class="flex flex-col">
                                <span class="font-black text-lg uppercase text-blue-600 tracking-tighter leading-none">{{ req.nasabah?.nama }}</span>
                                <span class="text-[10px] text-gray-400 font-bold uppercase mt-1">ID: #SET-{{ req.id }}</span>
                            </div>
                        </td>
                        <td class="px-6 py-6 text-center">
                            <div v-if="req.ai_validation" class="flex flex-col">
                                <span class="font-black text-xs text-gray-700 uppercase">{{ req.ai_validation.ai_class }}</span>
                                <span class="text-[9px] text-[#41D3BD] font-black uppercase">{{ (req.ai_validation.ai_confidence * 100).toFixed(0) }}% Akurasi</span>
                            </div>
                            <span v-else class="text-gray-300 italic text-xs">Tanpa Scan</span>
                        </td>
                        <td class="px-6 py-6 text-center">
                            <div class="font-bold text-xs">{{ formatDateTime(req.tanggal_pengajuan).d }}</div>
                            <div class="text-[9px] text-gray-400 font-black">{{ formatDateTime(req.tanggal_pengajuan).t }} WIB</div>
                        </td>
                        <td class="px-6 py-6 text-center font-black text-slate-700">{{ req.estimasi_berat }} Kg</td>
                        <td class="px-6 py-6 text-center font-black text-xs text-blue-700 uppercase">{{ req.jadwal?.driver?.nama || '-' }}</td>
                        <td class="px-6 py-6 text-center">
                            <span class="px-4 py-1.5 rounded-full text-[9px] font-black uppercase tracking-widest border shadow-sm"
                                :class="{'bg-yellow-50 text-yellow-600 border-yellow-100': req.status === 'menunggu', 'bg-green-50 text-green-600 border-green-100': req.status === 'selesai', 'bg-red-50 text-red-600 border-red-100': req.status === 'dibatalkan', 'bg-blue-50 text-blue-600 border-blue-100': ['dijadwalkan', 'dalam_penjemputan'].includes(req.status)}">{{ req.status.replace('_', ' ') }}</span>
                        </td>
                        <td class="pr-12 py-6 text-right">
                            <div class="flex justify-end space-x-2">
                                <button v-if="req.status === 'selesai'" @click="downloadInvoice(req.id)" class="w-10 h-10 bg-purple-50 text-purple-600 rounded-xl hover:bg-purple-600 shadow-sm transition-all flex items-center justify-center"><i class="fa-solid fa-file-invoice"></i></button>
                                <button @click="openEditModal(req)" class="w-10 h-10 rounded-xl shadow-sm flex items-center justify-center transition-all" :class="req.status === 'selesai' || req.status === 'dibatalkan' ? 'bg-gray-100 text-gray-400' : 'bg-blue-50 text-blue-600 hover:bg-blue-600 hover:text-white'"><i :class="req.status === 'selesai' || req.status === 'dibatalkan' ? 'fa-solid fa-eye' : 'fa-solid fa-pen-nib'"></i></button>
                                <router-link v-if="req.status !== 'selesai' && req.status !== 'dibatalkan'" :to="'/setoran/' + req.id + '/tracking'" class="w-10 h-10 bg-teal-50 text-[#41D3BD] rounded-xl hover:bg-[#41D3BD] hover:text-white flex items-center justify-center shadow-sm transition-all"><i class="fa-solid fa-map-location-dot"></i></router-link>
                            </div>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>

        <!-- 2. VIEW MOBILE: CARDS (TETAP SAMA) -->
        <div :class="{'blur-sm pointer-events-none': isAnyModalOpen}" class="lg:hidden space-y-4 px-2 pb-10 transition-all duration-300">
            <div v-for="req in requests" :key="req.id" class="bg-white p-5 rounded-[2rem] shadow-sm border border-gray-100 space-y-4">
                <div class="flex justify-between items-start">
                    <div class="min-w-0">
                        <h4 class="font-black text-blue-600 uppercase text-sm truncate pr-2">{{ req.nasabah?.nama }}</h4>
                        <p class="text-[9px] font-bold text-gray-400 uppercase">#SET-{{ req.id }}</p>
                    </div>
                    <span class="px-2 py-0.5 rounded-full font-black text-[8px] uppercase tracking-widest border"
                        :class="{'bg-yellow-50 text-yellow-600 border-yellow-100': req.status === 'menunggu', 'bg-green-50 text-green-600 border-green-100': req.status === 'selesai', 'bg-red-50 text-red-600 border-red-100': req.status === 'dibatalkan', 'bg-blue-50 text-blue-600 border-blue-100': ['dijadwalkan', 'dalam_penjemputan'].includes(req.status)}">{{ req.status }}</span>
                </div>
                <div class="flex-1 flex space-x-2">
                    <button @click="openEditModal(req)" class="flex-1 py-3 bg-blue-600 text-white rounded-xl font-black text-[10px] uppercase shadow-sm"> {{ (req.status === 'selesai' || req.status === 'dibatalkan') ? 'Lihat Detail' : 'Kelola' }} </button>
                    <router-link v-if="req.status !== 'selesai' && req.status !== 'dibatalkan'" :to="'/setoran/' + req.id + '/tracking'" class="w-12 h-12 bg-teal-50 text-[#41D3BD] rounded-xl flex items-center justify-center border border-teal-100"><i class="fa-solid fa-map-location-dot"></i></router-link>
                    <button v-if="req.status === 'selesai'" @click="downloadInvoice(req.id)" class="w-12 h-12 bg-purple-50 text-purple-600 rounded-xl flex items-center justify-center border border-purple-100"><i class="fa-solid fa-file-invoice"></i></button>
                </div>
            </div>
        </div>

        <!-- MODAL: DIPERKECIL UKURANNYA (max-w-4xl) AGAR GAK NABRAK SIDEBAR -->
        <div v-if="openEdit" class="fixed inset-0 z-[100] flex items-center justify-center bg-black/40 backdrop-blur-sm px-4 transition-all">
            <div class="bg-white rounded-[2.5rem] md:rounded-[3.5rem] max-w-4xl w-full p-6 md:p-10 shadow-2xl relative max-h-[90vh] overflow-y-auto border-[6px] md:border-[10px] border-slate-900">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-8 md:gap-12">
                    <!-- KIRI: AI INFO -->
                    <div class="space-y-4 md:space-y-6">
                        <h3 class="text-lg md:text-2xl font-black text-blue-600 uppercase tracking-widest border-b-4 border-[#41D3BD] inline-block pb-1">Bukti Foto & AI</h3>
                        <div class="w-full aspect-video bg-slate-100 rounded-2xl overflow-hidden border-2 border-gray-100 shadow-lg relative">
                            <img :src="'/storage/' + currSetoran.ai.image" class="w-full h-full object-cover">
                        </div>
                        <div class="bg-blue-50 p-4 rounded-2xl border border-blue-100">
                            <p class="text-[8px] md:text-[10px] font-black text-blue-400 uppercase mb-1">Analisa AI</p>
                            <p class="text-lg md:text-xl font-black text-blue-800 uppercase leading-none">{{ currSetoran.ai.class }} ({{ (currSetoran.ai.confidence * 100).toFixed(0) }}%)</p>
                        </div>
                        <div class="space-y-3">
                            <p class="text-[9px] md:text-[11px] font-black text-gray-400 uppercase tracking-widest ml-2">Validasi Admin</p>
                            <div class="flex space-x-2 md:space-x-4">
                                <button :disabled="isLocked" @click="currSetoran.ai.is_correct = 1" :class="currSetoran.ai.is_correct === 1 ? 'bg-green-500 text-white shadow-lg' : 'bg-gray-100 text-gray-400'" class="flex-1 py-3 md:py-4 rounded-xl md:rounded-2xl font-black uppercase text-[10px] transition-all">Sesuai</button>
                                <button :disabled="isLocked" @click="currSetoran.ai.is_correct = 0" :class="currSetoran.ai.is_correct === 0 ? 'bg-red-500 text-white shadow-lg' : 'bg-gray-100 text-gray-400'" class="flex-1 py-3 md:py-4 rounded-xl md:rounded-2xl font-black uppercase text-[10px] transition-all">Salah</button>
                            </div>
                        </div>
                    </div>

                    <!-- KANAN: OPERATIONAL -->
                    <div class="space-y-4 md:space-y-6">
                        <h3 class="text-lg md:text-2xl font-black text-blue-600 uppercase tracking-widest border-b-4 border-[#41D3BD] inline-block pb-1">Detail Operasional</h3>
                        <form @submit.prevent="handleUpdate" class="space-y-4 md:space-y-5">
                            <div class="space-y-1">
                                <label class="text-[9px] md:text-[11px] font-black text-gray-400 uppercase tracking-widest ml-2">Penugasan Petugas</label>
                                <select :disabled="isLocked" v-model="currSetoran.jadwal_id" class="w-full px-5 py-4 md:py-5 bg-gray-50 border-none rounded-xl md:rounded-[2rem] outline-none font-black text-slate-800 uppercase text-[10px] md:text-xs">
                                    <option value="">-- PILIH PETUGAS --</option>
                                    <option v-for="jadwal in jadwalList" :key="jadwal.id" :value="jadwal.id">{{ jadwal.driver?.nama }} - {{ jadwal.hari }}</option>
                                </select>
                            </div>
                            <div class="space-y-1">
                                <label class="text-[9px] md:text-[11px] font-black text-gray-400 uppercase tracking-widest ml-2">Status Penjemputan</label>
                                <select :disabled="isLocked" v-model="currSetoran.status" class="w-full px-5 py-4 md:py-5 bg-gray-50 border-none rounded-xl md:rounded-[2rem] font-black text-slate-800 uppercase text-[10px] md:text-xs">
                                    <option value="menunggu">DAFTAR TUNGGU</option>
                                    <option value="dijadwalkan">DIJADWALKAN</option>
                                    <option value="dalam_penjemputan">DALAM PERJALANAN</option>
                                    <option value="selesai">SELESAI</option>
                                    <option value="dibatalkan">DIBATALKAN</option>
                                </select>
                            </div>
                            <div class="space-y-1">
                                <label class="text-[9px] md:text-[11px] font-black text-gray-400 uppercase tracking-widest ml-2">Berat Terverifikasi (Kg)</label>
                                <input :disabled="isLocked" v-model="currSetoran.berat_final" type="number" step="0.01" class="w-full px-5 py-4 md:py-5 bg-gray-50 border-none rounded-xl md:rounded-[2rem] font-black text-blue-600 text-lg md:text-xl">
                            </div>
                            <div class="flex flex-col-reverse md:flex-row justify-end gap-3 pt-6 border-t">
                                <button @click="openEdit = false" type="button" class="w-full md:w-auto px-8 py-4 bg-gray-100 rounded-full font-black text-gray-400 uppercase text-[10px] tracking-widest">Tutup</button>
                                <button v-if="!isLocked" type="submit" class="w-full md:w-auto px-10 py-4 bg-slate-900 text-[#41D3BD] rounded-full font-black shadow-2xl uppercase text-[10px] tracking-widest hover:scale-105 transition-all">Simpan Perubahan</button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>
