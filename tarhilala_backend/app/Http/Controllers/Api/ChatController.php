<?php

namespace App\Http\Controllers\Api;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\ChatRoom;
use App\Models\ChatMessage;
use App\Http\Controllers\Controller;

class ChatController extends Controller
{
    public function getRoom()
    {
        $user = Auth::user();

        $room = ChatRoom::firstOrCreate([
            'nasabah_id' => $user->id,
        ], [
            'admin_id' => 1,
            'status' => 'open'
        ]);

        return response()->json($room);
    }

    public function getMessages($id)
    {
        $messages = ChatMessage::with('pengirim')
            ->where('chat_room_id', $id)
            ->orderBy('waktu_kirim', 'asc')
            ->get();

        return response()->json($messages);
    }

    public function sendMessage(Request $request)
    {
        $user = Auth::user();

        $message = ChatMessage::create([
            'chat_room_id' => $request->chat_room_id,
            'pengirim_id' => $user->id,
            'pesan' => $request->pesan,
            'is_read' => false,
            'waktu_kirim' => now()
        ]);

        return response()->json($message);
    }
}
