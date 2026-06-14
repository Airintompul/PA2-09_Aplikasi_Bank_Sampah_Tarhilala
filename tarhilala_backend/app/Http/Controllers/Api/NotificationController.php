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

        // Sesuaikan response agar pas dengan Frontend Vue
        return response()->json([
            'status' => 'success',
            'data' => [
                'notifications' => $data,
                'unread_count' => $data->where('is_read', false)->count()
            ]
        ]);
    }

    public function markAsRead($id)
    {
        Notifikasi::where('id', $id)
            ->where('user_id', auth()->id())
            ->update(['is_read' => true]);

        return response()->json(['status' => 'success', 'message' => 'Notifikasi dibaca']);
    }

    /**
     * Menandai semua notifikasi milik user ini sebagai 'sudah dibaca'
     */
    public function markAllRead()
    {
        Notifikasi::where('user_id', auth()->id())
            ->where('is_read', false)
            ->update(['is_read' => true]);

        return response()->json([
            'status' => 'success',
            'message' => 'Semua notifikasi telah ditandai dibaca'
        ]);
    }

    public function unreadCount()
    {
        $count = Notifikasi::where('user_id', auth()->id())
                    ->where('is_read', false)
                    ->count();

        return response()->json(['unread' => $count]);
    }
}
