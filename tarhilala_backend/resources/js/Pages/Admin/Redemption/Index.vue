<script setup>
import AdminLayout from '@/Layouts/AdminLayout.vue';
import { ref, onMounted } from 'vue';
import axios from 'axios';

const redemptions = ref([]);
const isLoading = ref(true);

// --- STATE MODAL ---
const showConfirmModal = ref(false);
const showSuccessModal = ref(false);
const modalData = ref({ id: null, status: '', title: '', message: '', color: '' });

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
    // Membuka koordinat di tab baru Google Maps
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
        showSuccessModal.value = true;
        setTimeout(() => { showSuccessModal.value = false; }, 2000);
    } catch (error) {
        alert("Gagal memperbarui status.");
    } finally {
        isLoading.value = false;
    }
};

onMounted(() => fetchRedemptions());
</script>

<template>
    <AdminLayout>
        <div class="mb-8 flex justify-between items-center">
            <h2 class="text-4xl font-black text-gray-900 uppercase tracking-tighter">Daftar <span class="text-[#41D3BD]">Penukaran</span></h2>
            <div class="bg-white px-6 py-2 rounded-2xl shadow-sm border border-gray-100 font-bold text-xs uppercase tracking-widest text-gray-400">
                Total: {{ redemptions.length }} Permintaan
            </div>
        </div>

        <div class="bg-white rounded-[2.5rem] shadow-sm relative overflow-hidden border border-gray-100">
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

                    <tr v-if="redemptions.length === 0 && !isLoading">
                        <td colspan="5" class="py-20 text-center text-gray-300 font-bold uppercase italic tracking-widest">
                            Belum ada data penukaran reward
                        </td>
                    </tr>

                    <tr v-for="item in redemptions" :key="item.id" class="hover:bg-gray-50/50 transition-all">
                        <td class="pl-12 py-6">
                            <div class="font-black text-[#1E56A0] uppercase text-sm leading-none">{{ item.user?.nama }}</div>
                            <div class="text-[10px] text-gray-400 font-bold mt-1 uppercase">ID: #REDEEM-{{ item.id }}</div>
                        </td>
                        <td class="px-6 py-6">
                            <div class="font-bold text-gray-700 uppercase text-xs">{{ item.reward?.nama_reward }}</div>
                            <div class="text-[10px] font-black text-blue-600 uppercase mt-1">
                                {{ item.jumlah }} Unit • {{ item.poin_digunakan }} Poin
                            </div>
                        </td>

                        <!-- KOLOM ALAMAT & KLIK LOKASI -->
                        <td class="px-6 py-6">
                            <div class="flex items-start space-x-3 max-w-xs">
                                <!-- Tombol Maps Hijau -->
                                <button @click="openMaps(item.lokasi_lat, item.lokasi_lng)"
                                        class="mt-1 flex-shrink-0 w-9 h-9 bg-teal-50 text-[#41D3BD] rounded-xl hover:bg-[#41D3BD] hover:text-white transition-all flex items-center justify-center shadow-sm">
                                    <i class="fa-solid fa-map-location-dot text-lg"></i>
                                </button>
                                <div>
                                    <p class="text-[11px] font-bold text-gray-600 leading-tight">{{ item.alamat_pengiriman }}</p>
                                    <p v-if="item.catatan" class="text-[10px] text-orange-500 font-bold italic mt-1 uppercase">Ket: {{ item.catatan }}</p>
                                </div>
                            </div>
                        </td>

                        <td class="px-6 py-6 text-center">
                            <span :class="{
                                'bg-orange-50 text-orange-500 border-orange-100': item.status === 'menunggu',
                                'bg-blue-50 text-blue-500 border-blue-100': item.status === 'diproses',
                                'bg-indigo-50 text-indigo-500 border-indigo-100': item.status === 'dikirim',
                                'bg-green-50 text-green-500 border-green-100': item.status === 'selesai',
                                'bg-red-50 text-red-500 border-red-100': item.status === 'ditolak'
                            }" class="px-3 py-1 rounded-full border font-black text-[9px] uppercase tracking-widest shadow-sm">
                                {{ item.status }}
                            </span>
                        </td>

                        <td class="pr-12 py-6 text-right">
                            <div class="flex justify-end space-x-2">
                                <!-- Step 1: Menunggu -> Diproses -->
                                <button v-if="item.status === 'menunggu'" @click="triggerConfirm(item.id, 'diproses')"
                                        class="px-5 py-2.5 bg-blue-50 text-blue-600 rounded-xl hover:bg-blue-600 hover:text-white transition-all font-black text-[10px] uppercase shadow-sm">
                                    Proses
                                </button>

                                <!-- Step 2: Diproses -> Dikirim -->
                                <button v-if="item.status === 'diproses'" @click="triggerConfirm(item.id, 'dikirim')"
                                        class="px-5 py-2.5 bg-indigo-50 text-indigo-600 rounded-xl hover:bg-indigo-600 hover:text-white transition-all font-black text-[10px] uppercase shadow-sm">
                                    Kirim
                                </button>

                                <!-- Tombol Tolak (Hanya jika belum dikirim atau selesai) -->
                                <button v-if="['menunggu', 'diproses'].includes(item.status)" @click="triggerConfirm(item.id, 'ditolak')"
                                        class="w-10 h-10 bg-red-50 text-red-600 rounded-xl hover:bg-red-600 hover:text-white transition-all flex items-center justify-center shadow-sm">
                                    <i class="fa-solid fa-xmark"></i>
                                </button>

                                <!-- Label Selesai (Jika sudah selesai dikonfirmasi Nasabah) -->
                                <span v-if="item.status === 'selesai'" class="text-[10px] font-black text-green-500 uppercase italic">
                                    <i class="fa-solid fa-check-double mr-1"></i> Diterima Nasabah
                                </span>

                                <!-- Label Dikirim (Menunggu Nasabah klik tombol selesai di Flutter) -->
                                <span v-if="item.status === 'dikirim'" class="text-[10px] font-black text-indigo-400 uppercase italic">
                                    Sedang Diantar...
                                </span>

                                <span v-if="item.status === 'ditolak'" class="text-[10px] font-black text-gray-300 uppercase italic">Ditolak</span>
                            </div>
                        </td>
                    </tr>
                </tbody>
            </table>
            <div class="h-6"></div>
        </div>

        <!-- MODAL KONFIRMASI -->
        <div v-if="showConfirmModal" class="fixed inset-0 z-[100] flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
            <div class="bg-white rounded-[2.5rem] max-w-sm w-full p-8 shadow-2xl border-b-8 border-gray-900">
                <div class="w-16 h-16 rounded-full flex items-center justify-center mb-6 mx-auto bg-gray-50 border-4 border-white shadow-inner">
                    <i :class="modalData.status === 'ditolak' ? 'fa-solid fa-circle-exclamation text-red-500' : 'fa-solid fa-truck-fast text-blue-500'" class="text-3xl"></i>
                </div>
                <h3 class="text-xl font-black text-gray-900 text-center uppercase tracking-tighter">{{ modalData.title }}</h3>
                <p class="text-gray-500 text-sm text-center mt-2 leading-relaxed">{{ modalData.message }}</p>
                <div class="flex space-x-3 mt-8">
                    <button @click="showConfirmModal = false" class="flex-1 py-3 bg-gray-100 text-gray-400 rounded-xl font-black uppercase text-[10px] tracking-widest hover:bg-gray-200 transition-all">Batal</button>
                    <button @click="handleUpdate" :class="modalData.color" class="flex-1 py-3 text-white rounded-xl font-black uppercase text-[10px] tracking-widest shadow-lg hover:opacity-90 active:scale-95 transition-all">Konfirmasi</button>
                </div>
            </div>
        </div>

        <!-- SUCCESS TOAST -->
        <div v-if="showSuccessModal" class="fixed top-10 left-1/2 -translate-x-1/2 z-[110]">
            <div class="bg-black text-[#41D3BD] px-8 py-4 rounded-2xl font-black uppercase text-xs shadow-2xl flex items-center space-x-3 border-b-4 border-[#41D3BD]">
                <i class="fa-solid fa-check-circle"></i>
                <span>Status Berhasil Diperbarui!</span>
            </div>
        </div>

    </AdminLayout>
</template>

<style scoped>
/* Scrollbar halus untuk tabel jika datanya banyak */
.custom-scrollbar::-webkit-scrollbar { width: 4px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: #41D3BD; border-radius: 10px; }
</style>    
