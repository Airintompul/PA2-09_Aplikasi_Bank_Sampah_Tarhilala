<script setup>
import AdminLayout from '@/Layouts/AdminLayout.vue';
import { ref, onMounted, computed } from 'vue';
import axios from 'axios';

const redemptions = ref([]);
const isLoading = ref(true);
const successMessage = ref(''); // State untuk pesan sukses

// State untuk Filter
const selectedStatus = ref('all');

// --- LOGIC FILTERING ---
const filteredRedemptions = computed(() => {
    if (selectedStatus.value === 'all') return redemptions.value;
    return redemptions.value.filter(item => item.status === selectedStatus.value);
});

// --- STATE MODAL ---
const showConfirmModal = ref(false);
const modalData = ref({ id: null, status: '', title: '', message: '', color: '' });

// --- LOGIC HIDE NAVBAR & BLUR ---
const isAnyModalOpen = computed(() => {
    return showConfirmModal.value;
});

// Mengambil data dari API
const fetchRedemptions = async () => {
    isLoading.value = true;
    try {
        const response = await axios.get('/api/admin/redemptions', {
            headers: { Authorization: `Bearer ${localStorage.getItem('admin_token')}` }
        });
        redemptions.value = response.data.data;
    } catch (error) {
        console.error("Gagal mengambil data penukaran");
    } finally {
        isLoading.value = false;
    }
};

// --- LOGIC: BUKA GOOGLE MAPS ---
const openMaps = (lat, lng) => {
    if (!lat || !lng || lat === '0' || lat === 0) {
        alert("Nasabah tidak menyertakan titik lokasi GPS.");
        return;
    }
    const url = `https://www.google.com/maps?q=${lat},${lng}`;
    window.open(url, '_blank');
};

// --- LOGIC: TRIGGER MODAL KONFIRMASI ---
const triggerConfirm = (id, status) => {
    let title = '';
    let message = '';
    let color = '';

    switch (status) {
        case 'diproses':
            title = 'Proses Pesanan';
            message = 'Siapkan barang ini untuk segera dikirim ke nasabah?';
            color = 'bg-blue-600';
            break;
        case 'dikirim':
            title = 'Konfirmasi Pengiriman';
            message = 'Pastikan barang sudah dibawa kurir/petugas untuk diantar.';
            color = 'bg-indigo-600';
            break;
        case 'ditolak':
            title = 'Tolak Penukaran';
            message = 'Apakah Anda yakin ingin menolak permintaan ini? Poin akan dikembalikan ke nasabah.';
            color = 'bg-red-600';
            break;
    }

    modalData.value = { id, status, title, message, color };
    showConfirmModal.value = true;
};

// --- LOGIC: UPDATE STATUS KE API ---
const handleUpdate = async () => {
    showConfirmModal.value = false;
    isLoading.value = true;
    try {
        await axios.put(`/api/admin/redemptions/${modalData.value.id}`,
            { status: modalData.value.status },
            { headers: { Authorization: `Bearer ${localStorage.getItem('admin_token')}` } }
        );
        fetchRedemptions();
        showSuccess("Status Berhasil Diperbarui!");
    } catch (error) {
        alert("Gagal memperbarui status.");
    } finally {
        isLoading.value = false;
    }
};

const showSuccess = (msg) => {
    successMessage.value = msg;
    setTimeout(() => { successMessage.value = ''; }, 3000);
};

onMounted(() => fetchRedemptions());
</script>

<template>
    <AdminLayout :hideNavbar="isAnyModalOpen">

        <div :class="{'blur-md opacity-60 pointer-events-none transition-all duration-500': isAnyModalOpen}">

            <!-- Header Page -->
            <div class="mb-6 md:mb-8 flex flex-col md:flex-row justify-between items-start md:items-center gap-4 px-2 md:px-0">
                <div class="flex-1">
                    <h2 class="text-2xl md:text-4xl font-black text-gray-900 uppercase tracking-tighter leading-none">Daftar <span class="text-[#41D3BD]">Penukaran</span></h2>
                    <p class="text-[10px] text-gray-400 font-bold uppercase tracking-widest mt-2">Logistik & Distribusi Reward Nasabah</p>

                    <!-- NOTIFIKASI CRUD: Diletakkan di bawah teks logistik -->
                    <Transition name="fade">
                        <div v-if="successMessage" class="mt-4 p-3 bg-black text-[#41D3BD] rounded-xl font-black text-[10px] uppercase flex items-center border-l-4 border-[#41D3BD] shadow-lg w-fit animate-pulse">
                            <i class="fa-solid fa-circle-check mr-2"></i> {{ successMessage }}
                        </div>
                    </Transition>
                </div>

                <div class="flex flex-col md:flex-row gap-3 w-full md:w-auto">
                    <!-- FILTER DROPDOWN -->
                    <div class="relative group">
                        <select v-model="selectedStatus" class="w-full md:w-auto appearance-none bg-[#41D3BD] text-black px-8 py-4 rounded-2xl md:rounded-[2rem] font-black uppercase text-[10px] md:text-xs tracking-widest border-none outline-none cursor-pointer pr-14 shadow-lg group-hover:scale-105 transition-all duration-300">
                            <option class="bg-white text-black" value="all">SEMUA STATUS</option>
                            <option class="bg-white text-black" value="menunggu">DAFTAR TUNGGU</option>
                            <option class="bg-white text-black" value="diproses">DIPROSES</option>
                            <option class="bg-white text-black" value="dikirim">DIKIRIM</option>
                            <option class="bg-white text-black" value="selesai">SELESAI</option>
                            <option class="bg-white text-black" value="ditolak">DITOLAK</option>
                        </select>
                        <div class="absolute right-6 top-1/2 -translate-y-1/2 pointer-events-none text-black">
                            <i class="fa-solid fa-filter"></i>
                        </div>
                    </div>

                    <div class="bg-white px-6 py-4 rounded-2xl md:rounded-[2rem] shadow-sm border border-gray-100 font-black text-[10px] md:text-xs uppercase tracking-widest text-gray-400 flex items-center justify-center">
                        Total: {{ filteredRedemptions.length }} Data
                    </div>
                </div>
            </div>

            <!-- 1. VIEW DESKTOP: TABEL -->
            <div class="hidden lg:block bg-white rounded-[2.5rem] shadow-sm relative overflow-hidden border border-gray-100">
                <table class="w-full text-left">
                    <thead class="bg-[#41D3BD]">
                        <tr class="text-black font-black uppercase text-[11px] tracking-widest">
                            <th class="pl-12 py-6 rounded-tl-[2.5rem]">Nasabah</th>
                            <th class="px-6 py-6">Reward & Jumlah</th>
                            <th class="px-6 py-6">Alamat Pengiriman</th>
                            <th class="px-6 py-6 text-center">Status</th>
                            <th class="pr-12 py-6 text-right rounded-tr-[2.5rem]">Aksi</th>
                        </tr>
                    </thead>

                    <tbody class="divide-y divide-gray-50">
                        <tr v-if="isLoading">
                            <td colspan="5" class="py-20 text-center">
                                <div class="inline-block w-8 h-8 border-4 border-[#41D3BD] border-t-transparent rounded-full animate-spin"></div>
                            </td>
                        </tr>
                        <tr v-if="filteredRedemptions.length === 0 && !isLoading">
                            <td colspan="5" class="py-24 text-center text-gray-300 font-black uppercase italic tracking-widest text-xs">Data tidak ditemukan</td>
                        </tr>
                        <tr v-for="item in filteredRedemptions" :key="item.id" class="hover:bg-gray-50/50 transition-all duration-300">
                            <td class="pl-12 py-6">
                                <div class="font-black text-[#1E56A0] uppercase text-sm leading-none">{{ item.user?.nama }}</div>
                                <div class="text-[10px] text-gray-400 font-bold mt-1 uppercase">ID: #REDEEM-{{ item.id }}</div>
                            </td>
                            <td class="px-6 py-6">
                                <div class="font-bold text-gray-700 uppercase text-xs">{{ item.reward?.nama_reward }}</div>
                                <div class="text-[10px] font-black text-blue-600 uppercase mt-1">{{ item.jumlah }} Unit • {{ item.poin_digunakan }} Poin</div>
                            </td>
                            <td class="px-6 py-6">
                                <div class="flex items-start space-x-3 max-w-xs">
                                    <button @click="openMaps(item.lokasi_lat, item.lokasi_lng)" class="mt-1 shrink-0 w-9 h-9 bg-teal-50 text-[#41D3BD] rounded-xl hover:bg-[#41D3BD] hover:text-white transition-all flex items-center justify-center shadow-sm hover:scale-125 hover:rotate-12"><i class="fa-solid fa-map-location-dot text-lg"></i></button>
                                    <div>
                                        <p class="text-[11px] font-bold text-gray-600 leading-tight">{{ item.alamat_pengiriman }}</p>
                                        <p v-if="item.catatan" class="text-[10px] text-orange-500 font-bold italic mt-1 uppercase">Ket: {{ item.catatan }}</p>
                                    </div>
                                </div>
                            </td>
                            <td class="px-6 py-6 text-center">
                                <span :class="{'bg-orange-50 text-orange-500 border-orange-100': item.status === 'menunggu', 'bg-blue-50 text-blue-500 border-blue-100': item.status === 'diproses', 'bg-indigo-50 text-indigo-500 border-indigo-100': item.status === 'dikirim', 'bg-green-50 text-green-600 border-green-100': item.status === 'selesai', 'bg-red-50 text-red-600 border-red-100': item.status === 'ditolak'}" class="px-3 py-1 rounded-full border font-black text-[9px] uppercase tracking-widest shadow-sm transition-all duration-300">{{ item.status }}</span>
                            </td>
                            <td class="pr-12 py-6 text-right">
                                <div class="flex justify-end space-x-2">
                                    <button v-if="item.status === 'menunggu'" @click="triggerConfirm(item.id, 'diproses')" class="px-5 py-2.5 bg-blue-50 text-blue-600 rounded-xl font-black text-[10px] uppercase shadow-sm transition-all hover:scale-105">Proses</button>
                                    <button v-if="item.status === 'diproses'" @click="triggerConfirm(item.id, 'dikirim')" class="px-5 py-2.5 bg-indigo-50 text-indigo-600 rounded-xl font-black text-[10px] uppercase shadow-sm transition-all hover:scale-105">Kirim</button>
                                    <button v-if="['menunggu', 'diproses'].includes(item.status)" @click="triggerConfirm(item.id, 'ditolak')" class="w-10 h-10 bg-red-50 text-red-600 rounded-xl flex items-center justify-center shadow-sm hover:bg-red-600 hover:text-white transition-all hover:scale-125 hover:rotate-12"><i class="fa-solid fa-xmark"></i></button>
                                    <span v-if="item.status === 'selesai'" class="text-[10px] font-black text-green-500 uppercase italic"><i class="fa-solid fa-check-double mr-1"></i> Selesai</span>
                                    <span v-if="item.status === 'dikirim'" class="text-[10px] font-black text-indigo-400 uppercase italic">Dikirim...</span>
                                    <span v-if="item.status === 'ditolak'" class="text-[10px] font-black text-gray-300 uppercase italic">Ditolak</span>
                                </div>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <!-- 2. VIEW MOBILE: KARTU -->
            <div class="lg:hidden space-y-4 px-2 pb-10 transition-all duration-500">
                <div v-for="item in filteredRedemptions" :key="item.id" class="bg-white p-5 rounded-[2rem] shadow-sm border border-gray-100 space-y-4">
                    <div class="flex justify-between items-start">
                        <div class="min-w-0">
                            <h4 class="font-black text-[#1E56A0] uppercase text-sm truncate pr-2">{{ item.user?.nama }}</h4>
                            <p class="text-[9px] font-bold text-gray-400 uppercase">#REDEEM-{{ item.id }}</p>
                        </div>
                        <span :class="{'bg-orange-50 text-orange-500 border-orange-100': item.status === 'menunggu', 'bg-blue-50 text-blue-500 border-blue-100': item.status === 'diproses', 'bg-indigo-50 text-indigo-500 border-indigo-100': item.status === 'dikirim', 'bg-green-50 text-green-600 border-green-100': item.status === 'selesai', 'bg-red-50 text-red-600 border-red-100': item.status === 'ditolak'}" class="px-2 py-0.5 rounded-full border font-black text-[8px] uppercase tracking-widest shadow-sm">{{ item.status }}</span>
                    </div>

                    <div class="bg-blue-50/30 p-3 rounded-xl">
                        <h5 class="font-black text-gray-700 uppercase text-[10px]">{{ item.reward?.nama_reward }}</h5>
                        <p class="text-[9px] font-bold text-blue-600 uppercase mt-1">{{ item.jumlah }} Unit • {{ item.poin_digunakan }} Poin</p>
                    </div>

                    <div class="flex items-start gap-3 bg-gray-50 p-3 rounded-xl border border-gray-100">
                        <button @click="openMaps(item.lokasi_lat, item.lokasi_lng)" class="shrink-0 w-10 h-10 bg-white text-[#41D3BD] rounded-xl shadow-sm flex items-center justify-center border border-teal-100 active:scale-95 transition-all"><i class="fa-solid fa-map-location-dot text-lg"></i></button>
                        <div class="min-w-0">
                            <p class="text-[10px] font-bold text-gray-500 leading-snug break-words">{{ item.alamat_pengiriman }}</p>
                            <p v-if="item.catatan" class="text-[9px] text-orange-500 font-bold italic mt-1 uppercase">Note: {{ item.catatan }}</p>
                        </div>
                    </div>

                    <div class="flex gap-2">
                        <button v-if="item.status === 'menunggu'" @click="triggerConfirm(item.id, 'diproses')" class="flex-1 py-3 bg-blue-600 text-white rounded-xl font-black text-[10px] uppercase shadow-lg active:scale-95 transition-all">Proses Pesanan</button>
                        <button v-if="item.status === 'diproses'" @click="triggerConfirm(item.id, 'dikirim')" class="flex-1 py-3 bg-indigo-600 text-white rounded-xl font-black text-[10px] uppercase shadow-lg active:scale-95 transition-all">Kirim Barang</button>
                        <button v-if="['menunggu', 'diproses'].includes(item.status)" @click="triggerConfirm(item.id, 'ditolak')" class="w-12 h-12 bg-red-50 text-red-600 rounded-xl flex items-center justify-center border border-red-100 active:scale-95 transition-all"><i class="fa-solid fa-xmark text-lg"></i></button>

                        <div v-if="item.status === 'selesai'" class="w-full py-3 bg-green-50 text-green-600 rounded-xl font-black text-[9px] uppercase text-center border border-green-100 italic">Selesai</div>
                        <div v-if="item.status === 'dikirim'" class="w-full py-3 bg-indigo-50 text-indigo-400 rounded-xl font-black text-[9px] uppercase text-center border border-indigo-100 italic">Sedang Diantar...</div>
                        <div v-if="item.status === 'ditolak'" class="w-full py-3 bg-gray-50 text-gray-300 rounded-xl font-black text-[9px] uppercase text-center border border-gray-200 italic">Ditolak</div>
                    </div>
                </div>
            </div>
        </div>

        <!-- MODAL KONFIRMASI -->
        <div v-if="showConfirmModal" class="fixed inset-0 z-[100] flex items-center justify-center bg-black/40 backdrop-blur-sm p-4">
            <div class="bg-white rounded-[2.5rem] max-w-sm w-full p-6 md:p-8 shadow-2xl border-b-8 border-gray-900 transition-all duration-300">
                <button @click="showConfirmModal = false" class="absolute top-4 right-4 w-8 h-8 bg-gray-100 rounded-full flex items-center justify-center hover:rotate-90 transition-all"><i class="fa-solid fa-xmark text-gray-400"></i></button>
                <div class="w-16 h-16 rounded-full flex items-center justify-center mb-6 mx-auto bg-gray-50 border-4 border-white shadow-inner">
                    <i :class="modalData.status === 'ditolak' ? 'fa-solid fa-circle-exclamation text-red-500' : 'fa-solid fa-truck-fast text-blue-500'" class="text-3xl"></i>
                </div>
                <h3 class="text-lg md:text-xl font-black text-gray-900 text-center uppercase tracking-tighter">{{ modalData.title }}</h3>
                <p class="text-gray-500 text-xs md:text-sm text-center mt-2 leading-relaxed">{{ modalData.message }}</p>
                <div class="flex space-x-2 mt-8">
                    <button @click="showConfirmModal = false" class="flex-1 py-3 bg-gray-100 text-gray-400 rounded-xl font-black uppercase text-[10px] tracking-widest">Batal</button>
                    <button @click="handleUpdate" :class="modalData.color" class="flex-1 py-3 text-white rounded-xl font-black uppercase text-[10px] tracking-widest shadow-lg hover:scale-105 active:scale-95 transition-all">Konfirmasi</button>
                </div>
            </div>
        </div>

    </AdminLayout>
</template>

<style scoped>
.transition-all { transition: all 0.3s ease-in-out; }
.fade-enter-active, .fade-leave-active { transition: opacity 0.5s ease; }
.fade-enter-from, .fade-leave-to { opacity: 0; }
</style>
