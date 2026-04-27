<script setup>
import AdminLayout from '@/Layouts/AdminLayout.vue';
import { ref, onMounted } from 'vue';
import api from '@/api';

// --- STATE DATA ---
const routes = ref([]);
const schedules = ref([]);
const drivers = ref([]);
const isLoading = ref(true);
const successMessage = ref('');

// State Modals
const openAddRoute = ref(false);
const openEditRoute = ref(false);
const openAddSchedule = ref(false);
const openEditSchedule = ref(false);
const openDelete = ref(false);

// State Forms
const currRoute = ref({ id: '', nama_rute: '', wilayah: '' });
const currSchedule = ref({ id: '', rute_id: '', driver_id: '', hari: '', jam_mulai: '', jam_selesai: '' });

// State Delete Helper
const deleteConfig = ref({ url: '', name: '' });

// --- LOGIC: AMBIL DATA (SINGLE REQUEST) ---
const fetchData = async () => {
    try {
        const response = await api.get('/location');
        routes.value = response.data.data.routes;
        schedules.value = response.data.data.schedules;
        drivers.value = response.data.data.drivers;
    } catch (error) {
        console.error("Gagal memuat data lokasi");
    } finally {
        isLoading.value = false;
    }
};

// --- LOGIC: CRUD RUTE ---
const handleStoreRoute = async () => {
    try {
        await api.post('/location/rute', currRoute.value);
        closeModals();
        showSuccess("Rute Berhasil Ditambahkan!");
        fetchData();
    } catch (error) { alert("Gagal simpan rute"); }
};

const handleUpdateRoute = async () => {
    try {
        await api.put(`/location/rute/${currRoute.value.id}`, currRoute.value);
        closeModals();
        showSuccess("Rute Berhasil Diperbarui!");
        fetchData();
    } catch (error) { alert("Gagal update rute"); }
};

// --- LOGIC: CRUD JADWAL ---
const handleStoreSchedule = async () => {
    try {
        await api.post('/location/jadwal', currSchedule.value);
        closeModals();
        showSuccess("Jadwal Berhasil Ditambahkan!");
        fetchData();
    } catch (error) { alert("Gagal simpan jadwal"); }
};

const handleUpdateSchedule = async () => {
    try {
        await api.put(`/location/jadwal/${currSchedule.value.id}`, currSchedule.value);
        closeModals();
        showSuccess("Jadwal Berhasil Diperbarui!");
        fetchData();
    } catch (error) { alert("Gagal update jadwal"); }
};

// --- LOGIC: DELETE GLOBAL ---
const confirmDelete = (url, name) => {
    deleteConfig.value = { url, name };
    openDelete.value = true;
};

const executeDelete = async () => {
    try {
        await api.delete(deleteConfig.value.url);
        openDelete.value = false;
        showSuccess("Data Berhasil Dihapus!");
        fetchData();
    } catch (error) { alert("Gagal menghapus data"); }
};

// --- HELPERS ---
const closeModals = () => {
    openAddRoute.value = openEditRoute.value = openAddSchedule.value = openEditSchedule.value = false;
    currRoute.value = { id: '', nama_rute: '', wilayah: '' };
    currSchedule.value = { id: '', rute_id: '', driver_id: '', hari: '', jam_mulai: '', jam_selesai: '' };
};

const showSuccess = (msg) => {
    successMessage.value = msg;
    setTimeout(() => successMessage.value = '', 3000);
};

onMounted(() => fetchData());
</script>

<template>
    <AdminLayout>
        <div class="mb-10">
            <h2 class="text-4xl font-black text-gray-900 uppercase tracking-tight">Location & Schedules</h2>
        </div>

        <!-- Alert Berhasil -->
        <div v-if="successMessage" class="mb-6 p-5 bg-green-500 text-white rounded-2xl font-bold shadow-lg flex items-center">
            <i class="fa-solid fa-circle-check mr-3"></i> {{ successMessage }}
        </div>

        <!-- SECTION 1: MASTER RUTE -->
        <div class="flex justify-between items-center mb-6">
            <h3 class="text-2xl font-black text-gray-700 uppercase tracking-tighter">Master Rute</h3>
            <button @click="openAddRoute = true" class="bg-[#41D3BD] text-black px-6 py-3 rounded-2xl font-black uppercase text-xs tracking-widest shadow-sm hover:opacity-80 transition-all">
                <i class="fa-solid fa-location-dot mr-2"></i> Add Route
            </button>
        </div>

        <div class="bg-white rounded-[2.5rem] shadow-sm border border-gray-100 relative mb-12 overflow-hidden">
            <table class="w-full text-left">
                <thead class="bg-[#41D3BD]">
                    <tr>
                        <th class="pl-20 py-6 text-black font-medium text-lg rounded-tl-[2.5rem]">Nama Rute</th>
                        <th class="px-6 py-6 text-black font-medium text-lg">Wilayah Cakupan</th>
                        <th class="px-8 py-6 text-center rounded-tr-[2.5rem]">
                            <span class="bg-white px-5 py-1 rounded-lg text-xs font-black text-black uppercase">Action</span>
                        </th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 text-black font-medium">
                    <tr v-for="r in routes" :key="r.id" class="hover:bg-gray-50/50 transition-all">
                        <td class="pl-20 py-6 font-bold uppercase text-blue-600">{{ r.nama_rute }}</td>
                        <td class="px-6 py-6">{{ r.wilayah }}</td>
                        <td class="px-8 py-6 text-center">
                            <div class="flex justify-center space-x-2">
                                <button @click="currRoute = { ...r }; openEditRoute = true" class="p-2.5 bg-blue-50 text-blue-600 rounded-xl hover:bg-blue-600 hover:text-white transition-all"><i class="fa-solid fa-pen-to-square"></i></button>
                                <button @click="confirmDelete(`/location/rute/${r.id}`, r.nama_rute)" class="p-2.5 bg-red-50 text-red-600 rounded-xl hover:bg-red-600 hover:text-white transition-all"><i class="fa-solid fa-trash"></i></button>
                            </div>
                        </td>
                    </tr>
                </tbody>
            </table>
            <div class="h-6"></div>
        </div>

        <!-- SECTION 2: JADWAL PENJEMPUTAN -->
        <div class="flex justify-between items-center mb-6">
            <h3 class="text-2xl font-black text-gray-700 uppercase tracking-tighter">Jadwal Penjemputan</h3>
            <button @click="openAddSchedule = true" class="bg-[#41D3BD] text-black px-6 py-3 rounded-2xl font-black uppercase text-xs tracking-widest shadow-sm hover:opacity-80 transition-all">
                <i class="fa-solid fa-calendar-plus mr-2"></i> Add Schedule
            </button>
        </div>

        <div class="bg-white rounded-[2.5rem] shadow-sm border border-gray-100 relative overflow-hidden">
            <table class="w-full text-left">
                <thead class="bg-[#41D3BD]">
                    <tr>
                        <th class="pl-20 py-6 text-black font-medium text-lg rounded-tl-[2.5rem]">Rute</th>
                        <th class="px-6 py-6 text-black font-medium text-lg text-center">Driver</th>
                        <th class="px-6 py-6 text-black font-medium text-lg text-center">Hari</th>
                        <th class="px-6 py-6 text-black font-medium text-lg text-center">Jam Kerja</th>
                        <th class="px-8 py-6 text-center rounded-tr-[2.5rem]">
                            <span class="bg-white px-5 py-1 rounded-lg text-xs font-black text-black uppercase">Action</span>
                        </th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 text-black font-medium">
                    <tr v-for="s in schedules" :key="s.id" class="hover:bg-gray-50/50 transition-all">
                        <td class="pl-20 py-8 font-bold uppercase text-blue-600">{{ s.rute?.nama_rute }}</td>
                        <td class="px-6 py-8 text-center uppercase font-semibold text-gray-600">{{ s.driver?.nama }}</td>
                        <td class="px-6 py-8 text-center uppercase font-black text-gray-800">{{ s.hari }}</td>
                        <td class="px-6 py-8 text-center text-sm font-black">{{ s.jam_mulai.substring(0,5) }} - {{ s.jam_selesai.substring(0,5) }}</td>
                        <td class="px-8 py-8 text-center">
                            <div class="flex justify-center space-x-2">
                                <button @click="currSchedule = { ...s }; openEditSchedule = true" class="p-2.5 bg-blue-50 text-blue-600 rounded-xl hover:bg-blue-600 hover:text-white transition-all"><i class="fa-solid fa-pen-to-square"></i></button>
                                <button @click="confirmDelete(`/location/jadwal/${s.id}`, `Jadwal ${s.hari}`)" class="p-2.5 bg-red-50 text-red-600 rounded-xl hover:bg-red-600 hover:text-white transition-all"><i class="fa-solid fa-trash"></i></button>
                            </div>
                        </td>
                    </tr>
                </tbody>
            </table>
            <div class="h-6"></div>
        </div>

        <!-- MODALS (RUTE) -->
        <div v-if="openAddRoute || openEditRoute" class="fixed inset-0 z-[100] flex items-center justify-center bg-black/50 backdrop-blur-sm px-4">
            <div class="bg-white rounded-[3rem] max-w-lg w-full p-10 shadow-2xl">
                <h3 class="text-2xl font-black text-gray-800 uppercase mb-8">{{ openAddRoute ? 'Add New Route' : 'Update Route' }}</h3>
                <form @submit.prevent="openAddRoute ? handleStoreRoute() : handleUpdateRoute()" class="space-y-4">
                    <div>
                        <label class="text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Nama Rute</label>
                        <input v-model="currRoute.nama_rute" type="text" required class="w-full px-6 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] font-bold">
                    </div>
                    <div>
                        <label class="text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Wilayah Cakupan</label>
                        <textarea v-model="currRoute.wilayah" rows="3" required class="w-full px-6 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] font-bold"></textarea>
                    </div>
                    <div class="flex justify-end space-x-3 pt-6 border-t">
                        <button @click="closeModals" type="button" class="px-8 py-4 bg-gray-100 rounded-2xl font-black text-gray-400 uppercase text-xs">Batal</button>
                        <button type="submit" class="px-8 py-4 bg-blue-600 text-white rounded-2xl font-black shadow-lg uppercase text-xs">Simpan</button>
                    </div>
                </form>
            </div>
        </div>

        <!-- MODALS (JADWAL) -->
        <div v-if="openAddSchedule || openEditSchedule" class="fixed inset-0 z-[100] flex items-center justify-center bg-black/50 backdrop-blur-sm px-4">
            <div class="bg-white rounded-[3rem] max-w-lg w-full p-10 shadow-2xl">
                <h3 class="text-2xl font-black text-gray-800 uppercase mb-8">{{ openAddSchedule ? 'Add Schedule' : 'Update Schedule' }}</h3>
                <form @submit.prevent="openAddSchedule ? handleStoreSchedule() : handleUpdateSchedule()" class="space-y-4">
                    <div class="grid grid-cols-2 gap-4">
                        <div>
                            <label class="text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Pilih Rute</label>
                            <select v-model="currSchedule.rute_id" class="w-full px-6 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] font-bold uppercase text-xs">
                                <option v-for="r in routes" :key="r.id" :value="r.id">{{ r.nama_rute }}</option>
                            </select>
                        </div>
                        <div>
                            <label class="text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Pilih Driver</label>
                            <select v-model="currSchedule.driver_id" class="w-full px-6 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] font-bold uppercase text-xs">
                                <option v-for="d in drivers" :key="d.id" :value="d.id">{{ d.nama }}</option>
                            </select>
                        </div>
                    </div>
                    <div>
                        <label class="text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Hari Operasional</label>
                        <select v-model="currSchedule.hari" class="w-full px-6 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] font-bold uppercase text-xs">
                            <option v-for="h in ['senin','selasa','rabu','kamis','jumat','sabtu','minggu']" :key="h" :value="h">{{ h }}</option>
                        </select>
                    </div>
                    <div class="grid grid-cols-2 gap-4">
                        <div>
                            <label class="text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Jam Mulai</label>
                            <input v-model="currSchedule.jam_mulai" type="time" class="w-full px-6 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] font-bold">
                        </div>
                        <div>
                            <label class="text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Jam Selesai</label>
                            <input v-model="currSchedule.jam_selesai" type="time" class="w-full px-6 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] font-bold">
                        </div>
                    </div>
                    <div class="flex justify-end space-x-3 pt-6 border-t">
                        <button @click="closeModals" type="button" class="px-8 py-4 bg-gray-100 rounded-2xl font-black text-gray-400 uppercase text-xs">Batal</button>
                        <button type="submit" class="px-8 py-4 bg-blue-600 text-white rounded-2xl font-black shadow-lg uppercase text-xs">Simpan</button>
                    </div>
                </form>
            </div>
        </div>

        <!-- GLOBAL DELETE MODAL -->
        <div v-if="openDelete" class="fixed inset-0 z-[110] flex items-center justify-center bg-black/50 backdrop-blur-sm px-4">
            <div class="bg-white rounded-[3rem] max-w-sm w-full p-10 text-center shadow-2xl">
                <div class="w-20 h-20 bg-red-50 text-red-500 rounded-full flex items-center justify-center mx-auto mb-6 text-4xl"><i class="fa-solid fa-triangle-exclamation"></i></div>
                <h3 class="text-xl font-black text-gray-800 uppercase mb-2">Hapus Data?</h3>
                <p class="text-gray-400 text-sm font-bold mb-8 uppercase tracking-tighter">Menghapus <span class="text-red-500">{{ deleteConfig.name }}</span> bersifat permanen.</p>
                <div class="flex justify-center space-x-3">
                    <button @click="openDelete = false" class="px-8 py-4 bg-gray-100 rounded-2xl font-black text-gray-400 uppercase text-xs">Batal</button>
                    <button @click="executeDelete" class="px-8 py-4 bg-red-600 text-white rounded-2xl font-black shadow-lg uppercase text-xs">Ya, Hapus</button>
                </div>
            </div>
        </div>

    </AdminLayout>
</template>
