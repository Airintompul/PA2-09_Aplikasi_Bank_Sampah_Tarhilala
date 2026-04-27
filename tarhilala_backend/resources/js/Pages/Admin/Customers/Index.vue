<script setup>
import AdminLayout from '@/Layouts/AdminLayout.vue';
import { ref, onMounted } from 'vue';
import api from '@/api'; // Menggunakan instance axios yang sudah dikonfigurasi

// --- STATE DATA ---
const customers = ref([]);
const isLoading = ref(true);
const successMessage = ref('');

// State Modals
const openAdd = ref(false);
const openEdit = ref(false);
const openDelete = ref(false);

// State Form
const currUser = ref({ id: '', nama: '', email: '', nomor_telepon: '', password: '' });

// --- LOGIC: AMBIL DATA DARI API ---
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

// --- LOGIC: SIMPAN NASABAH BARU ---
const handleStore = async () => {
    try {
        await api.post('/customers', currUser.value);
        closeModals();
        showSuccess("Nasabah Berhasil Ditambahkan!");
        fetchCustomers();
    } catch (error) {
        alert(error.response?.data?.message || "Gagal menyimpan nasabah");
    }
};

// --- LOGIC: UPDATE DATA ---
const handleUpdate = async () => {
    try {
        await api.put(`/customers/${currUser.value.id}`, currUser.value);
        closeModals();
        showSuccess("Data Nasabah Berhasil Diperbarui!");
        fetchCustomers();
    } catch (error) {
        alert("Gagal memperbarui data nasabah");
    }
};

// --- LOGIC: HAPUS DATA ---
const handleDelete = async () => {
    try {
        await api.delete(`/customers/${currUser.value.id}`);
        openDelete.value = false;
        showSuccess("Nasabah Berhasil Dihapus!");
        fetchCustomers();
    } catch (error) {
        alert("Gagal menghapus data");
    }
};

// --- HELPER FUNCTIONS ---
const openEditModal = (user) => {
    // Reset password field agar tidak terkirim string kosong/lama secara tidak sengaja
    currUser.value = { ...user, password: '' };
    openEdit.value = true;
};

const closeModals = () => {
    openAdd.value = false;
    openEdit.value = false;
    currUser.value = { id: '', nama: '', email: '', nomor_telepon: '', password: '' };
};

const showSuccess = (msg) => {
    successMessage.value = msg;
    setTimeout(() => successMessage.value = '', 3000);
};

// Format Tanggal
const formatDate = (dateString) => {
    const options = { day: '2-digit', month: 'short', year: 'numeric' };
    return new Date(dateString).toLocaleDateString('id-ID', options);
};

onMounted(() => fetchCustomers());
</script>

<template>
    <AdminLayout>
        <div class="flex justify-between items-center mb-8">
            <h2 class="text-4xl font-black text-gray-900 uppercase tracking-tight">Customers</h2>
            <button @click="openAdd = true" class="flex items-center space-x-3 bg-[#41D3BD] hover:opacity-80 text-black px-8 py-4 rounded-[2rem] transition-all shadow-lg font-black uppercase text-sm tracking-widest">
                <i class="fa-solid fa-user-plus text-lg"></i>
                <span>Add Customer</span>
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
                        <th class="pl-20 py-6 text-black font-black uppercase text-sm tracking-widest rounded-tl-[2.5rem]">Nama Nasabah</th>
                        <th class="px-6 py-6 text-black font-black uppercase text-sm tracking-widest">Email</th>
                        <th class="px-6 py-6 text-black font-black uppercase text-sm tracking-widest text-center">No. Telepon</th>
                        <th class="px-6 py-6 text-black font-black uppercase text-sm tracking-widest text-center">Registrasi</th>
                        <th class="px-8 py-6 text-center rounded-tr-[2.5rem]">
                            <span class="bg-white px-5 py-1 rounded-lg text-xs font-black text-black uppercase">Action</span>
                        </th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 text-black font-medium">
                    <tr v-for="customer in customers" :key="customer.id" class="hover:bg-gray-50/50 transition-all">
                        <td class="pl-20 py-6">
                            <span class="font-black text-lg uppercase text-black tracking-tighter">{{ customer.nama }}</span>
                            <div class="text-[10px] text-gray-400 font-bold uppercase mt-1">ID: #NSB-{{ customer.id }}</div>
                        </td>
                        <td class="px-6 py-6 font-bold text-gray-700">{{ customer.email }}</td>
                        <td class="px-6 py-6 text-center font-black text-gray-800">{{ customer.nomor_telepon || '-' }}</td>
                        <td class="px-6 py-6 text-center text-gray-400 font-bold text-xs uppercase">{{ formatDate(customer.created_at) }}</td>
                        <td class="px-8 py-6 text-center">
                            <div class="flex justify-center space-x-2">
                                <button @click="openEditModal(customer)" class="p-3 bg-blue-50 text-blue-600 rounded-xl hover:bg-blue-600 hover:text-white transition-all">
                                    <i class="fa-solid fa-user-pen"></i>
                                </button>
                                <button @click="currUser = customer; openDelete = true" class="p-3 bg-red-50 text-red-600 rounded-xl hover:bg-red-600 hover:text-white transition-all">
                                    <i class="fa-solid fa-trash"></i>
                                </button>
                            </div>
                        </td>
                    </tr>
                    <tr v-if="customers.length === 0 && !isLoading">
                        <td colspan="5" class="py-20 text-center text-gray-300 font-black uppercase italic tracking-widest text-sm">Belum ada data nasabah</td>
                    </tr>
                </tbody>
            </table>
            <div class="h-6"></div>
        </div>

        <!-- MODAL ADD/EDIT -->
        <div v-if="openAdd || openEdit" class="fixed inset-0 z-[100] flex items-center justify-center bg-black/50 backdrop-blur-sm px-4">
            <div class="bg-white rounded-[3rem] max-w-lg w-full p-10 shadow-2xl relative">
                <h3 class="text-2xl font-black text-gray-800 uppercase tracking-tighter mb-8 text-center">
                    {{ openAdd ? 'Add New Customer' : 'Update Customer' }}
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
                        <button @click="closeModals" type="button" class="px-8 py-4 bg-gray-100 rounded-2xl font-black text-gray-400 uppercase text-xs tracking-widest">Batal</button>
                        <button type="submit" class="px-8 py-4 bg-blue-600 text-white rounded-2xl font-black shadow-lg uppercase text-xs tracking-widest hover:scale-105 transition-all">Simpan</button>
                    </div>
                </form>
            </div>
        </div>

        <!-- MODAL DELETE -->
        <div v-if="openDelete" class="fixed inset-0 z-[100] flex items-center justify-center bg-black/50 backdrop-blur-sm px-4">
            <div class="bg-white rounded-[3rem] max-w-sm w-full p-10 text-center shadow-2xl">
                <div class="w-20 h-20 bg-red-50 text-red-500 rounded-full flex items-center justify-center mx-auto mb-6 text-4xl">
                    <i class="fa-solid fa-user-minus"></i>
                </div>
                <h3 class="text-xl font-black text-gray-800 uppercase tracking-tight mb-2">Hapus Nasabah?</h3>
                <p class="text-gray-400 text-sm font-bold mb-8 uppercase tracking-tighter">Seluruh data <span class="text-red-500">{{ currUser.nama }}</span> akan dihapus dari database.</p>
                <div class="flex justify-center space-x-3">
                    <button @click="openDelete = false" class="px-8 py-4 bg-gray-100 rounded-2xl font-black text-gray-400 uppercase text-xs">Batal</button>
                    <button @click="handleDelete" class="px-8 py-4 bg-red-600 text-white rounded-2xl font-black shadow-lg shadow-red-200 uppercase text-xs">Ya, Hapus</button>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>

<style scoped>
/* Transisi Smooth */
.divide-y tr { transition: all 0.2s ease-in-out; }
</style>
