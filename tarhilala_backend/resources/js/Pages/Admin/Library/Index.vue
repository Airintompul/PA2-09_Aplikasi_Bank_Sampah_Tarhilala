<script setup>
import AdminLayout from '@/Layouts/AdminLayout.vue';
import { ref, onMounted } from 'vue';
import api from '@/api';

// --- STATE DATA ---
const contents = ref([]);
const isLoading = ref(true);
const successMessage = ref('');

// State Modals
const openAdd = ref(false);
const openEdit = ref(false);
const openDelete = ref(false);

// State Form
const currContent = ref({ id: '', judul: '', isi: '', status: 'draft', thumbnail: null });
const imagePreview = ref(null);

// --- LOGIC: AMBIL DATA DARI API ---
const fetchContents = async () => {
    try {
        const response = await api.get('/library');
        contents.value = response.data.data;
    } catch (error) {
        console.error("Gagal memuat konten edukasi");
    } finally {
        isLoading.value = false;
    }
};

// --- LOGIC: HANDLE FILE INPUT ---
const onFileChange = (e) => {
    const file = e.target.files[0];
    currContent.value.thumbnail = file;
    imagePreview.value = URL.createObjectURL(file);
};

// --- LOGIC: SIMPAN KONTEN BARU ---
const handleStore = async () => {
    const formData = new FormData();
    formData.append('judul', currContent.value.judul);
    formData.append('isi', currContent.value.isi);
    formData.append('status', currContent.value.status);
    if (currContent.value.thumbnail) formData.append('thumbnail', currContent.value.thumbnail);

    try {
        await api.post('/library', formData, {
            headers: { 'Content-Type': 'multipart/form-data' }
        });
        closeModals();
        showSuccess("Konten Berhasil Diterbitkan!");
        fetchContents();
    } catch (error) {
        alert("Gagal menyimpan konten");
    }
};

// --- LOGIC: UPDATE KONTEN ---
const handleUpdate = async () => {
    const formData = new FormData();
    formData.append('judul', currContent.value.judul);
    formData.append('isi', currContent.value.isi);
    formData.append('status', currContent.value.status);
    if (currContent.value.thumbnail instanceof File) {
        formData.append('thumbnail', currContent.value.thumbnail);
    }

    // Laravel Multipart Bug Fix: Spoofing PUT via POST
    formData.append('_method', 'PUT');

    try {
        await api.post(`/library/${currContent.value.id}`, formData);
        closeModals();
        showSuccess("Konten Berhasil Diperbarui!");
        fetchContents();
    } catch (error) {
        alert("Gagal memperbarui konten");
    }
};

// --- LOGIC: HAPUS KONTEN ---
const handleDelete = async () => {
    try {
        await api.delete(`/library/${currContent.value.id}`);
        openDelete.value = false;
        showSuccess("Konten Berhasil Dihapus!");
        fetchContents();
    } catch (error) {
        alert("Gagal menghapus data");
    }
};

// --- HELPERS ---
const openEditModal = (content) => {
    currContent.value = { ...content };
    imagePreview.value = content.thumbnail; // Menampilkan thumbnail lama
    openEdit.value = true;
};

const closeModals = () => {
    openAdd.value = false;
    openEdit.value = false;
    currContent.value = { id: '', judul: '', isi: '', status: 'draft', thumbnail: null };
    imagePreview.value = null;
};

const showSuccess = (msg) => {
    successMessage.value = msg;
    setTimeout(() => successMessage.value = '', 3000);
};

onMounted(() => fetchContents());
</script>

<template>
    <AdminLayout>
        <div class="flex justify-between items-center mb-8">
            <h2 class="text-4xl font-black text-gray-900 uppercase tracking-tight">Library</h2>
            <button @click="openAdd = true" class="flex items-center space-x-3 bg-[#41D3BD] hover:opacity-80 text-black px-8 py-4 rounded-[2rem] transition-all shadow-lg font-black uppercase text-sm tracking-widest">
                <i class="fa-solid fa-plus text-lg"></i>
                <span>Add Content</span>
            </button>
        </div>

        <!-- Alert Berhasil -->
        <div v-if="successMessage" class="mb-6 p-5 bg-green-500 text-white rounded-2xl font-bold shadow-lg flex items-center">
            <i class="fa-solid fa-circle-check mr-3"></i> {{ successMessage }}
        </div>

        <!-- Table Container -->
        <div class="bg-white rounded-[2.5rem] shadow-sm border border-gray-100 relative overflow-hidden">
            <table class="w-full text-left">
                <thead class="bg-[#41D3BD]">
                    <tr>
                        <th class="pl-20 py-6 w-40 rounded-tl-[2.5rem] text-black font-black uppercase text-sm">Thumbnail</th>
                        <th class="px-6 py-6 text-black font-black uppercase text-sm">Judul Konten</th>
                        <th class="px-6 py-6 text-black font-black uppercase text-sm text-center">Penulis</th>
                        <th class="px-6 py-6 text-black font-black uppercase text-sm text-center">Status</th>
                        <th class="px-8 py-6 text-center rounded-tr-[2.5rem]">
                            <span class="bg-white px-5 py-1 rounded-lg text-xs font-black text-black uppercase">Action</span>
                        </th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 text-black font-medium">
                    <tr v-for="content in contents" :key="content.id" class="hover:bg-gray-50/50 transition-all">
                        <td class="pl-20 py-6">
                            <div class="w-24 h-16 bg-gray-100 rounded-xl flex items-center justify-center border border-gray-50 overflow-hidden shadow-sm">
                                <img v-if="content.thumbnail" :src="content.thumbnail" class="w-full h-full object-cover">
                                <i v-else class="fa-solid fa-image text-gray-300 text-xl"></i>
                            </div>
                        </td>
                        <td class="px-6 py-6 font-black text-blue-600 uppercase truncate max-w-xs">{{ content.judul }}</td>
                        <td class="px-6 py-6 text-center font-bold text-gray-500">{{ content.penulis?.nama || 'Admin' }}</td>
                        <td class="px-6 py-6 text-center">
                            <span class="px-4 py-1 rounded-full font-black text-[10px] uppercase border"
                                :class="content.status === 'published' ? 'bg-green-50 text-green-600 border-green-200' : 'bg-red-50 text-red-600 border-red-200'">
                                {{ content.status }}
                            </span>
                        </td>
                        <td class="px-8 py-6 text-center">
                            <div class="flex justify-center space-x-2">
                                <button @click="openEditModal(content)" class="p-3 bg-blue-50 text-blue-600 rounded-xl hover:bg-blue-600 hover:text-white transition-all">
                                    <i class="fa-solid fa-pen-to-square"></i>
                                </button>
                                <button @click="currContent = content; openDelete = true" class="p-3 bg-red-50 text-red-600 rounded-xl hover:bg-red-600 hover:text-white transition-all">
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
            <div class="bg-white rounded-[3rem] max-w-2xl w-full p-10 shadow-2xl relative max-h-[90vh] overflow-y-auto">
                <h3 class="text-2xl font-black text-gray-800 uppercase tracking-tighter mb-8 text-center">
                    {{ openAdd ? 'Add New Content' : 'Update Content' }}
                </h3>

                <form @submit.prevent="openAdd ? handleStore() : handleUpdate()" class="space-y-4">
                    <div>
                        <label class="text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Judul Artikel</label>
                        <input v-model="currContent.judul" type="text" required class="w-full px-6 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-bold text-gray-700">
                    </div>

                    <div class="grid grid-cols-2 gap-4">
                        <div>
                            <label class="text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Status</label>
                            <select v-model="currContent.status" class="w-full px-6 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-bold text-gray-700 text-xs uppercase">
                                <option value="draft">Draft</option>
                                <option value="published">Published</option>
                                <option value="archived">Archived</option>
                            </select>
                        </div>
                        <div>
                            <label class="text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Upload Thumbnail</label>
                            <input type="file" @change="onFileChange" class="w-full text-xs text-gray-400 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-xs file:font-black file:bg-[#41D3BD]/10 file:text-[#41D3BD] hover:file:bg-[#41D3BD]/20" />
                        </div>
                    </div>

                    <div>
                        <label class="text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Isi Konten</label>
                        <textarea v-model="currContent.isi" rows="6" required class="w-full px-6 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-bold text-gray-700"></textarea>
                    </div>

                    <div v-if="imagePreview" class="w-full h-32 rounded-2xl overflow-hidden border border-gray-100">
                        <img :src="imagePreview" class="w-full h-full object-cover">
                    </div>

                    <div class="flex justify-end space-x-3 pt-6 border-t border-gray-50">
                        <button @click="closeModals" type="button" class="px-8 py-4 bg-gray-100 rounded-2xl font-black text-gray-400 uppercase text-xs tracking-widest">Batal</button>
                        <button type="submit" class="px-8 py-4 bg-blue-600 text-white rounded-2xl font-black shadow-lg uppercase text-xs tracking-widest hover:scale-105 transition-all">Simpan</button>
                    </div>
                </form>
            </div>
        </div>

        <!-- MODAL DELETE -->
        <div v-if="openDelete" class="fixed inset-0 z-[110] flex items-center justify-center bg-black/50 backdrop-blur-sm px-4">
            <div class="bg-white rounded-[3rem] max-w-sm w-full p-10 text-center shadow-2xl">
                <div class="w-20 h-20 bg-red-50 text-red-500 rounded-full flex items-center justify-center mx-auto mb-6 text-4xl">
                    <i class="fa-solid fa-trash-can"></i>
                </div>
                <h3 class="text-xl font-black text-gray-800 uppercase tracking-tight mb-2">Hapus Artikel?</h3>
                <p class="text-gray-400 text-sm font-bold mb-8 uppercase tracking-tighter">Konten <span class="text-red-500">{{ currContent.judul }}</span> akan dihapus permanen.</p>
                <div class="flex justify-center space-x-3">
                    <button @click="openDelete = false" class="px-8 py-4 bg-gray-100 rounded-2xl font-black text-gray-400 uppercase text-xs">Batal</button>
                    <button @click="handleDelete" class="px-8 py-4 bg-red-600 text-white rounded-2xl font-black shadow-lg shadow-red-200 uppercase text-xs">Ya, Hapus</button>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>
