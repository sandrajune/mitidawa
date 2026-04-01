import "jsr:@supabase/functions-js/edge-runtime.d.ts"

// These headers allow Flutter to talk to the function without security blocks
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const refusalMessage = "I am the MitiDawa assistant. I can only help you with questions about medicinal plants and natural remedies."

const systemPolicy = `You are the official ethnobotanical knowledge expert and assistant for the MitiDawa app.

STRICT SCOPE:
- You may ONLY provide information related to plants, medicinal plants, botany, herbalism, and natural remedies.
- Do NOT answer any question outside plant and natural-remedy scope.
- If the user asks anything outside this scope (politics, coding, math, general trivia, non-remedy topics, etc.), you must refuse.

REFUSAL FORMAT:
- Use this exact refusal sentence and nothing else:
"${refusalMessage}"

SAFETY:
- For remedy-related guidance, include a brief disclaimer to consult a certified medical professional for serious conditions.
`

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

    const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        system_instruction: { 
          parts: [{ text: systemPolicy }],
        },
        contents: [{
          parts: [{
            text: `User prompt: ${prompt}`,
          }],
        }],
      }),
    });

    const data = await response.json();
    console.log("4. Gemini replied with:", JSON.stringify(data));

    // If Google threw an error (like an invalid key), catch it here
    if (data.error) {
      console.error("ERROR from Google:", data.error.message);
      throw new Error(data.error.message);
    }
    
    const rawReply = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
    const trimmedReply = rawReply.trim();
    const reply = trimmedReply.length === 0 ? refusalMessage : trimmedReply;

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