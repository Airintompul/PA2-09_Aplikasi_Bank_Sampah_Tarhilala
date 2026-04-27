<script setup>
import { useRoute, useRouter } from 'vue-router';

const route = useRoute();
const router = useRouter();

const menus = [
    { name: 'Dashboard', icon: 'fa-solid fa-table-cells-large', path: '/dashboard' },
    { name: 'Message', icon: 'fa-regular fa-comment-dots', path: '/messages' },
    { name: 'Product', icon: 'fa-solid fa-box-archive', path: '/product' },
    { name: 'Pick-Up', icon: 'fa-solid fa-truck-pickup', path: '/setoran' },
    { name: 'Billing', icon: 'fa-solid fa-file-invoice-dollar', path: '/billing' },
    { name: 'Employee', icon: 'fa-solid fa-user-tie', path: '/employee' },
    { name: 'Customers', icon: 'fa-solid fa-users', path: '/customers' },
    { name: 'Location', icon: 'fa-solid fa-location-dot', path: '/location' },
    { name: 'Library', icon: 'fa-solid fa-images', path: '/library' },
    { name: 'Reward', icon: 'fa-solid fa-award', path: '/reward' },
];

const handleLogout = () => {
    // Hapus data login dari browser
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_user');
    // Pindah ke halaman login
    router.push('/login');
};
</script>

<template>
    <aside class="w-64 bg-[#41D3BD] flex flex-col h-screen shadow-xl z-20">
        <!-- Logo -->
        <div class="p-6 mb-2 flex justify-center items-center">
            <img src="/assets/img/Logo1.png" alt="Logo" class="w-40 h-auto object-contain">
        </div>

        <!-- Navigation -->
        <nav class="flex-1 px-4 space-y-1 overflow-y-auto custom-sidebar-scroll">
            <router-link
                v-for="menu in menus"
                :key="menu.name"
                :to="menu.path"
                class="flex items-center space-x-3 px-4 py-3 rounded-xl transition-all duration-200"
                :class="route.path === menu.path
                    ? 'bg-white shadow-md text-gray-800'
                    : 'text-white hover:bg-white/20'"
            >
                <i :class="[menu.icon, 'w-6 text-center text-lg']"></i>
                <span class="font-bold uppercase text-[11px] tracking-wider">{{ menu.name }}</span>
            </router-link>
        </nav>

        <!-- Logout -->
        <div class="p-4 mt-auto">
            <button
                @click="handleLogout"
                class="w-full flex items-center space-x-3 px-6 py-3 bg-white/30 hover:bg-white rounded-xl transition-all text-gray-800 font-black border border-white/20 uppercase text-xs"
            >
                <i class="fa-solid fa-right-from-bracket rotate-180"></i>
                <span>Logout</span>
            </button>
        </div>
    </aside>
</template>

<style scoped>
.custom-sidebar-scroll::-webkit-scrollbar { width: 0px; }
</style>
