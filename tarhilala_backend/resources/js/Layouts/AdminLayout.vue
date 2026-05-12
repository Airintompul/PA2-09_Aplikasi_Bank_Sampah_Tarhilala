<script setup>
import { ref, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import Sidebar from '@/Components/Sidebar.vue';
import api from '@/api'; // MENGGUNAKAN INSTANCE API YANG SUDAH KITA SET

const router = useRouter();
const user = ref({ nama: 'Admin', role: 'Staff' });
const searchQuery = ref('');

// --- STATE NOTIFIKASI ---
const notifications = ref([]);
const unreadCount = ref(0);
const showNotifDropdown = ref(false);

onMounted(() => {
    // Ambil data user dari LocalStorage
    const savedUser = localStorage.getItem('admin_user');
    if (savedUser) {
        user.value = JSON.parse(savedUser);
    } else {
        router.push('/login');
    }

    fetchNotifications();
    // Auto refresh notifikasi setiap 60 detik
    const interval = setInterval(fetchNotifications, 60000);

    // Bersihkan interval saat komponen di-unmount
    onUnmounted(() => clearInterval(interval));
});

// FUNGSI: Mengambil notifikasi dari API
const fetchNotifications = async () => {
    try {
        // Menggunakan instance 'api' agar token otomatis terkirim (Solusi 401)
        const response = await api.get('/notifications');

        notifications.value = response.data.data.notifications;
        unreadCount.value = response.data.data.unread_count;
    } catch (error) {
        console.error("Gagal memuat notifikasi:", error);
        if (error.response?.status === 401) {
            router.push('/login');
        }
    }
};

// FUNGSI: Menandai sudah dibaca
const markAsRead = async (notif) => {
    if (notif.is_read) return;
    try {
        // Panggil endpoint read sesuai route: api/admin/notifications/{id}/read
        await api.put(`/notifications/${notif.id}/read`);

        // Update state lokal agar warna langsung berubah
        notif.is_read = 1;
        if (unreadCount.value > 0) unreadCount.value--;
    } catch (error) {
        console.error("Gagal menandai notifikasi:", error);
    }
};

// Format tanggal sederhana
const formatDate = (dateString) => {
    if (!dateString) return '';
    const date = new Date(dateString);
    return date.toLocaleDateString('id-ID', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' });
};
</script>

<template>
    <div class="flex h-screen overflow-hidden bg-[#f3f4f6]">
        <!-- Sidebar Component -->
        <Sidebar />

        <!-- Main Content Area -->
        <div class="flex-1 flex flex-col overflow-hidden">
            <!-- Top Navbar -->
            <header class="bg-white border-b flex items-center justify-between px-8 py-4 z-20 shadow-sm">
                <div class="flex items-center">
                    <h1 class="text-xl font-black text-gray-800 uppercase tracking-tight">
                        Welcome Back, Admin!! 👋
                    </h1>
                </div>

                <div class="flex items-center space-x-6">
                    <!-- Search Bar -->
                    <div class="relative group">
                        <span class="absolute inset-y-0 left-0 flex items-center pl-3">
                            <i class="fa-solid fa-magnifying-glass text-gray-400 group-focus-within:text-[#41D3BD] transition-colors"></i>
                        </span>
                        <input
                            v-model="searchQuery"
                            type="text"
                            class="block w-64 pl-10 pr-3 py-2 border border-transparent bg-gray-100 rounded-xl focus:bg-white focus:ring-2 focus:ring-[#41D3BD] outline-none transition-all sm:text-sm"
                            placeholder="Search data..."
                        >
                    </div>

                    <!-- Action Buttons -->
                    <div class="flex items-center space-x-3 border-r pr-6">

                        <!-- NOTIFICATION DROPDOWN -->
                        <div class="relative">
                            <button
                                @click="showNotifDropdown = !showNotifDropdown"
                                class="relative text-gray-500 hover:text-[#41D3BD] p-2 rounded-lg transition-all"
                            >
                                <i class="fa-regular fa-bell text-xl"></i>
                                <!-- Badge Angka -->
                                <span v-if="unreadCount > 0" class="absolute top-1 right-1 bg-red-500 text-white text-[9px] font-black px-1.5 py-0.5 rounded-full border-2 border-white">
                                    {{ unreadCount }}
                                </span>
                            </button>

                            <!-- Dropdown Box -->
                            <div v-if="showNotifDropdown" class="absolute right-0 mt-3 w-80 bg-white border border-gray-100 shadow-2xl rounded-2xl overflow-hidden z-50">
                                <div class="p-4 border-b flex justify-between items-center bg-gray-50 text-black">
                                    <span class="font-black text-xs uppercase tracking-widest text-gray-800">Notifications</span>
                                    <span class="text-[9px] font-black bg-[#41D3BD] text-white px-2 py-0.5 rounded-full uppercase">{{ unreadCount }} New</span>
                                </div>

                                <!-- AREA LIST: Max Height ditambahkan agar bisa scroll -->
                                <div class="max-h-[350px] overflow-y-auto custom-scrollbar bg-white text-black">
                                    <div v-if="notifications.length === 0" class="p-10 text-center">
                                        <i class="fa-solid fa-bell-slash text-gray-200 text-3xl mb-2"></i>
                                        <p class="text-gray-400 text-[10px] font-bold uppercase">No notifications</p>
                                    </div>

                                    <div
                                        v-for="notif in notifications"
                                        :key="notif.id"
                                        @click="markAsRead(notif)"
                                        :class="[
                                            'p-4 border-b border-gray-50 cursor-pointer transition-all hover:bg-gray-50 flex gap-3',
                                            !notif.is_read ? 'bg-blue-50/40' : 'bg-white'
                                        ]"
                                    >
                                        <!-- Indikator Belum Dibaca -->
                                        <div v-if="!notif.is_read" class="w-2 h-2 bg-blue-500 rounded-full mt-1.5 shrink-0"></div>
                                        <div v-else class="w-2 h-2 bg-transparent rounded-full mt-1.5 shrink-0"></div>

                                        <div class="flex-1">
                                            <h5 class="text-xs font-black text-gray-800 uppercase leading-tight">{{ notif.judul }}</h5>
                                            <p class="text-[11px] text-gray-500 mt-1 font-medium leading-relaxed">{{ notif.pesan }}</p>
                                            <div class="flex justify-between items-center mt-2">
                                                <span class="text-[9px] text-gray-400 font-bold uppercase">{{ formatDate(notif.created_at) }}</span>
                                                <span v-if="!notif.is_read" class="text-[8px] font-black text-blue-600 uppercase">New</span>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div class="p-3 border-t bg-gray-50 text-center">
                                    <button class="text-[10px] font-black text-[#41D3BD] uppercase hover:underline tracking-widest">
                                        View all activities
                                    </button>
                                </div>
                            </div>
                        </div>

                        <button class="flex items-center space-x-2 bg-gray-100 hover:bg-gray-200 px-4 py-2 rounded-xl text-xs font-black uppercase tracking-tighter transition-all text-black">
                            <i class="fa-solid fa-arrow-up-from-bracket"></i>
                            <span>export</span>
                        </button>
                    </div>

                    <!-- Profile Section -->
                    <div class="flex items-center space-x-3 pl-2 border-l">
                        <div class="text-right">
                            <p class="text-sm font-black text-gray-800 uppercase leading-none">{{ user.nama }}</p>
                            <p class="text-[10px] font-bold text-[#41D3BD] uppercase tracking-widest mt-1">{{ user.role }}</p>
                        </div>
                        <div class="w-10 h-10 bg-gray-200 rounded-full flex items-center justify-center border-2 border-[#41D3BD] shadow-sm">
                            <i class="fa-solid fa-user text-gray-500 text-lg"></i>
                        </div>
                    </div>
                </div>
            </header>

            <!-- Dynamic Page Content -->
            <main class="flex-1 overflow-x-hidden overflow-y-auto bg-[#F9FAFB] p-10 custom-scrollbar">
                <slot />
            </main>
        </div>

        <!-- Overlay Background Click -->
        <div v-if="showNotifDropdown" @click="showNotifDropdown = false" class="fixed inset-0 z-40 bg-transparent"></div>
    </div>
</template>

<style>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
body { font-family: 'Plus Jakarta Sans', sans-serif; }

/* Scrollbar Style */
.custom-scrollbar::-webkit-scrollbar { width: 4px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: #41D3BD; border-radius: 10px; }
.custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
</style>
