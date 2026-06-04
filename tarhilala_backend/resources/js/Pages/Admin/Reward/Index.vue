<script setup>
import AdminLayout from '@/Layouts/AdminLayout.vue';
import { ref, onMounted, computed, watch } from 'vue';
import axios from 'axios';

// --- STATE DATA ---
const rewards = ref([]);
const isLoading = ref(true);
const successMessage = ref('');
const errorMessage = ref(''); // State untuk notifikasi error/warning

// State Modal
const openAdd = ref(false);
const openEdit = ref(false);
const openDelete = ref(false);

// --- LOGIC HIDE NAVBAR & BLUR ---
const isAnyModalOpen = computed(() => {
    return openAdd.value || openEdit.value || openDelete.value;
});

// State Form
const currReward = ref({ id: '', nama_reward: '', poin_dibutuhkan: 0, stok: 0, deskripsi: '', gambar: null });
const imagePreview = ref(null);

// --- VALIDASI AUTO-SNAP (Mencegah Ketikan Manual Angka Minus) ---
watch(() => currReward.value.stok, (newVal) => {
    if (newVal < 0) currReward.value.stok = 0;
});
watch(() => currReward.value.poin_dibutuhkan, (newVal) => {
    if (newVal < 0) currReward.value.poin_dibutuhkan = 0;
});

// Konfigurasi Header Token
const getHeaders = () => ({
    'Authorization': `Bearer ${localStorage.getItem('admin_token')}`,
    'Accept': 'application/json'
});

// --- LOGIC: AMBIL DATA ---
const fetchRewards = async () => {
    try {
        const response = await axios.get('/api/admin/rewards', {
            headers: getHeaders()
        });
        rewards.value = response.data.data;
    } catch (error) {
        console.error("Gagal mengambil data reward");
    } finally {
        isLoading.value = false;
    }
};

const onFileChange = (e) => {
    const file = e.target.files[0];
    if (file) {
        currReward.value.gambar = file;
        imagePreview.value = URL.createObjectURL(file);
    }
};

// --- HELPER NOTIFIKASI (KONSISTEN) ---
const showSuccess = (msg) => {
    successMessage.value = msg;
    errorMessage.value = '';
    setTimeout(() => successMessage.value = '', 4000);
};

const showError = (msg) => {
    errorMessage.value = msg;
    successMessage.value = '';
    setTimeout(() => errorMessage.value = '', 4000);
};

const handleStore = async () => {
    // VALIDASI WAJIB ISI (NAMA & DESKRIPSI)
    if (!currReward.value.nama_reward || !currReward.value.deskripsi || currReward.value.deskripsi.trim() === "") {
        showError("Please fill out this field!");
        return;
    }

    const formData = new FormData();
    formData.append('nama_reward', currReward.value.nama_reward);
    formData.append('poin_dibutuhkan', currReward.value.poin_dibutuhkan);
    formData.append('stok', currReward.value.stok);
    formData.append('deskripsi', currReward.value.deskripsi || '');
    if (currReward.value.gambar) formData.append('gambar', currReward.value.gambar);

    try {
        await axios.post('/api/admin/rewards', formData, {
            headers: { ...getHeaders(), 'Content-Type': 'multipart/form-data' }
        });
        closeModals();
        showSuccess("Reward Berhasil Ditambahkan!");
        fetchRewards();
    } catch (error) {
        showError(error.response?.data?.message || "Gagal menyimpan data");
    }
};

const handleUpdate = async () => {
    // VALIDASI WAJIB ISI (NAMA & DESKRIPSI)
    if (!currReward.value.nama_reward || !currReward.value.deskripsi || currReward.value.deskripsi.trim() === "") {
        showError("Please fill out this field!");
        return;
    }

    isLoading.value = true;
    try {
        const formData = new FormData();
        formData.append('nama_reward', currReward.value.nama_reward);
        formData.append('poin_dibutuhkan', currReward.value.poin_dibutuhkan);
        formData.append('stok', currReward.value.stok);
        formData.append('deskripsi', currReward.value.deskripsi || '');

        if (currReward.value.gambar instanceof File) {
            formData.append('gambar', currReward.value.gambar);
        }

        await axios.post(`/api/admin/rewards/${currReward.value.id}`, formData, {
            headers: { ...getHeaders(), 'Content-Type': 'multipart/form-data' }
        });

        showSuccess("Reward Berhasil Diperbarui!");
        fetchRewards();
        closeModals();
    } catch (error) {
        showError("Gagal memperbarui data");
    } finally {
        isLoading.value = false;
    }
};

const handleDelete = async () => {
    try {
        await axios.delete(`/api/admin/rewards/${currReward.value.id}`, {
            headers: getHeaders()
        });
        openDelete.value = false;
        showSuccess("Reward Berhasil Dihapus!");
        fetchRewards();
    } catch (error) {
        showError("Gagal menghapus data");
    }
};

const openEditModal = (reward) => {
    currReward.value = { ...reward };
    imagePreview.value = reward.gambar;
    openEdit.value = true;
};

const closeModals = () => {
    openAdd.value = false;
    openEdit.value = false;
    currReward.value = { id: '', nama_reward: '', poin_dibutuhkan: 0, stok: 0, deskripsi: '', gambar: null };
    imagePreview.value = null;
};

onMounted(() => fetchRewards());
</script>

<template>
    <AdminLayout :hideNavbar="isAnyModalOpen">

        <!-- AREA BACKGROUND: Konten utama dengan efek Blur -->
        <div :class="{'blur-md opacity-50 pointer-events-none transition-all duration-500': isAnyModalOpen}">

            <!-- Header Page -->
            <div class="flex flex-col md:flex-row justify-between items-start md:items-center mb-8 gap-4 px-2 md:px-0">
                <div>
                    <h2 class="text-2xl md:text-4xl font-black text-gray-900 uppercase tracking-tight leading-none">
                        Daftar <span class="text-[#41D3BD]">Reward</span>
                    </h2>
                    <p class="text-[10px] md:text-xs font-bold text-gray-400 uppercase tracking-widest mt-2">
                        Katalog Tukar Poin & Manajemen Stok Hadiah
                    </p>
                </div>
                <button @click="openAdd = true" class="w-full md:w-auto flex items-center justify-center space-x-3 bg-[#41D3BD] hover:opacity-80 text-black px-8 py-4 rounded-2xl md:rounded-[2rem] transition-all shadow-lg font-black uppercase text-xs md:text-sm tracking-widest">
                    <i class="fa-solid fa-plus text-lg"></i>
                    <span>Add Reward</span>
                </button>
            </div>

            <!-- NOTIFIKASI VALIDASI: POSISI INLINE DI BAWAH DESKRIPSI (KONSISTEN) -->
            <Transition name="fade">
                <div v-if="successMessage || errorMessage"
                     :class="successMessage ? 'bg-black text-[#41D3BD] border-[#41D3BD]' : 'bg-black text-orange-500 border-orange-500'"
                     class="mx-2 md:mx-0 mb-8 p-4 md:p-5 rounded-2xl md:rounded-3xl font-black shadow-xl flex items-center border-l-8 text-xs md:text-sm transition-all">

                    <!-- Ikon Dinamis: Teal Check atau Orange Exclamation -->
                    <i :class="successMessage ? 'fa-solid fa-circle-check text-[#41D3BD]' : 'fa-solid fa-circle-exclamation text-orange-500'" class="text-xl md:text-2xl mr-4"></i>

                    <div class="flex flex-col text-left">
                        <span class="uppercase tracking-tight text-sm md:text-base leading-none">{{ successMessage || errorMessage }}</span>
                    </div>
                </div>
            </Transition>

            <!-- 1. VIEW DESKTOP: TABEL -->
            <div class="hidden lg:block bg-white rounded-[2.5rem] shadow-sm border border-gray-100 relative overflow-hidden transition-all duration-300">
                <table class="w-full text-left border-collapse">
                    <thead class="bg-[#41D3BD]">
                        <tr class="text-black font-black uppercase text-[11px] tracking-widest">
                            <th class="pl-12 py-7 rounded-tl-[2.5rem]">Foto</th>
                            <th class="px-6 py-7">Nama Barang</th>
                            <th class="px-6 py-7 text-center">Poin Harga</th>
                            <th class="px-6 py-7 text-center">Stok</th>
                            <th class="px-6 py-7 text-center">Status</th>
                            <th class="pr-12 py-7 text-right rounded-tr-[2.5rem]">Aksi</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-50 font-medium">
                        <tr v-for="reward in rewards" :key="reward.id" class="hover:bg-gray-50/50 transition-all">
                            <td class="pl-12 py-6">
                                <div class="w-16 h-16 bg-slate-100 rounded-2xl flex items-center justify-center border-2 border-white shadow-sm overflow-hidden shrink-0">
                                    <img v-if="reward.gambar" :src="reward.gambar" class="w-full h-full object-cover">
                                    <i v-else class="fa-solid fa-gift text-gray-300 text-2xl"></i>
                                </div>
                            </td>
                            <td class="px-6 py-6">
                                <div class="flex flex-col">
                                    <span class="font-black text-lg uppercase text-blue-600 tracking-tighter leading-none">{{ reward.nama_reward }}</span>
                                    <span class="text-[10px] text-gray-400 font-bold uppercase mt-1">ID: #RWD-{{ reward.id }}</span>
                                </div>
                            </td>
                            <td class="px-6 py-6 text-center">
                                <span class="font-black text-lg text-slate-800 tracking-tighter">
                                    {{ Number(reward.poin_dibutuhkan).toLocaleString() }} <span class="text-[10px] uppercase text-gray-400">Pts</span>
                                </span>
                            </td>
                            <td class="px-6 py-6 text-center">
                                <span class="font-black text-lg text-slate-700 tracking-tighter">{{ reward.stok }} <span class="text-[10px] text-gray-400 uppercase">Unit</span></span>
                            </td>
                            <td class="px-6 py-6 text-center">
                                <span class="px-4 py-1.5 rounded-full font-black text-[9px] uppercase tracking-widest border shadow-sm"
                                    :class="reward.stok > 0 ? 'bg-green-50 text-green-600 border-green-100' : 'bg-red-50 text-red-600 border-red-100'">
                                    {{ reward.stok > 0 ? 'TERSEDIA' : 'HABIS' }}
                                </span>
                            </td>
                            <td class="pr-12 py-6 text-right">
                                <div class="flex justify-end space-x-2">
                                    <button @click="openEditModal(reward)" class="w-10 h-10 bg-blue-50 text-blue-600 rounded-xl hover:bg-blue-600 hover:text-white transition-all shadow-sm flex items-center justify-center">
                                        <i class="fa-solid fa-pen-nib"></i>
                                    </button>
                                    <button @click="currReward = reward; openDelete = true" class="w-10 h-10 bg-red-50 text-red-600 rounded-xl hover:bg-red-600 hover:text-white transition-all shadow-sm flex items-center justify-center">
                                        <i class="fa-solid fa-trash"></i>
                                    </button>
                                </div>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <!-- 2. VIEW MOBILE: CARDS (UTUH TIDAK DIPANGKAS) -->
            <div class="lg:hidden space-y-4 px-2 pb-10">
                <div v-for="reward in rewards" :key="reward.id" class="bg-white p-5 rounded-[2rem] shadow-sm border border-gray-100 space-y-4">
                    <div class="flex items-center space-x-4">
                        <div class="w-20 h-20 bg-slate-100 rounded-2xl border-2 border-white shadow-sm overflow-hidden shrink-0">
                            <img v-if="reward.gambar" :src="reward.gambar" class="w-full h-full object-cover">
                            <i v-else class="fa-solid fa-gift text-gray-300 text-xl"></i>
                        </div>
                        <div class="min-w-0 flex-1">
                            <div class="flex justify-between items-start">
                                <div class="flex flex-col">
                                    <h3 class="text-sm font-black text-blue-600 uppercase truncate tracking-tighter">{{ reward.nama_reward }}</h3>
                                    <p class="text-[9px] font-bold text-gray-400 uppercase tracking-widest mt-0.5">Stok: {{ reward.stok }} Unit</p>
                                </div>
                                <div class="flex space-x-1">
                                    <button @click="openEditModal(reward)" class="text-blue-500 p-1"><i class="fa-solid fa-pen-nib"></i></button>
                                    <button @click="currReward = reward; openDelete = true" class="text-red-500 p-1"><i class="fa-solid fa-trash"></i></button>
                                </div>
                            </div>
                            <div class="flex items-center justify-between mt-2">
                                <p class="text-xs font-black text-gray-800 tracking-tighter">{{ Number(reward.poin_dibutuhkan).toLocaleString() }} Poin</p>
                                <span class="text-[8px] font-black uppercase px-2 py-0.5 rounded border tracking-widest shadow-sm"
                                    :class="reward.stok > 0 ? 'text-green-600 border-green-100' : 'text-red-600 border-red-100'">
                                    {{ reward.stok > 0 ? 'IN STOCK' : 'OUT' }}
                                </span>
                            </div>
                        </div>
                    </div>
                </div>
                <div v-if="isLoading" class="text-center py-10 font-black text-gray-300 uppercase text-[10px]">Syncing Inventory...</div>
            </div>
        </div>

        <!-- MODAL ADD/EDIT: DIPERKECIL (max-w-xl) -->
        <div v-if="openAdd || openEdit" class="fixed inset-0 z-[999] flex items-center justify-center bg-black/40 backdrop-blur-sm px-4 py-8 transition-all">
            <div class="bg-white rounded-[2.5rem] md:rounded-[3rem] max-w-xl w-full p-6 md:p-10 shadow-2xl relative overflow-y-auto max-h-[92vh] border-[6px] border-slate-900 transition-all">
                <h3 class="text-xl md:text-2xl font-black text-gray-800 uppercase tracking-tighter mb-8 text-center">
                    {{ openAdd ? 'Register Reward' : 'Update Reward' }}
                </h3>

                <form @submit.prevent="openAdd ? handleStore() : handleUpdate()" class="space-y-5">
                    <div>
                        <label class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Nama Barang Reward</label>
                        <input v-model="currReward.nama_reward" type="text" required class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-bold text-gray-700 text-sm uppercase">
                    </div>
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                            <label class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Poin Harga</label>
                            <input v-model="currReward.poin_dibutuhkan" type="number" min="0" required class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-black text-blue-600 text-lg tracking-tighter">
                        </div>
                        <div>
                            <label class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Jumlah Stok</label>
                            <input v-model="currReward.stok" type="number" min="0" required class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-black text-slate-800 text-lg tracking-tighter">
                        </div>
                    </div>
                    <div>
                        <label class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Deskripsi Detail</label>
                        <textarea v-model="currReward.deskripsi" rows="3" required class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-bold text-gray-700 text-sm leading-relaxed"></textarea>
                    </div>
                    <div>
                        <label class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Unggah Foto Barang</label>
                        <div class="mt-2 flex items-center space-x-4">
                            <div v-if="imagePreview" class="w-20 h-20 rounded-2xl overflow-hidden border-2 border-white shadow-md bg-gray-50 shrink-0">
                                <img :src="imagePreview" class="w-full h-full object-cover">
                            </div>
                            <input type="file" @change="onFileChange" accept="image/*" class="w-full text-[10px] text-gray-400 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-[10px] file:font-black file:bg-[#41D3BD]/10 file:text-[#41D3BD]">
                        </div>
                    </div>

                    <div class="flex flex-col-reverse md:flex-row justify-end gap-3 pt-6 border-t border-gray-50">
                        <button @click="closeModals" type="button" class="w-full md:w-auto px-8 py-4 bg-gray-100 rounded-full font-black text-gray-400 uppercase text-[10px] tracking-widest">Batal</button>
                        <button type="submit" class="w-full md:w-auto px-10 py-4 bg-blue-600 text-white rounded-full font-black shadow-lg uppercase text-[10px] hover:scale-105 transition-all">
                            Simpan Reward
                        </button>
                    </div>
                </form>
            </div>
        </div>

        <!-- MODAL DELETE -->
        <div v-if="openDelete" class="fixed inset-0 z-[110] flex items-center justify-center bg-black/50 backdrop-blur-sm px-4">
            <div class="bg-white rounded-[2.5rem] max-w-sm w-full p-8 text-center shadow-2xl border-b-8 border-gray-900 transition-all">
                <div class="w-16 h-16 bg-red-50 text-red-500 rounded-full flex items-center justify-center mx-auto mb-6 text-3xl shadow-inner">
                    <i class="fa-solid fa-gift"></i>
                </div>
                <h3 class="text-lg font-black text-gray-800 uppercase tracking-tighter mb-2">Hapus Reward?</h3>
                <p class="text-gray-400 text-[10px] font-bold mb-8 uppercase tracking-widest leading-relaxed">Reward <span class="text-red-500">{{ currReward.nama_reward }}</span> tidak akan tersedia lagi untuk ditukar nasabah.</p>
                <div class="flex space-x-2">
                    <button @click="openDelete = false" class="flex-1 py-4 bg-gray-100 rounded-2xl font-black text-gray-400 uppercase text-[10px]">Batal</button>
                    <button @click="handleDelete" class="flex-1 py-4 bg-red-600 text-white rounded-2xl font-black shadow-lg uppercase text-[10px]">Ya, Hapus</button>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>

<style scoped>
.transition-all { transition: all 0.3s ease-in-out; }
</style>
