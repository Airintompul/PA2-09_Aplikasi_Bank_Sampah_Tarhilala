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
    id: '',
    nasabah: '',
    status: '',
    jadwal_id: '',
    berat_final: '',
    catatan: '',
    ai: {
        class: '',
        confidence: 0,
        image: '',
        is_correct: null,
        admin_class: ''
    }
});

// --- COMPUTED: KUNCI JIKA SELESAI ATAU DIBATALKAN ---
const isLocked = computed(() => {
    return currSetoran.value.status === 'selesai' || currSetoran.value.status === 'dibatalkan';
});

// --- LOGIC: AMBIL DAFTAR REQUEST ---
const fetchRequests = async () => {
    try {
        const response = await api.get('/setoran');
        requests.value = response.data.data;
    } catch (error) {
        console.error("Gagal mengambil data request");
    } finally {
        isLoading.value = false;
    }
};

// --- LOGIC: AMBIL DATA JADWAL ---
const fetchJadwal = async () => {
    try {
        const response = await api.get('/location');
        jadwalList.value = response.data.data.schedules;
    } catch (error) {
        console.error("Gagal memuat daftar jadwal petugas");
    }
};

// --- LOGIC: DOWNLOAD INVOICE ---
const downloadInvoice = async (id) => {
    try {
        const response = await api.get(`/setoran/${id}/invoice`, {
            responseType: 'blob',
        });
        const url = window.URL.createObjectURL(new Blob([response.data]));
        const link = document.createElement('a');
        link.href = url;
        link.setAttribute('download', `Invoice-SET-${id}.pdf`);
        document.body.appendChild(link);
        link.click();
        link.remove();
    } catch (error) {
        alert("Invoice belum tersedia atau file rusak.");
    }
};

// --- LOGIC: UPDATE DATA ---
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
    } catch (error) {
        if (error.response && error.response.status === 422) {
            alert(error.response.data.message);
        } else {
            alert("Terjadi kesalahan saat menyimpan data.");
        }
    }
};

// --- HELPERS ---
const openEditModal = (req) => {
    currSetoran.value = {
        id: req.id,
        nasabah: req.nasabah?.nama || 'Tidak Diketahui',
        status: req.status,
        jadwal_id: req.jadwal_id || '',
        berat_final: req.berat_final,
        catatan: req.catatan,
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

onMounted(() => {
    fetchRequests();
    fetchJadwal();
});
</script>

<template>
    <AdminLayout>
        <div class="flex justify-between items-center mb-8">
            <h2 class="text-4xl font-black text-gray-900 uppercase tracking-tight leading-none">Daftar <span class="text-[#41D3BD]">Penjemputan</span></h2>
            <button class="flex items-center space-x-3 bg-[#41D3BD] hover:opacity-80 text-black px-8 py-4 rounded-[2rem] transition-all shadow-lg font-black uppercase text-sm tracking-widest">
                <i class="fa-solid fa-file-export text-lg"></i>
                <span>Ekspor Laporan</span>
            </button>
        </div>

        <div v-if="successMessage" class="mb-6 p-5 bg-black text-[#41D3BD] rounded-3xl font-black shadow-xl flex items-center border-l-8 border-[#41D3BD]">
            <i class="fa-solid fa-circle-check text-2xl mr-4"></i> {{ successMessage }}
        </div>

        <!-- TABEL REQUEST -->
        <div class="bg-white dark:bg-slate-900 rounded-[2.5rem] shadow-sm border border-gray-100 dark:border-slate-800 relative overflow-hidden">
            <table class="w-full text-left border-collapse">
                <thead class="bg-[#41D3BD]">
                    <tr class="text-black font-black uppercase text-[11px] tracking-widest">
                        <th class="pl-12 py-7 rounded-tl-[2.5rem]">Nasabah</th>
                        <th class="px-6 py-7 text-center">Hasil AI</th>
                        <th class="px-6 py-7 text-center">Tgl Pengajuan</th>
                        <th class="px-6 py-7 text-center">Estimasi</th>
                        <th class="px-6 py-7 text-center">Petugas</th>
                        <th class="px-6 py-7 text-center">Status</th>
                        <th class="pr-12 py-7 text-right rounded-tr-[2.5rem]">Aksi</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-50 dark:divide-slate-800">
                    <tr v-for="req in requests" :key="req.id" class="hover:bg-gray-50/50 transition-all">
                        <td class="pl-12 py-6">
                            <div class="flex flex-col">
                                <span class="font-black text-lg uppercase text-blue-600 tracking-tighter leading-none">{{ req.nasabah?.nama }}</span>
                                <span class="text-[10px] text-gray-400 font-bold uppercase mt-1">ID: #SET-{{ req.id }}</span>
                            </div>
                        </td>
                        <td class="px-6 py-6 text-center">
                            <div v-if="req.ai_validation" class="flex flex-col">
                                <span class="font-black text-xs text-gray-700 dark:text-gray-300 uppercase">{{ req.ai_validation.ai_class }}</span>
                                <span class="text-[9px] text-[#41D3BD] font-black uppercase">{{ (req.ai_validation.ai_confidence * 100).toFixed(0) }}% Akurasi</span>
                            </div>
                            <span v-else class="text-gray-300 italic text-xs">Tanpa Scan</span>
                        </td>
                        <td class="px-6 py-6 text-center">
                            <div class="font-bold text-xs">{{ formatDateTime(req.tanggal_pengajuan).d }}</div>
                            <div class="text-[9px] text-gray-400 font-black">{{ formatDateTime(req.tanggal_pengajuan).t }} WIB</div>
                        </td>
                        <td class="px-6 py-6 text-center font-black text-slate-700 dark:text-white">{{ req.estimasi_berat }} Kg</td>
                        <td class="px-6 py-6 text-center">
                            <div v-if="req.jadwal?.driver" class="flex flex-col">
                                <span class="font-black text-xs text-blue-700 uppercase leading-none">{{ req.jadwal.driver.nama }}</span>
                            </div>
                            <span v-else class="text-gray-300 italic text-xs">Belum Ada</span>
                        </td>
                        <td class="px-6 py-6 text-center">
                            <span class="px-4 py-1.5 rounded-full text-[9px] font-black uppercase tracking-widest shadow-sm border"
                                :class="{
                                    'bg-yellow-50 text-yellow-600 border-yellow-100': req.status === 'menunggu',
                                    'bg-green-50 text-green-600 border-green-100': req.status === 'selesai',
                                    'bg-red-50 text-red-600 border-red-100': req.status === 'dibatalkan',
                                    'bg-blue-50 text-blue-600 border-blue-100': ['dijadwalkan', 'dalam_penjemputan'].includes(req.status)
                                }">
                                {{ req.status.replace('_', ' ') }}
                            </span>
                        </td>
                        <td class="pr-12 py-6 text-right">
                            <div class="flex justify-end space-x-2">
                                <!-- Cetak Invoice hanya jika selesai -->
                                <button v-if="req.status === 'selesai'" @click="downloadInvoice(req.id)" class="w-10 h-10 bg-purple-50 text-purple-600 rounded-xl hover:bg-purple-600 hover:text-white transition-all shadow-sm">
                                    <i class="fa-solid fa-file-invoice"></i>
                                </button>

                                <!-- Ikon Mata (Hanya Lihat) jika Selesai/Batal, Ikon Pena (Edit) jika proses -->
                                <button @click="openEditModal(req)" class="w-10 h-10 rounded-xl transition-all shadow-sm flex items-center justify-center"
                                    :class="req.status === 'selesai' || req.status === 'dibatalkan' ? 'bg-gray-100 text-gray-400' : 'bg-blue-50 text-blue-600 hover:bg-blue-600 hover:text-white'">
                                    <i :class="req.status === 'selesai' || req.status === 'dibatalkan' ? 'fa-solid fa-eye' : 'fa-solid fa-pen-nib'"></i>
                                </button>

                                <!-- MAP TRACKING: Hanya tampil jika BELUM Selesai & BELUM Dibatalkan -->
                                <router-link
                                    v-if="req.status !== 'selesai' && req.status !== 'dibatalkan'"
                                    :to="'/setoran/' + req.id + '/tracking'"
                                    class="w-10 h-10 bg-teal-50 text-[#41D3BD] rounded-xl hover:bg-[#41D3BD] hover:text-white transition-all flex items-center justify-center shadow-sm"
                                >
                                    <i class="fa-solid fa-map-location-dot"></i>
                                </router-link>
                            </div>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>

        <!-- MODAL: DETAIL & EDIT -->
        <div v-if="openEdit" class="fixed inset-0 z-[100] flex items-center justify-center bg-black/80 backdrop-blur-md px-4">
            <div class="bg-white dark:bg-slate-900 rounded-[3.5rem] max-w-6xl w-full p-12 shadow-2xl relative max-h-[90vh] overflow-y-auto border-[10px] border-slate-900">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-16">

                    <!-- KIRI: INFORMASI AI -->
                    <div class="space-y-6">
                        <h3 class="text-2xl font-black text-slate-900 dark:text-white uppercase tracking-widest border-b-4 border-[#41D3BD] inline-block pb-1 text-blue-600">Bukti Foto & AI</h3>
                        <div class="w-full aspect-video bg-slate-100 rounded-[2.5rem] overflow-hidden border-4 border-white shadow-xl relative">
                            <img :src="'/storage/' + currSetoran.ai.image" class="w-full h-full object-cover">
                        </div>

                        <div class="bg-blue-50 p-6 rounded-3xl border border-blue-100">
                            <p class="text-[10px] font-black text-blue-400 uppercase mb-1">Analisa AI</p>
                            <p class="text-2xl font-black text-blue-800 uppercase">{{ currSetoran.ai.class }} ({{ (currSetoran.ai.confidence * 100).toFixed(0) }}%)</p>
                        </div>

                        <div class="space-y-4">
                            <p class="text-[11px] font-black text-gray-400 uppercase tracking-widest ml-2">Validasi Admin</p>
                            <div class="flex space-x-4">
                                <button :disabled="isLocked" @click="currSetoran.ai.is_correct = 1" :class="currSetoran.ai.is_correct === 1 ? 'bg-green-500 text-white shadow-lg' : 'bg-gray-100 text-gray-400'" class="flex-1 py-4 rounded-2xl font-black uppercase text-xs transition-all">Sesuai</button>
                                <button :disabled="isLocked" @click="currSetoran.ai.is_correct = 0" :class="currSetoran.ai.is_correct === 0 ? 'bg-red-500 text-white shadow-lg' : 'bg-gray-100 text-gray-400'" class="flex-1 py-4 rounded-2xl font-black uppercase text-xs transition-all">Salah</button>
                            </div>
                        </div>
                    </div>

                    <!-- KANAN: FORM -->
                    <div class="space-y-6">
                        <h3 class="text-2xl font-black text-slate-900 dark:text-white uppercase tracking-widest border-b-4 border-[#41D3BD] inline-block pb-1 text-blue-600">Detail Operasional</h3>
                        <form @submit.prevent="handleUpdate" class="space-y-6">

                            <div class="space-y-2">
                                <label class="text-[11px] font-black text-gray-400 uppercase tracking-widest ml-2">Penugasan Petugas</label>
                                <select :disabled="isLocked" v-model="currSetoran.jadwal_id" class="w-full px-8 py-5 bg-gray-50 border-none rounded-[2rem] outline-none font-black text-slate-800 uppercase text-xs disabled:opacity-50">
                                    <option value="">-- PILIH PETUGAS --</option>
                                    <option v-for="jadwal in jadwalList" :key="jadwal.id" :value="jadwal.id">
                                        {{ jadwal.driver?.nama }} - {{ jadwal.hari }} ({{ jadwal.jam_mulai }})
                                    </option>
                                </select>
                            </div>

                            <div class="space-y-2">
                                <label class="text-[11px] font-black text-gray-400 uppercase tracking-widest ml-2">Status Penjemputan</label>
                                <select :disabled="isLocked" v-model="currSetoran.status" class="w-full px-8 py-5 bg-gray-50 border-none rounded-[2rem] outline-none font-black text-slate-800 uppercase text-xs disabled:opacity-50">
                                    <option value="menunggu">DAFTAR TUNGGU</option>
                                    <option value="dijadwalkan">DIJADWALKAN</option>
                                    <option value="dalam_penjemputan">DALAM PERJALANAN</option>
                                    <option value="selesai">SELESAI</option>
                                    <option value="dibatalkan">DIBATALKAN</option>
                                </select>
                            </div>

                            <div class="space-y-2">
                                <label class="text-[11px] font-black text-gray-400 uppercase tracking-widest ml-2">Berat Terverifikasi (Kg)</label>
                                <input :disabled="isLocked" v-model="currSetoran.berat_final" type="number" step="0.01" class="w-full px-8 py-5 bg-gray-50 border-none rounded-[2rem] font-black text-blue-600 text-xl disabled:opacity-50">
                            </div>

                            <div class="flex justify-end space-x-4 pt-10 border-t">
                                <button @click="openEdit = false" type="button" class="px-10 py-5 bg-gray-100 rounded-full font-black text-gray-400 uppercase text-xs tracking-widest hover:bg-gray-200 transition-all">
                                    Tutup
                                </button>
                                <button v-if="!isLocked" type="submit" class="px-12 py-5 bg-slate-900 text-[#41D3BD] rounded-full font-black shadow-2xl uppercase text-xs tracking-widest hover:scale-105 active:scale-95 transition-all">
                                    Simpan Perubahan
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>
