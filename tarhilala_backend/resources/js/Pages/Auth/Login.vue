<template>
  <div class="min-h-screen flex items-center justify-center bg-[#F3F4F6] relative overflow-hidden px-4">

    <!-- Elemen Dekoratif Modern (Blur Background) -->
    <div class="absolute -top-24 -left-24 w-96 h-96 bg-[#41D3BD]/20 rounded-full blur-3xl"></div>
    <div class="absolute -bottom-24 -right-24 w-96 h-96 bg-blue-400/10 rounded-full blur-3xl"></div>

    <div class="max-w-md w-full relative z-10">
      <!-- Login Card -->
      <div class="bg-white rounded-[3rem] shadow-[0_20px_50px_rgba(0,0,0,0.04)] border border-white p-10 md:p-14 transition-all">

        <!-- Logo & Title -->
        <div class="text-center mb-10">
          <div class="inline-block p-4 rounded-3xl bg-[#f9fafb] mb-6 shadow-sm">
             <img src="/assets/img/Logo1.png" class="w-32 h-auto object-contain" alt="Logo">
          </div>
          <h2 class="text-3xl font-black text-gray-800 uppercase tracking-tight">Admin Login</h2>
          <p class="text-gray-400 text-[10px] font-black uppercase tracking-[0.3em] mt-2 italic">Management System v1.0</p>
        </div>

        <!-- Login Form -->
        <form @submit.prevent="handleLogin" class="space-y-6">

          <!-- Email Field -->
          <div class="space-y-2">
            <label class="text-[11px] font-black text-gray-400 uppercase ml-4 tracking-widest">Email Address</label>
            <div class="relative group">
                <span class="absolute inset-y-0 left-0 flex items-center pl-5 text-gray-400 group-focus-within:text-[#41D3BD] transition-colors">
                    <i class="fa-solid fa-envelope"></i>
                </span>
                <input
                    v-model="form.email"
                    type="email"
                    required
                    class="w-full pl-12 pr-6 py-4 bg-[#F9FAFB] border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-bold text-gray-700 placeholder-gray-300 transition-all shadow-inner"
                    placeholder="admin@tarhilala.com"
                >
            </div>
          </div>

          <!-- Password Field -->
          <div class="space-y-2">
            <label class="text-[11px] font-black text-gray-400 uppercase ml-4 tracking-widest">Security Password</label>
            <div class="relative group">
                <span class="absolute inset-y-0 left-0 flex items-center pl-5 text-gray-400 group-focus-within:text-[#41D3BD] transition-colors">
                    <i class="fa-solid fa-lock"></i>
                </span>
                <input
                    v-model="form.password"
                    type="password"
                    required
                    class="w-full pl-12 pr-6 py-4 bg-[#F9FAFB] border-none rounded-2xl focus:ring-2 focus:ring-[#41D3BD] outline-none font-bold text-gray-700 placeholder-gray-300 transition-all shadow-inner"
                    placeholder="••••••••"
                >
            </div>
          </div>

          <!-- Error Alert -->
          <Transition name="fade">
            <div v-if="errorMessage" class="bg-red-50 text-red-600 p-4 rounded-2xl text-xs font-black italic border border-red-100 flex items-center shadow-sm">
                <i class="fa-solid fa-triangle-exclamation mr-3 text-sm"></i>
                {{ errorMessage }}
            </div>
          </Transition>

          <!-- Submit Button -->
          <button
            type="submit"
            :disabled="isLoading"
            class="w-full bg-[#41D3BD] hover:bg-[#38bda9] text-black font-black py-5 rounded-[2rem] shadow-xl shadow-[#41D3BD]/30 transition-all uppercase tracking-[0.2em] mt-4 flex justify-center items-center active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <span v-if="!isLoading" class="flex items-center">
                Masuk Sekarang <i class="fa-solid fa-arrow-right-to-bracket ml-3"></i>
            </span>
            <div v-else class="w-6 h-6 border-4 border-black/20 border-t-black rounded-full animate-spin"></div>
          </button>
        </form>

        <div class="mt-12 text-center border-t border-gray-50 pt-8">
            <p class="text-[10px] font-black text-gray-300 uppercase tracking-widest leading-relaxed">
                Bank Sampah Tarhilala <br> &copy; 2024 All Rights Reserved
            </p>
        </div>

      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import axios from 'axios';

const router = useRouter();
const isLoading = ref(false);
const errorMessage = ref('');

const form = ref({
    email: '',
    password: ''
});

const handleLogin = async () => {
    isLoading.value = true;
    errorMessage.value = '';

    try {
        // Melakukan request ke API Admin Login
        const response = await axios.post('/api/admin/login', form.value);

        // Sesuai dengan hasil Thunder Client Anda:
        // response.data.data.token adalah letak kuncinya
        const token = response.data.data.token;
        const user = response.data.data.user;

        // Simpan Data ke LocalStorage
        localStorage.setItem('admin_token', token);
        localStorage.setItem('admin_user', JSON.stringify(user));

        // Pindah Halaman ke Dashboard menggunakan window.location
        // agar state aplikasi (termasuk axios headers) benar-benar ter-reset
        window.location.href = '/dashboard';

    } catch (error) {
        console.error("Login Error:", error);
        if (error.response) {
            errorMessage.value = error.response.data.message || 'Kombinasi Email & Password Salah';
        } else {
            errorMessage.value = 'Gagal terhubung ke server. Cek koneksi Anda.';
        }
    } finally {
        isLoading.value = false;
    }
};
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');

.fade-enter-active, .fade-leave-active { transition: opacity 0.4s ease; }
.fade-enter-from, .fade-leave-to { opacity: 0; }

input::placeholder {
    font-weight: 600;
    opacity: 0.5;
}
</style>
