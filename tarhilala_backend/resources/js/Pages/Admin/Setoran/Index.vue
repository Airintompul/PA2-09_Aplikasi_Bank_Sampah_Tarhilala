<script setup>
import AdminLayout from '@/Layouts/AdminLayout.vue';
import { ref, onMounted } from 'vue';
import api from '@/api';

// --- STATE DATA ---
const requests = ref([]);
const isLoading = ref(true);
const successMessage = ref('');

// State Modal
const openEdit = ref(false);
const currSetoran = ref({
    id: '',
    nasabah: '',
    status: '',
    berat_final: '',
    catatan: '',
    lat: '',
    lng: '',
    // --- TAMBAHAN DATA AI ---
    ai: {
        id: '',
        class: '',
        confidence: 0,
        image: '',
        is_correct: null,
        admin_class: ''
    }
});

// --- LOGIC: AMBIL DATA DARI API ---
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

// --- LOGIC: UPDATE STATUS & VALIDASI AI ---
const handleUpdate = async () => {
    try {
        // 1. Update Operasional Setoran
        await api.put(`/setoran/${currSetoran.value.id}`, {
            status: currSetoran.value.status,
            berat_final: currSetoran.value.berat_final,
            catatan: currSetoran.value.catatan
        });

        // 2. Simpan Validasi AI (Learning Process)
        await api.post(`/setoran/${currSetoran.value.id}/verify-ai`, {
            is_correct: currSetoran.value.ai.is_correct,
            admin_class: currSetoran.value.ai.admin_class
        });

        openEdit.value = false;
        showSuccess("Data & Validasi AI Berhasil Diperbarui!");
        fetchRequests();
    } catch (error) {
        alert("Gagal memperbarui data");
    }
};

// --- HELPERS ---
const openEditModal = (req) => {
    currSetoran.value = {
        id: req.id,
        nasabah: req.nasabah?.nama || 'Unknown',
        status: req.status,
        berat_final: req.berat_final,
        catatan: req.catatan,
        lat: req.lokasi_lat,
        lng: req.lokasi_lng,
        // Mapping data AI dari database
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
    const d = date.toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' });
    const t = date.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' });
    return { d, t };
};

onMounted(() => fetchRequests());
</script>

<template>
    <AdminLayout>
        <div class="flex justify-between items-center mb-8">
            <h2 class="text-4xl font-black text-gray-900 uppercase tracking-tight">Pick-up Request</h2>
            <button class="flex items-center space-x-3 bg-[#41D3BD] hover:opacity-80 text-black px-8 py-4 rounded-[2rem] transition-all shadow-lg font-black uppercase text-sm tracking-widest">
                <i class="fa-solid fa-file-export text-lg"></i>
                <span>Export Report</span>
            </button>
        </div>

        <div v-if="successMessage" class="mb-6 p-5 bg-green-500 text-white rounded-2xl font-bold shadow-lg flex items-center">
            <i class="fa-solid fa-circle-check mr-3 text-xl"></i> {{ successMessage }}
        </div>

        <div class="bg-white rounded-[2.5rem] shadow-sm border border-gray-100 relative overflow-hidden">
            <table class="w-full text-left">
                <thead class="bg-[#41D3BD]">
                    <tr>
                        <th class="pl-20 py-6 text-black font-black uppercase text-sm tracking-widest rounded-tl-[2.5rem]">Nasabah</th>
                        <th class="px-6 py-6 text-black font-black uppercase text-sm text-center">AI Result</th>
                        <th class="px-6 py-6 text-black font-black uppercase text-sm text-center">Tgl Pengajuan</th>
                        <th class="px-6 py-6 text-black font-black uppercase text-sm text-center">Estimasi</th>
                        <th class="px-6 py-6 text-black font-black uppercase text-sm text-center">Status</th>
                        <th class="px-8 py-6 text-center rounded-tr-[2.5rem]">
                            <span class="bg-white px-5 py-1 rounded-lg text-xs font-black text-black uppercase">Action</span>
                        </th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 text-black font-medium text-sm">
                    <tr v-for="req in requests" :key="req.id" class="hover:bg-gray-50/50 transition-all">
                        <td class="pl-20 py-6">
                            <div class="flex flex-col">
                                <span class="font-black text-lg uppercase text-blue-600 tracking-tighter">{{ req.nasabah?.nama || 'N/A' }}</span>
                                <span class="text-[10px] text-gray-400 font-bold uppercase">ID: #SET-{{ req.id }}</span>
                            </div>
                        </td>
                        <!-- KOLOM AI BARU -->
                        <td class="px-6 py-6 text-center">
                            <div v-if="req.ai_validation" class="flex flex-col">
                                <span class="font-black uppercase text-gray-700">{{ req.ai_validation.ai_class }}</span>
                                <span class="text-[10px] text-gray-400">{{ (req.ai_validation.ai_confidence * 100).toFixed(0) }}% Acc</span>
                            </div>
                            <span v-else class="text-gray-300 italic">No Data</span>
                        </td>
                        <td class="px-6 py-6 text-center">
                            <div class="font-bold">{{ formatDateTime(req.tanggal_pengajuan).d }}</div>
                            <div class="text-[10px] text-gray-400 uppercase font-black">{{ formatDateTime(req.tanggal_pengajuan).t }} WIB</div>
                        </td>
                        <td class="px-6 py-6 text-center font-black">{{ req.estimasi_berat }} Kg</td>
                        <td class="px-6 py-6 text-center">
                            <span class="px-4 py-1 rounded-full text-[10px] font-black uppercase"
                                :class="{
                                    'bg-yellow-100 text-yellow-700': req.status === 'menunggu',
                                    'bg-green-100 text-green-700': req.status === 'selesai',
                                    'bg-red-100 text-red-700': req.status === 'dibatalkan',
                                    'bg-blue-100 text-blue-700': ['dijadwalkan', 'dalam_penjemputan'].includes(req.status)
                                }">
                                {{ req.status.replace('_', ' ') }}
                            </span>
                        </td>
                        <td class="px-8 py-6 text-center">
                            <div class="flex justify-center space-x-2">
                                <button @click="openEditModal(req)" class="p-3 bg-blue-50 text-blue-600 rounded-xl hover:bg-blue-600 hover:text-white transition-all">
                                    <i class="fa-solid fa-pen-to-square"></i>
                                </button>
                                <router-link :to="'/setoran/' + req.id + '/tracking'" class="p-3 bg-[#41D3BD]/10 text-[#41D3BD] rounded-xl hover:bg-[#41D3BD] hover:text-white transition-all">
                                    <i class="fa-solid fa-map-location-dot"></i>
                                </router-link>
                            </div>
                        </td>
                    </tr>
                </tbody>
            </table>
            <div class="h-6"></div>
        </div>

        <!-- MODAL UPDATE + AI LEARNING -->
        <div v-if="openEdit" class="fixed inset-0 z-[100] flex items-center justify-center bg-black/50 backdrop-blur-sm px-4">
            <div class="bg-white rounded-[3rem] max-w-5xl w-full p-10 shadow-2xl relative max-h-[90vh] overflow-y-auto">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-12">

                    <!-- KIRI: AI LEARNING CENTER -->
                    <div class="space-y-6">
                        <h3 class="text-xl font-black text-gray-700 uppercase tracking-widest border-b pb-4">AI Learning Center</h3>

                        <!-- Foto dari Nasabah -->
                        <div class="w-full aspect-video bg-gray-100 rounded-3xl overflow-hidden border-4 border-white shadow-md">
                            <img :src="'/storage/' + currSetoran.ai.image" class="w-full h-full object-cover" @error="(e) => e.target.src = '/assets/img/placeholder.png'">
                        </div>

                        <div class="bg-blue-50 p-6 rounded-[2rem] border border-blue-100">
                            <p class="text-[10px] font-black text-blue-400 uppercase mb-1">Prediksi AI Awal</p>
                            <p class="text-2xl font-black text-blue-800 uppercase">{{ currSetoran.ai.class }} ({{ (currSetoran.ai.confidence * 100).toFixed(0) }}%)</p>
                        </div>

                        <div class="space-y-4">
                            <p class="text-[10px] font-black text-gray-400 uppercase ml-2">Apakah Klasifikasi Diatas Benar?</p>
                            <div class="flex space-x-4">
                                <button @click="currSetoran.ai.is_correct = 1" :class="currSetoran.ai.is_correct === 1 ? 'bg-green-500 text-white shadow-lg' : 'bg-gray-100 text-gray-400'" class="flex-1 py-4 rounded-2xl font-black uppercase text-xs transition-all">Benar</button>
                                <button @click="currSetoran.ai.is_correct = 0" :class="currSetoran.ai.is_correct === 0 ? 'bg-red-500 text-white shadow-lg' : 'bg-gray-100 text-gray-400'" class="flex-1 py-4 rounded-2xl font-black uppercase text-xs transition-all">Salah</button>
                            </div>
                        </div>

                        <div v-if="currSetoran.ai.is_correct === 0" class="animate-pulse">
                            <label class="text-[10px] font-black text-red-500 uppercase tracking-widest ml-2">Koreksi Admin (Dataset Baru)</label>
                            <input v-model="currSetoran.ai.admin_class" type="text" placeholder="Masukkan jenis sampah yang benar..." class="w-full px-6 py-4 bg-red-50 border-none rounded-2xl focus:ring-2 focus:ring-red-400 outline-none font-bold text-gray-700">
                        </div>
                    </div>

                    <!-- KANAN: UPDATE OPERASIONAL -->
                    <div class="space-y-6">
                        <h3 class="text-xl font-black text-gray-700 uppercase tracking-widest border-b pb-4 text-right">Pickup Status</h3>

                        <form @submit.prevent="handleUpdate" class="space-y-5">
                            <div class="bg-gray-50 p-6 rounded-[2rem] border border-gray-100">
                                <p class="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1">Nasabah</p>
                                <p class="text-gray-800 font-black text-xl uppercase tracking-tighter">{{ currSetoran.nasabah }}</p>
                            </div>

                            <div>
                                <label class="text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Update Status</label>
                                <select v-model="currSetoran.status" class="w-full px-6 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-black text-gray-700 uppercase text-xs">
                                    <option value="menunggu">MENUNGGU</option>
                                    <option value="dijadwalkan">DIJADWALKAN</option>
                                    <option value="dalam_penjemputan">DALAM PENJEMPUTAN</option>
                                    <option value="selesai">SELESAI</option>
                                    <option value="dibatalkan">DIBATALKAN</option>
                                </select>
                            </div>

                            <div>
                                <label class="text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Berat Final (Kg)</label>
                                <input v-model="currSetoran.berat_final" type="number" step="0.01" class="w-full px-6 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-blue-400 outline-none font-black text-blue-600 text-lg">
                            </div>

                            <div>
                                <label class="text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Catatan</label>
                                <textarea v-model="currSetoran.catatan" rows="2" class="w-full px-6 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-bold text-gray-700 text-sm"></textarea>
                            </div>

                            <div class="flex justify-end space-x-3 pt-6 border-t border-gray-50">
                                <button @click="openEdit = false" type="button" class="px-8 py-4 bg-gray-100 rounded-2xl font-black text-gray-400 uppercase text-xs">Batal</button>
                                <button type="submit" class="px-8 py-4 bg-blue-600 text-white rounded-2xl font-black shadow-lg shadow-blue-200 uppercase text-xs tracking-widest hover:scale-105 transition-all">Simpan Perubahan</button>
                            </div>
                        </form>
                    </div>

                </div>
            </div>
        </div>
    </AdminLayout>
</template>

<style scoped>
[x-cloak] { display: none !important; }
</style>
