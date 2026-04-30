<script setup>
import AdminLayout from '@/Layouts/AdminLayout.vue';
import { ref, onMounted } from 'vue';
import axios from 'axios';

const redemptions = ref([]);
const isLoading = ref(true);

// --- STATE MODAL ---
const showConfirmModal = ref(false);
const showSuccessModal = ref(false);
const modalData = ref({ id: null, status: '', title: '', message: '' });

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

const triggerConfirm = (id, status) => {
    modalData.value = {
        id: id,
        status: status,
        title: status === 'selesai' ? 'Konfirmasi Selesai' : 'Tolak Penukaran',
        message: status === 'selesai'
            ? 'Tandai bahwa reward ini sudah diserahkan ke nasabah?'
            : 'Apakah Anda yakin ingin menolak permintaan ini?'
    };
    showConfirmModal.value = true;
};

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
        alert("Gagal memperbarui data.");
    } finally {
        isLoading.value = false;
    }
};

onMounted(() => fetchRedemptions());
</script>

<template>
    <AdminLayout>
        <div class="mb-8">
            <h2 class="text-4xl font-black text-gray-900 uppercase tracking-tighter">Redemption</h2>
        </div>

        <!-- Tabel Container (Tanpa Inner Card lagi, sesuai referensi) -->
        <div class="bg-white rounded-[2.5rem] shadow-sm relative overflow-hidden border border-gray-100">
            <table class="w-full text-left">
                <!-- Header Teal Melengkung -->
                <thead class="bg-[#41D3BD]">
                    <tr class="text-black font-black uppercase text-[11px] tracking-widest">
                        <th class="pl-12 py-6 rounded-tl-[2.5rem]">Nasabah</th>
                        <th class="px-6 py-6">Item Reward</th>
                        <th class="px-6 py-6 text-center">Poin</th>
                        <th class="px-6 py-6 text-center">Tgl Pengajuan</th>
                        <th class="px-6 py-6 text-center">Status</th>
                        <th class="pr-12 py-6 text-right rounded-tr-[2.5rem]">
                            <span class="bg-white px-5 py-1 rounded-lg">Action</span>
                        </th>
                    </tr>
                </thead>

                <!-- Body Tabel -->
                <tbody class="divide-y divide-gray-50">
                    <tr v-if="isLoading">
                        <td colspan="6" class="py-20 text-center">
                            <div class="inline-block w-8 h-8 border-4 border-[#41D3BD] border-t-transparent rounded-full animate-spin"></div>
                        </td>
                    </tr>

                    <tr v-if="redemptions.length === 0 && !isLoading">
                        <td colspan="6" class="py-20 text-center text-gray-300 font-bold uppercase italic tracking-widest">
                            Belum ada data penukaran
                        </td>
                    </tr>

                    <tr v-for="item in redemptions" :key="item.id" class="hover:bg-gray-50/50 transition-all">
                        <td class="pl-12 py-6">
                            <div class="font-black text-[#1E56A0] uppercase text-sm leading-none">{{ item.user?.nama }}</div>
                            <div class="text-[10px] text-gray-400 font-bold mt-1 uppercase">ID: #REDEEM-{{ item.id }}</div>
                        </td>
                        <td class="px-6 py-6 font-bold text-gray-700 uppercase text-xs">
                            {{ item.reward?.nama_reward }}
                        </td>
                        <td class="px-6 py-6 text-center">
                            <span class="text-blue-600 font-black text-xs uppercase">{{ item.poin_digunakan }} Pts</span>
                        </td>
                        <td class="px-6 py-6 text-center text-[11px] font-bold text-gray-400">
                            {{ new Date(item.tanggal_penukaran).toLocaleDateString('id-ID') }}
                        </td>
                        <td class="px-6 py-6 text-center">
                            <span :class="{
                                'text-orange-500': item.status === 'menunggu',
                                'text-green-500': item.status === 'selesai',
                                'text-red-500': item.status === 'ditolak'
                            }" class="font-black text-[10px] uppercase tracking-tighter">
                                {{ item.status }}
                            </span>
                        </td>
                        <td class="pr-12 py-6 text-right">
                            <div v-if="item.status === 'menunggu'" class="flex justify-end space-x-2">
                                <!-- Tombol Biru (Gaya Edit di referensi) -->
                                <button @click="triggerConfirm(item.id, 'selesai')" class="w-10 h-10 bg-blue-50 text-blue-600 rounded-xl hover:bg-blue-600 hover:text-white transition-all flex items-center justify-center">
                                    <i class="fa-solid fa-check"></i>
                                </button>
                                <!-- Tombol Merah (Gaya Delete di referensi) -->
                                <button @click="triggerConfirm(item.id, 'ditolak')" class="w-10 h-10 bg-red-50 text-red-600 rounded-xl hover:bg-red-600 hover:text-white transition-all flex items-center justify-center">
                                    <i class="fa-solid fa-xmark"></i>
                                </button>
                            </div>
                            <span v-else class="text-[10px] font-black text-gray-300 uppercase italic">Archived</span>
                        </td>
                    </tr>
                </tbody>
            </table>
            <!-- Ruang bawah agar tetap melengkung sempurna -->
            <div class="h-6"></div>
        </div>

        <!-- MODAL KONFIRMASI -->
        <div v-if="showConfirmModal" class="fixed inset-0 z-[100] flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
            <div class="bg-white rounded-[2.5rem] max-w-sm w-full p-8 shadow-2xl border-b-8 border-gray-900">
                <div class="w-16 h-16 rounded-full flex items-center justify-center mb-6 mx-auto"
                    :class="modalData.status === 'selesai' ? 'bg-green-100 text-green-600' : 'bg-red-100 text-red-600'">
                    <i :class="modalData.status === 'selesai' ? 'fa-solid fa-circle-check' : 'fa-solid fa-circle-exclamation'" class="text-3xl"></i>
                </div>
                <h3 class="text-xl font-black text-gray-900 text-center uppercase tracking-tighter">{{ modalData.title }}</h3>
                <p class="text-gray-500 text-sm text-center mt-2">{{ modalData.message }}</p>
                <div class="flex space-x-3 mt-8">
                    <button @click="showConfirmModal = false" class="flex-1 py-3 bg-gray-100 text-gray-400 rounded-xl font-black uppercase text-[10px] tracking-widest">Batal</button>
                    <button @click="handleUpdate" class="flex-1 py-3 text-white rounded-xl font-black uppercase text-[10px] tracking-widest"
                        :class="modalData.status === 'selesai' ? 'bg-green-600' : 'bg-red-600'">Ya, Yakin</button>
                </div>
            </div>
        </div>

        <!-- SUCCESS TOAST -->
        <div v-if="showSuccessModal" class="fixed top-10 left-1/2 -translate-x-1/2 z-[110]">
            <div class="bg-black text-[#41D3BD] px-8 py-4 rounded-2xl font-black uppercase text-xs shadow-2xl flex items-center space-x-3">
                <i class="fa-solid fa-check"></i>
                <span>Berhasil diperbarui!</span>
            </div>
        </div>

    </AdminLayout>
</template>
