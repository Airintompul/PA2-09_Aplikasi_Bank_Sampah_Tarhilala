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

// Ambil isi chat
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

// Kirim Pesan
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

// Ganti Status dari dalam chat
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
    // Jalankan Polling setiap 5 detik untuk cek pesan baru dari nasabah
    polling = setInterval(fetchMessages, 5000);
});

onUnmounted(() => {
    clearInterval(polling);
});
</script>

<template>
    <AdminLayout v-if="roomData">
        <div class="mb-6 flex items-center space-x-4">
            <router-link to="/messages" class="text-gray-400 hover:text-black transition-colors">
                <i class="fa-solid fa-arrow-left text-2xl"></i>
            </router-link>
            <h2 class="text-3xl font-black text-gray-900 uppercase tracking-tighter">Chat: {{ roomData.nasabah.nama }}</h2>
        </div>

        <div class="bg-white rounded-[2.5rem] shadow-sm border border-gray-100 flex flex-col h-[75vh] overflow-hidden">
            <!-- Header Chat -->
            <div class="bg-[#41D3BD] px-10 py-5 flex justify-between items-center text-black">
                <div class="flex items-center space-x-4">
                    <div class="w-12 h-12 bg-white rounded-full flex items-center justify-center font-black text-[#41D3BD] border-2 border-white/50">
                        {{ roomData.nasabah.nama.substring(0, 1) }}
                    </div>
                    <div>
                        <span class="font-black text-xl block leading-tight">CUSTOMER SUPPORT</span>
                        <span class="text-[10px] font-black bg-white/40 px-2 py-0.5 rounded uppercase tracking-tighter">Nasabah: {{ roomData.nasabah.nama }}</span>
                    </div>
                </div>

                <div class="flex items-center space-x-4">
                    <div class="flex flex-col items-end mr-2">
                        <span class="text-[9px] font-black uppercase opacity-60">Status</span>
                        <span class="font-black uppercase text-sm" :class="roomData.status === 'open' ? 'text-green-900' : 'text-red-900'">{{ roomData.status }}</span>
                    </div>
                    <button @click="toggleRoomStatus" class="bg-white/20 hover:bg-white text-black px-6 py-2 rounded-xl text-xs font-black transition-all border border-white/40 shadow-sm uppercase">
                        {{ roomData.status === 'open' ? 'Tutup Room' : 'Buka Room' }}
                    </button>
                </div>
            </div>

            <!-- Area Pesan -->
            <div ref="chatbox" class="flex-1 overflow-y-auto p-10 space-y-6 bg-gray-50/50 custom-scrollbar">
                <div v-for="msg in messages" :key="msg.id" :class="['flex', msg.pengirim_id != roomData.nasabah_id ? 'justify-end' : 'justify-start']">
                    <!-- Gelembung Admin -->
                    <div v-if="msg.pengirim_id != roomData.nasabah_id" class="bg-[#41D3BD] text-black p-5 rounded-2xl rounded-tr-none max-w-lg shadow-sm border border-black/5">
                        <p class="font-medium text-sm">{{ msg.pesan }}</p>
                        <div class="flex items-center justify-end mt-2 space-x-2 opacity-40">
                            <span class="text-[9px] font-black uppercase">{{ msg.waktu_kirim }}</span>
                            <i class="fa-solid fa-check-double text-[9px]"></i>
                        </div>
                    </div>
                    <!-- Gelembung Nasabah -->
                    <div v-else class="bg-white text-black p-5 rounded-2xl rounded-tl-none max-w-lg shadow-sm border border-gray-200">
                        <p class="font-medium text-sm">{{ msg.pesan }}</p>
                        <span class="text-[9px] font-black block mt-2 text-gray-400 italic uppercase">{{ msg.waktu_kirim }}</span>
                    </div>
                </div>
            </div>

            <!-- Input Area -->
            <div class="p-8 bg-white border-t border-gray-100">
                <div v-if="roomData.status === 'open'" class="flex space-x-4">
                    <input v-model="newMessage" @keyup.enter="sendMessage" type="text" placeholder="Tulis balasan..."
                           class="flex-1 px-8 py-4 border border-gray-200 rounded-2xl outline-none focus:ring-2 focus:ring-[#41D3BD] font-bold text-sm">
                    <button @click="sendMessage" class="bg-[#41D3BD] text-black px-10 py-4 rounded-2xl font-black shadow-lg hover:scale-105 active:scale-95 transition-all flex items-center uppercase text-xs tracking-widest">
                        Kirim <i class="fa-solid fa-paper-plane ml-3"></i>
                    </button>
                </div>
                <div v-else class="bg-red-50 border border-red-100 p-4 rounded-2xl text-center">
                    <p class="text-red-700 font-bold italic text-sm uppercase tracking-wider">
                        <i class="fa-solid fa-lock mr-2"></i> Room ini telah ditutup. Silakan buka kembali untuk membalas.
                    </p>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>

<style scoped>
.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: #41D3BD; border-radius: 10px; }
</style>
