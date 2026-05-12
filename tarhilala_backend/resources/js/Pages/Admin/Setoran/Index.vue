<script setup>
import AdminLayout from '@/Layouts/AdminLayout.vue';
import { ref, onMounted } from 'vue';
import api from '@/api';

// --- STATE DATA ---
const requests = ref([]);
const jadwalList = ref([]); // Menyimpan daftar driver & jadwal
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

// --- LOGIC: AMBIL DATA JADWAL & DRIVER (FIX 404) ---
const fetchJadwal = async () => {
    try {
        // Menggunakan endpoint /location karena biasanya data jadwal & driver ada di sana
        const response = await api.get('/location');
        jadwalList.value = response.data.data.schedules;
    } catch (error) {
        console.error("Gagal memuat daftar jadwal driver");
    }
};

// --- LOGIC: DOWNLOAD INVOICE PDF ---
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

// --- LOGIC: UPDATE SEMUA DATA ---
const handleUpdate = async () => {
    try {
        // 1. Update Operasional & Driver Assignment
        await api.put(`/setoran/${currSetoran.value.id}`, {
            status: currSetoran.value.status,
            jadwal_id: currSetoran.value.jadwal_id,
            berat_final: currSetoran.value.berat_final,
            catatan: currSetoran.value.catatan
        });

        // 2. Simpan Validasi AI
        if (currSetoran.value.ai.is_correct !== null) {
            await api.post(`/setoran/${currSetoran.value.id}/verify-ai`, {
                is_correct: currSetoran.value.ai.is_correct,
                admin_class: currSetoran.value.ai.admin_class
            });
        }

        openEdit.value = false;
        showSuccess("Data Penjemputan Berhasil Diperbarui!");
        fetchRequests();
    } catch (error) {
        alert("Terjadi kesalahan saat menyimpan data.");
    }
};

// --- HELPERS ---
const openEditModal = (req) => {
    currSetoran.value = {
        id: req.id,
        nasabah: req.nasabah?.nama || 'Unknown',
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
            <h2 class="text-4xl font-black text-gray-900 uppercase tracking-tight leading-none">Pick-up <span class="text-[#41D3BD]">Request</span></h2>
            <button class="flex items-center space-x-3 bg-[#41D3BD] hover:opacity-80 text-black px-8 py-4 rounded-[2rem] transition-all shadow-lg font-black uppercase text-sm tracking-widest">
                <i class="fa-solid fa-file-export text-lg"></i>
                <span>Export Report</span>
            </button>
        </div>

        <div v-if="successMessage" class="mb-6 p-5 bg-black text-[#41D3BD] rounded-3xl font-black shadow-xl flex items-center border-l-8 border-[#41D3BD]">
            <i class="fa-solid fa-circle-check text-2xl mr-4"></i> {{ successMessage }}
        </div>

        <!-- TABEL REQUEST -->
        <div class="bg-white dark:bg-slate-900 rounded-[2.5rem] shadow-sm border border-gray-100 dark:border-slate-800 relative overflow-hidden transition-all duration-500">
            <table class="w-full text-left border-collapse">
                <thead class="bg-[#41D3BD] dark:bg-teal-700">
                    <tr class="text-black dark:text-white font-black uppercase text-[11px] tracking-widest">
                        <th class="pl-12 py-7 rounded-tl-[2.5rem]">Nasabah</th>
                        <th class="px-6 py-7 text-center">AI Result</th>
                        <th class="px-6 py-7 text-center">Tgl Pengajuan</th>
                        <th class="px-6 py-7 text-center">Estimasi</th>
                        <th class="px-6 py-7 text-center">Driver Assigned</th>
                        <th class="px-6 py-7 text-center">Status</th>
                        <th class="pr-12 py-7 text-right rounded-tr-[2.5rem]">
                            <span class="bg-white dark:bg-slate-800 px-5 py-1 rounded-lg">Action</span>
                        </th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-50 dark:divide-slate-800 transition-all duration-500">
                    <tr v-for="req in requests" :key="req.id" class="hover:bg-gray-50/50 dark:hover:bg-slate-800/30 transition-all group">
                        <td class="pl-12 py-6">
                            <div class="flex flex-col">
                                <span class="font-black text-lg uppercase text-blue-600 dark:text-blue-400 tracking-tighter leading-none">{{ req.nasabah?.nama }}</span>
                                <span class="text-[10px] text-gray-400 dark:text-slate-500 font-bold uppercase mt-1">ID: #SET-{{ req.id }}</span>
                            </div>
                        </td>
                        <td class="px-6 py-6 text-center">
                            <div v-if="req.ai_validation" class="flex flex-col">
                                <span class="font-black text-xs text-gray-700 dark:text-gray-300 uppercase">{{ req.ai_validation.ai_class }}</span>
                                <span class="text-[9px] text-[#41D3BD] font-black uppercase">{{ (req.ai_validation.ai_confidence * 100).toFixed(0) }}% Acc</span>
                            </div>
                            <span v-else class="text-gray-300 italic text-xs">No Scan</span>
                        </td>
                        <td class="px-6 py-6 text-center">
                            <div class="font-bold text-xs">{{ formatDateTime(req.tanggal_pengajuan).d }}</div>
                            <div class="text-[9px] text-gray-400 font-black">{{ formatDateTime(req.tanggal_pengajuan).t }} WIB</div>
                        </td>
                        <td class="px-6 py-6 text-center font-black text-slate-700 dark:text-white">{{ req.estimasi_berat }} Kg</td>
                        <td class="px-6 py-6 text-center">
                            <div v-if="req.jadwal?.driver" class="flex flex-col">
                                <span class="font-black text-xs text-blue-700 dark:text-blue-400 uppercase leading-none">{{ req.jadwal.driver.nama }}</span>
                                <span class="text-[8px] text-gray-400 uppercase mt-1">On Schedule</span>
                            </div>
                            <span v-else class="text-gray-300 italic text-xs">Unassigned</span>
                        </td>
                        <td class="px-6 py-6 text-center">
                            <span class="px-4 py-1.5 rounded-full text-[9px] font-black uppercase tracking-widest shadow-sm border border-gray-100 dark:border-slate-700"
                                :class="{
                                    'bg-yellow-50 text-yellow-600': req.status === 'menunggu',
                                    'bg-green-50 text-green-600': req.status === 'selesai',
                                    'bg-red-50 text-red-600': req.status === 'dibatalkan',
                                    'bg-blue-50 text-blue-600': ['dijadwalkan', 'dalam_penjemputan'].includes(req.status)
                                }">
                                {{ req.status.replace('_', ' ') }}
                            </span>
                        </td>
                        <td class="pr-12 py-6 text-right">
                            <div class="flex justify-end space-x-2">
                                <button v-if="req.status === 'selesai'" @click="downloadInvoice(req.id)" class="w-10 h-10 bg-purple-50 text-purple-600 rounded-xl hover:bg-purple-600 hover:text-white transition-all shadow-sm">
                                    <i class="fa-solid fa-file-invoice"></i>
                                </button>
                                <button v-else @click="openEditModal(req)" class="w-10 h-10 bg-blue-50 text-blue-600 rounded-xl hover:bg-blue-600 hover:text-white transition-all shadow-sm">
                                    <i class="fa-solid fa-pen-nib"></i>
                                </button>
                                <router-link :to="'/setoran/' + req.id + '/tracking'" class="w-10 h-10 bg-teal-50 text-[#41D3BD] rounded-xl hover:bg-[#41D3BD] hover:text-white transition-all shadow-sm flex items-center justify-center">
                                    <i class="fa-solid fa-map-location-dot"></i>
                                </router-link>
                            </div>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>

        <!-- MODAL: OPERASIONAL & AI LEARNING -->
        <div v-if="openEdit" class="fixed inset-0 z-[100] flex items-center justify-center bg-black/80 backdrop-blur-md px-4 transition-all">
            <div class="bg-white dark:bg-slate-900 rounded-[3.5rem] max-w-6xl w-full p-12 shadow-2xl relative max-h-[90vh] overflow-y-auto border-[10px] border-slate-900 dark:border-slate-800">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-16">

                    <!-- LEFT: AI CENTER -->
                    <div class="space-y-6">
                        <h3 class="text-2xl font-black text-slate-900 dark:text-white uppercase tracking-widest border-b-4 border-[#41D3BD] inline-block pb-1">AI Intelligence</h3>
                        <div class="w-full aspect-video bg-slate-100 dark:bg-slate-800 rounded-[2.5rem] overflow-hidden border-4 border-white dark:border-slate-700 shadow-xl relative group">
                            <img :src="'/storage/' + currSetoran.ai.image" class="w-full h-full object-cover">
                            <div class="absolute bottom-4 left-4 bg-black/60 backdrop-blur-md px-4 py-2 rounded-xl text-[10px] text-white font-black uppercase">Source Image</div>
                        </div>
                        <div class="bg-blue-50 dark:bg-blue-900/30 p-8 rounded-[2.5rem] border border-blue-100 dark:border-blue-800">
                            <p class="text-[10px] font-black text-blue-400 uppercase mb-2 tracking-widest leading-none">Initial Classification</p>
                            <p class="text-3xl font-black text-blue-800 dark:text-blue-300 uppercase tracking-tighter">{{ currSetoran.ai.class }} ({{ (currSetoran.ai.confidence * 100).toFixed(0) }}%)</p>
                        </div>
                        <div class="space-y-4">
                            <p class="text-[11px] font-black text-gray-400 dark:text-slate-500 uppercase ml-2 tracking-widest">Verify Accuracy</p>
                            <div class="flex space-x-4">
                                <button @click="currSetoran.ai.is_correct = 1" :class="currSetoran.ai.is_correct === 1 ? 'bg-green-500 text-white shadow-lg' : 'bg-gray-100 dark:bg-slate-800 text-gray-400'" class="flex-1 py-4 rounded-2xl font-black uppercase text-xs transition-all">Validated</button>
                                <button @click="currSetoran.ai.is_correct = 0" :class="currSetoran.ai.is_correct === 0 ? 'bg-red-500 text-white shadow-lg' : 'bg-gray-100 dark:bg-slate-800 text-gray-400'" class="flex-1 py-4 rounded-2xl font-black uppercase text-xs transition-all">Incorrect</button>
                            </div>
                        </div>
                        <div v-if="currSetoran.ai.is_correct === 0" class="animate-pulse">
                            <label class="text-[10px] font-black text-red-500 uppercase tracking-widest ml-2">Corrective Designation</label>
                            <input v-model="currSetoran.ai.admin_class" type="text" placeholder="Specify actual waste type..." class="w-full px-8 py-5 bg-red-50 dark:bg-red-950/20 border-none rounded-2xl focus:ring-2 focus:ring-red-400 outline-none font-bold text-red-800 dark:text-red-400">
                        </div>
                    </div>

                    <!-- RIGHT: OPERATIONAL FORM -->
                    <div class="space-y-6">
                        <h3 class="text-2xl font-black text-slate-900 dark:text-white uppercase tracking-widest border-b-4 border-[#41D3BD] inline-block pb-1 text-right">Terminal Status</h3>
                        <form @submit.prevent="handleUpdate" class="space-y-6">
                            <div class="bg-gray-50 dark:bg-slate-800 p-8 rounded-[2.5rem] border border-gray-100 dark:border-slate-700">
                                <p class="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1 leading-none">Registered Name</p>
                                <p class="text-slate-800 dark:text-white font-black text-2xl uppercase tracking-tighter">{{ currSetoran.nasabah }}</p>
                            </div>

                            <div class="grid grid-cols-1 gap-6">
                                <div class="space-y-2">
                                    <label class="text-[11px] font-black text-gray-400 uppercase tracking-widest ml-2 leading-none">Assign Field Driver</label>
                                    <select v-model="currSetoran.jadwal_id" class="w-full px-8 py-5 bg-gray-50 dark:bg-slate-800 border-none rounded-[2rem] focus:ring-4 focus:ring-[#41D3BD]/30 outline-none font-black text-slate-800 dark:text-white uppercase text-xs transition-all">
                                        <option value="">SELECT AVAILABLE DRIVER</option>
                                        <option v-for="jadwal in jadwalList" :key="jadwal.id" :value="jadwal.id">
                                            {{ jadwal.driver?.nama }} - {{ jadwal.hari }} ({{ jadwal.jam_mulai }})
                                        </option>
                                    </select>
                                </div>

                                <div class="space-y-2">
                                    <label class="text-[11px] font-black text-gray-400 uppercase tracking-widest ml-2 leading-none">Lifecycle State</label>
                                    <select v-model="currSetoran.status" class="w-full px-8 py-5 bg-gray-50 dark:bg-slate-800 border-none rounded-[2rem] focus:ring-4 focus:ring-[#41D3BD]/30 outline-none font-black text-slate-800 dark:text-white uppercase text-xs transition-all">
                                        <option value="menunggu">WAITING LIST</option>
                                        <option value="dijadwalkan">DISPATCHED (SCHEDULED)</option>
                                        <option value="dalam_penjemputan">IN TRANSIT</option>
                                        <option value="selesai">COMPLETED & VERIFIED</option>
                                        <option value="dibatalkan">TERMINATED / CANCELLED</option>
                                    </select>
                                </div>
                            </div>

                            <div class="space-y-2">
                                <label class="text-[11px] font-black text-gray-400 uppercase tracking-widest ml-2 leading-none">Verified Weight (Kg)</label>
                                <input v-model="currSetoran.berat_final" type="number" step="0.01" class="w-full px-8 py-5 bg-gray-50 dark:bg-slate-800 border-none rounded-[2rem] focus:ring-4 focus:ring-blue-400/30 outline-none font-black text-blue-600 dark:text-blue-400 text-xl transition-all">
                            </div>

                            <div class="space-y-2">
                                <label class="text-[11px] font-black text-gray-400 uppercase tracking-widest ml-2 leading-none">Internal Logistics Notes</label>
                                <textarea v-model="currSetoran.catatan" rows="3" class="w-full px-8 py-5 bg-gray-50 dark:bg-slate-800 border-none rounded-[2rem] focus:ring-4 focus:ring-[#41D3BD]/30 outline-none font-bold text-slate-700 dark:text-white text-sm transition-all"></textarea>
                            </div>

                            <div class="flex justify-end space-x-4 pt-10 border-t border-gray-50 dark:border-slate-800">
                                <button @click="openEdit = false" type="button" class="px-10 py-5 bg-gray-100 dark:bg-slate-800 rounded-full font-black text-gray-400 dark:text-slate-500 uppercase text-xs tracking-widest hover:bg-gray-200">Discard</button>
                                <button type="submit" class="px-12 py-5 bg-slate-900 dark:bg-[#41D3BD] text-[#41D3BD] dark:text-slate-900 rounded-full font-black shadow-2xl uppercase text-xs tracking-widest hover:scale-105 active:scale-95 transition-all">
                                    Commit Sync
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>

<style scoped>
/* Scrollbar Styling */
::-webkit-scrollbar { width: 6px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb { background: #41D3BD; border-radius: 10px; }

/* Transisi Dark Mode Halus */
* {
    transition: background-color 0.4s ease-in-out, border-color 0.4s ease-in-out, color 0.4s ease-in-out;
}
</style>
