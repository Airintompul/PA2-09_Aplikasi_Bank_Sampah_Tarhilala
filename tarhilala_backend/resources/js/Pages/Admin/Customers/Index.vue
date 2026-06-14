<script setup>
import AdminLayout from '@/Layouts/AdminLayout.vue';
import { ref, onMounted, computed } from 'vue';
import api from '@/api';

// --- STATE DATA ---
const customers = ref([]);
const isLoading = ref(true);
const successMessage = ref('');
const errorMessage = ref(''); // State untuk notifikasi warning/error

// State Modals
const openAdd = ref(false);
const openEdit = ref(false);
const openDelete = ref(false);

// STATE SHOW/HIDE PASSWORD
const showPassword = ref(false);

// LOGIC: Deteksi jika ada modal yang aktif
const isAnyModalOpen = computed(() => {
    return openAdd.value || openEdit.value || openDelete.value;
});

// State Form
const currUser = ref({ id: '', nama: '', email: '', nomor_telepon: '', password: '' });

// --- LOGIC API: FETCH ---
const fetchCustomers = async () => {
    try {
        const response = await api.get('/customers');
        customers.value = response.data.data;
    } catch (error) {
        console.error("Gagal mengambil data nasabah");
    } finally {
        isLoading.value = false;
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

// --- LOGIC: SIMPAN NASABAH ---
const handleStore = async () => {
    // VALIDASI WAJIB ISI NOMOR TELEPON
    if (!currUser.value.nomor_telepon || currUser.value.nomor_telepon.trim() === "") {
        showError("Please fill out this field (Phone Number)");
        return;
    }

    try {
        await api.post('/customers', currUser.value);
        closeModals();
        showSuccess("Nasabah Berhasil Ditambahkan!");
        fetchCustomers();
    } catch (error) {
        showError(error.response?.data?.message || "Gagal menyimpan nasabah");
    }
};

// --- LOGIC: UPDATE ---
const handleUpdate = async () => {
    // VALIDASI WAJIB ISI NOMOR TELEPON
    if (!currUser.value.nomor_telepon || currUser.value.nomor_telepon.trim() === "") {
        showError("Please fill out this field (Phone Number)");
        return;
    }

    try {
        await api.put(`/customers/${currUser.value.id}`, currUser.value);
        closeModals();
        showSuccess("Data Nasabah Berhasil Diperbarui!");
        fetchCustomers();
    } catch (error) {
        showError("Gagal memperbarui data nasabah");
    }
};

// --- LOGIC: HAPUS ---
const handleDelete = async () => {
    try {
        await api.delete(`/customers/${currUser.value.id}`);
        openDelete.value = false;
        showSuccess("Nasabah Berhasil Dihapus!");
        fetchCustomers();
    } catch (error) {
        showError("Gagal menghapus data");
    }
};

// --- HELPERS ---
const openEditModal = (user) => {
    currUser.value = { ...user, password: '' };
    openEdit.value = true;
};

const closeModals = () => {
    openAdd.value = false;
    openEdit.value = false;
    showPassword.value = false; // Reset status mata saat tutup modal
    currUser.value = { id: '', nama: '', email: '', nomor_telepon: '', password: '' };
};

const formatDate = (dateString) => {
    if (!dateString) return '-';
    const options = { day: '2-digit', month: 'short', year: 'numeric' };
    return new Date(dateString).toLocaleDateString('id-ID', options);
};

onMounted(() => fetchCustomers());
</script>

<template>
    <AdminLayout :hideNavbar="isAnyModalOpen">

        <!-- AREA BACKGROUND -->
        <div :class="{'blur-md opacity-50 pointer-events-none transition-all duration-500': isAnyModalOpen}">

            <!-- Header Section -->
            <div class="flex flex-col md:flex-row justify-between items-start md:items-center mb-8 gap-4 px-2 md:px-0">
                <div>
                    <h2 class="text-2xl md:text-4xl font-black text-gray-900 uppercase tracking-tight leading-none">
                        Daftar <span class="text-[#41D3BD]">Nasabah</span>
                    </h2>
                    <p class="text-[10px] md:text-xs font-bold text-gray-400 uppercase tracking-widest mt-2">
                        Manajemen Database & Keanggotaan Nasabah
                    </p>
                </div>
                <button @click="openAdd = true" class="w-full md:w-auto flex items-center justify-center space-x-3 bg-[#41D3BD] hover:opacity-80 text-black px-8 py-4 rounded-2xl md:rounded-[2rem] transition-all shadow-lg font-black uppercase text-xs md:text-sm tracking-widest">
                    <i class="fa-solid fa-user-plus text-lg"></i>
                    <span>Add Customer</span>
                </button>
            </div>

            <!-- NOTIFIKASI VALIDASI: POSISI INLINE DI BAWAH DESKRIPSI (KONSISTEN) -->
            <Transition name="fade">
                <div v-if="successMessage || errorMessage"
                     :class="successMessage ? 'bg-black text-[#41D3BD] border-[#41D3BD]' : 'bg-black text-orange-500 border-orange-500'"
                     class="mx-2 md:mx-0 mb-8 p-4 md:p-5 rounded-2xl md:rounded-3xl font-black shadow-xl flex items-center border-l-8 text-xs md:text-sm transition-all">

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
                            <th class="pl-12 py-7 rounded-tl-[2.5rem]">Nama Nasabah</th>
                            <th class="px-6 py-7">Email Address</th>
                            <th class="px-6 py-7 text-center">No. Telepon</th>
                            <th class="px-6 py-7 text-center">Tgl Registrasi</th>
                            <th class="pr-12 py-7 text-right rounded-tr-[2.5rem]">Aksi</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-50 font-medium">
                        <tr v-for="customer in customers" :key="customer.id" class="hover:bg-gray-50/50 transition-all">
                            <td class="pl-12 py-6">
                                <div class="flex flex-col">
                                    <span class="font-black text-lg uppercase text-black-600 tracking-tighter leading-none">{{ customer.nama }}</span>
                                    <span class="text-[10px] text-gray-400 font-bold uppercase mt-1">ID: #NSB-{{ customer.id }}</span>
                                </div>
                            </td>
                            <td class="px-6 py-6 font-bold text-slate-700 text-sm italic">{{ customer.email }}</td>
                            <td class="px-6 py-6 text-center font-black text-slate-800 tracking-tighter">{{ customer.nomor_telepon || '-' }}</td>
                            <td class="px-6 py-6 text-center text-[10px] text-gray-400 font-black uppercase tracking-wider">{{ formatDate(customer.created_at) }}</td>
                            <td class="pr-12 py-6 text-right">
                                <div class="flex justify-end space-x-2">
                                    <button @click="openEditModal(customer)" class="w-10 h-10 bg-blue-50 text-blue-600 rounded-xl hover:bg-blue-600 hover:text-white transition-all shadow-sm flex items-center justify-center">
                                        <i class="fa-solid fa-user-pen"></i>
                                    </button>
                                    <button @click="currUser = customer; openDelete = true" class="w-10 h-10 bg-red-50 text-red-600 rounded-xl hover:bg-red-600 hover:text-white transition-all shadow-sm flex items-center justify-center">
                                        <i class="fa-solid fa-trash"></i>
                                    </button>
                                </div>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <!-- 2. VIEW MOBILE: CARDS -->
            <div class="lg:hidden space-y-4 px-2 pb-10">
                <div v-for="customer in customers" :key="customer.id" class="bg-white p-5 rounded-[2rem] shadow-sm border border-gray-100 space-y-4">
                    <div class="flex justify-between items-start">
                        <div class="flex items-center space-x-3 min-w-0">
                            <div class="w-10 h-10 bg-slate-100 rounded-xl flex items-center justify-center font-black text-[#41D3BD] text-lg border border-white shadow-sm">
                                {{ customer.nama.substring(0, 1).toUpperCase() }}
                            </div>
                            <div class="min-w-0">
                                <h4 class="font-black text-blue-600 uppercase text-sm truncate pr-2 tracking-tighter">{{ customer.nama }}</h4>
                                <p class="text-[9px] font-bold text-gray-400 uppercase">#NSB-{{ customer.id }}</p>
                            </div>
                        </div>
                        <div class="flex space-x-1">
                            <button @click="openEditModal(customer)" class="p-2 text-blue-500"><i class="fa-solid fa-user-pen text-sm"></i></button>
                            <button @click="currUser = customer; openDelete = true" class="p-2 text-red-500"><i class="fa-solid fa-trash text-sm"></i></button>
                        </div>
                    </div>

                    <div class="bg-gray-50 p-3 rounded-2xl border border-gray-100 grid grid-cols-2 gap-2">
                        <div class="min-w-0">
                            <p class="text-[8px] font-black text-gray-400 uppercase mb-1">Email Address</p>
                            <p class="text-[10px] font-bold text-slate-700 truncate leading-none">{{ customer.email }}</p>
                        </div>
                        <div class="text-right">
                            <p class="text-[8px] font-black text-gray-400 uppercase mb-1">Phone Number</p>
                            <p class="text-[10px] font-black text-slate-800 leading-none">{{ customer.nomor_telepon || '-' }}</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- MODAL ADD/EDIT -->
        <div v-if="openAdd || openEdit" class="fixed inset-0 z-[999] flex items-center justify-center bg-black/40 backdrop-blur-sm px-4 py-8">
            <div class="bg-white rounded-[2.5rem] md:rounded-[3rem] max-w-xl w-full p-6 md:p-10 shadow-2xl relative overflow-y-auto max-h-[92vh] border-[6px] border-slate-900 transition-all duration-300">
                <h3 class="text-xl md:text-2xl font-black text-gray-800 uppercase tracking-tighter mb-8 text-center">
                    {{ openAdd ? 'Add New Customer' : 'Update Customer' }}
                </h3>

                <form @submit.prevent="openAdd ? handleStore() : handleUpdate()" class="space-y-5">
                    <div>
                        <label class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Nama Lengkap Nasabah</label>
                        <input v-model="currUser.nama" type="text" required class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-bold text-gray-700 text-sm uppercase">
                    </div>
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                            <label class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Email Akun</label>
                            <input v-model="currUser.email" type="email" required class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-bold text-gray-700 text-sm">
                        </div>
                        <div>
                            <label class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">No. WhatsApp</label>
                            <input v-model="currUser.nomor_telepon" type="text" required placeholder="Wajib diisi..." class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-bold text-gray-700 text-sm tracking-tighter">
                        </div>
                    </div>

                    <!-- INPUT PASSWORD DENGAN SHOW/HIDE (IKON MATA) -->
                    <div>
                        <label class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">
                            Akses Password {{ openEdit ? '(Kosongkan jika tidak diubah)' : '' }}
                        </label>
                        <div class="relative">
                            <input
                                v-model="currUser.password"
                                :type="showPassword ? 'text' : 'password'"
                                :required="openAdd"
                                class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-bold text-gray-700 text-sm"
                            >
                            <button
                                type="button"
                                @click="showPassword = !showPassword"
                                class="absolute right-5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-[#41D3BD] transition-colors"
                            >
                                <i class="fa-solid" :class="showPassword ? 'fa-eye-slash' : 'fa-eye'"></i>
                            </button>
                        </div>
                    </div>

                    <div class="flex flex-col-reverse md:flex-row justify-end gap-3 pt-6 border-t border-gray-50">
                        <button @click="closeModals" type="button" class="w-full md:w-auto px-8 py-4 bg-gray-100 rounded-full font-black text-gray-400 uppercase text-[10px] tracking-widest">Batal</button>
                        <button type="submit" class="w-full md:w-auto px-10 py-4 bg-blue-600 text-white rounded-full font-black shadow-lg uppercase text-[10px] hover:scale-105 transition-all">
                            Simpan Nasabah
                        </button>
                    </div>
                </form>
            </div>
        </div>

        <!-- MODAL DELETE -->
        <div v-if="openDelete" class="fixed inset-0 z-[999] flex items-center justify-center bg-black/50 backdrop-blur-sm px-4">
            <div class="bg-white rounded-[2.5rem] max-w-sm w-full p-8 text-center shadow-2xl border-b-8 border-gray-900 transition-all">
                <div class="w-16 h-16 bg-red-50 text-red-500 rounded-full flex items-center justify-center mx-auto mb-6 text-3xl shadow-inner">
                    <i class="fa-solid fa-user-minus"></i>
                </div>
                <h3 class="text-lg font-black text-gray-800 uppercase tracking-tighter mb-2">Hapus Nasabah?</h3>
                <p class="text-gray-400 text-[10px] font-bold mb-8 uppercase tracking-widest leading-relaxed">Seluruh data riwayat untuk <span class="text-red-500">{{ currUser.nama }}</span> akan terhapus permanen.</p>
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
