<script setup>
import AdminLayout from '@/Layouts/AdminLayout.vue';
</script>

<template>
    <AdminLayout>
        <div class="space-y-8">
            <div>
                <h2 class="text-4xl font-black text-gray-800 uppercase tracking-tight">System Overview</h2>
                <p class="text-gray-400 font-bold uppercase text-xs tracking-widest mt-2">Data Real-time Bank Sampah</p>
            </div>

            <!-- Grid Stats -->
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                <div v-for="i in 4" :key="i" class="bg-white p-8 rounded-[2.5rem] border border-gray-100 shadow-sm">
                    <p class="text-[10px] font-black text-gray-300 uppercase">Statistik {{ i }}</p>
                    <h3 class="text-3xl font-black text-gray-800 mt-2">0</h3>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>
