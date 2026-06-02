<script setup>
import AdminLayout from '@/Layouts/AdminLayout.vue';
import { ref, onMounted } from 'vue';
import api from '@/api';

const rooms = ref([]);
const isLoading = ref(true);

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

const toggleStatus = async (room) => {
    try {
        await api.patch(`/messages/${room.id}/status`);
        fetchRooms();
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
        <!-- Header Section: Disamakan dengan Setoran -->
        <div class="mb-8 md:mb-10 px-2 md:px-0">
            <h2 class="text-2xl md:text-4xl font-black text-gray-900 uppercase tracking-tight leading-none">
                Pesan <span class="text-[#41D3BD]">Nasabah</span>
            </h2>
            <p class="text-gray-400 font-bold uppercase text-[10px] md:text-xs tracking-widest mt-2">
                Daftar Percakapan & Konsultasi Nasabah
            </p>
        </div>

        <!-- 1. VIEW DESKTOP: TABEL (Identik dengan style Setoran) -->
        <div class="hidden lg:block bg-white rounded-[2.5rem] shadow-sm border border-gray-100 relative overflow-hidden transition-all duration-300">
            <table class="w-full text-left border-collapse">
                <thead class="bg-[#41D3BD]">
                    <tr class="text-black font-black uppercase text-[11px] tracking-widest">
                        <th class="pl-12 py-7 rounded-tl-[2.5rem]">Nasabah</th>
                        <th class="px-6 py-7">Pesan Terakhir</th>
                        <th class="px-6 py-7 text-center">Status Room</th>
                        <th class="pr-12 py-7 text-right rounded-tr-[2.5rem]">Aksi</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-50">
                    <tr v-if="isLoading">
                        <td colspan="4" class="py-20 text-center">
                            <div class="inline-block w-8 h-8 border-4 border-[#41D3BD] border-t-transparent rounded-full animate-spin"></div>
                        </td>
                    </tr>
                    <tr v-else v-for="room in rooms" :key="room.id" class="hover:bg-gray-50/50 transition-all">
                        <td class="pl-12 py-6">
                            <div class="flex items-center space-x-4">
                                <div class="w-12 h-12 bg-slate-100 rounded-2xl flex items-center justify-center font-black text-[#41D3BD] uppercase border-2 border-white shadow-sm shrink-0">
                                    {{ room.nasabah.nama.substring(0, 1) }}
                                </div>
                                <div class="flex flex-col">
                                    <span class="font-black text-lg uppercase text-blue-600 tracking-tighter leading-none">
                                        {{ room.nasabah.nama }}
                                    </span>
                                    <span class="text-[10px] text-gray-400 font-bold uppercase mt-1">Room ID: #CHAT-{{ room.id }}</span>
                                </div>
                            </div>
                        </td>
                        <td class="px-6 py-6">
                            <p class="text-gray-700 line-clamp-1 font-bold italic text-xs leading-tight" v-if="room.messages.length">
                                "{{ room.messages[0].pesan }}"
                            </p>
                            <p class="text-gray-300 italic text-xs font-bold" v-else>Belum ada pesan</p>
                            <div class="text-[9px] text-gray-400 mt-1 font-black uppercase tracking-wider" v-if="room.messages.length">
                                <i class="fa-regular fa-clock mr-1"></i> {{ room.messages[0].waktu_kirim }}
                            </div>
                        </td>
                        <td class="px-6 py-6 text-center">
                            <span class="px-4 py-1.5 rounded-full text-[9px] font-black uppercase tracking-widest border shadow-sm transition-all"
                                :class="room.status === 'open' ? 'bg-green-50 text-green-600 border-green-100' : 'bg-red-50 text-red-600 border-red-100'">
                                {{ room.status }}
                            </span>
                        </td>
                        <td class="pr-12 py-6 text-right">
                            <div class="flex justify-end space-x-2">
                                <router-link :to="'/messages/' + room.id" class="px-6 py-2.5 bg-[#41D3BD] text-black rounded-xl font-black text-[10px] uppercase tracking-widest shadow-sm hover:opacity-80 transition-all">
                                    Buka Chat
                                </router-link>
                                <button @click="toggleStatus(room)" class="w-10 h-10 rounded-xl shadow-sm flex items-center justify-center transition-all bg-slate-50 text-slate-400 hover:bg-slate-900 hover:text-white">
                                    <i class="fa-solid" :class="room.status === 'open' ? 'fa-lock' : 'fa-lock-open'"></i>
                                </button>
                            </div>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>

        <!-- 2. VIEW MOBILE: CARDS (Identik dengan style Setoran) -->
        <div class="lg:hidden space-y-4 px-2 pb-10">
            <div v-for="room in rooms" :key="room.id" class="bg-white p-5 rounded-[2rem] shadow-sm border border-gray-100 space-y-4">
                <div class="flex justify-between items-start">
                    <div class="flex items-center space-x-3 min-w-0">
                        <div class="w-10 h-10 bg-slate-100 rounded-xl flex items-center justify-center font-black text-[#41D3BD] text-sm border border-white shadow-sm">
                            {{ room.nasabah.nama.substring(0, 1) }}
                        </div>
                        <div class="min-w-0">
                            <h4 class="font-black text-blue-600 uppercase text-sm truncate pr-2 tracking-tighter">{{ room.nasabah.nama }}</h4>
                            <p class="text-[9px] font-bold text-gray-400 uppercase">#CHAT-{{ room.id }}</p>
                        </div>
                    </div>
                    <span class="px-2 py-0.5 rounded-full font-black text-[8px] uppercase tracking-widest border shadow-sm"
                        :class="room.status === 'open' ? 'bg-green-50 text-green-600 border-green-100' : 'bg-red-50 text-red-600 border-red-100'">
                        {{ room.status }}
                    </span>
                </div>

                <div class="bg-gray-50 p-3 rounded-2xl border border-gray-100">
                    <p class="text-[10px] text-gray-600 font-bold italic line-clamp-2" v-if="room.messages.length">
                        "{{ room.messages[0].pesan }}"
                    </p>
                    <p class="text-gray-300 italic text-[10px] font-bold" v-else>Belum ada pesan</p>
                    <div class="text-[8px] text-gray-400 mt-2 font-black uppercase tracking-wider" v-if="room.messages.length">
                        {{ room.messages[0].waktu_kirim }}
                    </div>
                </div>

                <div class="flex gap-2">
                    <router-link :to="'/messages/' + room.id" class="flex-1 py-3 bg-[#41D3BD] text-black rounded-xl font-black text-[10px] uppercase text-center tracking-widest shadow-sm active:scale-95 transition-all">
                        Buka Percakapan
                    </router-link>
                    <button @click="toggleStatus(room)" class="w-12 h-12 bg-slate-100 text-slate-400 rounded-xl flex items-center justify-center border border-gray-100 active:scale-95 transition-all">
                        <i class="fa-solid" :class="room.status === 'open' ? 'fa-lock' : 'fa-lock-open'"></i>
                    </button>
                </div>
            </div>

            <div v-if="isLoading" class="text-center py-10 font-black text-gray-300 uppercase text-[10px]">Syncing Conversations...</div>
        </div>
    </AdminLayout>
</template>

<style scoped>
.transition-all { transition: all 0.3s ease-in-out; }
</style>
