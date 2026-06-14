<script setup>
import { ref, onMounted, nextTick, computed } from 'vue';
import { useRouter } from 'vue-router';
import Sidebar from '@/Components/Sidebar.vue';
import api from '@/api';

// --- PROPS ---
defineProps({
    hideNavbar: { type: Boolean, default: false }
});

const router = useRouter();
const user = ref({ nama: 'Admin', role: 'Staff' });

// --- STATE SIDEBAR ---
const isSidebarOpen = ref(true);

const toggleSidebar = () => {
    isSidebarOpen.value = !isSidebarOpen.value;
    nextTick(() => {
        setTimeout(() => {
            window.dispatchEvent(new Event('resize'));
        }, 350);
    });
};

// --- STATE NOTIFIKASI ---
const notifications = ref([]);
const showNotifDropdown = ref(false);

// Hitung jumlah yang belum dibaca secara dinamis dari array lokal
const unreadCount = computed(() => {
    return notifications.value.filter(n => !n.is_read).length;
});

const fetchNotifications = async () => {
    try {
        const response = await api.get('/notifications');
        notifications.value = response.data.data.notifications;
    } catch (error) {
        console.error("Gagal mengambil notifikasi:", error);
    }
};

// Fungsi memformat waktu (X menit/jam yang lalu)
const formatTime = (timeStr) => {
    if (!timeStr) return "-";
    const date = new Date(timeStr);
    const now = new Date();
    const diffInSeconds = Math.floor((now - date) / 1000);

    if (diffInSeconds < 60) return 'Baru saja';
    if (diffInSeconds < 3600) return `${Math.floor(diffInSeconds / 60)}m lalu`;
    if (diffInSeconds < 86400) return `${Math.floor(diffInSeconds / 3600)}j lalu`;
    return `${Math.floor(diffInSeconds / 86400)} hari lalu`;
};

// 1. Fungsi menandai SATU notif dibaca
const markAsRead = async (notif) => {
    if (notif.is_read) return; // Jika sudah dibaca, abaikan klik

    try {
        // Update di server
        await api.post(`/notifications/${notif.id}/read`);
        // Update di lokal (agar warna & counter langsung berubah)
        notif.is_read = 1;
    } catch (error) {
        console.error("Gagal menandai dibaca:", error);
    }
};

// 2. Fungsi menandai SEMUA dibaca
const markAllRead = async () => {
    if (unreadCount.value === 0) return;

    try {
        // Update di server
        await api.post('/notifications/mark-all-read');
        // Update SEMUA data lokal menjadi sudah dibaca
        notifications.value = notifications.value.map(n => ({
            ...n,
            is_read: 1
        }));
    } catch (error) {
        console.error("Gagal menandai semua dibaca:", error);
    }
};

const closeDropdown = () => {
    showNotifDropdown.value = false;
};

onMounted(() => {
    if (window.innerWidth < 1024) {
        isSidebarOpen.value = false;
    }
    fetchNotifications();

    const savedUser = localStorage.getItem('admin_user');
    if (savedUser) user.value = JSON.parse(savedUser);
});
</script>

<template>
    <div class="flex h-screen overflow-hidden bg-[#F8FAFC] relative font-jakarta text-slate-900">

        <!-- MOBILE OVERLAY -->
        <Transition name="fade">
            <div v-if="isSidebarOpen" @click="isSidebarOpen = false"
                 class="fixed inset-0 bg-black/40 z-[60] lg:hidden backdrop-blur-sm"></div>
        </Transition>

        <!-- SIDEBAR -->
        <aside :class="[
            isSidebarOpen ? 'w-72 translate-x-0' : '-translate-x-full lg:translate-x-0 lg:w-24',
            'fixed lg:static inset-y-0 left-0 z-[70] bg-[#41D3BD] transition-all duration-300 transform flex-shrink-0 shadow-xl lg:shadow-none'
        ]">
            <Sidebar :isCollapsed="!isSidebarOpen" @toggle="toggleSidebar" />
        </aside>

        <div class="flex-1 flex flex-col min-w-0 overflow-hidden relative">

            <!-- HEADER -->
            <header v-if="!hideNavbar" class="h-20 bg-white border-b border-gray-100 flex items-center justify-between px-6 md:px-10 z-50 shrink-0 shadow-sm">
                <div class="flex items-center gap-4">
                    <button @click="toggleSidebar" class="p-2 text-[#41D3BD] lg:hidden transition-transform active:scale-90">
                        <i class="fa-solid fa-bars-staggered text-xl"></i>
                    </button>
                    <h1 class="text-sm md:text-xl font-extrabold uppercase tracking-tight text-slate-800">WELCOME BACK, ADMIN!! 👋</h1>
                </div>

                <div class="flex items-center space-x-4 md:space-x-6">
                    <!-- NOTIFICATIONS SYSTEM -->
                    <div class="relative">
                        <button @click.stop="showNotifDropdown = !showNotifDropdown"
                                class="p-2 text-gray-400 hover:text-[#41D3BD] transition-all relative rounded-full hover:bg-slate-50">
                            <i class="fa-regular fa-bell text-2xl"></i>
                            <!-- Counter Badge -->
                            <span v-if="unreadCount > 0"
                                  class="absolute top-1 right-1 bg-red-500 text-white text-[9px] w-5 h-5 flex items-center justify-center rounded-full border-2 border-white font-black animate-pulse">
                                {{ unreadCount }}
                            </span>
                        </button>

                        <Transition name="fade">
                            <div v-if="showNotifDropdown"
                                 class="absolute right-0 mt-4 w-80 md:w-96 bg-white shadow-2xl rounded-[2rem] border border-gray-100 z-[100] overflow-hidden flex flex-col border-b-8 border-slate-900">

                                <div class="p-6 bg-slate-50 border-b border-gray-100 flex justify-between items-center">
                                    <div class="flex items-center gap-2">
                                        <h3 class="font-black text-[10px] uppercase tracking-widest text-slate-800">Pemberitahuan</h3>
                                        <span v-if="unreadCount > 0" class="bg-[#41D3BD]/20 text-[#41D3BD] text-[9px] px-2 py-0.5 rounded-full font-black">{{ unreadCount }} BARU</span>
                                    </div>
                                    <button @click="markAllRead"
                                            class="text-[10px] font-black text-[#41D3BD] uppercase hover:opacity-70 transition-all disabled:opacity-30"
                                            :disabled="unreadCount === 0">
                                        Tandai Semua
                                    </button>
                                </div>

                                <!-- NOTIFICATION LIST -->
                                <div class="max-h-[400px] overflow-y-auto custom-scrollbar bg-white">
                                    <div v-if="notifications.length === 0" class="p-10 text-center text-gray-400">
                                        <i class="fa-solid fa-bell-slash text-2xl mb-2 opacity-20"></i>
                                        <p class="text-[10px] font-bold uppercase tracking-widest">Tidak ada notifikasi</p>
                                    </div>

                                    <div v-for="n in notifications" :key="n.id"
                                         @click="markAsRead(n)"
                                         :class="[n.is_read ? 'bg-white opacity-60' : 'bg-teal-50/40 border-l-4 border-[#41D3BD] shadow-[inset_0_0_10px_rgba(65,211,189,0.05)]']"
                                         class="p-5 border-b border-gray-50 cursor-pointer hover:bg-slate-50 transition-all group">
                                        <div class="flex gap-4">
                                            <!-- Icon dinamis berdasarkan tipe -->
                                            <div :class="[n.is_read ? 'bg-slate-100 text-slate-400' : 'bg-[#41D3BD] text-white shadow-md shadow-[#41D3BD]/20']"
                                                 class="w-10 h-10 rounded-xl flex items-center justify-center shrink-0 transition-all group-hover:scale-110">
                                                <i class="fa-solid" :class="[
                                                    n.judul.toLowerCase().includes('setoran') ? 'fa-box' :
                                                    n.judul.toLowerCase().includes('penarikan') ? 'fa-wallet' : 'fa-bell'
                                                ]"></i>
                                            </div>
                                            <div class="flex-1 min-w-0">
                                                <div class="flex justify-between items-start mb-1">
                                                    <p class="text-[11px] font-black text-slate-800 uppercase leading-tight truncate mr-2">{{ n.judul }}</p>
                                                    <span class="text-[8px] font-bold text-gray-400 uppercase shrink-0">{{ formatTime(n.created_at) }}</span>
                                                </div>
                                                <p class="text-[11px] font-medium text-slate-500 leading-relaxed line-clamp-2">{{ n.pesan }}</p>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div class="p-4 bg-slate-50 text-center border-t border-gray-100">
                                    <button @click="showNotifDropdown = false" class="text-[10px] font-black text-gray-400 uppercase tracking-widest hover:text-slate-800 transition-colors">Tutup Menu</button>
                                </div>
                            </div>
                        </Transition>
                    </div>

                    <!-- PROFILE SECTION -->
                    <div class="flex items-center space-x-3 pl-4 border-l border-gray-100">
                        <div class="text-right hidden sm:block leading-tight">
                            <p class="text-xs font-black uppercase text-slate-800">{{ user.nama }}</p>
                            <p class="text-[10px] font-bold text-[#41D3BD] uppercase tracking-tighter">{{ user.role }} Account</p>
                        </div>
                        <div class="w-10 h-10 bg-slate-200 rounded-full border-2 border-[#41D3BD] flex items-center justify-center overflow-hidden shadow-sm">
                            <i class="fa-solid fa-user text-slate-400 text-lg"></i>
                        </div>
                    </div>
                </div>
            </header>

            <!-- MAIN CONTENT -->
            <main :class="['flex-1 overflow-x-hidden overflow-y-auto bg-[#F8FAFC] custom-scrollbar relative z-0', hideNavbar ? 'p-0' : 'p-6 md:p-8 lg:p-10']"
                  @click="closeDropdown">
                <div class="max-w-[1600px] mx-auto">
                    <slot />
                </div>
            </main>
        </div>
    </div>
</template>

<style>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');

:root { font-family: 'Plus Jakarta Sans', sans-serif; }
body { font-family: 'Plus Jakarta Sans', sans-serif; background-color: #F8FAFC; }

.custom-scrollbar::-webkit-scrollbar { width: 4px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: #cbd5e1; border-radius: 10px; }
.custom-scrollbar::-webkit-scrollbar-thumb:hover { background: #41D3BD; }

.fade-enter-active, .fade-leave-active { transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); }
.fade-enter-from, .fade-leave-to { opacity: 0; transform: translateY(-10px); }

/* Animasi Badge Bergetar saat ada notif baru */
@keyframes bounce {
    0%, 100% { transform: translateY(0); }
    50% { transform: translateY(-2px); }
}
.animate-bounce { animation: bounce 0.5s infinite; }
</style>
