<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $table = 'users';

    protected $fillable = [
        'nama',
        'email',
        'nomor_telepon',
        'password',
        'role',
        'reset_token',
        'reset_token_expired_at'
    ];

    /**
     * Sembunyikan data sensitif agar TIDAK MUNCUL di JSON API
     */
    protected $hidden = [
        'password',
        'reset_token',
        'reset_token_expired_at',
    ];

    /**
     * Otomatis ubah tipe data saat ditarik dari database
     */
    protected $casts = [
        'reset_token_expired_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public $timestamps = true;

    // =====================================================
    // RELASI DATABASE (SANGAT PENTING UNTUK FULL API)
    // =====================================================

    /**
     * Relasi ke Setoran (Sebagai Nasabah)
     */
    public function setoran()
    {
        return $this->hasMany(Setoran::class, 'nasabah_id');
    }

    /**
     * Relasi ke Wallet (Sistem Keuangan)
     */
    public function wallets()
    {
        return $this->hasMany(Wallet::class, 'user_id');
    }

    /**
     * Relasi ke Chat Room (Sebagai Nasabah)
     */
    public function chatRooms()
    {
        return $this->hasMany(ChatRoom::class, 'nasabah_id');
    }

    /**
     * Relasi ke Notifikasi
     */
    public function notifikasi()
    {
        return $this->hasMany(Notifikasi::class, 'user_id');
    }

    // =====================================================
    // HELPER METHODS UNTUK API
    // =====================================================

    /**
     * Cek apakah user adalah Admin
     */
    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }

    /**
     * Cek apakah user adalah Petugas/Driver
     */
    public function isPetugas(): bool
    {
        return $this->role === 'petugas';
    }
}
