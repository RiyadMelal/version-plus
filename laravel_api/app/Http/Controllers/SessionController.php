<?php

namespace App\Http\Controllers;

use App\Models\Session;
use Illuminate\Http\Request;

class SessionController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index($groupId)
    {
        return Session::where('group_id', $groupId)->get();
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request,$groupId)
    {
        $validated = $request->validate([
            's_date' => 'required|date',
            'end_date' => 'required|date',
            'comment' => 'required|string',
            'group_id' => 'required|exists:groups,id'
        ]);

        $session = new Session($validated);
        $session->group_id = $groupId;
        $session->save();

        return response()->json($session, 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(Session $session)
    {
        //
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(Session $session)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request,$groupId,$id)
    {
        $session = Session::where('group_id', $groupId)->findOrFail($id);

        $session->update($request->only('s_date', 'end_date','comment'));

        return response()->json($session);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy($id)
    {
        $session = Session::where('id', $id)->findOrFail($id);
        $session->delete();

        return response()->json(null, 204);
    }
    function allSessions()
    {
        $sessions = Session::all();
        return response()->json(['data' => $sessions]);
    }

}
