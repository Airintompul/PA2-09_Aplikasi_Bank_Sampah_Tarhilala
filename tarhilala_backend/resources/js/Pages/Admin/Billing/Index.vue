<script setup>
import AdminLayout from '@/Layouts/AdminLayout.vue';
import { ref, onMounted } from 'vue';
import { financeApi } from '@/api'; // Import instance finance yang baru dibuat

// --- STATE ---
const withdrawals = ref([]);
const isLoading = ref(true);
const successMessage = ref('');

// State Modal Update
const openEdit = ref(false);
const currWD = ref({ id: '', user_id: '', jumlah: '', status: '', metode: '' });

// --- LOGIC: AMBIL DATA DARI MICROSERVICE ---
const fetchWithdrawals = async () => {
    try {
        const response = await financeApi.get('/penarikan');
        withdrawals.value = response.data.data;
    } catch (error) {
        console.error("Gagal memuat data penarikan");
    } finally {
        isLoading.value = false;
    }
};

// --- LOGIC: UPDATE STATUS PENARIKAN ---
const handleUpdateStatus = async () => {
    try {
        await financeApi.put(`/penarikan/${currWD.value.id}`, {
            status: currWD.value.status
        });

        openEdit.value = false;
        showSuccess("Status Penarikan Berhasil Diperbarui!");
        fetchWithdrawals(); // Refresh tabel
    } catch (error) {
        alert(error.response?.data?.message || "Gagal memperbarui status");
    }
};

// --- HELPERS ---
const openEditModal = (wd) => {
    currWD.value = { ...wd };
    openEdit.value = true;
};

const showSuccess = (msg) => {
    successMessage.value = msg;
    setTimeout(() => successMessage.value = '', 3000);
};

onMounted(() => fetchWithdrawals());
</script>

<template>
    <AdminLayout>
        <div class="flex justify-between items-center mb-8">
            <h2 class="text-4xl font-black text-gray-900 uppercase tracking-tight">Billing</h2>
            <button class="flex items-center space-x-3 bg-[#41D3BD] hover:opacity-80 text-black px-8 py-4 rounded-[2rem] transition-all shadow-lg font-black uppercase text-sm tracking-widest">
                <i class="fa-solid fa-file-invoice-dollar text-lg"></i>
                <span>Export Finance Report</span>
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
                        <th class="px-6 py-6 text-black font-black uppercase text-sm tracking-widest text-center">Jumlah</th>
                        <th class="px-6 py-6 text-black font-black uppercase text-sm tracking-widest">Metode</th>
                        <th class="px-6 py-6 text-black font-black uppercase text-sm tracking-widest text-center">Status</th>
                        <th class="px-8 py-6 text-center rounded-tr-[2.5rem]">
                            <span class="bg-white px-5 py-1 rounded-lg text-xs font-black text-black uppercase">Action</span>
                        </th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 text-black font-medium">
                    <tr v-for="wd in withdrawals" :key="wd.id" class="hover:bg-gray-50/50 transition-all">
                        <td class="pl-20 py-6">
                            <span class="font-black text-lg uppercase text-blue-600 tracking-tighter">NASABAH #{{ wd.user_id }}</span>
                            <div class="text-[10px] text-gray-400 font-bold uppercase mt-1">Ref: #WD-{{ wd.id }}</div>
                        </td>
                        <td class="px-6 py-6 text-center font-black text-lg text-gray-800">
                            Rp {{ Number(wd.jumlah).toLocaleString('id-ID') }}
                        </td>
                        <td class="px-6 py-6 uppercase text-xs font-black">
                            <span class="px-2 py-1 bg-gray-100 rounded-md border border-gray-200 text-gray-500">
                                <i class="fa-solid fa-building-columns mr-1"></i> {{ wd.metode }}
                            </span>
                        </td>
                        <td class="px-6 py-6 text-center">
                            <span class="px-4 py-1 rounded-full text-[10px] font-black uppercase"
                                :class="{
                                    'bg-yellow-100 text-yellow-700': wd.status === 'menunggu',
                                    'bg-blue-100 text-blue-700': wd.status === 'diproses',
                                    'bg-green-100 text-green-700': wd.status === 'selesai',
                                    'bg-red-100 text-red-700': wd.status === 'ditolak'
                                }">
                                {{ wd.status }}
                            </span>
                        </td>
                        <td class="px-8 py-6 text-center">
                            <button @click="openEditModal(wd)" class="p-3 bg-blue-50 text-blue-600 rounded-xl hover:bg-blue-600 hover:text-white transition-all shadow-sm">
                                <i class="fa-solid fa-gear"></i>
                            </button>
                        </td>
                    </tr>
                    <tr v-if="withdrawals.length === 0 && !isLoading">
                        <td colspan="5" class="py-20 text-center text-gray-300 font-black uppercase italic tracking-widest text-sm">Tidak ada transaksi keuangan</td>
                    </tr>
                </tbody>
            </table>
            <div class="h-6"></div>
        </div>

        <!-- MODAL UPDATE STATUS (PENCARIAN DANA) -->
        <div v-if="openEdit" class="fixed inset-0 z-[100] flex items-center justify-center bg-black/50 backdrop-blur-sm px-4">
            <div class="bg-white rounded-[3rem] max-w-lg w-full p-10 shadow-2xl relative">
                <div class="flex justify-between items-start mb-8">
                    <div>
                        <h3 class="text-2xl font-black text-gray-800 uppercase tracking-tighter">Update Penarikan</h3>
                        <p class="text-xs font-bold text-gray-400 uppercase mt-1">Nasabah ID: {{ currWD.user_id }}</p>
                    </div>
                    <span class="px-4 py-2 bg-[#41D3BD]/10 text-[#41D3BD] rounded-2xl font-black text-lg">
                        Rp {{ Number(currWD.jumlah).toLocaleString() }}
                    </span>
                </div>

                <form @submit.prevent="handleUpdateStatus" class="space-y-6">
                    <div>
                        <label class="text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Status Transaksi</label>
                        <select v-model="currWD.status" class="w-full px-6 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-black text-gray-700 uppercase text-xs">
                            <option value="menunggu">MENUNGGU</option>
                            <option value="diproses">DIPROSES (Konfirmasi Admin)</option>
                            <option value="selesai">SELESAI (Potong Saldo)</option>
                            <option value="ditolak">DITOLAK</option>
                        </select>
                        <p v-if="currWD.status === 'selesai'" class="mt-2 text-[10px] text-red-500 font-bold italic">
                            *PENTING: Memilih SELESAI akan otomatis memotong saldo dompet Nasabah.
                        </p>
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
