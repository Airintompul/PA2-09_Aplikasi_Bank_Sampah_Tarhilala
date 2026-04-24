<script setup>
import AdminLayout from '@/Layouts/AdminLayout.vue';
import { ref, onMounted } from 'vue';
import api from '@/api';

// --- STATE DATA ---
const employees = ref([]);
const isLoading = ref(true);
const successMessage = ref('');

// State Modal
const openAdd = ref(false);
const openEdit = ref(false);
const openDelete = ref(false);

// State Form
const currUser = ref({ id: '', nama: '', email: '', nomor_telepon: '', password: '', role: 'petugas' });

// --- LOGIC: AMBIL DATA DARI API ---
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

// --- LOGIC: SIMPAN PETUGAS BARU ---
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

// --- LOGIC: UPDATE DATA ---
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

// --- LOGIC: HAPUS DATA ---
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

// --- HELPER FUNCTIONS ---
const openEditModal = (user) => {
    // Kosongkan password saat buka edit agar tidak terkirim password lama
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
    <AdminLayout>
        <div class="flex justify-between items-center mb-8">
            <h2 class="text-4xl font-black text-gray-900 uppercase tracking-tight">Employee</h2>
            <button @click="openAdd = true" class="flex items-center space-x-3 bg-[#41D3BD] hover:opacity-80 text-black px-8 py-4 rounded-[2rem] transition-all shadow-lg font-black uppercase text-sm tracking-widest">
                <i class="fa-solid fa-user-plus text-lg"></i>
                <span>Add Employee</span>
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
                        <th class="pl-20 py-6 text-black font-medium uppercase text-lg">Nama Petugas</th>
                        <th class="px-6 py-6 text-black font-medium uppercase text-lg text-center">Role</th>
                        <th class="px-6 py-6 text-black font-medium uppercase text-lg">Email / Kontak</th>
                        <th class="px-8 py-6 text-center rounded-tr-[2.5rem]">
                            <span class="bg-white px-5 py-1 rounded-lg text-xs font-black text-black uppercase">Action</span>
                        </th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 text-black font-medium">
                    <tr v-for="emp in employees" :key="emp.id" class="hover:bg-gray-50/50 transition-all">
                        <td class="pl-20 py-6">
                            <span class="font-black text-lg uppercase text-black tracking-tighter">{{ emp.nama }}</span>
                            <div class="text-[10px] text-gray-400 font-bold uppercase mt-1">ID: #EMP-{{ emp.id }}</div>
                        </td>
                        <td class="px-6 py-6 text-center">
                            <span class="px-4 py-1 bg-gray-100 rounded-lg text-[10px] font-black uppercase text-gray-600">
                                {{ emp.role }}
                            </span>
                        </td>
                        <td class="px-6 py-6">
                            <p class="font-bold text-gray-800">{{ emp.email }}</p>
                            <p class="text-xs text-gray-400 font-black tracking-widest mt-1">{{ emp.nomor_telepon || '-' }}</p>
                        </td>
                        <td class="px-8 py-6 text-center">
                            <div class="flex justify-center space-x-2">
                                <button @click="openEditModal(emp)" class="p-3 bg-blue-50 text-blue-600 rounded-xl hover:bg-blue-600 hover:text-white transition-all">
                                    <i class="fa-solid fa-user-pen"></i>
                                </button>
                                <button @click="currUser = emp; openDelete = true" class="p-3 bg-red-50 text-red-600 rounded-xl hover:bg-red-600 hover:text-white transition-all">
                                    <i class="fa-solid fa-trash"></i>
                                </button>
                            </div>
                        </td>
                    </tr>
                </tbody>
            </table>
            <div class="h-6"></div>
        </div>

        <!-- MODAL ADD/EDIT -->
        <div v-if="openAdd || openEdit" class="fixed inset-0 z-[100] flex items-center justify-center bg-black/50 backdrop-blur-sm px-4">
            <div class="bg-white rounded-[3rem] max-w-lg w-full p-10 shadow-2xl relative">
                <h3 class="text-2xl font-black text-gray-800 uppercase tracking-tighter mb-8 text-center">
                    {{ openAdd ? 'Add New Employee' : 'Update Employee' }}
                </h3>

                <form @submit.prevent="openAdd ? handleStore() : handleUpdate()" class="space-y-4">
                    <div>
                        <label class="text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Nama Lengkap</label>
                        <input v-model="currUser.nama" type="text" required class="w-full px-6 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-bold text-gray-700">
                    </div>
                    <div class="grid grid-cols-2 gap-4">
                        <div>
                            <label class="text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Email</label>
                            <input v-model="currUser.email" type="email" required class="w-full px-6 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-bold text-gray-700">
                        </div>
                        <div>
                            <label class="text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">No. Telepon</label>
                            <input v-model="currUser.nomor_telepon" type="text" class="w-full px-6 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-bold text-gray-700">
                        </div>
                    </div>
                    <div>
                        <label class="text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Password {{ openEdit ? '(Kosongkan jika tidak diubah)' : '' }}</label>
                        <input v-model="currUser.password" type="password" :required="openAdd" class="w-full px-6 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-bold text-gray-700">
                    </div>

                    <div class="flex justify-end space-x-3 pt-6 border-t border-gray-50">
                        <button @click="closeModals" type="button" class="px-8 py-4 bg-gray-100 rounded-2xl font-black text-gray-400 uppercase text-xs">Batal</button>
                        <button type="submit" class="px-8 py-4 bg-blue-600 text-white rounded-2xl font-black shadow-lg uppercase text-xs hover:scale-105 transition-all">Simpan</button>
                    </div>
                </form>
            </div>
        </div>

        <!-- MODAL DELETE -->
        <div v-if="openDelete" class="fixed inset-0 z-[100] flex items-center justify-center bg-black/50 backdrop-blur-sm px-4">
            <div class="bg-white rounded-[3rem] max-w-sm w-full p-10 text-center shadow-2xl">
                <div class="w-20 h-20 bg-red-50 text-red-500 rounded-full flex items-center justify-center mx-auto mb-6 text-4xl">
                    <i class="fa-solid fa-user-xmark"></i>
                </div>
                <h3 class="text-xl font-black text-gray-800 uppercase tracking-tight mb-2">Hapus Petugas?</h3>
                <p class="text-gray-400 text-sm font-bold mb-8 uppercase tracking-tighter">Menghapus <span class="text-red-500">{{ currUser.nama }}</span> akan menghilangkan aksesnya ke sistem.</p>
                <div class="flex justify-center space-x-3">
                    <button @click="openDelete = false" class="px-8 py-4 bg-gray-100 rounded-2xl font-black text-gray-400 uppercase text-xs">Batal</button>
                    <button @click="handleDelete" class="px-8 py-4 bg-red-600 text-white rounded-2xl font-black shadow-lg shadow-red-200 uppercase text-xs">Ya, Hapus</button>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>
