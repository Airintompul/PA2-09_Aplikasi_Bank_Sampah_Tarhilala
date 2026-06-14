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
const currSchedule = ref({ id: '', rute_id: '', driver_id: '', hari: '', jam_mulai: '07:00', jam_selesai: '17:00' });

// --- DAFTAR JAM (07:00 - 17:00) ---
const timeOptions = computed(() => {
    const times = [];
    for (let hour = 7; hour <= 17; hour++) {
        const hh = hour < 10 ? `0${hour}` : `${hour}`;
        times.push(`${hh}:00`);
        if (hour < 17) times.push(`${hh}:30`);
    }
    return times;
});

const deleteConfig = ref({ url: '', name: '' });

// --- LOGIC API ---
const fetchData = async () => {
    isLoading.value = true;
    try {
        const response = await api.get('/location');
        routes.value = response.data.data.routes || [];
        schedules.value = response.data.data.schedules || [];
        drivers.value = response.data.data.drivers || [];
    } catch (error) {
        console.error("Gagal memuat data lokasi:", error);
    } finally {
        isLoading.value = false;
    }
};

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

const closeModals = () => {
    openAddRoute.value = openEditRoute.value = openAddSchedule.value = openEditSchedule.value = false;
    currRoute.value = { id: '', nama_rute: '', wilayah: '' };
    currSchedule.value = { id: '', rute_id: '', driver_id: '', hari: '', jam_mulai: '07:00', jam_selesai: '17:00' };
};

const showSuccess = (msg) => {
    successMessage.value = msg;
    setTimeout(() => successMessage.value = '', 3000);
};

onMounted(() => fetchData());
</script>

<template>
    <AdminLayout :hideNavbar="isAnyModalOpen">

        <div :class="{'blur-md opacity-50 pointer-events-none transition-all duration-500': isAnyModalOpen}">

            <!-- Header -->
            <div class="mb-8 md:mb-10 px-2 md:px-0">
                <h2 class="text-2xl md:text-4xl font-black text-gray-900 uppercase tracking-tight leading-none">
                    Rute & <span class="text-[#41D3BD]">Jadwal Penjemputan</span>
                </h2>
                <p class="text-gray-400 font-bold uppercase text-[10px] md:text-xs tracking-widest mt-2">
                    Manajemen Wilayah & Operasional
                </p>
            </div>

            <!-- Alert -->
            <div v-if="successMessage && !isAnyModalOpen" class="mx-2 md:mx-0 mb-6 p-4 md:p-5 bg-black text-[#41D3BD] rounded-2xl font-black shadow-xl flex items-center text-xs">
                <i class="fa-solid fa-circle-check mr-4 text-lg"></i> {{ successMessage }}
            </div>

            <!-- SECTION 1: MASTER RUTE -->
            <div class="flex justify-between items-center mb-6 px-2 md:px-0">
                <h3 class="text-lg md:text-2xl font-black text-gray-700 uppercase">Master Rute</h3>
                <button @click="openAddRoute = true" class="bg-[#41D3BD] text-black px-5 py-2.5 rounded-xl font-black uppercase text-[10px] shadow-lg">Add Route</button>
            </div>

            <!-- Tabel Rute Desktop -->
            <div class="hidden lg:block bg-white rounded-[2.5rem] shadow-sm border border-gray-100 mb-10 overflow-hidden">
                <table class="w-full text-left">
                    <thead class="bg-[#41D3BD]">
                        <tr class="text-black font-black uppercase text-[11px] tracking-widest">
                            <th class="pl-10 py-6">Nama Rute</th>
                            <th class="px-6 py-6">Wilayah</th>
                            <th class="pr-10 py-6 text-right">Aksi</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-50">
                        <tr v-for="r in routes" :key="r.id" class="hover:bg-gray-50/50">
                            <td class="pl-10 py-5 font-black uppercase text-black-600 tracking-tighter">{{ r.nama_rute }}</td>
                            <td class="px-6 py-5 text-xs text-gray-500 font-bold uppercase">{{ r.wilayah }}</td>
                            <td class="pr-10 py-5 text-right">
                                <div class="flex justify-end space-x-2">
                                    <button @click="currRoute = { ...r }; openEditRoute = true" class="w-9 h-9 bg-blue-50 text-blue-600 rounded-lg flex items-center justify-center"><i class="fa-solid fa-pen-nib"></i></button>
                                    <button @click="confirmDelete(`/location/rute/${r.id}`, r.nama_rute)" class="w-9 h-9 bg-red-50 text-red-600 rounded-lg flex items-center justify-center"><i class="fa-solid fa-trash"></i></button>
                                </div>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <!-- TAMPILAN RUTE MOBILE (DATA YANG HILANG DITAMBAHKAN LAGI) -->
            <div class="lg:hidden space-y-4 px-2 mb-10">
                <div v-for="r in routes" :key="r.id" class="bg-white p-5 rounded-[2rem] shadow-sm border border-gray-100 flex justify-between items-center">
                    <div class="min-w-0">
                        <h4 class="font-black text-blue-600 uppercase text-sm truncate pr-2">{{ r.nama_rute }}</h4>
                        <p class="text-[9px] font-bold text-gray-400 uppercase mt-1">{{ r.wilayah }}</p>
                    </div>
                    <div class="flex space-x-1">
                        <button @click="currRoute = { ...r }; openEditRoute = true" class="p-2 text-blue-500"><i class="fa-solid fa-pen-nib"></i></button>
                        <button @click="confirmDelete(`/location/rute/${r.id}`, r.nama_rute)" class="p-2 text-red-500"><i class="fa-solid fa-trash"></i></button>
                    </div>
                </div>
            </div>

            <!-- SECTION 2: JADWAL -->
            <div class="flex justify-between items-center mb-6 px-2 md:px-0">
                <h3 class="text-lg md:text-2xl font-black text-gray-700 uppercase">Jadwal Operasional</h3>
                <button @click="openAddSchedule = true" class="bg-[#41D3BD] text-black px-5 py-2.5 rounded-xl font-black uppercase text-[10px] shadow-lg">Add Schedule</button>
            </div>

            <!-- Tabel Jadwal Desktop -->
            <div class="hidden lg:block bg-white rounded-[2.5rem] shadow-sm border border-gray-100 mb-10 overflow-hidden">
                <table class="w-full text-left">
                    <thead class="bg-[#41D3BD]">
                        <tr class="text-black font-black uppercase text-[11px] tracking-widest">
                            <th class="pl-10 py-6">Rute & Petugas</th>
                            <th class="px-6 py-6 text-center">Hari Kerja</th>
                            <th class="px-6 py-6 text-center">Jam Operasional</th>
                            <th class="pr-10 py-6 text-right">Aksi</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-50">
                        <tr v-for="s in schedules" :key="s.id" class="hover:bg-gray-50/50">
                            <td class="pl-10 py-5">
                                <span class="font-black text-black-600 uppercase">{{ s.rute?.nama_rute }}</span>
                                <div class="text-[9px] text-gray-400 font-bold uppercase mt-1">Petugas: {{ s.driver?.nama }}</div>
                            </td>
                            <td class="px-6 py-5 text-center font-black uppercase text-xs text-gray-600">{{ s.hari }}</td>
                            <td class="px-6 py-5 text-center font-black text-xs text-teal-600">{{ s.jam_mulai.substring(0,5) }} - {{ s.jam_selesai.substring(0,5) }}</td>
                            <td class="pr-10 py-5 text-right">
                                <div class="flex justify-end space-x-2">
                                    <button @click="currSchedule = { ...s }; openEditSchedule = true" class="w-9 h-9 bg-blue-50 text-blue-600 rounded-lg flex items-center justify-center"><i class="fa-solid fa-pen-nib"></i></button>
                                    <button @click="confirmDelete(`/location/jadwal/${s.id}`, `Jadwal ${s.hari}`)" class="w-9 h-9 bg-red-50 text-red-600 rounded-lg flex items-center justify-center"><i class="fa-solid fa-trash"></i></button>
                                </div>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <!-- TAMPILAN JADWAL MOBILE (DATA YANG HILANG DITAMBAHKAN LAGI) -->
            <div class="lg:hidden space-y-4 px-2 pb-10">
                <div v-for="s in schedules" :key="s.id" class="bg-white p-5 rounded-[2rem] shadow-sm border border-gray-100">
                    <div class="flex justify-between items-start mb-3">
                        <div class="min-w-0">
                            <h4 class="font-black text-blue-600 uppercase text-sm truncate">{{ s.rute?.nama_rute }}</h4>
                            <p class="text-[9px] font-bold text-gray-400 uppercase">Petugas: {{ s.driver?.nama }}</p>
                        </div>
                        <div class="flex space-x-1">
                            <button @click="currSchedule = { ...s }; openEditSchedule = true" class="p-2 text-blue-500"><i class="fa-solid fa-pen-nib"></i></button>
                            <button @click="confirmDelete(`/location/jadwal/${s.id}`, `Jadwal ${s.hari}`)" class="p-2 text-red-500"><i class="fa-solid fa-trash"></i></button>
                        </div>
                    </div>
                    <div class="flex justify-between items-center bg-gray-50 px-4 py-2 rounded-xl border border-gray-100">
                        <span class="text-[10px] font-black uppercase text-gray-700 tracking-widest">{{ s.hari }}</span>
                        <span class="text-[10px] font-black text-teal-600">{{ s.jam_mulai.substring(0,5) }} - {{ s.jam_selesai.substring(0,5) }}</span>
                    </div>
                </div>
            </div>

            <div v-if="isLoading" class="text-center py-10 font-black text-gray-300 uppercase text-[10px]">Loading Data...</div>
        </div>

        <!-- MODAL JADWAL (SUDAH DIRAPIKAN UNTUK MOBILE) -->
        <div v-if="openAddSchedule || openEditSchedule" class="fixed inset-0 z-[100] flex items-center justify-center bg-black/40 backdrop-blur-sm px-4">
            <div class="bg-white rounded-[2.5rem] md:rounded-[3rem] max-w-xl w-full p-6 md:p-10 shadow-2xl overflow-y-auto max-h-[92vh] border-[6px] border-slate-900">
                <h3 class="text-xl md:text-2xl font-black text-gray-800 uppercase mb-8 text-center">Jadwal Operasional</h3>
                <form @submit.prevent="openAddSchedule ? handleStoreSchedule() : handleUpdateSchedule()" class="space-y-5">

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                            <label class="text-[9px] font-black text-gray-400 uppercase tracking-widest ml-2">Pilih Rute</label>
                            <select v-model="currSchedule.rute_id" class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl font-black text-slate-800 uppercase text-[10px]">
                                <option v-for="r in routes" :key="r.id" :value="r.id">{{ r.nama_rute }}</option>
                            </select>
                        </div>
                        <div>
                            <label class="text-[9px] font-black text-gray-400 uppercase tracking-widest ml-2">Pilih Petugas</label>
                            <select v-model="currSchedule.driver_id" class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl font-black text-slate-800 uppercase text-[10px]">
                                <option v-for="d in drivers" :key="d.id" :value="d.id">{{ d.nama }}</option>
                            </select>
                        </div>
                    </div>

                    <div>
                        <label class="text-[9px] font-black text-gray-400 uppercase tracking-widest ml-2">Hari Operasional</label>
                        <select v-model="currSchedule.hari" class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl font-black text-slate-800 uppercase text-[10px]">
                            <option v-for="h in ['senin','selasa','rabu','kamis','jumat','sabtu','minggu']" :key="h" :value="h">{{ h.toUpperCase() }}</option>
                        </select>
                    </div>

                    <!-- GRID RESPONSIF: Tumpuk di Mobile, Sejajar di Desktop -->
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                            <label class="text-[9px] font-black text-gray-400 uppercase ml-2">Jam Mulai</label>
                            <select v-model="currSchedule.jam_mulai" class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl font-bold text-lg focus:ring-2 focus:ring-[#41D3BD]">
                                <option v-for="time in timeOptions" :key="time" :value="time">{{ time }}</option>
                            </select>
                        </div>
                        <div>
                            <label class="text-[9px] font-black text-gray-400 uppercase ml-2">Jam Selesai</label>
                            <select v-model="currSchedule.jam_selesai" class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl font-bold text-lg focus:ring-2 focus:ring-[#41D3BD]">
                                <option v-for="time in timeOptions" :key="time" :value="time">{{ time }}</option>
                            </select>
                        </div>
                    </div>

                    <div class="flex flex-col gap-3 pt-6 border-t border-gray-100">
                        <button type="submit" class="w-full py-4 bg-blue-600 text-white rounded-full font-black shadow-lg uppercase text-[10px] hover:scale-105 transition-all">Simpan Jadwal</button>
                        <button @click="closeModals" type="button" class="w-full py-4 bg-gray-100 rounded-full font-black text-gray-400 uppercase text-[10px]">Batal</button>
                    </div>
                </form>
            </div>
        </div>

        <!-- MODAL RUTE -->
        <div v-if="openAddRoute || openEditRoute" class="fixed inset-0 z-[100] flex items-center justify-center bg-black/40 backdrop-blur-sm px-4">
            <div class="bg-white rounded-[2.5rem] md:rounded-[3rem] max-w-xl w-full p-6 md:p-10 shadow-2xl border-[6px] border-slate-900 transition-all">
                <h3 class="text-xl font-black text-gray-800 uppercase mb-8 text-center">{{ openAddRoute ? 'Add New Route' : 'Update Route' }}</h3>
                <form @submit.prevent="openAddRoute ? handleStoreRoute() : handleUpdateRoute()" class="space-y-5">
                    <div>
                        <label class="text-[9px] font-black text-gray-400 uppercase tracking-widest ml-2">Nama Rute</label>
                        <input v-model="currRoute.nama_rute" type="text" required class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl font-bold text-sm uppercase">
                    </div>
                    <div>
                        <label class="text-[9px] font-black text-gray-400 uppercase tracking-widest ml-2">Wilayah Cakupan</label>
                        <textarea v-model="currRoute.wilayah" @input="currRoute.wilayah = currRoute.wilayah.toUpperCase()" rows="3" required class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl font-bold text-sm uppercase"></textarea>
                    </div>
                    <div class="flex flex-col gap-3 pt-6 border-t border-gray-50">
                        <button type="submit" class="w-full py-4 bg-blue-600 text-white rounded-full font-black shadow-lg uppercase text-[10px]">Simpan Rute</button>
                        <button @click="closeModals" type="button" class="w-full py-4 bg-gray-100 rounded-full font-black text-gray-400 uppercase text-[10px]">Batal</button>
                    </div>
                </form>
            </div>
        </div>

        <!-- MODAL DELETE -->
        <div v-if="openDelete" class="fixed inset-0 z-[110] flex items-center justify-center bg-black/50 backdrop-blur-sm px-4">
            <div class="bg-white rounded-[2.5rem] max-w-sm w-full p-8 text-center shadow-2xl border-b-8 border-gray-900 transition-all">
                <div class="w-16 h-16 bg-red-50 text-red-500 rounded-full flex items-center justify-center mx-auto mb-6 text-3xl shadow-inner"><i class="fa-solid fa-triangle-exclamation"></i></div>
                <h3 class="text-lg font-black text-gray-800 uppercase tracking-tighter mb-2">Hapus Data?</h3>
                <div class="flex space-x-2 mt-6">
                    <button @click="openDelete = false" class="flex-1 py-4 bg-gray-100 rounded-2xl font-black text-gray-400 uppercase text-[10px]">Batal</button>
                    <button @click="executeDelete" class="flex-1 py-4 bg-red-600 text-white rounded-2xl font-black shadow-lg uppercase text-[10px]">Hapus</button>
                </div>
            </div>
        </div>

    </AdminLayout>
</template>

<style scoped>
.transition-all { transition: all 0.3s ease-in-out; }
/* Mencegah tampilan scrollbar yang buruk di HP */
select {
    -webkit-appearance: none;
    -moz-appearance: none;
    appearance: none;
    background-image: url("data:image/svg+xml;charset=UTF-8,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3e%3cpolyline points='6 9 12 15 18 9'%3e%3c/polyline%3e%3c/svg%3e");
    background-repeat: no-repeat;
    background-position: right 1rem center;
    background-size: 1em;
}
</style>
