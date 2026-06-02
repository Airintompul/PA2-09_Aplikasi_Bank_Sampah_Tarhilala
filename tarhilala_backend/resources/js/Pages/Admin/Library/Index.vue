<script setup>
import AdminLayout from '@/Layouts/AdminLayout.vue';
import { ref, onMounted, computed } from 'vue';
import api from '@/api';

// --- STATE DATA ---
const contents = ref([]);
const isLoading = ref(true);
const successMessage = ref('');

// State Modals
const openAdd = ref(false);
const openEdit = ref(false);
const openDelete = ref(false);

// --- LOGIC HIDE NAVBAR & BLUR ---
const isAnyModalOpen = computed(() => {
    return openAdd.value || openEdit.value || openDelete.value;
});

// State Form
const currContent = ref({ id: '', judul: '', isi: '', status: 'draft', thumbnail: null });
const imagePreview = ref(null);

// --- LOGIC: AMBIL DATA ---
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

const onFileChange = (e) => {
    const file = e.target.files[0];
    currContent.value.thumbnail = file;
    imagePreview.value = URL.createObjectURL(file);
};

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

const handleUpdate = async () => {
    const formData = new FormData();
    formData.append('judul', currContent.value.judul);
    formData.append('isi', currContent.value.isi);
    formData.append('status', currContent.value.status);
    if (currContent.value.thumbnail instanceof File) {
        formData.append('thumbnail', currContent.value.thumbnail);
    }

    try {
        await api.post(`/library/${currContent.value.id}`, formData);
        closeModals();
        showSuccess("Konten Berhasil Diperbarui!");
        fetchContents();
    } catch (error) {
        alert("Gagal memperbarui konten");
    }
};

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

const openEditModal = (content) => {
    currContent.value = { ...content };
    imagePreview.value = content.thumbnail;
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
    <AdminLayout :hideNavbar="isAnyModalOpen">

        <!-- AREA BACKGROUND: Blur saat modal buka -->
        <div :class="{'blur-md opacity-50 pointer-events-none transition-all duration-500': isAnyModalOpen}">

            <!-- Header Page: Gaya Setoran -->
            <div class="flex flex-col md:flex-row justify-between items-start md:items-center mb-8 gap-4 px-2 md:px-0">
                <div>
                    <h2 class="text-2xl md:text-4xl font-black text-gray-900 uppercase tracking-tight leading-none">
                        Daftar <span class="text-[#41D3BD]">Berita</span>
                    </h2>
                    <p class="text-[10px] md:text-xs font-bold text-gray-400 uppercase tracking-widest mt-2">
                        Pusat Edukasi & Literasi Pengelolaan Sampah
                    </p>
                </div>
                <button @click="openAdd = true" class="w-full md:w-auto flex items-center justify-center space-x-3 bg-[#41D3BD] hover:opacity-80 text-black px-8 py-4 rounded-2xl md:rounded-[2rem] transition-all shadow-lg font-black uppercase text-xs md:text-sm tracking-widest">
                    <i class="fa-solid fa-plus text-lg"></i>
                    <span>Add Content</span>
                </button>
            </div>

            <!-- Alert Berhasil: Gaya Setoran -->
            <div v-if="successMessage" class="mx-2 md:mx-0 mb-6 p-4 md:p-5 bg-black text-[#41D3BD] rounded-2xl md:rounded-3xl font-black shadow-xl flex items-center border-l-8 border-[#41D3BD] text-xs md:text-sm">
                <i class="fa-solid fa-circle-check text-xl md:text-2xl mr-4"></i> {{ successMessage }}
            </div>

            <!-- 1. VIEW DESKTOP: TABEL -->
            <div class="hidden lg:block bg-white rounded-[2.5rem] shadow-sm border border-gray-100 relative overflow-hidden transition-all duration-300">
                <table class="w-full text-left border-collapse">
                    <thead class="bg-[#41D3BD]">
                        <tr class="text-black font-black uppercase text-[11px] tracking-widest">
                            <th class="pl-12 py-7 rounded-tl-[2.5rem]">Thumbnail</th>
                            <th class="px-6 py-7">Judul Artikel</th>
                            <th class="px-6 py-7 text-center">Status</th>
                            <th class="px-6 py-7 text-center">Penulis</th>
                            <th class="pr-12 py-7 text-right rounded-tr-[2.5rem]">Aksi</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-50 font-medium">
                        <tr v-for="content in contents" :key="content.id" class="hover:bg-gray-50/50 transition-all">
                            <td class="pl-12 py-6">
                                <div class="w-24 h-16 bg-slate-100 rounded-xl flex items-center justify-center border-2 border-white shadow-sm overflow-hidden shrink-0">
                                    <img v-if="content.thumbnail" :src="content.thumbnail" class="w-full h-full object-cover">
                                    <i v-else class="fa-solid fa-image text-gray-300 text-xl"></i>
                                </div>
                            </td>
                            <td class="px-6 py-6">
                                <div class="flex flex-col">
                                    <span class="font-black text-lg uppercase text-blue-600 tracking-tighter leading-none truncate max-w-xs">{{ content.judul }}</span>
                                    <span class="text-[10px] text-gray-400 font-bold uppercase mt-1">ID: #LIB-{{ content.id }}</span>
                                </div>
                            </td>
                            <td class="px-6 py-6 text-center">
                                <span class="px-4 py-1.5 rounded-full font-black text-[9px] uppercase tracking-widest border shadow-sm"
                                    :class="content.status === 'published' ? 'bg-green-50 text-green-600 border-green-100' : 'bg-red-50 text-red-600 border-red-100'">
                                    {{ content.status }}
                                </span>
                            </td>
                            <td class="px-6 py-6 text-center font-black text-gray-600 text-xs uppercase tracking-tight">
                                {{ content.penulis?.nama || 'Administrator' }}
                            </td>
                            <td class="pr-12 py-6 text-right">
                                <div class="flex justify-end space-x-2">
                                    <button @click="openEditModal(content)" class="w-10 h-10 bg-blue-50 text-blue-600 rounded-xl hover:bg-blue-600 hover:text-white transition-all shadow-sm flex items-center justify-center">
                                        <i class="fa-solid fa-pen-nib"></i>
                                    </button>
                                    <button @click="currContent = content; openDelete = true" class="w-10 h-10 bg-red-50 text-red-600 rounded-xl hover:bg-red-600 hover:text-white transition-all shadow-sm flex items-center justify-center">
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
                <div v-for="content in contents" :key="content.id" class="bg-white p-5 rounded-[2rem] shadow-sm border border-gray-100 space-y-4">
                    <div class="flex items-center space-x-4">
                        <div class="w-20 h-20 bg-slate-100 rounded-2xl border border-white shadow-sm overflow-hidden shrink-0">
                            <img v-if="content.thumbnail" :src="content.thumbnail" class="w-full h-full object-cover">
                            <i v-else class="fa-solid fa-image text-gray-300 text-xl"></i>
                        </div>
                        <div class="min-w-0 flex-1">
                            <div class="flex justify-between items-start">
                                <span class="text-[8px] font-black uppercase px-2 py-0.5 rounded border tracking-widest shadow-sm"
                                    :class="content.status === 'published' ? 'bg-green-50 text-green-600 border-green-100' : 'bg-red-50 text-red-600 border-red-100'">
                                    {{ content.status }}
                                </span>
                                <div class="flex space-x-1">
                                    <button @click="openEditModal(content)" class="text-blue-500 p-1"><i class="fa-solid fa-pen-nib"></i></button>
                                    <button @click="currContent = content; openDelete = true" class="text-red-500 p-1"><i class="fa-solid fa-trash"></i></button>
                                </div>
                            </div>
                            <h3 class="text-sm font-black text-blue-600 uppercase mt-1 truncate tracking-tighter">{{ content.judul }}</h3>
                            <p class="text-[9px] font-bold text-gray-400 uppercase mt-1">Author: {{ content.penulis?.nama || 'Admin' }}</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- MODAL ADD/EDIT: DIPERKECIL (max-w-xl) & Gaya Font Target -->
        <div v-if="openAdd || openEdit" class="fixed inset-0 z-[999] flex items-center justify-center bg-black/40 backdrop-blur-sm px-4 py-8 transition-all">
            <div class="bg-white rounded-[2.5rem] max-w-xl w-full p-6 md:p-10 shadow-2xl relative overflow-y-auto max-h-[92vh] border-[6px] border-slate-900 transition-all">
                <h3 class="text-xl md:text-2xl font-black text-gray-800 uppercase tracking-tighter mb-8 text-center">
                    {{ openAdd ? 'Publish Content' : 'Update Content' }}
                </h3>

                <form @submit.prevent="openAdd ? handleStore() : handleUpdate()" class="space-y-5">
                    <div>
                        <label class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Judul Artikel</label>
                        <input v-model="currContent.judul" type="text" required class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-bold text-gray-700 text-sm uppercase">
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                            <label class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Status Publikasi</label>
                            <select v-model="currContent.status" class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-black text-gray-700 text-xs uppercase">
                                <option value="draft">DRAFT MODE</option>
                                <option value="published">PUBLISHED</option>
                                <option value="archived">ARCHIVED</option>
                            </select>
                        </div>
                        <div>
                            <label class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Ganti Thumbnail</label>
                            <input type="file" @change="onFileChange" class="w-full text-[10px] text-gray-400 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-[10px] file:font-black file:bg-[#41D3BD]/10 file:text-[#41D3BD]">
                        </div>
                    </div>

                    <div>
                        <label class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase tracking-widest ml-2">Isi Konten Artikel</label>
                        <textarea v-model="currContent.isi" rows="5" required class="w-full px-5 py-4 bg-gray-50 border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-bold text-gray-700 text-sm leading-relaxed"></textarea>
                    </div>

                    <div v-if="imagePreview" class="w-full h-32 md:h-40 rounded-2xl overflow-hidden border-2 border-white bg-gray-50 shadow-md">
                        <img :src="imagePreview" class="w-full h-full object-cover">
                    </div>

                    <div class="flex flex-col-reverse md:flex-row justify-end gap-3 pt-6 border-t border-gray-50">
                        <button @click="closeModals" type="button" class="w-full md:w-auto px-8 py-4 bg-gray-100 rounded-full font-black text-gray-400 uppercase text-[10px] tracking-widest">Batal</button>
                        <button type="submit" class="w-full md:w-auto px-10 py-4 bg-blue-600 text-white rounded-full font-black shadow-lg uppercase text-[10px] hover:scale-105 transition-all">
                            Simpan Artikel
                        </button>
                    </div>
                </form>
            </div>
        </div>

        <!-- MODAL DELETE -->
        <div v-if="openDelete" class="fixed inset-0 z-[110] flex items-center justify-center bg-black/50 backdrop-blur-sm px-4">
            <div class="bg-white rounded-[2.5rem] max-w-sm w-full p-8 text-center shadow-2xl border-b-8 border-gray-900">
                <div class="w-16 h-16 bg-red-50 text-red-500 rounded-full flex items-center justify-center mx-auto mb-6 text-3xl shadow-inner">
                    <i class="fa-solid fa-trash-can"></i>
                </div>
                <h3 class="text-lg font-black text-gray-900 uppercase tracking-tighter mb-2">Hapus Artikel?</h3>
                <p class="text-gray-400 text-[10px] font-bold mb-8 uppercase tracking-widest">Konten <span class="text-red-500">{{ currContent.judul }}</span> akan dihapus permanen.</p>
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
