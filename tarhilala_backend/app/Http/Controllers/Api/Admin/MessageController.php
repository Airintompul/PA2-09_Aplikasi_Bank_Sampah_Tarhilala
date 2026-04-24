<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\ChatRoom;
use App\Models\ChatMessage;
use Illuminate\Http\Request;

class MessageController extends Controller
{
    /**
     * Menampilkan daftar chat room (Daftar Inbox)
     */
    public function index()
    {
        // Mengambil room, nama nasabah, dan hanya pesan terakhir untuk preview
        $rooms = ChatRoom::with(['nasabah:id,nama', 'messages' => function($q) {
            $q->latest('waktu_kirim')->limit(1);
        }])->orderBy('created_at', 'desc')->get();

        return response()->json([
            'status' => 'success',
            'data' => $rooms
        ], 200);
    }

    /**
     * Menampilkan detail percakapan dalam satu room
     */
    public function show($id)
    {
        $room = ChatRoom::with(['nasabah', 'messages.pengirim:id,nama,role'])->findOrFail($id);

        // Tandai semua pesan dari nasabah sebagai 'sudah dibaca' oleh admin
        ChatMessage::where('chat_room_id', $id)
            ->where('pengirim_id', '!=', auth()->id())
            ->update(['is_read' => true]);

        return response()->json([
            'status' => 'success',
            'data' => $room
        ], 200);
    }

    /**
     * Mengubah status chat (Open/Closed)
     */
    public function updateStatus(Request $request, $id)
    {
        $room = ChatRoom::findOrFail($id);

        // Toggle status
        $room->status = ($room->status == 'open') ? 'closed' : 'open';
        $room->save();

        return response()->json([
            'status' => 'success',
            'message' => 'Status chat berhasil diubah menjadi ' . $room->status,
            'data' => $room
        ], 200);
    }

    /**
     * Mengirim pesan balasan dari Admin
     */
    public function store(Request $request, $id)
    {
        $room = ChatRoom::findOrFail($id);

        // Proteksi jika room sudah ditutup
        if ($room->status == 'closed') {
            return response()->json([
                'status' => 'error',
                'message' => 'Chat room sudah ditutup. Silakan buka kembali untuk mengirim pesan.'
            ], 403);
        }

        $request->validate([
            'pesan' => 'required|string'
        ]);

        $message = ChatMessage::create([
            'chat_room_id' => $id,
            'pengirim_id' => auth()->id(), // ID Admin dari Token
            'pesan' => $request->pesan,
            'waktu_kirim' => now()
        ]);

        // Opsional: Update timestamp updated_at di chat_room agar room naik ke atas di daftar inbox
        $room->touch();

        return response()->json([
            'status' => 'success',
            'message' => 'Pesan berhasil dikirim',
            'data' => $message
        ], 201);
    }
}
