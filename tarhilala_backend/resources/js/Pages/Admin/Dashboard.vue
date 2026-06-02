<script setup>
import AdminLayout from '@/Layouts/AdminLayout.vue';
import { ref, onMounted } from 'vue';
import api, { financeApi } from '@/api';
import { Bar, Pie } from 'vue-chartjs';
import { Chart as ChartJS, Title, Tooltip, Legend, BarElement, CategoryScale, LinearScale, ArcElement } from 'chart.js';

// Registrasi Komponen ChartJS
ChartJS.register(Title, Tooltip, Legend, BarElement, CategoryScale, LinearScale, ArcElement);

// --- STATE DATA ---
const stats = ref({ nasabah: 0, petugas: 0, pickup: 0, saldo: 0 });
const isLoading = ref(true);

// --- CONFIG GRAFIK BAR ---
const barChartData = ref({
    labels: [],
    datasets: [{
        label: 'Penjemputan Selesai',
        backgroundColor: '#41D3BD',
        borderRadius: 10,
        data: []
    }]
});

// --- CONFIG GRAFIK PIE ---
const pieChartData = ref({
    labels: [],
    datasets: [{
        backgroundColor: ['#3B71CA', '#F9AB40', '#41D3BD', '#BA68C8', '#EF4444', '#D1D5DB'],
        borderWidth: 2,
        borderColor: '#ffffff',
        data: []
    }]
});

// Penting: maintainAspectRatio false agar chart menyesuaikan tinggi container div
const chartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
        legend: {
            display: true,
            position: 'bottom',
            labels: { boxWidth: 10, font: { size: 10 } }
        }
    }
};

// --- LOGIC: FETCH DATA ---
const fetchDashboardData = async () => {
    try {
        const [resMain, resFinance] = await Promise.all([
            api.get('/dashboard'),
            financeApi.get('/finance-stats')
        ]);

        const main = resMain.data.data;
        stats.value = {
            nasabah: main.total_nasabah,
            petugas: main.total_petugas,
            pickup: main.pickup_selesai,
            saldo: resFinance.data.data.total_saldo
        };

        barChartData.value.labels = main.chart_labels;
        barChartData.value.datasets[0].data = main.chart_values;
        pieChartData.value.labels = main.pie_labels;
        pieChartData.value.datasets[0].data = main.pie_values;

    } catch (error) {
        console.error("Gagal memuat data dashboard", error);
    } finally {
        isLoading.value = false;
    }
};

onMounted(() => fetchDashboardData());
</script>

<template>
    <AdminLayout>
        <div class="space-y-6 md:space-y-10 pb-10">
            <!-- Header -->
            <div class="px-2 md:px-0">
                    <h2 class="text-2xl md:text-4xl font-black text-gray-900 uppercase tracking-tight leading-none">
                        Dashboard <span class="text-[#41D3BD]">Tarhilala</span>
                    </h2>
            <p class="text-gray-400 font-bold uppercase text-[8px] md:text-[10px] tracking-[0.2em] mt-1 md:mt-2">Data Real-time Bank Sampah Tarhilala</p>
            </div>

            <!-- 4 SUMMARY CARDS -->
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 md:gap-8 px-2 md:px-0">
                <!-- Card 1: Nasabah -->
                <div class="bg-white p-6 md:p-8 rounded-[2rem] border border-gray-100 shadow-sm flex items-center justify-between">
                    <div>
                        <p class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase tracking-widest">Nasabah</p>
                        <h3 class="text-3xl md:text-4xl font-black text-gray-800 mt-1 md:mt-2">{{ stats.nasabah }}</h3>
                        <p class="text-[8px] md:text-[9px] font-bold text-green-500 uppercase mt-1">Aktif Terdaftar</p>
                    </div>
                    <div class="w-12 h-12 md:w-14 md:h-14 bg-blue-50 text-blue-500 rounded-2xl flex items-center justify-center text-xl md:text-2xl shrink-0"><i class="fa-solid fa-users"></i></div>
                </div>

                <!-- Card 2: Petugas -->
                <div class="bg-white p-6 md:p-8 rounded-[2rem] border border-gray-100 shadow-sm flex items-center justify-between">
                    <div>
                        <p class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase tracking-widest">Petugas</p>
                        <h3 class="text-3xl md:text-4xl font-black text-gray-800 mt-1 md:mt-2">{{ stats.petugas }}</h3>
                        <p class="text-[8px] md:text-[9px] font-bold text-purple-500 uppercase mt-1">Tim Lapangan</p>
                    </div>
                    <div class="w-12 h-12 md:w-14 md:h-14 bg-purple-50 text-purple-500 rounded-2xl flex items-center justify-center text-xl md:text-2xl shrink-0"><i class="fa-solid fa-user-tie"></i></div>
                </div>

                <!-- Card 3: Pickup -->
                <div class="bg-white p-6 md:p-8 rounded-[2rem] border border-gray-100 shadow-sm flex items-center justify-between">
                    <div>
                        <p class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase tracking-widest">Pickup Selesai</p>
                        <h3 class="text-3xl md:text-4xl font-black text-gray-800 mt-1 md:mt-2">{{ stats.pickup }}</h3>
                        <p class="text-[8px] md:text-[9px] font-bold text-emerald-500 uppercase mt-1">Transaksi Sukses</p>
                    </div>
                    <div class="w-12 h-12 md:w-14 md:h-14 bg-emerald-50 text-emerald-500 rounded-2xl flex items-center justify-center text-xl md:text-2xl shrink-0"><i class="fa-solid fa-truck-fast"></i></div>
                </div>

                <!-- Card 4: Total Saldo -->
                <div class="bg-white p-6 md:p-8 rounded-[2rem] border border-gray-100 shadow-sm flex items-center justify-between">
                    <div class="min-w-0">
                        <p class="text-[9px] md:text-[10px] font-black text-gray-400 uppercase tracking-widest">Total Saldo</p>
                        <h3 class="text-lg md:text-xl font-black text-gray-800 mt-1 md:mt-2 truncate">Rp {{ Number(stats.saldo).toLocaleString('id-ID') }}</h3>
                        <p class="text-[8px] md:text-[9px] font-bold text-yellow-600 uppercase mt-1">Dana Nasabah</p>
                    </div>
                    <div class="w-12 h-12 md:w-14 md:h-14 bg-yellow-50 text-yellow-600 rounded-2xl flex items-center justify-center text-xl md:text-2xl shrink-0"><i class="fa-solid fa-wallet"></i></div>
                </div>
            </div>

            <!-- STATISTIK GRAFIK SECTION -->
            <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 md:gap-8 px-2 md:px-0">
                <!-- Grafik Bar -->
                <div class="lg:col-span-2 bg-white p-6 md:p-10 rounded-[2.5rem] md:rounded-[3rem] border border-gray-100 shadow-sm">
                    <div class="flex justify-between items-center mb-6 md:mb-8">
                        <h4 class="text-sm md:text-lg font-black text-gray-800 uppercase">Analitik Penjemputan</h4>
                        <span class="text-[8px] md:text-[10px] font-black text-[#41D3BD] uppercase bg-[#41D3BD]/10 px-3 py-1 rounded-lg">7 Hari</span>
                    </div>
                    <div class="h-64 md:h-72">
                        <Bar v-if="!isLoading" :data="barChartData" :options="chartOptions" />
                    </div>
                </div>

                <!-- Grafik Pie -->
                <div class="bg-white p-6 md:p-10 rounded-[2.5rem] md:rounded-[3rem] border border-gray-100 shadow-sm flex flex-col items-center">
                    <h4 class="text-sm md:text-lg font-black text-gray-800 uppercase mb-6 md:mb-8 text-center">Komposisi Sampah</h4>
                    <div class="w-full h-64 md:flex-1">
                        <Pie v-if="!isLoading" :data="pieChartData" :options="chartOptions" />
                    </div>
                </div>
            </div>

            <!-- Welcome Message -->
            <div class="bg-white p-8 md:p-12 rounded-[2.5rem] md:rounded-[3rem] border border-gray-100 shadow-sm relative overflow-hidden mx-2 md:mx-0">
                <div class="relative z-10 flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
                    <div>
                        <h4 class="text-xl md:text-2xl font-black text-gray-800 uppercase tracking-tight">Selamat Datang</h4>
                        <p class="text-gray-500 text-xs md:text-sm font-medium max-w-xl mt-1">Data real-time dari server operasional dan layanan keuangan.</p>
                    </div>
                    <i class="fa-solid fa-shield-heart text-5xl md:text-7xl text-[#41D3BD]/20 hidden sm:block"></i>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>

<style scoped>
canvas { max-width: 100% !important; }
</style>
