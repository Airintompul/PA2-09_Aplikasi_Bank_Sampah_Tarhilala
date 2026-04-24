<script setup>
import AdminLayout from '@/Layouts/AdminLayout.vue';
import { ref, onMounted } from 'vue';
import api from '@/api';

const rooms = ref([]);
const isLoading = ref(true);

// Ambil daftar Inbox dari API
const fetchRooms = async () => {
    try {
        const response = await api.get('/messages');
        rooms.value = response.data.data;
    } catch (error) {
        console.error("Gagal memuat chat:", error);
    } finally {
        isLoading.value = false;
    }
};

// Ubah Status Room (Open/Closed)
const toggleStatus = async (room) => {
    try {
        await api.patch(`/messages/${room.id}/status`);
        fetchRooms(); // Refresh data
    } catch (error) {
        alert("Gagal mengubah status");
    }
};

onMounted(() => {
    fetchRooms();
});
</script>

<template>
    <AdminLayout>
        <div class="mb-8">
            <h2 class="text-4xl font-black text-gray-900 uppercase tracking-tight">Messages</h2>
            <p class="text-gray-400 font-bold uppercase text-xs tracking-widest mt-2">Daftar Percakapan Nasabah</p>
        </div>

        <div class="bg-white rounded-[2.5rem] shadow-sm border border-gray-100 relative overflow-hidden">
            <table class="w-full text-left">
                <thead class="bg-[#41D3BD]">
                    <tr>
                        <th class="pl-20 py-6 text-black font-medium text-lg rounded-tl-[2.5rem]">Nasabah</th>
                        <th class="px-6 py-6 text-black font-medium text-lg">Pesan Terakhir</th>
                        <th class="px-6 py-6 text-black font-medium text-lg text-center">Status Room</th>
                        <th class="px-8 py-6 text-center rounded-tr-[2.5rem]">
                            <span class="bg-white px-5 py-1 rounded-lg text-xs font-bold text-black uppercase">Action</span>
                        </th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 text-black font-medium">
                    <tr v-for="room in rooms" :key="room.id" class="hover:bg-gray-50/50 transition-all">
                        <td class="pl-20 py-6">
                            <div class="flex items-center space-x-4">
                                <div class="w-12 h-12 bg-gray-200 rounded-full flex items-center justify-center font-black text-gray-500 uppercase border border-gray-300">
                                    {{ room.nasabah.nama.substring(0, 1) }}
                                </div>
                                <span class="font-bold text-lg uppercase text-blue-600">{{ room.nasabah.nama }}</span>
                            </div>
                        </td>
                        <td class="px-6 py-6">
                            <p class="text-gray-700 line-clamp-1 italic" v-if="room.messages.length">
                                {{ room.messages[0].pesan }}
                            </p>
                            <p class="text-gray-400 italic" v-else>Belum ada pesan</p>
                            <div class="text-[10px] text-gray-400 mt-1 font-bold italic" v-if="room.messages.length">
                                {{ room.messages[0].waktu_kirim }}
                            </div>
                        </td>
                        <td class="px-6 py-6 text-center">
                            <span class="px-4 py-1 rounded-full text-[10px] font-black uppercase"
                                :class="room.status === 'open' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'">
                                {{ room.status }}
                            </span>
                        </td>
                        <!-- SESUDAH (DIPERBAIKI) -->
                        <td class="px-8 py-6 text-center relative">
                            <div class="flex items-center justify-center space-x-2">
                                <router-link :to="'/messages/' + room.id" class="bg-[#41D3BD] text-black px-4 py-2 rounded-xl font-bold text-xs uppercase tracking-widest hover:opacity-80 transition-all">
                                    Buka Chat
                                </router-link>
                                <button @click="toggleStatus(room)" class="p-2 bg-gray-100 rounded-xl hover:bg-gray-200">
                                    <i class="fa-solid" :class="room.status === 'open' ? 'fa-lock text-red-500' : 'fa-lock-open text-green-500'"></i>
                                </button>
                            </div>
                        </td>
                    </tr>
                </tbody>
            </table>
            <div class="h-6"></div>
        </div>
    </AdminLayout>
</template>
