<script setup>
import AdminLayout from '@/Layouts/AdminLayout.vue';
import { ref, onMounted } from 'vue';
import { financeApi } from '@/api';

// --- STATE DATA ---
const withdrawals = ref([]);
const isLoading = ref(true);
const isSubmitting = ref(false);
const successMessage = ref('');

// State Modal & File
const openEdit = ref(false);
const currWD = ref({
    id: '',
    user_id: '',
    jumlah: '',
    status: '',
    metode: '',
    nomor_tujuan: '',
    nama_penerima: ''
});
const selectedFile = ref(null);

// --- LOGIC: AMBIL DATA DARI MICROSERVICE ---
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
        if (selectedFile.value) {
            formData.append('bukti_transfer', selectedFile.value);
        }

        // PANGGIL URL YANG SUDAH KITA BUAT DI PORT 8000 TADI
        // Gunakan axios standar (bukan financeApi) karena kita lewat project 8000
        await axios.post(`/api/admin/penarikan-update/${currWD.value.id}`, formData, {
            headers: {
                'Content-Type': 'multipart/form-data',
                'Authorization': `Bearer ${localStorage.getItem('admin_token')}`
            }
        });

        alert("Berhasil!");
        fetchWithdrawals();
        openEdit.value = false;
    } catch (error) {
        console.error(error.response);
        alert("Gagal mengirim file. Cek console browser.");
    } finally {
        isSubmitting.value = false;
    }
};

// --- HELPERS ---
const openEditModal = (wd) => {
    // Memetakan data secara eksplisit agar menghindari bug object reference kosong
    currWD.value = {
        id: wd.id,
        user_id: wd.user_id,
        jumlah: wd.jumlah,
        status: wd.status,
        metode: wd.metode,
        nomor_tujuan: wd.nomor_tujuan || '-',
        nama_penerima: wd.nama_penerima || '-'
    };
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
        case 'menunggu': return 'bg-orange-100 text-orange-600 border border-orange-200';
        case 'diproses': return 'bg-blue-100 text-blue-600 border border-blue-200';
        case 'selesai': return 'bg-green-100 text-green-600 border border-green-200';
        case 'ditolak': return 'bg-red-100 text-red-600 border border-red-200';
        default: return 'bg-gray-100 text-gray-600';
    }
};

onMounted(() => fetchWithdrawals());
</script>

<template>
    <AdminLayout>
        <!-- Header Section -->
        <div class="flex justify-between items-end mb-10 transition-all duration-500">
            <div>
                <h2 class="text-4xl font-black text-slate-900 dark:text-white uppercase tracking-tighter leading-none">
                    Financial <span class="text-[#41D3BD]">Billing</span>
                </h2>
                <p class="text-gray-400 dark:text-slate-500 font-bold uppercase text-xs tracking-widest mt-3">
                    Manajemen pencairan dana nasabah (CIA Integrity Standards)
                </p>
            </div>
            <button class="flex items-center space-x-3 bg-slate-900 dark:bg-[#41D3BD] text-[#41D3BD] dark:text-slate-900 px-10 py-5 rounded-[2rem] transition-all duration-300 shadow-xl font-black uppercase text-sm tracking-widest hover:scale-105 active:scale-95">
                <i class="fa-solid fa-file-invoice-dollar text-lg"></i>
                <span>Export Report</span>
            </button>
        </div>

        <!-- Alert Notification -->
        <Transition name="fade">
            <div v-if="successMessage" class="mb-8 p-5 bg-black text-[#41D3BD] rounded-3xl font-black shadow-xl flex items-center border-l-8 border-[#41D3BD]">
                <i class="fa-solid fa-circle-check text-2xl mr-4"></i> {{ successMessage }}
            </div>
        </Transition>

        <!-- Table Container -->
        <div class="bg-white dark:bg-slate-900 rounded-[3rem] shadow-2xl border border-gray-100 dark:border-slate-800 relative overflow-hidden transition-all duration-500">

            <div v-if="isLoading" class="absolute inset-0 bg-white/50 dark:bg-slate-900/50 backdrop-blur-sm z-20 flex items-center justify-center">
                <div class="w-12 h-12 border-4 border-[#41D3BD] border-t-transparent rounded-full animate-spin"></div>
            </div>

            <table class="w-full text-left border-collapse">
                <thead class="bg-[#41D3BD] dark:bg-teal-700">
                    <tr>
                        <th class="pl-12 py-7 text-black dark:text-white font-black uppercase text-xs tracking-widest rounded-tl-[3rem]">User / Identity</th>
                        <th class="px-6 py-7 text-black dark:text-white font-black uppercase text-xs tracking-widest text-center">Amount (IDR)</th>
                        <th class="px-6 py-7 text-black dark:text-white font-black uppercase text-xs tracking-widest">Transfer Destination</th>
                        <th class="px-6 py-7 text-black dark:text-white font-black uppercase text-xs tracking-widest text-center">Status</th>
                        <th class="pr-12 py-7 text-center rounded-tr-[3rem]">
                            <span class="bg-white dark:bg-slate-800 px-5 py-1 rounded-lg text-[10px] font-black text-black dark:text-[#41D3BD] uppercase tracking-tighter">Action</span>
                        </th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-50 dark:divide-slate-800 transition-colors duration-500">
                    <tr v-for="wd in withdrawals" :key="wd.id" class="hover:bg-gray-50/50 dark:hover:bg-slate-800/30 transition-all group">
                        <td class="pl-12 py-6">
                            <div class="flex items-center space-x-5">
                                <div class="w-12 h-12 bg-slate-100 dark:bg-slate-800 rounded-2xl flex items-center justify-center font-black text-[#41D3BD] uppercase border-2 border-transparent group-hover:border-[#41D3BD] transition-all">
                                    <i class="fa-solid fa-user-tag text-sm"></i>
                                </div>
                                <div class="flex flex-col">
                                    <span class="font-black text-lg text-blue-600 dark:text-blue-400 uppercase tracking-tighter leading-none">Nasabah #{{ wd.user_id }}</span>
                                    <span class="text-[10px] text-gray-400 dark:text-slate-500 font-bold uppercase mt-1">Ref: #WD-{{ wd.id }}</span>
                                </div>
                            </div>
                        </td>
                        <td class="px-6 py-6 text-center">
                            <div class="font-black text-xl text-slate-800 dark:text-white tracking-tighter leading-none">
                                Rp {{ Number(wd.jumlah).toLocaleString('id-ID') }}
                            </div>
                            <div class="text-[9px] text-slate-400 uppercase mt-1 font-bold">Withdraw Amount</div>
                        </td>
                        <td class="px-6 py-6">
                            <div class="flex flex-col">
                                <div class="flex items-center space-x-2">
                                    <span class="bg-slate-900 text-[#41D3BD] px-2 py-0.5 rounded text-[9px] font-black">{{ wd.metode }}</span>
                                    <span class="font-black text-slate-700 dark:text-slate-200 text-sm">{{ wd.nomor_tujuan || '-' }}</span>
                                </div>
                                <span class="text-[10px] font-bold text-gray-400 dark:text-slate-500 uppercase mt-1 tracking-wider">A/N: {{ wd.nama_penerima || 'N/A' }}</span>
                            </div>
                        </td>
                        <td class="px-6 py-6 text-center">
                            <span :class="getStatusClass(wd.status)" class="px-4 py-1.5 rounded-full font-black text-[9px] uppercase tracking-widest border shadow-sm">
                                {{ wd.status }}
                            </span>
                        </td>
                        <td class="pr-12 py-6 text-center">
                            <div class="flex items-center justify-end space-x-3 opacity-40 group-hover:opacity-100 transition-opacity">
                                <button v-if="wd.status === 'menunggu' || wd.status === 'diproses'"
                                    @click="openEditModal(wd)"
                                    class="w-11 h-11 bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 rounded-2xl flex items-center justify-center hover:bg-blue-600 dark:hover:bg-blue-600 hover:text-white transition-all shadow-sm">
                                    <i class="fa-solid fa-sliders text-sm"></i>
                                </button>
                                <div v-else class="text-[10px] font-black text-gray-300 uppercase italic">Finalized</div>
                            </div>
                        </td>
                    </tr>
                </tbody>
            </table>
            <div class="h-10"></div>
        </div>

        <!-- MODAL: UPDATE WITHDRAWAL (PROFESSIONAL VERSION) -->
        <div v-if="openEdit" class="fixed inset-0 z-[100] flex items-center justify-center bg-black/50 backdrop-blur-sm p-4 transition-all">
            <div class="bg-white rounded-[3.5rem] max-w-lg w-full p-12 shadow-2xl relative border-[10px] border-slate-900 dark:border-slate-800 max-h-[90vh] overflow-y-auto">
                <div class="flex flex-col items-center text-center mb-10">
                    <div class="w-20 h-20 bg-blue-50 dark:bg-slate-800 text-blue-600 rounded-[2rem] flex items-center justify-center text-3xl mb-4 border border-blue-100 shadow-inner">
                        <i class="fa-solid fa-money-check-dollar"></i>
                    </div>
                    <h3 class="text-3xl font-black text-slate-900 dark:text-white uppercase tracking-tighter leading-none">Process Disbursement</h3>
                    <p class="text-gray-400 dark:text-slate-500 font-bold text-[10px] uppercase tracking-widest mt-2 leading-none">Authorization Ledger ID: #WD-{{ currWD.id }}</p>
                </div>

                <!-- Detail Rekening (Lolos ke Render Modal) -->
                <div class="grid grid-cols-2 gap-4 mb-8">
                    <div class="bg-slate-50 dark:bg-slate-800 p-4 rounded-2xl border border-slate-100 dark:border-slate-700">
                        <span class="text-[9px] font-black text-slate-400 uppercase tracking-widest block mb-1">Method / Number</span>
                        <span class="text-xs font-black text-slate-800 dark:text-white uppercase">{{ currWD.metode }} - {{ currWD.nomor_tujuan }}</span>
                    </div>
                    <div class="bg-slate-50 dark:bg-slate-800 p-4 rounded-2xl border border-slate-100 dark:border-slate-700">
                        <span class="text-[9px] font-black text-slate-400 uppercase tracking-widest block mb-1">Account Holder</span>
                        <span class="text-xs font-black text-slate-800 dark:text-white uppercase truncate block">{{ currWD.nama_penerima }}</span>
                    </div>
                </div>

                <form @submit.prevent="handleUpdateStatus" class="space-y-6">
                    <div class="space-y-4">
                        <div class="space-y-2">
                            <label class="text-[11px] font-black text-gray-400 uppercase tracking-widest ml-2">Update State</label>
                            <select v-model="currWD.status"
                                class="w-full px-8 py-5 bg-gray-50 dark:bg-slate-800 border-none rounded-[2rem] focus:ring-4 focus:ring-[#41D3BD]/30 outline-none font-black text-slate-800 dark:text-white uppercase text-xs transition-all">
                                <option value="menunggu">WAITING LIST</option>
                                <option value="diproses">UNDER REVIEW (IN PROCESS)</option>
                                <option value="selesai">COMPLETED (SEND FUNDS)</option>
                                <option value="ditolak">REJECTED (RETURN FUNDS)</option>
                            </select>
                        </div>

                        <!-- Input Bukti Transfer (Hanya muncul jika Selesai) -->
                        <div v-if="currWD.status === 'selesai'" class="space-y-3">
                            <label class="text-[11px] font-black text-blue-500 uppercase tracking-widest ml-2">Attach Transfer Receipt (Image)</label>
                            <input type="file" @change="onFileChange" accept="image/*" required
                                class="w-full text-xs text-gray-400 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-xs file:font-black file:bg-blue-50 file:text-blue-600 hover:file:bg-blue-100">
                        </div>

                        <!-- Warning Pesan -->
                        <div v-if="currWD.status === 'ditolak'" class="p-4 bg-red-50 dark:bg-red-950/20 rounded-2xl border border-red-100 dark:border-red-900/50">
                            <p class="text-[9px] text-red-600 dark:text-red-400 font-black uppercase tracking-tighter">
                                <i class="fa-solid fa-triangle-exclamation mr-1"></i> Funds will be automatically credited back to user's wallet.
                            </p>
                        </div>
                    </div>

                    <div class="flex justify-end space-x-4 pt-6">
                        <button @click="closeModals" type="button" class="px-10 py-5 bg-gray-100 dark:bg-slate-800 rounded-full font-black text-gray-400 dark:text-slate-500 uppercase text-xs tracking-widest hover:bg-gray-200 transition-colors">Discard</button>
                        <button type="submit" :disabled="isSubmitting"
                            class="px-12 py-5 bg-slate-900 dark:bg-[#41D3BD] text-[#41D3BD] dark:text-slate-900 rounded-full font-black shadow-2xl uppercase text-xs tracking-widest hover:scale-105 active:scale-95 transition-all flex items-center">
                            <span v-if="!isSubmitting">Confirm Execution</span>
                            <span v-else class="flex items-center"><i class="fa-solid fa-spinner animate-spin mr-3"></i> Processing...</span>
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </AdminLayout>
</template>

<style scoped>
.fade-enter-active, .fade-leave-active { transition: opacity 0.4s ease; }
.fade-enter-from, .fade-leave-to { opacity: 0; }
* { transition: background-color 0.4s ease-in-out, border-color 0.4s ease-in-out, color 0.4s ease-in-out; }
</style>
