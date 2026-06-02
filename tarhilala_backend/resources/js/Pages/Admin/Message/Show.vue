<script setup>
import AdminLayout from '@/Layouts/AdminLayout.vue';
import { ref, onMounted, onUnmounted, nextTick } from 'vue';
import { useRoute } from 'vue-router';
import api from '@/api';

const route = useRoute();
const roomId = route.params.id;
const roomData = ref(null);
const messages = ref([]);
const newMessage = ref('');
const chatbox = ref(null);
let polling = null;

const fetchMessages = async () => {
    try {
        const response = await api.get(`/messages/${roomId}`);
        roomData.value = response.data.data;
        messages.value = response.data.data.messages;
        scrollToBottom();
    } catch (error) {
        console.error("Gagal memuat pesan");
    }
};

const sendMessage = async () => {
    if (!newMessage.value.trim()) return;
    try {
        await api.post(`/messages/${roomId}/send`, { pesan: newMessage.value });
        newMessage.value = '';
        fetchMessages();
    } catch (error) {
        alert("Gagal mengirim pesan. Pastikan room masih OPEN.");
    }
};

const toggleRoomStatus = async () => {
    await api.patch(`/messages/${roomId}/status`);
    fetchMessages();
};

const scrollToBottom = () => {
    nextTick(() => {
        if (chatbox.value) {
            chatbox.value.scrollTop = chatbox.value.scrollHeight;
        }
    });
};

onMounted(() => {
    fetchMessages();
    polling = setInterval(fetchMessages, 5000);
});

onUnmounted(() => {
    clearInterval(polling);
});
</script>

<template>
    <AdminLayout v-if="roomData">
        <!-- Header Page -->
        <div class="mb-4 md:mb-6 flex items-center space-x-3 md:space-x-4 px-2 md:px-0">
            <router-link to="/messages" class="text-gray-400 hover:text-black transition-colors">
                <i class="fa-solid fa-arrow-left text-xl md:text-2xl"></i>
            </router-link>
            <h2 class="text-xl md:text-3xl font-black text-gray-900 uppercase tracking-tighter truncate">Chat: {{ roomData.nasabah.nama }}</h2>
        </div>

        <!-- Chat Container -->
        <!-- h-[80vh] di mobile agar lebih tinggi, md:h-[75vh] di desktop -->
        <div class="bg-white rounded-[2rem] md:rounded-[2.5rem] shadow-sm border border-gray-100 flex flex-col h-[75vh] md:h-[75vh] overflow-hidden mx-2 md:mx-0">

            <!-- Header Chat (Status & Support) -->
            <div class="bg-[#41D3BD] px-4 md:px-10 py-3 md:py-5 flex justify-between items-center text-black shrink-0">
                <div class="flex items-center space-x-3 md:space-x-4">
                    <div class="w-10 h-10 md:w-12 md:h-12 bg-white rounded-full flex items-center justify-center font-black text-[#41D3BD] border-2 border-white/50 shrink-0 text-sm md:text-base">
                        {{ roomData.nasabah.nama.substring(0, 1) }}
                    </div>
                    <div class="min-w-0">
                        <span class="font-black text-sm md:text-xl block leading-tight truncate uppercase">SUPPORT</span>
                        <span class="text-[8px] md:text-[10px] font-black bg-white/40 px-2 py-0.5 rounded uppercase tracking-tighter block md:inline mt-0.5">Nasabah: {{ roomData.nasabah.nama }}</span>
                    </div>
                </div>

                <div class="flex items-center space-x-2 md:space-x-4 shrink-0">
                    <div class="hidden sm:flex flex-col items-end mr-2">
                        <span class="text-[9px] font-black uppercase opacity-60">Status</span>
                        <span class="font-black uppercase text-sm" :class="roomData.status === 'open' ? 'text-green-900' : 'text-red-900'">{{ roomData.status }}</span>
                    </div>
                    <button @click="toggleRoomStatus" class="bg-white/20 hover:bg-white text-black px-3 md:px-6 py-2 rounded-xl text-[10px] md:text-xs font-black transition-all border border-white/40 shadow-sm uppercase whitespace-nowrap">
                        {{ roomData.status === 'open' ? 'Tutup' : 'Buka' }}
                    </button>
                </div>
            </div>

            <!-- Area Pesan (Scrolling) -->
            <div ref="chatbox" class="flex-1 overflow-y-auto p-4 md:p-10 space-y-4 md:space-y-6 bg-gray-50/50 custom-scrollbar">
                <div v-for="msg in messages" :key="msg.id" :class="['flex', msg.pengirim_id != roomData.nasabah_id ? 'justify-end' : 'justify-start']">
                    <!-- Gelembung Admin -->
                    <div v-if="msg.pengirim_id != roomData.nasabah_id" class="bg-[#41D3BD] text-black p-3 md:p-5 rounded-2xl rounded-tr-none max-w-[85%] md:max-w-lg shadow-sm border border-black/5">
                        <p class="font-medium text-xs md:text-sm break-words">{{ msg.pesan }}</p>
                        <div class="flex items-center justify-end mt-2 space-x-2 opacity-40">
                            <span class="text-[8px] md:text-[9px] font-black uppercase">{{ msg.waktu_kirim }}</span>
                            <i class="fa-solid fa-check-double text-[8px] md:text-[9px]"></i>
                        </div>
                    </div>
                    <!-- Gelembung Nasabah -->
                    <div v-else class="bg-white text-black p-3 md:p-5 rounded-2xl rounded-tl-none max-w-[85%] md:max-w-lg shadow-sm border border-gray-200">
                        <p class="font-medium text-xs md:text-sm break-words">{{ msg.pesan }}</p>
                        <span class="text-[8px] md:text-[9px] font-black block mt-2 text-gray-400 italic uppercase">{{ msg.waktu_kirim }}</span>
                    </div>
                </div>
            </div>

            <!-- Input Area -->
            <div class="p-4 md:p-8 bg-white border-t border-gray-100 shrink-0">
                <div v-if="roomData.status === 'open'" class="flex space-x-2 md:space-x-4">
                    <input v-model="newMessage" @keyup.enter="sendMessage" type="text" placeholder="Balas..."
                           class="flex-1 px-4 md:px-8 py-3 md:py-4 border border-gray-200 rounded-xl md:rounded-2xl outline-none focus:ring-2 focus:ring-[#41D3BD] font-bold text-xs md:text-sm">
                    <button @click="sendMessage" class="bg-[#41D3BD] text-black px-4 md:px-10 py-3 md:py-4 rounded-xl md:rounded-2xl font-black shadow-lg hover:scale-105 active:scale-95 transition-all flex items-center uppercase text-[10px] md:text-xs tracking-widest shrink-0">
                        <span class="hidden sm:inline">Kirim</span> <i class="fa-solid fa-paper-plane sm:ml-3"></i>
                    </button>
                </div>
                <div v-else class="bg-red-50 border border-red-100 p-3 md:p-4 rounded-xl md:rounded-2xl text-center">
                    <p class="text-red-700 font-bold italic text-[10px] md:text-sm uppercase tracking-wider">
                        <i class="fa-solid fa-lock mr-2"></i> Room ditutup.
                    </p>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>

<style scoped>
.custom-scrollbar::-webkit-scrollbar { width: 4px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: #41D3BD; border-radius: 10px; }
</style>
