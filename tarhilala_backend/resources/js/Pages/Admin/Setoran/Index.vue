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
    lng: ''
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

// --- LOGIC: UPDATE STATUS ---
const handleUpdate = async () => {
    try {
        await api.put(`/setoran/${currSetoran.value.id}`, {
            status: currSetoran.value.status,
            berat_final: currSetoran.value.berat_final,
            catatan: currSetoran.value.catatan
        });

        openEdit.value = false;
        showSuccess("Status Penjemputan Berhasil Diperbarui!");
        fetchRequests();
    } catch (error) {
        alert("Gagal memperbarui status");
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
        lng: req.lokasi_lng
    };
    openEdit.value = true;
};

const showSuccess = (msg) => {
    successMessage.value = msg;
    setTimeout(() => successMessage.value = '', 3000);
};

// Format Tanggal & Jam
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

        <!-- Alert Berhasil -->
        <div v-if="successMessage" class="mb-6 p-5 bg-green-500 text-white rounded-2xl font-bold shadow-lg flex items-center">
            <i class="fa-solid fa-circle-check mr-3 text-xl"></i> {{ successMessage }}
        </div>

        <!-- Table Container -->
        <div class="bg-white rounded-[2.5rem] shadow-sm border border-gray-100 relative overflow-hidden">
            <table class="w-full text-left">
                <thead class="bg-[#41D3BD]">
                    <tr>
                        <th class="pl-20 py-6 text-black font-black uppercase text-sm tracking-widest rounded-tl-[2.5rem]">Nasabah</th>
                        <th class="px-6 py-6 text-black font-black uppercase text-sm tracking-widest text-center">Tgl Pengajuan</th>
                        <th class="px-6 py-6 text-black font-black uppercase text-sm tracking-widest text-center">Estimasi</th>
                        <th class="px-6 py-6 text-black font-black uppercase text-sm tracking-widest text-center">Metode</th>
                        <th class="px-6 py-6 text-black font-black uppercase text-sm tracking-widest text-center">Status</th>
                        <th class="px-8 py-6 text-center rounded-tr-[2.5rem]">
                            <span class="bg-white px-5 py-1 rounded-lg text-xs font-black text-black uppercase">Action</span>
                        </th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 text-black font-medium">
                    <tr v-for="req in requests" :key="req.id" class="hover:bg-gray-50/50 transition-all">
                        <td class="pl-20 py-6">
                            <div class="flex flex-col">
                                <span class="font-black text-lg uppercase text-blue-600 tracking-tighter">{{ req.nasabah?.nama || 'N/A' }}</span>
                                <span class="text-[10px] text-gray-400 font-bold uppercase">ID: #SET-{{ req.id }}</span>
                            </div>
                        </td>
                        <td class="px-6 py-6 text-center">
                            <div class="font-bold text-sm">{{ formatDateTime(req.tanggal_pengajuan).d }}</div>
                            <div class="text-[10px] text-gray-400 font-black uppercase">{{ formatDateTime(req.tanggal_pengajuan).t }} WIB</div>
                        </td>
                        <td class="px-6 py-6 text-center font-black text-gray-800">{{ req.estimasi_berat }} Kg</td>
                        <td class="px-6 py-6 text-center uppercase text-[10px] font-black">
                            <span class="px-2 py-1 bg-gray-100 rounded-md border border-gray-200">{{ req.metode_pembayaran }}</span>
                        </td>
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
                                <a :href="'https://www.google.com/maps?q=' + req.lokasi_lat + ',' + req.lokasi_lng" target="_blank" class="p-3 bg-red-50 text-red-500 rounded-xl hover:bg-red-500 hover:text-white transition-all">
                                    <i class="fa-solid fa-map-location-dot"></i>
                                </a>
                            </div>
                        </td>
                    </tr>
                    <tr v-if="requests.length === 0 && !isLoading">
                        <td colspan="6" class="py-20 text-center text-gray-300 font-black uppercase italic tracking-widest text-sm">Belum ada request masuk hari ini</td>
                    </tr>
                </tbody>
            </table>
            <div class="h-6"></div>
        </div>

        <!-- MODAL UPDATE STATUS -->
        <div v-if="openEdit" class="fixed inset-0 z-[100] flex items-center justify-center bg-black/50 backdrop-blur-sm px-4">
            <div class="bg-white rounded-[3rem] max-w-lg w-full p-10 shadow-2xl relative">
                <h3 class="text-2xl font-black text-gray-800 uppercase tracking-tighter mb-8 text-center">Update Pickup Status</h3>

                <form @submit.prevent="handleUpdate" class="space-y-5">
                    <div class="bg-gray-50 p-6 rounded-[2rem] border border-gray-100">
                        <p class="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1">Informasi Nasabah</p>
                        <p class="text-blue-600 font-black text-xl uppercase tracking-tighter">{{ currSetoran.nasabah }}</p>
                        <a :href="'https://www.google.com/maps?q=' + currSetoran.lat + ',' + currSetoran.lng" target="_blank" class="text-red-500 text-[10px] font-black uppercase underline mt-2 inline-block">Buka Koordinat GPS</a>
                    </div>

                    <div>
                        <label class="text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Status Penjemputan</label>
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
                        <label class="text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Catatan Driver/Admin</label>
                        <textarea v-model="currSetoran.catatan" rows="2" class="w-full px-6 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-bold text-gray-700 text-sm"></textarea>
                    </div>

                    <div class="flex justify-end space-x-3 pt-6 border-t border-gray-50">
                        <button @click="openEdit = false" type="button" class="px-8 py-4 bg-gray-100 rounded-2xl font-black text-gray-400 uppercase text-xs tracking-widest">Batal</button>
                        <button type="submit" class="px-8 py-4 bg-blue-600 text-white rounded-2xl font-black shadow-lg uppercase text-xs tracking-widest hover:scale-105 transition-all">Simpan Perubahan</button>
                    </div>
                </form>
            </div>
        </div>
    </AdminLayout>
</template>
