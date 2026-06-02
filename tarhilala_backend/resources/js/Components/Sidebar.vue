<script setup>
import { useRoute, useRouter } from 'vue-router';

// 1. TERIMA PROP & DEFINISIKAN EMIT
defineProps({
    isCollapsed: Boolean
});
const emit = defineEmits(['toggle']);

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
    { name: 'Redemption', icon: 'fa-solid fa-clipboard-check', path: '/redemption' },
];

const handleLogout = () => {
    localStorage.removeItem('admin_token');
    router.push('/login');
};
</script>

<template>
    <div class="flex flex-col h-full bg-[#41D3BD] shadow-xl transition-all duration-300 relative overflow-hidden">

        <!-- HEADER SIDEBAR (LOGO & TOGGLE) -->
        <!-- h-20 agar sejajar dengan tinggi Top Navbar di AdminLayout -->
        <div class="h-20 flex items-center px-6 shrink-0 transition-all duration-300"
             :class="isCollapsed ? 'justify-center' : 'justify-between'">

            <!-- Logo: Hanya muncul jika lebar -->
            <div v-if="!isCollapsed" class="flex items-center">
                <img src="/assets/img/Logo1.png" alt="Logo" class="w-32 md:w-36 h-auto object-contain">
            </div>

            <!-- TOMBOL TOGGLE (Hanya muncul di Desktop LG) -->
            <!-- Kita gunakan desain tombol kecil yang menyatu agar terlihat mewah -->
            <button
                @click="emit('toggle')"
                class="hidden lg:flex w-8 h-8 bg-white/20 hover:bg-white/40 text-white rounded-lg items-center justify-center transition-all active:scale-90"
            >
                <i :class="isCollapsed ? 'fa-solid fa-bars' : 'fa-solid fa-align-left'" class="text-base"></i>
            </button>
        </div>

        <!-- AREA NAVIGASI (Dapat di-scroll secara internal) -->
        <nav class="flex-1 px-4 space-y-1 overflow-y-auto overflow-x-hidden custom-sidebar-scroll pt-4">
            <router-link
                v-for="menu in menus"
                :key="menu.name"
                :to="menu.path"
                class="flex items-center px-4 py-3.5 rounded-xl transition-all duration-200 group mb-1"
                :class="[
                    route.path === menu.path
                        ? 'bg-white shadow-lg text-gray-800'
                        : 'text-white hover:bg-white/10',
                    isCollapsed ? 'justify-center px-0' : 'space-x-4'
                ]"
                :title="isCollapsed ? menu.name : ''"
            >
                <!-- Icon: shrink-0 agar tidak gepeng saat sidebar sempit -->
                <div class="w-6 flex justify-center shrink-0">
                    <i :class="[menu.icon, 'text-lg']"></i>
                </div>

                <!-- Text Menu: font tracking agar terlihat modern -->
                <span v-if="!isCollapsed"
                      class="font-bold uppercase text-[10px] tracking-[0.1em] truncate transition-opacity duration-300">
                    {{ menu.name }}
                </span>
            </router-link>
        </nav>

        <!-- LOGOUT SECTION (Tetap di paling bawah) -->
        <div class="p-4 mt-auto shrink-0 bg-[#3abda8]">
            <button
                @click="handleLogout"
                class="w-full flex items-center bg-white/10 hover:bg-white/30 text-white rounded-xl transition-all font-black border border-white/10 uppercase text-[10px] tracking-widest"
                :class="isCollapsed ? 'justify-center py-4' : 'px-4 py-3.5 space-x-4'"
            >
                <i class="fa-solid fa-right-from-bracket rotate-180 shrink-0"></i>
                <span v-if="!isCollapsed">Logout</span>
            </button>
        </div>
    </div>
</template>

<style scoped>
/* Scrollbar khusus untuk Sidebar agar tipis dan modern di Android */
.custom-sidebar-scroll::-webkit-scrollbar {
    width: 4px;
}
.custom-sidebar-scroll::-webkit-scrollbar-track {
    background: transparent;
}
.custom-sidebar-scroll::-webkit-scrollbar-thumb {
    background: rgba(255, 255, 255, 0.2);
    border-radius: 10px;
}
.custom-sidebar-scroll::-webkit-scrollbar-thumb:hover {
    background: rgba(255, 255, 255, 0.4);
}
</style>
