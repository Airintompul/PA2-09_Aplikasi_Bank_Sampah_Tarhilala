<?php

namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class ChatMessage extends Model {
    protected $table = 'chat_message';
    protected $fillable = ['chat_room_id', 'pengirim_id', 'pesan', 'is_read', 'waktu_kirim'];
    public $timestamps = false;

    public function pengirim() { return $this->belongsTo(User::class, 'pengirim_id'); }
}
