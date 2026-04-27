<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use App\Models\User;
use App\Models\ChatMessage;

class ChatRoom extends Model
{
    protected $table = 'chat_room';

    protected $fillable = [
        'nasabah_id',
        'admin_id',
        'status'
    ];

    public $timestamps = false;

    public function nasabah()
    {
        return $this->belongsTo(User::class, 'nasabah_id');
    }

    public function admin()
    {
        return $this->belongsTo(User::class, 'admin_id');
    }

    public function messages()
    {
        return $this->hasMany(ChatMessage::class, 'chat_room_id');
    }
}
