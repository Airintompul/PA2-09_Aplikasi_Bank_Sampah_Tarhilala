<script setup>
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import Sidebar from '@/Components/Sidebar.vue';

const router = useRouter();
const user = ref({ nama: 'Admin', role: 'Staff' });

onMounted(() => {
    // Ambil data user dari LocalStorage yang disimpan saat Login
    const savedUser = localStorage.getItem('admin_user');
    if (savedUser) {
        user.value = JSON.parse(savedUser);
    } else {
        // Jika tidak ada data user (belum login), arahkan ke Login
        router.push('/login');
    }
});

const searchQuery = ref('');
</script>

<template>
    <div class="flex h-screen overflow-hidden bg-[#f3f4f6]">
        <!-- Sidebar Component -->
        <Sidebar />

        <!-- Main Content Area -->
        <div class="flex-1 flex flex-col overflow-hidden">
            <!-- Top Navbar -->
            <header class="bg-white border-b flex items-center justify-between px-8 py-4 z-10 shadow-sm">
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
                        <button class="text-gray-500 hover:text-[#41D3BD] p-2 rounded-lg">
                            <i class="fa-regular fa-comment-dots text-xl"></i>
                        </button>
                        <button class="flex items-center space-x-2 bg-gray-100 hover:bg-gray-200 px-4 py-2 rounded-xl text-xs font-black uppercase tracking-tighter transition-all">
                            <i class="fa-solid fa-arrow-up-from-bracket"></i>
                            <span>export</span>
                        </button>
                    </div>

                    <!-- Profile Section -->
                    <div class="flex items-center space-x-3 pl-2">
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
                <!-- Slot untuk konten halaman (v-slot) -->
                <slot />
            </main>
        </div>
    </div>
</template>

<style>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
body { font-family: 'Plus Jakarta Sans', sans-serif; }

.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: #41D3BD; border-radius: 10px; }
</style>
