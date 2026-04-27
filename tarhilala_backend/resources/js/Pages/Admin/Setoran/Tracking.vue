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
            isLoading.value = false; // Matikan loading agar HTML muncul

            // --- RAHASIA: Tunggu Vue selesai merender HTML baru panggil Map ---
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

// --- 2. INISIALISASI PETA (Setelah wadah map muncul) ---
const initMap = (lat, lng) => {
    const container = document.getElementById('map');
    if (!container) return; // Proteksi agar tidak error lagi jika wadah hilang

    if (map) return;

    const latitude = parseFloat(lat);
    const longitude = parseFloat(lng);

    map = L.map('map').setView([latitude, longitude], 16);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(map);

    const nasabahIcon = L.divIcon({
        html: '<i class="fa-solid fa-house-user text-red-600 text-3xl"></i>',
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
                    html: '<div class="bg-blue-600 p-2 rounded-full border-2 border-white shadow-lg"><i class="fa-solid fa-truck-pickup text-white text-xs"></i></div>',
                    className: 'custom-marker',
                    iconSize: [35, 35],
                    iconAnchor: [17, 17]
                });

                if (driverMarker) {
                    driverMarker.setLatLng(pos);
                } else {
                    driverMarker = L.marker(pos, { icon: driverIcon }).addTo(map).bindPopup("Lokasi Petugas");
                }

                const nasabahPos = [parseFloat(setoran.value.lokasi_lat), parseFloat(setoran.value.lokasi_lng)];
                map.fitBounds(L.latLngBounds([nasabahPos, pos]), { padding: [50, 50] });
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
        <!-- Header -->
        <div class="mb-8 flex items-center space-x-4">
            <router-link to="/setoran" class="p-3 bg-white rounded-2xl shadow-sm text-gray-400 hover:text-black">
                <i class="fa-solid fa-arrow-left"></i>
            </router-link>
            <h2 class="text-3xl font-black text-gray-800 uppercase tracking-tight">Live Tracking</h2>
        </div>

        <!-- Layout Utama -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <!-- PETA AREA -->
            <div class="lg:col-span-2">
                <div class="bg-white p-4 rounded-[3rem] shadow-sm border border-gray-100">
                    <!-- Loading Placeholder saat data diambil -->
                    <div v-if="isLoading" class="h-[600px] w-full bg-gray-50 animate-pulse rounded-[2.5rem] flex items-center justify-center">
                        <p class="text-gray-400 font-bold uppercase italic">Memuat Peta...</p>
                    </div>

                    <!-- PENTING: Wadah Map sesungguhnya -->
                    <div v-show="!isLoading" id="map" style="height: 600px; width: 100%;" class="rounded-[2.5rem] z-0"></div>
                </div>
            </div>

            <!-- INFO AREA -->
            <div v-if="setoran" class="space-y-6">
                <div class="bg-white p-10 rounded-[3rem] shadow-sm border border-gray-100">
                    <h3 class="text-[#41D3BD] font-black uppercase text-sm mb-6">Detail Penjemputan</h3>
                    <div class="space-y-6 text-black font-medium">
                        <div>
                            <p class="text-[10px] font-black text-gray-300 uppercase">Nasabah</p>
                            <p class="text-xl font-black uppercase text-gray-800">{{ setoran.nasabah.nama }}</p>
                        </div>
                        <div>
                            <p class="text-[10px] font-black text-gray-300 uppercase">Driver</p>
                            <p class="text-xl font-black uppercase text-blue-600">{{ setoran.jadwal?.driver?.nama || 'BELUM ADA' }}</p>
                        </div>
                        <div>
                            <p class="text-[10px] font-black text-gray-300 uppercase">Status</p>
                            <span class="px-4 py-1 bg-blue-50 text-blue-600 rounded-lg text-[10px] font-black uppercase inline-block mt-2">
                                {{ setoran.status }}
                            </span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>
