<script setup>
import { ref, onMounted, onUnmounted, nextTick } from 'vue';
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
    // Beri sinyal resize ke window agar grafik (Chart) menyesuaikan lebar baru
    nextTick(() => {
        setTimeout(() => {
            window.dispatchEvent(new Event('resize'));
        }, 350);
    });
};

// --- LOGIC RESPONSIVE (Hanya saat pertama kali muat) ---
onMounted(() => {
    // Jalankan pengecekan hanya SEKALI saat halaman dimuat
    // Agar jika user menutup manual di desktop, dia tidak terbuka sendiri lagi
    if (window.innerWidth < 1024) {
        isSidebarOpen.value = false;
    }

    fetchNotifications();

    const savedUser = localStorage.getItem('admin_user');
    if (savedUser) user.value = JSON.parse(savedUser);
});

// --- STATE NOTIFIKASI ---
const notifications = ref([]);
const unreadCount = ref(0);
const showNotifDropdown = ref(false);

const fetchNotifications = async () => {
    try {
        const response = await api.get('/notifications');
        notifications.value = response.data.data.notifications;
        unreadCount.value = response.data.data.unread_count;
    } catch (error) { console.error("Notif Error:", error); }
};
</script>

<template>
    <div class="flex h-screen overflow-hidden bg-[#F8FAFC] relative font-jakarta text-slate-900">

        <!-- 1. MOBILE OVERLAY (Hanya muncul di HP) -->
        <Transition name="fade">
            <div v-if="isSidebarOpen" @click="isSidebarOpen = false"
                 class="fixed inset-0 bg-black/40 z-[60] lg:hidden backdrop-blur-sm transition-opacity duration-300"></div>
        </Transition>

        <!-- 2. SIDEBAR -->
        <!-- lg:static membuat sidebar memakan ruang di desktop dan mendorong konten ke kanan -->
        <aside :class="[
            isSidebarOpen ? 'w-72 translate-x-0' : '-translate-x-full lg:translate-x-0 lg:w-24',
            'fixed lg:static inset-y-0 left-0 z-[70] bg-[#41D3BD] transition-all duration-300 transform flex-shrink-0 shadow-xl lg:shadow-none'
        ]">
            <Sidebar :isCollapsed="!isSidebarOpen" @toggle="toggleSidebar" />
        </aside>

        <!-- 3. MAIN CONTENT WRAPPER -->
        <div class="flex-1 flex flex-col min-w-0 overflow-hidden relative">

            <!-- HEADER / TOP NAVBAR -->
            <header v-if="!hideNavbar" class="h-20 bg-white border-b border-gray-100 flex items-center justify-between px-6 md:px-10 z-50 shrink-0 shadow-sm">

                <!-- Left Side: Hamburger & Welcome Text -->
                <div class="flex items-center gap-4">
                    <button @click="toggleSidebar"
                            class="p-2 text-[#41D3BD] hover:bg-teal-50 rounded-lg transition-all active:scale-90 lg:hidden">
                        <i class="fa-solid fa-bars-staggered text-xl"></i>
                    </button>

                    <h1 class="text-sm md:text-xl font-extrabold uppercase tracking-tight text-slate-800 leading-none">
                        WELCOME BACK, ADMIN!! 👋
                    </h1>
                </div>

                <!-- Right Side: Notif & Profile -->
                <div class="flex items-center space-x-4 md:space-x-6">

                    <!-- Notifications -->
                    <div class="relative">
                        <button @click.stop="showNotifDropdown = !showNotifDropdown"
                                class="p-2 text-gray-400 hover:text-[#41D3BD] transition-colors relative">
                            <i class="fa-regular fa-bell text-2xl"></i>
                            <span v-if="unreadCount > 0"
                                  class="absolute top-1 right-1 bg-red-500 text-white text-[10px] w-5 h-5 flex items-center justify-center rounded-full border-2 border-white font-bold">
                                {{ unreadCount }}
                            </span>
                        </button>
                        <!-- Dropdown Notif Code Tetap Sama (jika ada) -->
                    </div>

                    <!-- User Profile Info -->
                    <div class="flex items-center space-x-3 pl-4 border-l border-gray-100">
                        <div class="text-right hidden sm:block leading-tight">
                            <p class="text-xs font-black uppercase text-slate-800 tracking-tighter">Admin</p>
                            <p class="text-[10px] font-bold text-[#41D3BD] uppercase">Staff Account</p>
                        </div>
                        <div class="w-10 h-10 bg-slate-200 rounded-full border-2 border-[#41D3BD] flex items-center justify-center overflow-hidden shadow-sm">
                            <i class="fa-solid fa-user text-slate-400 text-lg"></i>
                        </div>
                    </div>
                </div>
            </header>

            <!-- 4. DASHBOARD AREA -->
            <main :class="[
                'flex-1 overflow-x-hidden overflow-y-auto bg-[#F8FAFC] custom-scrollbar relative z-0',
                hideNavbar ? 'p-0' : 'p-6 md:p-8 lg:p-10'
            ]">
                <div class="max-w-[1600px] mx-auto">
                    <slot />
                </div>
            </main>
        </div>
    </div>
</template>

<style>
/* FONT PLUS JAKARTA SANS */
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');

:root {
    font-family: 'Plus Jakarta Sans', sans-serif;
}

body {
    font-family: 'Plus Jakarta Sans', sans-serif;
    background-color: #F8FAFC;
}

.font-jakarta {
    font-family: 'Plus Jakarta Sans', sans-serif;
}

/* Style Scrollbar Dashboard */
.custom-scrollbar::-webkit-scrollbar { width: 4px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: #cbd5e1; border-radius: 10px; }
.custom-scrollbar::-webkit-scrollbar-thumb:hover { background: #41D3BD; }

/* Animasi Entry */
.fade-enter-active, .fade-leave-active { transition: opacity 0.3s; }
.fade-enter-from, .fade-leave-to { opacity: 0; }

canvas { max-width: 100% !important; }
</style>
