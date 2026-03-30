import "jsr:@supabase/functions-js/edge-runtime.d.ts"

// These headers allow Flutter to talk to the function without security blocks
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  // Handle the initial CORS preflight check from Flutter
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    console.log("1. Function triggered!");
    
    // Grab the prompt from Flutter
    const { prompt } = await req.json();
    console.log("2. User asked:", prompt);
    
    // Check for the API Key
    const apiKey = Deno.env.get('GEMINI_API_KEY');
    if (!apiKey) {
      console.error("ERROR: Gemini API Key is missing!");
      throw new Error("Missing API Key");
    }

    console.log("3. Sending question to Gemini...");
    const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }]
      }),
    });

    const data = await response.json();
    console.log("4. Gemini replied with:", JSON.stringify(data));

    // If Google threw an error (like an invalid key), catch it here
    if (data.error) {
      console.error("ERROR from Google:", data.error.message);
      throw new Error(data.error.message);
    }
    
    const reply = data.candidates[0].content.parts[0].text;
    console.log("5. Success! Sending reply back to Flutter.");

    return new Response(JSON.stringify({ reply }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
    
  } catch (error: any) {
    console.error("Function crashed:", error.message);
    return new Response(JSON.stringify({ error: error.message }), { 
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" }
    });
  }
})