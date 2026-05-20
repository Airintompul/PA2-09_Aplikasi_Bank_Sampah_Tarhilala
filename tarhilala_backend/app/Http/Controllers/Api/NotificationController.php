<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notifikasi;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index()
    {
        $data = Notifikasi::where('user_id', auth()->id())
                ->orderBy('created_at', 'desc')
                ->get();

        return response()->json(['status' => 'success', 'data' => $data]);
    }

    public function markAsRead($id)
    {
        Notifikasi::where('id', $id)->where('user_id', auth()->id())
            ->update(['is_read' => true]);

        return response()->json(['message' => 'Notifikasi dibaca']);
    }

    public function unreadCount()
    {
        // Hitung berapa notif yang is_read-nya masih false
        $count = Notifikasi::where('user_id', auth()->id())
                    ->where('is_read', false)
                    ->count();

        return response()->json(['unread' => $count]);
    }
}
