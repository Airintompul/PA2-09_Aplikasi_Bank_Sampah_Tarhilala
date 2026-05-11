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

// --- CONFIG GRAFIK BAR (Tren Penjemputan) ---
const barChartData = ref({
    labels: [],
    datasets: [{
        label: 'Penjemputan Selesai',
        backgroundColor: '#41D3BD',
        borderRadius: 10,
        data: []
    }]
});

// --- CONFIG GRAFIK PIE (Komposisi Sampah Dinamis) ---
const pieChartData = ref({
    labels: [],
    datasets: [{
        backgroundColor: ['#3B71CA', '#F9AB40', '#41D3BD', '#BA68C8', '#EF4444', '#D1D5DB'],
        borderWidth: 2,
        borderColor: '#ffffff',
        data: []
    }]
});

const chartOptions = { responsive: true, maintainAspectRatio: false };

// --- LOGIC: FETCH DATA DARI DATABASE ---
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

        // Update data Grafik Bar (Tren)
        barChartData.value.labels = main.chart_labels;
        barChartData.value.datasets[0].data = main.chart_values;

        // Update data Grafik Pie (Dinamis dari Database)
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
        <div class="space-y-10">
            <!-- Header -->
            <div>
                <h2 class="text-4xl font-black text-gray-900 uppercase tracking-tight">Statistik Tarhilala</h2>
                <p class="text-gray-400 font-bold uppercase text-[10px] tracking-[0.3em] mt-2">Data Real-time Bank Sampah Tarhilala</p>
            </div>

            <!-- 4 SUMMARY CARDS (Symmetric Style) -->
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
                <!-- Card 1: Nasabah -->
                <div class="bg-white p-8 rounded-[2.5rem] border border-gray-100 shadow-sm flex items-center justify-between">
                    <div>
                        <p class="text-[10px] font-black text-gray-400 uppercase tracking-widest">Nasabah</p>
                        <h3 class="text-4xl font-black text-gray-800 mt-2">{{ stats.nasabah }}</h3>
                        <p class="text-[9px] font-bold text-green-500 uppercase mt-2">Aktif Terdaftar</p>
                    </div>
                    <div class="w-14 h-14 bg-blue-50 text-blue-500 rounded-2xl flex items-center justify-center text-2xl"><i class="fa-solid fa-users"></i></div>
                </div>

                <!-- Card 2: Petugas -->
                <div class="bg-white p-8 rounded-[2.5rem] border border-gray-100 shadow-sm flex items-center justify-between">
                    <div>
                        <p class="text-[10px] font-black text-gray-400 uppercase tracking-widest">Petugas</p>
                        <h3 class="text-4xl font-black text-gray-800 mt-2">{{ stats.petugas }}</h3>
                        <p class="text-[9px] font-bold text-purple-500 uppercase mt-2">Tim Lapangan</p>
                    </div>
                    <div class="w-14 h-14 bg-purple-50 text-purple-500 rounded-2xl flex items-center justify-center text-2xl"><i class="fa-solid fa-user-tie"></i></div>
                </div>

                <!-- Card 3: Pickup Berhasil (Sama Warnanya dengan Card Lain) -->
                <div class="bg-white p-8 rounded-[2.5rem] border border-gray-100 shadow-sm flex items-center justify-between">
                    <div>
                        <p class="text-[10px] font-black text-gray-400 uppercase tracking-widest">Pickup Selesai</p>
                        <h3 class="text-4xl font-black text-gray-800 mt-2">{{ stats.pickup }}</h3>
                        <p class="text-[9px] font-bold text-emerald-500 uppercase mt-2">Transaksi Sukses</p>
                    </div>
                    <div class="w-14 h-14 bg-emerald-50 text-emerald-500 rounded-2xl flex items-center justify-center text-2xl"><i class="fa-solid fa-truck-fast"></i></div>
                </div>

                <!-- Card 4: Total Saldo -->
                <div class="bg-white p-8 rounded-[2.5rem] border border-gray-100 shadow-sm flex items-center justify-between">
                    <div>
                        <p class="text-[10px] font-black text-gray-400 uppercase tracking-widest">Total Saldo</p>
                        <h3 class="text-xl font-black text-gray-800 mt-3">Rp {{ Number(stats.saldo).toLocaleString('id-ID') }}</h3>
                        <p class="text-[9px] font-bold text-yellow-600 uppercase mt-2">Dana Nasabah</p>
                    </div>
                    <div class="w-14 h-14 bg-yellow-50 text-yellow-600 rounded-2xl flex items-center justify-center text-2xl"><i class="fa-solid fa-wallet"></i></div>
                </div>
            </div>

            <!-- STATISTIK GRAFIK SECTION -->
            <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
                <!-- Grafik Bar (Trend Penjemputan) -->
                <div class="lg:col-span-2 bg-white p-10 rounded-[3rem] border border-gray-100 shadow-sm">
                    <div class="flex justify-between items-center mb-8">
                        <h4 class="text-lg font-black text-gray-800 uppercase tracking-tighter">Analitik Penjemputan</h4>
                        <span class="text-[10px] font-black text-[#41D3BD] uppercase tracking-widest bg-[#41D3BD]/10 px-3 py-1 rounded-lg">7 Hari Terakhir</span>
                    </div>
                    <div class="h-72">
                        <Bar v-if="!isLoading" :data="barChartData" :options="chartOptions" />
                    </div>
                </div>

                <!-- Grafik Pie (Komposisi Sampah Terbanyak dari DB) -->
                <div class="bg-white p-10 rounded-[3rem] border border-gray-100 shadow-sm flex flex-col items-center">
                    <h4 class="text-lg font-black text-gray-800 uppercase tracking-tighter mb-8 text-center">Komposisi Sampah</h4>
                    <div class="w-full flex-1 min-h-[250px]">
                        <Pie v-if="!isLoading" :data="pieChartData" :options="chartOptions" />
                    </div>
                </div>
            </div>

            <!-- Welcome Message -->
            <div class="bg-white p-12 rounded-[3rem] border border-gray-100 shadow-sm relative overflow-hidden">
                <div class="relative z-10 flex justify-between items-center">
                    <div>
                        <h4 class="text-2xl font-black text-gray-800 uppercase tracking-tight">Selamat Datang di Panel Kendali</h4>
                        <p class="text-gray-500 font-medium max-w-xl mt-2">Seluruh data yang ditampilkan diambil secara real-time dari server operasional dan layanan keuangan.</p>
                    </div>
                    <i class="fa-solid fa-shield-heart text-7xl text-[#41D3BD]/20"></i>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>

<style scoped>
canvas { width: 100% !important; }
</style>
