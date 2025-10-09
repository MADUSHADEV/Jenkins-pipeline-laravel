<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class HelloWorldController extends Controller
{
    public function index()
    {
        return response()->json([
            'message' => 'Hello World!',
            'timestamp' => now(),
            'status' => 'success'
        ]);
    }

    public function show($id)
    {
        $sampleData = [
            'id' => $id,
            'name' => 'Sample User ' . $id,
            'email' => 'user' . $id . '@example.com',
            'created_at' => now()->subDays(rand(1, 30))
        ];
        
        return response()->json($sampleData);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email'
        ]);
        
        return response()->json([
            'message' => 'Data received successfully',
            'data' => $data,
            'id' => rand(1000, 9999)
        ], 201);
    }
}
