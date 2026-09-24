import os, json, ast
from openai import OpenAI

client = OpenAI(
    base_url="https://api.groq.com/openai/v1",
    api_key=os.getenv("GROQ_API_KEY"),
)

# ---------- Tools ----------
def get_weather(city: str) -> str:
    data = {"Tokyo": "24°C, sunny", "Paris": "18°C, cloudy", "NYC": "12°C, rainy"}
    return data.get(city, f"No data for {city}")

def calculator(expression: str) -> str:
    try:
        node = ast.parse(expression, mode="eval")
        return str(eval(compile(node, "<calc>", "eval"), {"__builtins__": {}}, {}))
    except Exception as e:
        return f"Error: {e}"

TOOLS = {"get_weather": get_weather, "calculator": calculator}

TOOLS_SCHEMA = [
    {"type": "function", "function": {
        "name": "get_weather",
        "description": "Get the current weather for a city",
        "parameters": {"type": "object",
                       "properties": {"city": {"type": "string"}},
                       "required": ["city"]}}},
    {"type": "function", "function": {
        "name": "calculator",
        "description": "Evaluate a math expression like '24 * 3'",
        "parameters": {"type": "object",
                       "properties": {"expression": {"type": "string"}},
                       "required": ["expression"]}}},
]

MODEL = "openai/gpt-oss-120b"
SYSTEM = "You are a helpful agent. Use tools when needed, then answer directly."

# ---------- Agent loop ----------
def run_agent(user_input, max_steps=6, verbose=True):
    messages = [
        {"role": "system", "content": SYSTEM},
        {"role": "user", "content": user_input},
    ]

    for _ in range(max_steps):
        response = client.chat.completions.create(
            model=MODEL, messages=messages,
            tools=TOOLS_SCHEMA, tool_choice="auto",
        )
        msg = response.choices[0].message
        messages.append(msg)

        if not msg.tool_calls:
            return msg.content

        for call in msg.tool_calls:
            name = call.function.name
            args = json.loads(call.function.arguments)
            if verbose:
                print(f"  🔧 {name}({args})")
            try:
                result = TOOLS[name](**args)
            except Exception as e:
                result = f"Tool error: {e}"
            messages.append({
                "role": "tool",
                "tool_call_id": call.id,
                "content": str(result),
            })

    return "Max steps reached."

# ---------- CLI ----------
if __name__ == "__main__":
    print("Agent ready. Type 'quit' to exit.\n")
    while True:
        q = input("You: ").strip()
        if q.lower() in {"quit", "exit"}:
            break
        if not q:
            continue
        print("Agent:", run_agent(q), "\n")