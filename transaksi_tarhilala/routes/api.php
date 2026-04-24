<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\InternalFinanceController;
use App\Http\Controllers\Api\Admin\AdminWithdrawalController;

/*
|--------------------------------------------------------------------------
| Finance Service API Routes
|--------------------------------------------------------------------------
*/

// Pastikan urutan prefix-nya benar: api/admin/penarikan
Route::prefix('admin')->group(function () {
    Route::get('/penarikan', [AdminWithdrawalController::class, 'index']);
    Route::put('/penarikan/{id}', [AdminWithdrawalController::class, 'update']);
});

// Endpoint untuk dipanggil Main App (Port 8000)
Route::post('/internal/add-balance', [InternalFinanceController::class, 'addBalance']);
Route::post('/internal/deduct-points', [InternalFinanceController::class, 'deductPoints']);
