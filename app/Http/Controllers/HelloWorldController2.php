<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class HelloWorldController2 extends Controller
{
    public function index()
    {
        return view('hello', ['message' => 'Hello World from Controller 2!']);
    }

    public function show($id)
    {
        $data = [
            'id' => $id,
            'title' => 'Sample Title',
            'description' => 'This is a sample description for item '.$id,
        ];

        return response()->json($data);
    }

    public function create(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email',
        ]);

        // Sample processing logic
        $result = [
            'success' => true,
            'message' => 'Data processed successfully',
            'data' => $validated,
        ];

        return response()->json($result, 201);
    }
}
