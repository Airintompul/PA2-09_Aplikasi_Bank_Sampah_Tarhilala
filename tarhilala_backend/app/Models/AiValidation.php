<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AiValidation extends Model
{
    protected $table = 'ai_validation';
    protected $fillable = ['setoran_id', 'model_id', 'image_path', 'ai_class', 'ai_confidence', 'admin_class', 'is_correct'];
    public $timestamps = false;
}
