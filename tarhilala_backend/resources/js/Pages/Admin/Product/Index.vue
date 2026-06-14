<script setup>
import AdminLayout from '@/Layouts/AdminLayout.vue';
import { ref, onMounted, computed, watch } from 'vue';
import axios from 'axios';

// --- STATE DATA ---
const products = ref([]);
const isLoading = ref(true);
const successMessage = ref('');
const errorMessage = ref('');

// State Modal
const openAdd = ref(false);
const openEdit = ref(false);
const openDelete = ref(false);

// LOGIC: Deteksi jika ada modal yang aktif
const isAnyModalOpen = computed(() => {
    return openAdd.value || openEdit.value || openDelete.value;
});

// State Form
const currProduct = ref({ id: '', nama: '', kategori: '', harga_per_kg: 0, deskripsi: '', gambar: null });
const imagePreview = ref(null);

// --- VALIDASI AUTO-SNAP ---
watch(() => currProduct.value.harga_per_kg, (newVal) => {
    if (newVal < 0) currProduct.value.harga_per_kg = 0;
});

// --- LOGIC API ---
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

const onFileChange = (e) => {
    const file = e.target.files[0];
    if (file) {
        currProduct.value.gambar = file;
        imagePreview.value = URL.createObjectURL(file);
    }
};

// --- HELPER NOTIFIKASI ---
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
    if (!currProduct.value.deskripsi || currProduct.value.deskripsi.trim() === "") {
        showError("Please fill out this blank (Description)");
        return;
    }

    const formData = new FormData();
    formData.append('nama', currProduct.value.nama);
    formData.append('kategori', currProduct.value.kategori);
    formData.append('harga_per_kg', currProduct.value.harga_per_kg);
    formData.append('deskripsi', currProduct.value.deskripsi);
    if (currProduct.value.gambar) formData.append('gambar', currProduct.value.gambar);

    try {
        await axios.post('/api/admin/products', formData, {
            headers: { Authorization: `Bearer ${localStorage.getItem('admin_token')}` }
        });
        resetForm();
        openAdd.value = false;
        showSuccess("Produk Berhasil Ditambahkan!");
        fetchProducts();
    } catch (error) {
        showError(error.response?.data?.message || "Gagal menyimpan data");
    }
};

const handleUpdate = async () => {
    if (!currProduct.value.deskripsi || currProduct.value.deskripsi.trim() === "") {
        showError("Please fill out this blank (Description)");
        return;
    }

    isLoading.value = true;
    try {
        const formData = new FormData();
        formData.append('nama', currProduct.value.nama);
        formData.append('kategori', currProduct.value.kategori);
        formData.append('harga_per_kg', currProduct.value.harga_per_kg);
        formData.append('deskripsi', currProduct.value.deskripsi);

        if (currProduct.value.gambar instanceof File) {
            formData.append('gambar', currProduct.value.gambar);
        }

        await axios.post(`/api/admin/products/${currProduct.value.id}`, formData, {
            headers: {
                Authorization: `Bearer ${localStorage.getItem('admin_token')}`,
                'Accept': 'application/json'
            }
        });

        openEdit.value = false;
        fetchProducts();
        showSuccess("Produk Berhasil Diperbarui!");
    } catch (error) {
        showError("Gagal memperbarui data");
    } finally {
        isLoading.value = false;
    }
};

const handleDelete = async () => {
    try {
        await axios.delete(`/api/admin/products/${currProduct.value.id}`, {
            headers: { Authorization: `Bearer ${localStorage.getItem('admin_token')}` }
        });
        openDelete.value = false;
        showSuccess("Produk Berhasil Dihapus!");
        fetchProducts();
    } catch (error) {
        showError("Gagal menghapus data");
    }
};

const resetForm = () => {
    currProduct.value = { id: '', nama: '', kategori: '', harga_per_kg: 0, deskripsi: '', gambar: null };
    imagePreview.value = null;
};

onMounted(() => fetchProducts());
</script>

<template>
    <AdminLayout :hideNavbar="isAnyModalOpen">

        <div :class="{'blur-md opacity-50 pointer-events-none transition-all duration-500': isAnyModalOpen}">
            <!-- Header Page -->
            <div class="flex flex-col md:flex-row justify-between items-start md:items-center mb-8 gap-4 px-2 md:px-0">
                <div>
                    <h2 class="text-2xl md:text-4xl font-black text-gray-900 uppercase tracking-tight leading-none">
                        Daftar <span class="text-[#41D3BD]">Produk</span>
                    </h2>
                    <p class="text-[10px] md:text-xs font-bold text-gray-400 uppercase tracking-widest mt-2">
                        Manajemen Katalog & Harga Sampah
                    </p>
                </div>
                <button @click="resetForm(); openAdd = true" class="w-full md:w-auto flex items-center justify-center space-x-3 bg-[#41D3BD] hover:opacity-80 text-black px-8 py-4 rounded-2xl md:rounded-[2rem] transition-all shadow-lg font-black uppercase text-xs md:text-sm tracking-widest">
                    <i class="fa-solid fa-plus text-lg"></i>
                    <span>Add Product</span>
                </button>
            </div>

            <!-- NOTIFIKASI VALIDASI -->
            <Transition name="fade">
                <div v-if="successMessage || errorMessage"
                     :class="successMessage ? 'bg-black text-[#41D3BD] border-[#41D3BD]' : 'bg-black text-red-500 border-red-500'"
                     class="mx-2 md:mx-0 mb-8 p-4 md:p-5 rounded-2xl md:rounded-3xl font-black shadow-xl flex items-center border-l-8 text-xs md:text-sm transition-all">
                    <i :class="successMessage ? 'fa-solid fa-circle-check' : 'fa-solid fa-triangle-exclamation'" class="text-xl md:text-2xl mr-4"></i>
                    <div class="flex flex-col text-left">
                        <span class="uppercase tracking-tight text-sm md:text-base leading-none">{{ successMessage || errorMessage }}</span>
                    </div>
                </div>
            </Transition>

            <!-- TABEL VIEW (Desktop Only) -->
            <div class="hidden lg:block bg-white rounded-[2.5rem] shadow-sm border border-gray-100 relative overflow-hidden">
                <table class="w-full text-left border-collapse">
                    <thead class="bg-[#41D3BD]">
                        <tr class="text-black font-black uppercase text-[11px] tracking-widest">
                            <th class="pl-12 py-7 rounded-tl-[2.5rem]">Foto</th>
                            <th class="px-6 py-7">Nama Produk</th>
                            <th class="px-6 py-7 text-center">Kategori</th>
                            <th class="px-6 py-7 text-center">Harga / Kg</th>
                            <th class="pr-12 py-7 text-right rounded-tr-[2.5rem]">Aksi</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-50 font-medium">
                        <tr v-for="p in products" :key="p.id" class="hover:bg-gray-50/50 transition-all">
                            <td class="pl-12 py-6">
                                <div class="w-16 h-16 bg-slate-100 rounded-2xl flex items-center justify-center border-2 border-white shadow-sm overflow-hidden shrink-0">
                                    <img v-if="p.gambar" :src="p.gambar" class="w-full h-full object-cover">
                                    <i v-else class="fa-solid fa-image text-gray-300 text-2xl"></i>
                                </div>
                            </td>
                            <td class="px-6 py-6">
                                <div class="flex flex-col">
                                    <span class="font-black text-lg uppercase text-black-600 tracking-tighter leading-none">{{ p.nama }}</span>
                                    <span class="text-[10px] text-gray-400 font-bold uppercase mt-1">Ref: #CAT-{{ p.id }}</span>
                                </div>
                            </td>
                            <td class="px-6 py-6 text-center">
                                <span class="px-4 py-1.5 rounded-full text-[9px] font-black uppercase tracking-widest bg-gray-100 text-gray-500 border border-gray-200">
                                    {{ p.kategori }}
                                </span>
                            </td>
                            <td class="px-6 py-6 text-center">
                                <span class="font-black text-lg text-gray-800 tracking-tighter">Rp {{ Number(p.harga_per_kg).toLocaleString('id-ID') }}</span>
                            </td>
                            <td class="pr-12 py-6 text-right">
                                <div class="flex justify-end space-x-2">
                                    <button @click="currProduct = { ...p }; imagePreview = p.gambar; openEdit = true" class="w-10 h-10 bg-blue-50 text-blue-600 rounded-xl hover:bg-blue-600 hover:text-white transition-all shadow-sm flex items-center justify-center"><i class="fa-solid fa-pen-nib"></i></button>
                                    <button @click="currProduct = p; openDelete = true" class="w-10 h-10 bg-red-50 text-red-600 rounded-xl hover:bg-red-600 hover:text-white transition-all shadow-sm flex items-center justify-center"><i class="fa-solid fa-trash"></i></button>
                                </div>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <!-- CARD VIEW (Mobile Only) -->
            <div class="lg:hidden space-y-4 px-2">
                <div v-for="p in products" :key="p.id" class="bg-white p-5 rounded-[2rem] border border-gray-100 shadow-sm">
                    <div class="flex items-center space-x-4">
                        <div class="w-20 h-20 bg-slate-100 rounded-2xl overflow-hidden border-2 border-white shadow-sm shrink-0">
                            <img v-if="p.gambar" :src="p.gambar" class="w-full h-full object-cover">
                            <i v-else class="fa-solid fa-image text-gray-300 text-2xl flex items-center justify-center h-full"></i>
                        </div>
                        <div class="flex-1">
                            <div class="flex flex-col">
                                <span class="font-black text-base uppercase text-blue-600 tracking-tighter leading-none">{{ p.nama }}</span>
                                <span class="text-[9px] text-gray-400 font-bold uppercase mt-1">Ref: #CAT-{{ p.id }}</span>
                            </div>
                            <div class="mt-2 flex items-center justify-between">
                                <span class="font-black text-lg text-gray-800 tracking-tighter">Rp {{ Number(p.harga_per_kg).toLocaleString('id-ID') }}</span>
                                <span class="px-3 py-1 rounded-full text-[8px] font-black uppercase tracking-widest bg-gray-100 text-gray-500">{{ p.kategori }}</span>
                            </div>
                        </div>
                    </div>
                    <div class="flex space-x-2 mt-4 pt-4 border-t border-gray-50">
                        <button @click="currProduct = { ...p }; imagePreview = p.gambar; openEdit = true" class="flex-1 py-3 bg-blue-50 text-blue-600 rounded-xl font-black uppercase text-[10px] flex items-center justify-center"><i class="fa-solid fa-pen-nib mr-2"></i> Edit</button>
                        <button @click="currProduct = p; openDelete = true" class="flex-1 py-3 bg-red-50 text-red-600 rounded-xl font-black uppercase text-[10px] flex items-center justify-center"><i class="fa-solid fa-trash mr-2"></i> Hapus</button>
                    </div>
                </div>
            </div>
        </div>

        <!-- MODAL ADD/EDIT -->
        <div v-if="openAdd || openEdit" class="fixed inset-0 z-[999] flex items-center justify-center bg-black/40 backdrop-blur-sm px-4 py-8 transition-all">
            <div class="bg-white rounded-[2.5rem] md:rounded-[3rem] max-w-xl w-full p-6 md:p-10 shadow-2xl relative overflow-y-auto max-h-[92vh] border-[6px] border-slate-900 transition-all duration-300">
                <h3 class="text-xl md:text-2xl font-black text-gray-800 uppercase tracking-tighter mb-8 text-center">
                    {{ openAdd ? 'Add New Product' : 'Update Product' }}
                </h3>

                <form @submit.prevent="openAdd ? handleStore() : handleUpdate()" class="space-y-5">
                    <div>
                        <label class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Nama Produk</label>
                        <input v-model="currProduct.nama" type="text" required class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-bold text-gray-700 text-sm uppercase">
                    </div>
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                            <label class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Kategori</label>
                            <input v-model="currProduct.kategori" type="text" required class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-bold text-gray-700 text-sm uppercase">
                        </div>
                        <div>
                            <label class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Harga/Kg</label>
                            <input v-model="currProduct.harga_per_kg" type="number" min="0" required class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-black text-blue-600 text-lg tracking-tighter">
                        </div>
                    </div>
                    <div>
                        <label class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Deskripsi Produk</label>
                        <textarea v-model="currProduct.deskripsi" rows="2" required placeholder="" class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-bold text-gray-700 text-sm leading-relaxed"></textarea>
                    </div>
                    <div>
                        <label class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Upload Foto Produk</label>
                        <div class="mt-2 flex items-center space-x-4">
                            <div v-if="imagePreview" class="w-20 h-20 rounded-2xl overflow-hidden border-2 border-white shadow-md bg-gray-50 shrink-0">
                                <img :src="imagePreview" class="w-full h-full object-cover">
                            </div>
                            <input type="file" @change="onFileChange" class="w-full text-[10px] text-gray-400 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-[10px] file:font-black file:bg-[#41D3BD]/10 file:text-[#41D3BD]" />
                        </div>
                    </div>

                    <div class="flex flex-col-reverse md:flex-row justify-end gap-3 pt-6 border-t border-gray-50">
                        <button @click="openAdd = false; openEdit = false" type="button" class="w-full md:w-auto px-8 py-4 bg-gray-100 rounded-full font-black text-gray-400 uppercase text-[10px] tracking-widest">Batal</button>
                        <button type="submit" class="w-full md:w-auto px-10 py-4 bg-blue-600 text-white rounded-full font-black shadow-lg uppercase text-[10px] hover:scale-105 transition-all">
                            Simpan Produk
                        </button>
                    </div>
                </form>
            </div>
        </div>

        <!-- MODAL DELETE -->
        <div v-if="openDelete" class="fixed inset-0 z-[110] flex items-center justify-center bg-black/50 backdrop-blur-sm px-4">
            <div class="bg-white rounded-[2.5rem] max-w-sm w-full p-8 text-center shadow-2xl border-b-8 border-gray-900 transition-all">
                <div class="w-16 h-16 bg-red-50 text-red-500 rounded-full flex items-center justify-center mx-auto mb-6 text-3xl shadow-inner">
                    <i class="fa-solid fa-triangle-exclamation"></i>
                </div>
                <h3 class="text-lg font-black text-gray-800 uppercase tracking-tighter mb-2">Hapus Produk?</h3>
                <p class="text-gray-400 text-[10px] font-bold mb-8 uppercase tracking-widest">Penghapusan <span class="text-red-500">{{ currProduct.nama }}</span> bersifat permanen.</p>
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
