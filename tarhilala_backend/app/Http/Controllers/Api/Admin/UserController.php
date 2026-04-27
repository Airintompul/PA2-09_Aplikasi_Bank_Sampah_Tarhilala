<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;

class UserController extends Controller
{
    public function employeeIndex() {
        // Data petugas
        return view('admin.employee.index');
    }

    public function customerIndex() {
        // Data nasabah
        return view('admin.customers.index');
    }
}
