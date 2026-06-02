<script setup>
import AdminLayout from '@/Layouts/AdminLayout.vue';
import { ref, onMounted, computed } from 'vue';
import api from '@/api';

// --- STATE DATA ---
const employees = ref([]);
const isLoading = ref(true);
const successMessage = ref('');

// State Modal
const openAdd = ref(false);
const openEdit = ref(false);
const openDelete = ref(false);

// LOGIC: Deteksi jika ada modal yang aktif
const isAnyModalOpen = computed(() => {
    return openAdd.value || openEdit.value || openDelete.value;
});

// State Form
const currUser = ref({ id: '', nama: '', email: '', nomor_telepon: '', password: '', role: 'petugas' });

// --- LOGIC: AMBIL DATA ---
const fetchEmployees = async () => {
    try {
        const response = await api.get('/employees');
        employees.value = response.data.data;
    } catch (error) {
        console.error("Gagal mengambil data petugas");
    } finally {
        isLoading.value = false;
    }
};

// --- LOGIC: SIMPAN ---
const handleStore = async () => {
    try {
        await api.post('/employees', currUser.value);
        closeModals();
        showSuccess("Petugas Berhasil Ditambahkan!");
        fetchEmployees();
    } catch (error) {
        alert(error.response?.data?.message || "Gagal menyimpan petugas");
    }
};

// --- LOGIC: UPDATE ---
const handleUpdate = async () => {
    try {
        await api.put(`/employees/${currUser.value.id}`, currUser.value);
        closeModals();
        showSuccess("Data Petugas Berhasil Diperbarui!");
        fetchEmployees();
    } catch (error) {
        alert("Gagal memperbarui data petugas");
    }
};

// --- LOGIC: HAPUS ---
const handleDelete = async () => {
    try {
        await api.delete(`/employees/${currUser.value.id}`);
        openDelete.value = false;
        showSuccess("Petugas Berhasil Dihapus!");
        fetchEmployees();
    } catch (error) {
        alert("Gagal menghapus data");
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
    currUser.value = { id: '', nama: '', email: '', nomor_telepon: '', password: '', role: 'petugas' };
};

const showSuccess = (msg) => {
    successMessage.value = msg;
    setTimeout(() => successMessage.value = '', 3000);
};

onMounted(() => fetchEmployees());
</script>

<template>
    <AdminLayout :hideNavbar="isAnyModalOpen">

        <!-- AREA BACKGROUND: Konten utama dengan efek Blur -->
        <div :class="{'blur-md opacity-50 pointer-events-none transition-all duration-500': isAnyModalOpen}">

            <!-- Header Section: Disamakan dengan Setoran -->
            <div class="flex flex-col md:flex-row justify-between items-start md:items-center mb-8 gap-4 px-2 md:px-0">
                <div>
                    <h2 class="text-2xl md:text-4xl font-black text-gray-900 uppercase tracking-tight leading-none">
                        Daftar <span class="text-[#41D3BD]">Petugas</span>
                    </h2>
                    <p class="text-[10px] md:text-xs font-bold text-gray-400 uppercase tracking-widest mt-2">
                        Database Tim Lapangan & Administrasi
                    </p>
                </div>
                <button @click="openAdd = true" class="w-full md:w-auto flex items-center justify-center space-x-3 bg-[#41D3BD] hover:opacity-80 text-black px-8 py-4 rounded-2xl md:rounded-[2rem] transition-all shadow-lg font-black uppercase text-xs md:text-sm tracking-widest">
                    <i class="fa-solid fa-user-plus text-lg"></i>
                    <span>Add Employee</span>
                </button>
            </div>

            <!-- Alert Berhasil -->
            <div v-if="successMessage" class="mx-2 md:mx-0 mb-6 p-4 md:p-5 bg-black text-[#41D3BD] rounded-2xl md:rounded-3xl font-black shadow-xl flex items-center border-l-8 border-[#41D3BD] text-xs md:text-sm">
                <i class="fa-solid fa-circle-check text-xl md:text-2xl mr-4"></i> {{ successMessage }}
            </div>

            <!-- 1. VIEW DESKTOP: TABEL -->
            <div class="hidden lg:block bg-white rounded-[2.5rem] shadow-sm border border-gray-100 relative overflow-hidden transition-all duration-300">
                <table class="w-full text-left border-collapse">
                    <thead class="bg-[#41D3BD]">
                        <tr class="text-black font-black uppercase text-[11px] tracking-widest">
                            <th class="pl-12 py-7 rounded-tl-[2.5rem]">Nama Petugas</th>
                            <th class="px-6 py-7 text-center">Role Access</th>
                            <th class="px-6 py-7">Kontak & Email</th>
                            <th class="pr-12 py-7 text-right rounded-tr-[2.5rem]">Aksi</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-50 font-medium">
                        <tr v-for="emp in employees" :key="emp.id" class="hover:bg-gray-50/50 transition-all">
                            <td class="pl-12 py-6">
                                <div class="flex flex-col">
                                    <span class="font-black text-lg uppercase text-blue-600 tracking-tighter leading-none">{{ emp.nama }}</span>
                                    <span class="text-[10px] text-gray-400 font-bold uppercase mt-1">ID: #EMP-{{ emp.id }}</span>
                                </div>
                            </td>
                            <td class="px-6 py-6 text-center">
                                <span class="px-4 py-1.5 rounded-full text-[9px] font-black uppercase tracking-widest bg-gray-100 text-gray-500 border border-gray-200">
                                    {{ emp.role }}
                                </span>
                            </td>
                            <td class="px-6 py-6">
                                <p class="font-bold text-gray-800 text-sm leading-tight">{{ emp.email }}</p>
                                <p class="text-[10px] text-gray-400 font-black tracking-widest mt-1 uppercase">{{ emp.nomor_telepon || 'No Phone' }}</p>
                            </td>
                            <td class="pr-12 py-6 text-right">
                                <div class="flex justify-end space-x-2">
                                    <button @click="openEditModal(emp)" class="w-10 h-10 bg-blue-50 text-blue-600 rounded-xl hover:bg-blue-600 hover:text-white transition-all shadow-sm flex items-center justify-center">
                                        <i class="fa-solid fa-pen-nib"></i>
                                    </button>
                                    <button @click="currUser = emp; openDelete = true" class="w-10 h-10 bg-red-50 text-red-600 rounded-xl hover:bg-red-600 hover:text-white transition-all shadow-sm flex items-center justify-center">
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
                <div v-for="emp in employees" :key="emp.id" class="bg-white p-5 rounded-[2rem] shadow-sm border border-gray-100 space-y-4">
                    <div class="flex justify-between items-start">
                        <div class="flex items-center space-x-3 min-w-0">
                            <div class="w-10 h-10 bg-slate-100 rounded-xl flex items-center justify-center font-black text-[#41D3BD] text-sm border border-white shadow-sm">
                                <i class="fa-solid fa-user-shield"></i>
                            </div>
                            <div class="min-w-0">
                                <h4 class="font-black text-blue-600 uppercase text-sm truncate pr-2 tracking-tighter">{{ emp.nama }}</h4>
                                <p class="text-[9px] font-bold text-gray-400 uppercase">#EMP-{{ emp.id }}</p>
                            </div>
                        </div>
                        <span class="px-2 py-0.5 rounded-full font-black text-[8px] uppercase tracking-widest border shadow-sm bg-gray-50 text-gray-500">
                            {{ emp.role }}
                        </span>
                    </div>

                    <div class="bg-gray-50 p-3 rounded-2xl border border-gray-100 space-y-2">
                        <div class="flex items-center text-[10px] text-gray-700 font-bold">
                            <i class="fa-solid fa-envelope w-5 text-gray-400"></i> {{ emp.email }}
                        </div>
                        <div class="flex items-center text-[10px] text-gray-700 font-bold">
                            <i class="fa-solid fa-phone w-5 text-gray-400"></i> {{ emp.nomor_telepon || '-' }}
                        </div>
                    </div>

                    <div class="flex gap-2">
                        <button @click="openEditModal(emp)" class="flex-1 py-3 bg-blue-600 text-white rounded-xl font-black text-[10px] uppercase shadow-sm active:scale-95 transition-all">Edit Staff</button>
                        <button @click="currUser = emp; openDelete = true" class="w-12 h-12 bg-red-50 text-red-600 rounded-xl flex items-center justify-center border border-red-100 active:scale-95 transition-all">
                            <i class="fa-solid fa-trash"></i>
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!-- MODAL ADD/EDIT: Diperkecil (max-w-xl) & Gaya Font Target -->
        <div v-if="openAdd || openEdit" class="fixed inset-0 z-[999] flex items-center justify-center bg-black/40 backdrop-blur-sm px-4 py-8">
            <div class="bg-white rounded-[2.5rem] max-w-xl w-full p-6 md:p-10 shadow-2xl relative overflow-y-auto max-h-[92vh] border-[6px] border-slate-900 transition-all duration-300">
                <h3 class="text-xl md:text-2xl font-black text-gray-800 uppercase tracking-tighter mb-8 text-center">
                    {{ openAdd ? 'Add New Employee' : 'Update Employee' }}
                </h3>

                <form @submit.prevent="openAdd ? handleStore() : handleUpdate()" class="space-y-5">
                    <div>
                        <label class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Nama Lengkap</label>
                        <input v-model="currUser.nama" type="text" required class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-bold text-gray-700 text-sm uppercase">
                    </div>
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                            <label class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Email Staff</label>
                            <input v-model="currUser.email" type="email" required class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-bold text-gray-700 text-sm">
                        </div>
                        <div>
                            <label class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">No. WhatsApp</label>
                            <input v-model="currUser.nomor_telepon" type="text" class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-bold text-gray-700 text-sm">
                        </div>
                    </div>
                    <div>
                        <label class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">
                            Secure Password {{ openEdit ? '(Leave blank if no change)' : '' }}
                        </label>
                        <input v-model="currUser.password" type="password" :required="openAdd" class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-bold text-gray-700 text-sm">
                    </div>

                    <div class="flex flex-col-reverse md:flex-row justify-end gap-3 pt-6 border-t border-gray-50">
                        <button @click="closeModals" type="button" class="w-full md:w-auto px-8 py-4 bg-gray-100 rounded-full font-black text-gray-400 uppercase text-[10px]">Batal</button>
                        <button type="submit" class="w-full md:w-auto px-10 py-4 bg-blue-600 text-white rounded-full font-black shadow-lg uppercase text-[10px] hover:scale-105 transition-all">
                            Simpan Staff
                        </button>
                    </div>
                </form>
            </div>
        </div>

        <!-- MODAL DELETE -->
        <div v-if="openDelete" class="fixed inset-0 z-[999] flex items-center justify-center bg-black/50 backdrop-blur-sm px-4">
            <div class="bg-white rounded-[2.5rem] max-w-sm w-full p-8 text-center shadow-2xl border-b-8 border-gray-900">
                <div class="w-16 h-16 bg-red-50 text-red-500 rounded-full flex items-center justify-center mx-auto mb-6 text-3xl shadow-inner">
                    <i class="fa-solid fa-user-xmark"></i>
                </div>
                <h3 class="text-lg font-black text-gray-800 uppercase tracking-tighter mb-2">Terminate Access?</h3>
                <p class="text-gray-400 text-[10px] font-bold mb-8 uppercase tracking-widest">Akses sistem untuk <span class="text-red-500">{{ currUser.nama }}</span> akan dihapus permanen.</p>
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
