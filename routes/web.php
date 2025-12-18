<?php

use Illuminate\Support\Facades\Route;
use Inertia\Inertia;

Route::get('/', function () {
    return Inertia::render('welcome');
})->name('home');

Route::middleware(['auth', 'verified'])->group(function () {
    Route::get('dashboard', function () {
        return Inertia::render('dashboard');
    })->name('dashboard');

    Route::get('webhook-test', function () {
        return Inertia::render('webhook-test');
    })->name('webhook-test');
});

require __DIR__.'/settings.php';
require __DIR__.'/auth.php';
