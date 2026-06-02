<script setup>
import AdminLayout from '@/Layouts/AdminLayout.vue';
import { ref, onMounted, computed } from 'vue';
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

// --- LOGIC HIDE NAVBAR & BLUR ---
const isAnyModalOpen = computed(() => {
    return openAddRoute.value || openEditRoute.value || openAddSchedule.value || openEditSchedule.value || openDelete.value;
});

// State Forms
const currRoute = ref({ id: '', nama_rute: '', wilayah: '' });
const currSchedule = ref({ id: '', rute_id: '', driver_id: '', hari: '', jam_mulai: '', jam_selesai: '' });

// State Delete Helper
const deleteConfig = ref({ url: '', name: '' });

// --- LOGIC: AMBIL DATA ---
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
        currRoute.value.wilayah = currRoute.value.wilayah.toUpperCase();
        await api.post('/location/rute', currRoute.value);
        closeModals();
        showSuccess("Rute Berhasil Ditambahkan!");
        fetchData();
    } catch (error) { alert("Gagal simpan rute"); }
};

const handleUpdateRoute = async () => {
    try {
        currRoute.value.wilayah = currRoute.value.wilayah.toUpperCase();
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
    <AdminLayout :hideNavbar="isAnyModalOpen">

        <!-- AREA BACKGROUND: Blur saat modal buka -->
        <div :class="{'blur-md opacity-50 pointer-events-none transition-all duration-500': isAnyModalOpen}">

            <!-- Header Page -->
            <div class="mb-8 md:mb-10 px-2 md:px-0">
                <h2 class="text-2xl md:text-4xl font-black text-gray-900 uppercase tracking-tight leading-none">
                    Rute & <span class="text-[#41D3BD]">Jadwal Penjemputan</span>
                </h2>
                <p class="text-gray-400 font-bold uppercase text-[10px] md:text-xs tracking-widest mt-2">
                    Manajemen Wilayah Penjemputan & Jadwal Operasional
                </p>
            </div>

            <!-- Alert Berhasil -->
            <div v-if="successMessage && !isAnyModalOpen" class="mx-2 md:mx-0 mb-6 p-4 md:p-5 bg-black text-[#41D3BD] rounded-2xl md:rounded-3xl font-black shadow-xl flex items-center border-l-8 border-[#41D3BD] text-xs md:text-sm">
                <i class="fa-solid fa-circle-check text-xl md:text-2xl mr-4"></i> {{ successMessage }}
            </div>

            <!-- SECTION 1: MASTER RUTE -->
            <div class="flex flex-col md:flex-row justify-between items-start md:items-center mb-6 gap-3 px-2 md:px-0">
                <h3 class="text-lg md:text-2xl font-black text-gray-700 uppercase tracking-tighter">Master Rute</h3>
                <button @click="openAddRoute = true" class="w-full md:w-auto bg-[#41D3BD] text-black px-6 py-3 rounded-xl md:rounded-2xl font-black uppercase text-[10px] md:text-xs tracking-widest shadow-lg hover:opacity-80 transition-all">
                    <i class="fa-solid fa-location-dot mr-2"></i> Add Route
                </button>
            </div>

            <!-- Desktop Table: Rute -->
            <div class="hidden lg:block bg-white rounded-[2.5rem] shadow-sm border border-gray-100 relative mb-12 overflow-hidden transition-all">
                <table class="w-full text-left border-collapse">
                    <thead class="bg-[#41D3BD]">
                        <tr class="text-black font-black uppercase text-[11px] tracking-widest">
                            <th class="pl-12 py-7 rounded-tl-[2.5rem]">Nama Rute</th>
                            <th class="px-6 py-7">Wilayah Cakupan</th>
                            <th class="pr-12 py-7 text-right rounded-tr-[2.5rem]">Aksi</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-50 font-medium">
                        <tr v-for="r in routes" :key="r.id" class="hover:bg-gray-50/50 transition-all">
                            <td class="pl-12 py-6">
                                <span class="font-black text-lg uppercase text-blue-600 tracking-tighter">{{ r.nama_rute }}</span>
                                <div class="text-[9px] text-gray-400 font-bold uppercase mt-1">ID: #RTE-{{ r.id }}</div>
                            </td>
                            <td class="px-6 py-6 uppercase text-slate-500 text-xs tracking-wider font-bold">{{ r.wilayah }}</td>
                            <td class="pr-12 py-6 text-right">
                                <div class="flex justify-end space-x-2">
                                    <button @click="currRoute = { ...r }; openEditRoute = true" class="w-10 h-10 bg-blue-50 text-blue-600 rounded-xl hover:bg-blue-600 hover:text-white transition-all shadow-sm flex items-center justify-center">
                                        <i class="fa-solid fa-pen-nib"></i>
                                    </button>
                                    <button @click="confirmDelete(`/location/rute/${r.id}`, r.nama_rute)" class="w-10 h-10 bg-red-50 text-red-600 rounded-xl hover:bg-red-600 hover:text-white transition-all shadow-sm flex items-center justify-center">
                                        <i class="fa-solid fa-trash"></i>
                                    </button>
                                </div>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <!-- SECTION 2: JADWAL PENJEMPUTAN -->
            <div class="flex flex-col md:flex-row justify-between items-start md:items-center mb-6 gap-3 px-2 md:px-0">
                <h3 class="text-lg md:text-2xl font-black text-gray-700 uppercase tracking-tighter">Jadwal Operasional</h3>
                <button @click="openAddSchedule = true" class="w-full md:w-auto bg-[#41D3BD] text-black px-6 py-3 rounded-xl md:rounded-2xl font-black uppercase text-[10px] md:text-xs tracking-widest shadow-lg hover:opacity-80 transition-all">
                    <i class="fa-solid fa-calendar-plus mr-2"></i> Add Schedule
                </button>
            </div>

            <!-- Desktop Table: Jadwal -->
            <div class="hidden lg:block bg-white rounded-[2.5rem] shadow-sm border border-gray-100 relative mb-12 overflow-hidden transition-all">
                <table class="w-full text-left border-collapse">
                    <thead class="bg-[#41D3BD]">
                        <tr class="text-black font-black uppercase text-[11px] tracking-widest">
                            <th class="pl-12 py-7 rounded-tl-[2.5rem]">Rute & Petugas</th>
                            <th class="px-6 py-7 text-center">Hari Kerja</th>
                            <th class="px-6 py-7 text-center">Jam Operasional</th>
                            <th class="pr-12 py-7 text-right rounded-tr-[2.5rem]">Aksi</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-50 font-medium">
                        <tr v-for="s in schedules" :key="s.id" class="hover:bg-gray-50/50 transition-all">
                            <td class="pl-12 py-7">
                                <span class="font-black text-lg uppercase text-blue-600 tracking-tighter block leading-none">{{ s.rute?.nama_rute }}</span>
                                <span class="text-[10px] text-gray-400 font-bold uppercase mt-1">Petugas: {{ s.driver?.nama }}</span>
                            </td>
                            <td class="px-6 py-7 text-center">
                                <span class="px-4 py-1.5 rounded-full bg-slate-100 text-slate-700 font-black text-[10px] uppercase tracking-widest border border-slate-200">
                                    {{ s.hari }}
                                </span>
                            </td>
                            <td class="px-6 py-7 text-center font-black text-slate-800 text-sm tracking-widest">
                                {{ s.jam_mulai.substring(0,5) }} - {{ s.jam_selesai.substring(0,5) }} WIB
                            </td>
                            <td class="pr-12 py-7 text-right">
                                <div class="flex justify-end space-x-2">
                                    <button @click="currSchedule = { ...s }; openEditSchedule = true" class="w-10 h-10 bg-blue-50 text-blue-600 rounded-xl hover:bg-blue-600 hover:text-white transition-all shadow-sm flex items-center justify-center">
                                        <i class="fa-solid fa-pen-nib"></i>
                                    </button>
                                    <button @click="confirmDelete(`/location/jadwal/${s.id}`, `Jadwal ${s.hari}`)" class="w-10 h-10 bg-red-50 text-red-600 rounded-xl hover:bg-red-600 hover:text-white transition-all shadow-sm flex items-center justify-center">
                                        <i class="fa-solid fa-trash"></i>
                                    </button>
                                </div>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- ============================== MODALS (DIPERKECIL max-w-xl) ============================== -->

        <!-- MODAL RUTE -->
        <div v-if="openAddRoute || openEditRoute" class="fixed inset-0 z-[100] flex items-center justify-center bg-black/40 backdrop-blur-sm px-4">
            <div class="bg-white rounded-[2.5rem] md:rounded-[3rem] max-w-xl w-full p-6 md:p-10 shadow-2xl overflow-y-auto max-h-[92vh] border-[6px] border-slate-900 transition-all">
                <h3 class="text-xl md:text-2xl font-black text-gray-800 uppercase mb-8 text-center">{{ openAddRoute ? 'Add New Route' : 'Update Route' }}</h3>
                <form @submit.prevent="openAddRoute ? handleStoreRoute() : handleUpdateRoute()" class="space-y-5">
                    <div>
                        <label class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Identitas Nama Rute</label>
                        <input v-model="currRoute.nama_rute" type="text" required class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] font-bold text-sm uppercase">
                    </div>
                    <div>
                        <label class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Detail Wilayah Cakupan</label>
                        <textarea v-model="currRoute.wilayah" @input="currRoute.wilayah = currRoute.wilayah.toUpperCase()" rows="3" required class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] font-bold text-sm uppercase"></textarea>
                    </div>
                    <div class="flex flex-col-reverse md:flex-row justify-end gap-3 pt-6 border-t border-gray-50">
                        <button @click="closeModals" type="button" class="w-full md:w-auto px-8 py-4 bg-gray-100 rounded-full font-black text-gray-400 uppercase text-[10px]">Batal</button>
                        <button type="submit" class="w-full md:w-auto px-10 py-4 bg-blue-600 text-white rounded-full font-black shadow-lg uppercase text-[10px] hover:scale-105 transition-all">Simpan Rute</button>
                    </div>
                </form>
            </div>
        </div>

        <!-- MODAL JADWAL -->
        <div v-if="openAddSchedule || openEditSchedule" class="fixed inset-0 z-[100] flex items-center justify-center bg-black/40 backdrop-blur-sm px-4">
            <div class="bg-white rounded-[2.5rem] md:rounded-[3rem] max-w-xl w-full p-6 md:p-10 shadow-2xl overflow-y-auto max-h-[92vh] border-[6px] border-slate-900 transition-all">
                <h3 class="text-xl md:text-2xl font-black text-gray-800 uppercase mb-8 text-center">{{ openAddSchedule ? 'Add New Schedule' : 'Update Schedule' }}</h3>
                <form @submit.prevent="openAddSchedule ? handleStoreSchedule() : handleUpdateSchedule()" class="space-y-5">
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                            <label class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Pilih Rute</label>
                            <select v-model="currSchedule.rute_id" class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl font-black text-slate-800 uppercase text-[10px]">
                                <option v-for="r in routes" :key="r.id" :value="r.id">{{ r.nama_rute }}</option>
                            </select>
                        </div>
                        <div>
                            <label class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Pilih Petugas</label>
                            <select v-model="currSchedule.driver_id" class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl font-black text-slate-800 uppercase text-[10px]">
                                <option v-for="d in drivers" :key="d.id" :value="d.id">{{ d.nama }}</option>
                            </select>
                        </div>
                    </div>
                    <div>
                        <label class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Hari Operasional</label>
                        <select v-model="currSchedule.hari" class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl font-black text-slate-800 uppercase text-[10px]">
                            <option v-for="h in ['senin','selasa','rabu','kamis','jumat','sabtu','minggu']" :key="h" :value="h">{{ h.toUpperCase() }}</option>
                        </select>
                    </div>
                    <div class="grid grid-cols-2 gap-4">
                        <div>
                            <label class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase ml-2">Jam Mulai</label>
                            <input v-model="currSchedule.jam_mulai" type="time" class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl font-bold text-lg">
                        </div>
                        <div>
                            <label class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase ml-2">Jam Selesai</label>
                            <input v-model="currSchedule.jam_selesai" type="time" class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl font-bold text-lg">
                        </div>
                    </div>
                    <div class="flex flex-col-reverse md:flex-row justify-end gap-3 pt-6 border-t border-gray-50">
                        <button @click="closeModals" type="button" class="w-full md:w-auto px-8 py-4 bg-gray-100 rounded-full font-black text-gray-400 uppercase text-[10px]">Batal</button>
                        <button type="submit" class="w-full md:w-auto px-10 py-4 bg-blue-600 text-white rounded-full font-black shadow-lg uppercase text-[10px] hover:scale-105 transition-all">Simpan Jadwal</button>
                    </div>
                </form>
            </div>
        </div>

        <!-- MODAL DELETE GLOBAL -->
        <div v-if="openDelete" class="fixed inset-0 z-[110] flex items-center justify-center bg-black/50 backdrop-blur-sm px-4">
            <div class="bg-white rounded-[2.5rem] max-w-sm w-full p-8 text-center shadow-2xl border-b-8 border-gray-900">
                <div class="w-16 h-16 bg-red-50 text-red-500 rounded-full flex items-center justify-center mx-auto mb-6 text-3xl shadow-inner">
                    <i class="fa-solid fa-triangle-exclamation"></i>
                </div>
                <h3 class="text-lg font-black text-gray-800 uppercase tracking-tighter mb-2">Hapus Data?</h3>
                <p class="text-gray-400 text-[10px] font-bold mb-8 uppercase tracking-widest">Penghapusan <span class="text-red-500">{{ deleteConfig.name }}</span> bersifat permanen.</p>
                <div class="flex space-x-2">
                    <button @click="openDelete = false" class="flex-1 py-4 bg-gray-100 rounded-2xl font-black text-gray-400 uppercase text-[10px]">Batal</button>
                    <button @click="executeDelete" class="flex-1 py-4 bg-red-600 text-white rounded-2xl font-black shadow-lg uppercase text-[10px]">Ya, Hapus</button>
                </div>
            </div>
        </div>

    </AdminLayout>
</template>

<style scoped>
.transition-all { transition: all 0.3s ease-in-out; }
</style>
