<?php

use Illuminate\Support\Facades\Route;

// Apapun alamat yang diketik di browser (dashboard, product, dll)
// Laravel akan selalu memberikan file 'app.blade.php'
Route::get('/{any}', function () {
    return view('app');
})->where('any', '.*');
