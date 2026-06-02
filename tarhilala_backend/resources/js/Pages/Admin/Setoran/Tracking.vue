<script setup>
import AdminLayout from '@/Layouts/AdminLayout.vue';
import { ref, onMounted, onUnmounted, nextTick } from 'vue';
import { useRoute } from 'vue-router';
import api from '@/api';

const route = useRoute();
const setoranId = route.params.id;
const setoran = ref(null);
const isLoading = ref(true);

let map = null;
let driverMarker = null;
let polling = null;

// --- 1. AMBIL DATA DARI SERVER ---
const fetchDetail = async () => {
    try {
        const res = await api.get(`/setoran`);
        const data = res.data.data.find(i => i.id == setoranId);

        if (data) {
            setoran.value = data;
            isLoading.value = false;

            await nextTick();
            setTimeout(() => {
                initMap(data.lokasi_lat, data.lokasi_lng);
                if (data.jadwal?.driver_id) {
                    startTracking(data.jadwal.driver_id);
                }
            }, 100);
        }
    } catch (e) {
        console.error("Gagal load data");
        isLoading.value = false;
    }
};

// --- 2. INISIALISASI PETA ---
const initMap = (lat, lng) => {
    const container = document.getElementById('map');
    if (!container) return;

    if (map) return;

    const latitude = parseFloat(lat);
    const longitude = parseFloat(lng);

    map = L.map('map').setView([latitude, longitude], 16);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(map);

    const nasabahIcon = L.divIcon({
        html: '<i class="fa-solid fa-house-user text-red-600 text-2xl md:text-3xl"></i>',
        className: 'custom-marker',
        iconSize: [30, 30],
        iconAnchor: [15, 30]
    });

    L.marker([latitude, longitude], { icon: nasabahIcon }).addTo(map).bindPopup("Lokasi Nasabah").openPopup();
};

// --- 3. LOGIKA TRACKING DRIVER ---
const startTracking = (driverId) => {
    const updateDriver = async () => {
        try {
            const res = await api.get(`/driver-location/${driverId}`);
            if (res.data.status === 'success') {
                const { lat, lng } = res.data.data;
                const pos = [parseFloat(lat), parseFloat(lng)];

                const driverIcon = L.divIcon({
                    html: '<div class="bg-blue-600 p-2 rounded-full border-2 border-white shadow-lg"><i class="fa-solid fa-truck-pickup text-white text-[10px]"></i></div>',
                    className: 'custom-marker',
                    iconSize: [30, 30],
                    iconAnchor: [15, 15]
                });

                if (driverMarker) {
                    driverMarker.setLatLng(pos);
                } else {
                    driverMarker = L.marker(pos, { icon: driverIcon }).addTo(map).bindPopup("Lokasi Petugas");
                }

                const nasabahPos = [parseFloat(setoran.value.lokasi_lat), parseFloat(setoran.value.lokasi_lng)];
                map.fitBounds(L.latLngBounds([nasabahPos, pos]), { padding: [40, 40] });
            }
        } catch (e) { console.warn("Driver Offline"); }
    };

    updateDriver();
    polling = setInterval(updateDriver, 5000);
};

onMounted(() => fetchDetail());
onUnmounted(() => {
    clearInterval(polling);
    if(map) map.remove();
});
</script>

<template>
    <AdminLayout>
        <!-- Header Page: Responsif Teks -->
        <div class="mb-6 md:mb-8 flex items-center space-x-3 md:space-x-4 px-2 md:px-0">
            <router-link to="/setoran" class="p-2.5 md:p-3 bg-white rounded-xl md:rounded-2xl shadow-sm text-gray-400 hover:text-black transition-all">
                <i class="fa-solid fa-arrow-left text-lg md:text-xl"></i>
            </router-link>
            <h2 class="text-xl md:text-3xl font-black text-gray-800 uppercase tracking-tight leading-none">Live Tracking</h2>
        </div>

        <!-- Layout Utama: grid-cols-1 untuk Android -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 md:gap-8 px-2 md:px-0 pb-10">

            <!-- PETA AREA -->
            <div class="lg:col-span-2">
                <div class="bg-white p-3 md:p-4 rounded-[2rem] md:rounded-[3rem] shadow-sm border border-gray-100">
                    <!-- Loading Placeholder -->
                    <div v-if="isLoading" class="h-[350px] md:h-[600px] w-full bg-gray-50 animate-pulse rounded-[1.5rem] md:rounded-[2.5rem] flex items-center justify-center">
                        <p class="text-gray-400 font-black uppercase text-[10px] italic">Memuat Peta...</p>
                    </div>

                    <!-- Wadah Map: Tinggi h-[350px] di HP agar pas di layar -->
                    <div v-show="!isLoading" id="map" class="h-[350px] md:h-[600px] w-full rounded-[1.5rem] md:rounded-[2.5rem] z-0 border border-gray-50 shadow-inner"></div>
                </div>
            </div>

            <!-- INFO AREA -->
            <div v-if="setoran" class="space-y-6">
                <div class="bg-white p-6 md:p-10 rounded-[2rem] md:rounded-[3rem] shadow-sm border border-gray-100">
                    <h3 class="text-[#41D3BD] font-black uppercase text-xs md:text-sm mb-6 border-b border-gray-50 pb-4">Detail Penjemputan</h3>

                    <div class="space-y-5 md:space-y-6 text-black font-medium">
                        <div class="flex flex-col">
                            <p class="text-[9px] md:text-[10px] font-black text-gray-300 uppercase tracking-widest">Nasabah</p>
                            <p class="text-base md:text-xl font-black uppercase text-gray-800 truncate">{{ setoran.nasabah.nama }}</p>
                        </div>

                        <div class="flex flex-col">
                            <p class="text-[9px] md:text-[10px] font-black text-gray-300 uppercase tracking-widest">Driver Terpilih</p>
                            <p class="text-base md:text-xl font-black uppercase text-blue-600 truncate">{{ setoran.jadwal?.driver?.nama || 'BELUM ADA' }}</p>
                        </div>

                        <div class="pt-4 border-t border-gray-50">
                            <p class="text-[9px] md:text-[10px] font-black text-gray-300 uppercase tracking-widest mb-2">Status Saat Ini</p>
                            <span class="px-3 py-1.5 bg-blue-50 text-blue-600 rounded-xl text-[9px] md:text-[10px] font-black uppercase tracking-widest border border-blue-100 shadow-sm inline-block">
                                {{ setoran.status.replace('_', ' ') }}
                            </span>
                        </div>
                    </div>
                </div>

                <!-- Petunjuk Tambahan Mobile -->
                <div class="lg:hidden bg-teal-50 p-5 rounded-[2rem] border border-teal-100 flex items-center space-x-4">
                    <div class="w-10 h-10 bg-white rounded-full flex items-center justify-center text-[#41D3BD] shadow-sm shrink-0">
                        <i class="fa-solid fa-circle-info"></i>
                    </div>
                    <p class="text-[10px] font-bold text-teal-700 leading-tight">Gunakan dua jari untuk memperbesar atau menggeser peta di layar HP.</p>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>

<style scoped>
/* Pastikan marker tidak tertutup oleh elemen UI peta bawaan */
.custom-marker {
    display: flex;
    align-items: center;
    justify-content: center;
}
</style>
