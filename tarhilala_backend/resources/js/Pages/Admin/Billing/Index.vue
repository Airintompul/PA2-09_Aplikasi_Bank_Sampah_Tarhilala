<script setup>
import AdminLayout from '@/Layouts/AdminLayout.vue';
import { ref, onMounted, computed } from 'vue';
import axios from 'axios';
import { financeApi } from '@/api';

// --- STATE DATA ---
const withdrawals = ref([]);
const isLoading = ref(true);
const isSubmitting = ref(false);
const isExporting = ref(false); // State loading untuk ekspor
const successMessage = ref('');
const errorMessage = ref('');

const openEdit = ref(false);
const currWD = ref({ id: '', user_id: '', jumlah: '', status: '', metode: '', nomor_tujuan: '', nama_penerima: '' });
const selectedFile = ref(null);

// --- LOGIC HIDE NAVBAR & BLUR ---
const isAnyModalOpen = computed(() => {
    return openEdit.value;
});

const fetchWithdrawals = async () => {
    isLoading.value = true;
    try {
        const response = await financeApi.get('/penarikan');
        withdrawals.value = response.data.data;
    } catch (error) {
        console.error("Gagal memuat data penarikan:", error);
    } finally {
        isLoading.value = false;
    }
};

// =========================================================================
// LOGIC TOMBOL EKSPOR (FUNGSI UTAMA)
// =========================================================================
const handleExport = async () => {
    isExporting.value = true;
    try {
        // Tembak API Export di Service Gateway (Port 8000)
        const response = await axios.get('/api/admin/penarikan/export', {
            headers: { Authorization: `Bearer ${localStorage.getItem('admin_token')}` },
            responseType: 'blob', // PENTING: Menerima file sebagai data binary
        });

        // Proses pengunduhan di browser
        const url = window.URL.createObjectURL(new Blob([response.data]));
        const link = document.createElement('a');
        link.href = url;

        // Nama file yang akan muncul di komputer admin
        const date = new Date().toLocaleDateString().replace(/\//g, '-');
        link.setAttribute('download', `Laporan-Penarikan-Tanggal-${date}.xlsx`);

        document.body.appendChild(link);
        link.click();

        // Bersihkan resource memori
        link.remove();
        window.URL.revokeObjectURL(url);

        showSuccess("Laporan Excel berhasil diunduh!");
    } catch (error) {
    console.log("FULL ERROR:", error);

    if (error.response) {
        const text = await error.response.data.text();
        console.log(text);
    }
    } finally {
        isExporting.value = false;
    }
};
// =========================================================================

const onFileChange = (e) => {
    selectedFile.value = e.target.files[0];
};

const handleUpdateStatus = async () => {
    if (currWD.value.status === 'selesai' && !selectedFile.value) {
        alert("Wajib mengunggah bukti transfer!");
        return;
    }
    isSubmitting.value = true;
    try {
        const formData = new FormData();
        formData.append('status', currWD.value.status);
        if (selectedFile.value) formData.append('bukti_transfer', selectedFile.value);

        await axios.post(`/api/admin/penarikan-update/${currWD.value.id}`, formData, {
            headers: {
                'Content-Type': 'multipart/form-data',
                'Authorization': `Bearer ${localStorage.getItem('admin_token')}`
            }
        });
        fetchWithdrawals();
        openEdit.value = false;
        showSuccess("Berhasil Memperbarui Status!");
    } catch (error) {
        alert("Gagal memperbarui status");
    } finally {
        isSubmitting.value = false;
    }
};

const openEditModal = (wd) => {
    currWD.value = { ...wd };
    selectedFile.value = null;
    openEdit.value = true;
};

const closeModals = () => {
    openEdit.value = false;
    selectedFile.value = null;
};

const showSuccess = (msg) => {
    successMessage.value = msg;
    setTimeout(() => successMessage.value = '', 4000);
};

const getStatusClass = (status) => {
    switch (status) {
        case 'menunggu': return 'bg-orange-50 text-orange-600 border-orange-100';
        case 'diproses': return 'bg-blue-50 text-blue-600 border-blue-100';
        case 'selesai': return 'bg-green-50 text-green-600 border-green-100';
        case 'ditolak': return 'bg-red-50 text-red-600 border-red-100';
        default: return 'bg-gray-50 text-gray-400 border-gray-100';
    }
};

onMounted(() => fetchWithdrawals());
</script>

<template>
    <AdminLayout :hideNavbar="isAnyModalOpen">

        <div :class="{'blur-md opacity-50 pointer-events-none transition-all duration-500': isAnyModalOpen}">

            <!-- Header Section -->
            <div class="flex flex-col md:flex-row justify-between items-start md:items-center mb-8 gap-4 px-2 md:px-0">
                <div>
                    <h2 class="text-2xl md:text-4xl font-black text-gray-900 uppercase tracking-tight leading-none">
                        Penarikan <span class="text-[#41D3BD]">Saldo</span>
                    </h2>
                    <p class="text-[10px] md:text-xs font-bold text-gray-400 uppercase tracking-widest mt-2">
                        Manajemen Pencairan Dana & Transaksi Nasabah
                    </p>
                </div>

                <!-- TOMBOL EKSPOR: Sekarang berfungsi memanggil handleExport -->
                <button
                    @click="handleExport"
                    :disabled="isExporting"
                    class="w-full md:w-auto flex items-center justify-center space-x-3 bg-[#41D3BD] hover:opacity-80 text-black px-8 py-4 rounded-2xl md:rounded-[2rem] transition-all shadow-lg font-black uppercase text-xs md:text-sm tracking-widest disabled:opacity-50"
                >
                    <i v-if="isExporting" class="fa-solid fa-spinner animate-spin text-lg"></i>
                    <i v-else class="fa-solid fa-file-excel text-lg"></i>
                    <span>{{ isExporting ? 'Processing...' : 'Ekspor Laporan' }}</span>
                </button>
            </div>

            <!-- Alert Notifikasi -->
            <Transition name="fade">
                <div v-if="successMessage" class="mx-2 md:mx-0 mb-6 p-4 md:p-5 bg-black text-[#41D3BD] rounded-2xl md:rounded-3xl font-black shadow-xl flex items-center border-l-8 border-[#41D3BD] text-xs md:text-sm">
                    <i class="fa-solid fa-circle-check text-xl md:text-2xl mr-4"></i> {{ successMessage }}
                </div>
            </Transition>

            <!-- VIEW DESKTOP: TABEL -->
            <div class="hidden lg:block bg-white rounded-[2.5rem] shadow-sm border border-gray-100 relative overflow-hidden transition-all duration-300">
                <table class="w-full text-left border-collapse">
                    <thead class="bg-[#41D3BD]">
                        <tr class="text-black font-black uppercase text-[11px] tracking-widest">
                            <th class="pl-12 py-7 rounded-tl-[2.5rem]">Identitas User</th>
                            <th class="px-6 py-7 text-center">Nominal (IDR)</th>
                            <th class="px-6 py-7">Tujuan Transfer</th>
                            <th class="px-6 py-7 text-center">Status</th>
                            <th class="pr-12 py-7 text-right rounded-tr-[2.5rem]">Aksi</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-50 font-medium">
                        <tr v-if="isLoading">
                            <td colspan="5" class="py-20 text-center">
                                <div class="inline-block w-8 h-8 border-4 border-[#41D3BD] border-t-transparent rounded-full animate-spin"></div>
                            </td>
                        </tr>
                        <tr v-else v-for="wd in withdrawals" :key="wd.id" class="hover:bg-gray-50/50 transition-all">
                            <td class="pl-12 py-6">
                                <div class="flex flex-col">
                                    <span class="font-black text-lg uppercase text-blue-600 tracking-tighter leading-none">Nasabah #{{ wd.user_id }}</span>
                                    <span class="text-[10px] text-gray-400 font-bold uppercase mt-1">REF: #WD-{{ wd.id }}</span>
                                </div>
                            </td>
                            <td class="px-6 py-6 text-center font-black text-lg text-slate-800 tracking-tighter">
                                Rp {{ Number(wd.jumlah).toLocaleString('id-ID') }}
                            </td>
                            <td class="px-6 py-6">
                                <div class="flex items-center space-x-2">
                                    <span class="bg-[#41D3BD] text-black px-2 py-0.5 rounded text-[9px] font-black uppercase tracking-widest shadow-sm">{{ wd.metode }}</span>
                                    <span class="font-black text-slate-700 text-xs tracking-tight">{{ wd.nomor_tujuan }}</span>
                                </div>
                            </td>
                            <td class="px-6 py-6 text-center">
                                <span :class="getStatusClass(wd.status)" class="px-4 py-1.5 rounded-full font-black text-[9px] uppercase tracking-widest border shadow-sm">
                                    {{ wd.status }}
                                </span>
                            </td>
                            <td class="pr-12 py-6 text-right">
                                <div class="flex justify-end space-x-2">
                                    <button v-if="wd.status === 'menunggu' || wd.status === 'diproses'"
                                            @click="openEditModal(wd)"
                                            class="w-10 h-10 bg-blue-50 text-blue-600 rounded-xl hover:bg-blue-600 hover:text-white transition-all shadow-sm flex items-center justify-center">
                                        <i class="fa-solid fa-pen-nib"></i>
                                    </button>
                                    <span v-else class="text-[10px] font-black text-gray-300 uppercase italic px-2">Selesai</span>
                                </div>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <!-- VIEW MOBILE: CARDS -->
            <div class="lg:hidden space-y-4 px-2 pb-10">
                <div v-for="wd in withdrawals" :key="wd.id" class="bg-white p-5 rounded-[2rem] shadow-sm border border-gray-100 space-y-4">
                    <div class="flex justify-between items-start">
                        <div class="min-w-0">
                            <h4 class="font-black text-blue-600 uppercase text-sm truncate pr-2">Nasabah #{{ wd.user_id }}</h4>
                            <p class="text-[9px] font-bold text-gray-400 uppercase">#WD-{{ wd.id }}</p>
                        </div>
                        <span :class="getStatusClass(wd.status)" class="px-2 py-0.5 rounded-full font-black text-[8px] uppercase tracking-widest border shadow-sm">{{ wd.status }}</span>
                    </div>

                    <div class="bg-gray-50 p-3 rounded-2xl border border-gray-100 text-center">
                        <p class="text-[8px] font-black text-gray-400 uppercase mb-1 tracking-widest">Withdrawal Amount</p>
                        <p class="text-xl font-black text-slate-800 tracking-tighter">Rp {{ Number(wd.jumlah).toLocaleString('id-ID') }}</p>
                    </div>

                    <div class="flex gap-2">
                        <button v-if="wd.status === 'menunggu' || wd.status === 'diproses'"
                            @click="openEditModal(wd)"
                            class="flex-1 py-3 bg-[#41D3BD] text-black rounded-xl font-black text-[10px] uppercase tracking-widest shadow-sm active:scale-95 transition-all">
                            Kelola Transaksi
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!-- MODAL UPDATE -->
        <div v-if="openEdit" class="fixed inset-0 z-[999] flex items-center justify-center bg-black/40 backdrop-blur-sm px-4 py-8">
            <div class="bg-white rounded-[2.5rem] md:rounded-[3rem] max-w-xl w-full p-6 md:p-10 shadow-2xl relative overflow-y-auto max-h-[92vh] border-[6px] border-slate-900 transition-all duration-300">
                <div class="flex flex-col items-center text-center mb-8">
                    <div class="w-16 h-16 bg-blue-50 text-blue-600 rounded-2xl flex items-center justify-center text-2xl mb-4 shadow-inner"><i class="fa-solid fa-money-check-dollar"></i></div>
                    <h3 class="text-xl md:text-2xl font-black text-slate-900 uppercase tracking-tighter leading-none">Verifikasi Pencairan</h3>
                </div>

                <form @submit.prevent="handleUpdateStatus" class="space-y-6">
                    <div class="space-y-4">
                        <div class="space-y-2">
                            <label class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Update Status Transaksi</label>
                            <select v-model="currWD.status" class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl font-black text-slate-800 uppercase text-[10px] md:text-xs outline-none focus:ring-2 focus:ring-[#41D3BD]">
                                <option value="menunggu">DAFTAR TUNGGU</option>
                                <option value="diproses">SEDANG DIREVIEW</option>
                                <option value="selesai">SELESAI (KIRIM DANA)</option>
                                <option value="ditolak">TOLAK (REFUND POIN)</option>
                            </select>
                        </div>

                        <div v-if="currWD.status === 'selesai'" class="bg-blue-50/50 p-4 rounded-2xl border-2 border-blue-100 border-dashed space-y-3">
                            <label class="text-[9px] font-black text-blue-600 uppercase tracking-widest ml-1">Upload Bukti Transfer (PENTING)</label>
                            <input type="file" @change="onFileChange" accept="image/*" required class="w-full text-[10px] text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-[10px] file:font-black file:bg-[#41D3BD]/10 file:text-[#41D3BD]">
                        </div>
                    </div>

                    <div class="flex flex-col-reverse md:flex-row justify-end gap-3 pt-6 border-t border-gray-100">
                        <button @click="closeModals" type="button" class="w-full md:w-auto px-8 py-4 bg-gray-100 rounded-full font-black text-gray-400 uppercase text-[10px]">Batal</button>
                        <button type="submit" :disabled="isSubmitting"
                            class="w-full md:w-auto px-10 py-4 bg-slate-900 text-[#41D3BD] rounded-full font-black shadow-lg uppercase text-[10px] hover:scale-105 transition-all">
                            {{ isSubmitting ? 'Memproses...' : 'Simpan Status' }}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </AdminLayout>
</template>

<style scoped>
.transition-all { transition: all 0.3s ease-in-out; }
</style>
