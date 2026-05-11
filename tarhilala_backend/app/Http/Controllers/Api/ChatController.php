<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\ChatRoom;
use App\Models\ChatMessage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class ChatController extends Controller
{
    /**
     * Mendapatkan atau membuat chat room untuk Nasabah
     */
    public function getRoom(Request $request)
    {
        $nasabahId = Auth::id();

        // 1. Cari apakah nasabah sudah punya room yang berstatus 'open'
        $room = ChatRoom::where('nasabah_id', $nasabahId)
                        ->where('status', 'open')
                        ->first();

        if (!$room) {
            // 2. Jika belum ada, cari Admin yang tersedia
            $admin = User::where('role', 'admin')->first();

            if (!$admin) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Gagal memulai chat: Tidak ada admin yang tersedia.'
                ], 404);
            }

            // 3. Buat room baru dengan admin yang ditemukan
            $room = ChatRoom::create([
                'nasabah_id' => $nasabahId,
                'admin_id'   => $admin->id,
                'status'     => 'open'
            ]);
        }

        return response()->json([
            'status' => 'success',
            'room_id' => $room->id
        ]);
    }

    /**
     * Mendapatkan semua pesan dalam satu room
     */
    public function getMessages($id)
    {
        // Ambil pesan beserta info pengirimnya
        $messages = ChatMessage::with('pengirim:id,nama,role')
            ->where('chat_room_id', $id)
            ->orderBy('waktu_kirim', 'asc')
            ->get();

        return response()->json($messages);
    }

    /**
     * Mengirim pesan baru
     */
    public function sendMessage(Request $request)
    {
        // 1. Validasi input dari Flutter
        $request->validate([
            'chat_room_id' => 'required|exists:chat_room,id',
            'pesan' => 'required|string',
        ]);

        // 2. Simpan pesan ke database
        $message = ChatMessage::create([
            'chat_room_id' => $request->chat_room_id,
            'pengirim_id'  => Auth::id(), // ID user yang sedang login (Nasabah/Admin)
            'pesan'        => $request->pesan,
            'is_read'      => false,
            'waktu_kirim'  => now()
        ]);

        // 3. Opsional: Update timestamp updated_at di chat_room
        // Ini berguna agar admin bisa mengurutkan chat dari yang paling baru dibalas
        ChatRoom::where('id', $request->chat_room_id)->touch();

        return response()->json([
            'status' => 'success',
            'data' => $message->load('pengirim:id,nama,role')
        ], 201);
    }
}
