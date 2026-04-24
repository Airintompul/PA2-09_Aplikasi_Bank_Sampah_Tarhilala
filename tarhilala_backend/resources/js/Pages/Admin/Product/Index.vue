<script setup>
import AdminLayout from '@/Layouts/AdminLayout.vue';
import { ref, onMounted } from 'vue';
import axios from 'axios';

// --- STATE DATA ---
const products = ref([]);
const isLoading = ref(true);
const successMessage = ref('');

// State Modal
const openAdd = ref(false);
const openEdit = ref(false);
const openDelete = ref(false);

// State Form (Dinamis)
const currProduct = ref({ id: '', nama: '', kategori: '', harga_per_kg: '', deskripsi: '', gambar: null });
const imagePreview = ref(null);

// --- LOGIC: AMBIL DATA DARI API ---
const fetchProducts = async () => {
    try {
        const response = await axios.get('/api/admin/products', {
            headers: { Authorization: `Bearer ${localStorage.getItem('admin_token')}` }
        });
        products.value = response.data.data;
    } catch (error) {
        console.error("Gagal mengambil data produk");
    } finally {
        isLoading.value = false;
    }
};

// --- LOGIC: HANDLE FILE INPUT ---
const onFileChange = (e) => {
    const file = e.target.files[0];
    currProduct.value.gambar = file;
    imagePreview.value = URL.createObjectURL(file);
};

// --- LOGIC: SIMPAN PRODUK BARU ---
const handleStore = async () => {
    const formData = new FormData();
    formData.append('nama', currProduct.value.nama);
    formData.append('kategori', currProduct.value.kategori);
    formData.append('harga_per_kg', currProduct.value.harga_per_kg);
    formData.append('deskripsi', currProduct.value.deskripsi);
    if (currProduct.value.gambar) formData.append('gambar', currProduct.value.gambar);

    try {
        await axios.post('/api/admin/products', formData, {
            headers: { 'Content-Type': 'multipart/form-data', Authorization: `Bearer ${localStorage.getItem('admin_token')}` }
        });
        resetForm();
        openAdd.value = false;
        showSuccess("Produk Berhasil Ditambahkan!");
        fetchProducts();
    } catch (error) {
        alert("Gagal menyimpan data");
    }
};

// --- LOGIC: UPDATE PRODUK ---
const handleUpdate = async () => {
    isLoading.value = true;
    try {
        const formData = new FormData();

        // --- MANDATORY UNTUK LARAVEL UPDATE DENGAN FILE ---
        formData.append('_method', 'PUT');

        formData.append('nama', currProduct.value.nama);
        formData.append('kategori', currProduct.value.kategori);
        formData.append('harga_per_kg', currProduct.value.harga_per_kg);
        formData.append('deskripsi', currProduct.value.deskripsi || '');

        // Hanya kirim file jika Admin memilih file baru di input
        if (currProduct.value.gambar instanceof File) {
            formData.append('gambar', currProduct.value.gambar);
        }

        // Kirim ke API menggunakan POST
        const response = await api.post(`/products/${currProduct.value.id}`, formData, {
            headers: { 'Content-Type': 'multipart/form-data' }
        });

        if (response.data.status === 'success') {
            openEdit.value = false;
            fetchProducts(); // Refresh tabel
            alert("Produk Berhasil Diperbarui!");
        }

    } catch (error) {
        // --- DEBUGGING: Cara melihat pesan error asli dari Laravel ---
        if (error.response && error.response.status === 422) {
            const errors = error.response.data.errors;
            const firstErrorMessage = Object.values(errors)[0][0];
            alert("Gagal: " + firstErrorMessage);
        } else {
            alert("Gagal: " + (error.response?.data?.message || "Terjadi kesalahan server"));
        }
    } finally {
        isLoading.value = false;
    }
};

// --- LOGIC: HAPUS PRODUK ---
const handleDelete = async () => {
    try {
        await axios.delete(`/api/admin/products/${currProduct.value.id}`, {
            headers: { Authorization: `Bearer ${localStorage.getItem('admin_token')}` }
        });
        openDelete.value = false;
        showSuccess("Produk Berhasil Dihapus!");
        fetchProducts();
    } catch (error) {
        alert("Gagal menghapus data");
    }
};

// --- HELPER FUNCTIONS ---
const resetForm = () => {
    currProduct.value = { id: '', nama: '', kategori: '', harga_per_kg: '', deskripsi: '', gambar: null };
    imagePreview.value = null;
};

const showSuccess = (msg) => {
    successMessage.value = msg;
    setTimeout(() => successMessage.value = '', 3000);
};

onMounted(() => fetchProducts());
</script>

<template>
    <AdminLayout>
        <div class="flex justify-between items-center mb-8">
            <h2 class="text-4xl font-black text-gray-900 uppercase tracking-tight">Product</h2>
            <button @click="resetForm(); openAdd = true" class="flex items-center space-x-3 bg-[#41D3BD] hover:opacity-80 text-black px-8 py-4 rounded-[2rem] transition-all shadow-lg shadow-[#41D3BD]/20 font-black uppercase text-sm tracking-widest">
                <i class="fa-solid fa-plus text-lg"></i>
                <span>Add Product</span>
            </button>
        </div>

        <!-- Alert Berhasil -->
        <Transition name="fade">
            <div v-if="successMessage" class="mb-6 p-5 bg-green-500 text-white rounded-2xl font-bold shadow-lg border border-green-600 flex items-center">
                <i class="fa-solid fa-circle-check mr-3 text-xl"></i> {{ successMessage }}
            </div>
        </Transition>

        <!-- Table Container -->
        <div class="bg-white rounded-[2.5rem] shadow-sm border border-gray-100 relative">
            <table class="w-full text-left">
                <thead class="bg-[#41D3BD]">
                    <tr>
                        <th class="pl-20 py-6 w-32 rounded-tl-[2.5rem] text-black font-medium uppercase text-sm tracking-widest">Foto</th>
                        <th class="px-6 py-6 text-black font-medium uppercase text-sm tracking-widest">Nama</th>
                        <th class="px-6 py-6 text-black font-medium uppercase text-sm tracking-widest text-center">Kategori</th>
                        <th class="px-6 py-6 text-black font-medium uppercase text-sm tracking-widest text-center">Harga/Kg</th>
                        <th class="px-8 py-6 text-center rounded-tr-[2.5rem]">
                            <span class="bg-white px-5 py-1 rounded-lg text-xs font-medium text-black uppercase">Action</span>
                        </th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 text-black font-medium">
                    <tr v-for="p in products" :key="p.id" class="hover:bg-gray-50/50 transition-all">
                        <td class="pl-20 py-6">
                            <div class="w-16 h-16 bg-gray-100 rounded-2xl flex items-center justify-center border border-gray-50 overflow-hidden shadow-sm">
                                <img v-if="p.gambar" :src="p.gambar" class="w-full h-full object-cover">
                                <i v-else class="fa-solid fa-image text-gray-300 text-2xl"></i>
                            </div>
                        </td>
                        <td class="px-6 py-6 text-lg font-medium text-black uppercase">{{ p.nama }}</td>
                        <td class="px-6 py-6 text-center text-gray-500 font-medium uppercase text-xs">{{ p.kategori }}</td>
                        <td class="px-6 py-6 text-center font-medium text-lg text-gray-800">Rp {{ Number(p.harga_per_kg).toLocaleString('id-ID') }}/kg</td>
                        <td class="px-8 py-6 text-center relative" x-data-dropdown>
                            <div class="flex items-center justify-center space-x-2">
                                <button @click="currProduct = { ...p }; imagePreview = p.gambar; openEdit = true" class="p-3 bg-blue-50 text-blue-600 rounded-xl hover:bg-blue-600 hover:text-white transition-all">
                                    <i class="fa-solid fa-pen-to-square"></i>
                                </button>
                                <button @click="currProduct = p; openDelete = true" class="p-3 bg-red-50 text-red-600 rounded-xl hover:bg-red-600 hover:text-white transition-all">
                                    <i class="fa-solid fa-trash"></i>
                                </button>
                            </div>
                        </td>
                    </tr>
                </tbody>
            </table>
            <div class="h-6"></div>
        </div>

        <!-- MODAL ADD/EDIT (Disederhanakan menggunakan satu logika komponen) -->
        <div v-if="openAdd || openEdit" class="fixed inset-0 z-[100] flex items-center justify-center bg-black/50 backdrop-blur-sm px-4">
            <div class="bg-white rounded-[3rem] max-w-lg w-full p-10 shadow-2xl relative">
                <h3 class="text-2xl font-black text-gray-800 uppercase tracking-tighter mb-8">
                    {{ openAdd ? 'Add New Product' : 'Update Product' }}
                </h3>

                <form @submit.prevent="openAdd ? handleStore() : handleUpdate()" class="space-y-4">
                    <div>
                        <label class="text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Nama Produk</label>
                        <input v-model="currProduct.nama" type="text" required class="w-full px-6 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-bold text-gray-700">
                    </div>
                    <div class="grid grid-cols-2 gap-4">
                        <div>
                            <label class="text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Kategori</label>
                            <input v-model="currProduct.kategori" type="text" required class="w-full px-6 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-bold text-gray-700">
                        </div>
                        <div>
                            <label class="text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Harga/Kg</label>
                            <input v-model="currProduct.harga_per_kg" type="number" required class="w-full px-6 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-bold text-gray-700">
                        </div>
                    </div>
                    <div>
                        <label class="text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Deskripsi</label>
                        <textarea v-model="currProduct.deskripsi" rows="2" class="w-full px-6 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-bold text-gray-700"></textarea>
                    </div>
                    <div>
                        <label class="text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Upload Gambar</label>
                        <input type="file" @change="onFileChange" class="w-full text-xs text-gray-400 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-xs file:font-black file:bg-[#41D3BD]/10 file:text-[#41D3BD] hover:file:bg-[#41D3BD]/20" />
                    </div>

                    <div class="flex justify-end space-x-3 pt-6 border-t border-gray-50">
                        <button @click="openAdd = false; openEdit = false" type="button" class="px-8 py-4 bg-gray-100 rounded-2xl font-black text-gray-400 uppercase text-xs tracking-widest">Batal</button>
                        <button type="submit" class="px-8 py-4 bg-blue-600 text-white rounded-2xl font-black shadow-lg shadow-blue-200 uppercase text-xs tracking-widest hover:scale-105 transition-all">Simpan Data</button>
                    </div>
                </form>
            </div>
        </div>

        <!-- MODAL DELETE -->
        <div v-if="openDelete" class="fixed inset-0 z-[100] flex items-center justify-center bg-black/50 backdrop-blur-sm px-4">
            <div class="bg-white rounded-[3rem] max-w-sm w-full p-10 text-center shadow-2xl">
                <div class="w-20 h-20 bg-red-50 text-red-500 rounded-full flex items-center justify-center mx-auto mb-6 text-4xl">
                    <i class="fa-solid fa-triangle-exclamation"></i>
                </div>
                <h3 class="text-xl font-black text-gray-800 uppercase tracking-tight mb-2">Hapus Produk?</h3>
                <p class="text-gray-400 text-sm font-bold mb-8 uppercase tracking-tighter">Menghapus <span class="text-red-500">{{ currProduct.nama }}</span> tidak dapat dibatalkan.</p>
                <div class="flex justify-center space-x-3">
                    <button @click="openDelete = false" class="px-8 py-4 bg-gray-100 rounded-2xl font-black text-gray-400 uppercase text-xs">Batal</button>
                    <button @click="handleDelete" class="px-8 py-4 bg-red-600 text-white rounded-2xl font-black shadow-lg shadow-red-200 uppercase text-xs">Ya, Hapus</button>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>

<style scoped>
.fade-enter-active, .fade-leave-active { transition: opacity 0.5s; }
.fade-enter-from, .fade-leave-to { opacity: 0; }
</style>
