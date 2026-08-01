import sys
import importlib

modules = ["core.state", "core.loop", "core.entities", "core.reward", "scripts.emit_flow"]

print("🔎 GFLO Environment Check 🔎")
print("Python path:", sys.path[0])
print("Python version:", sys.version)

for mod in modules:
    try:
        importlib.import_module(mod)
        print(f"✅ Module '{mod}' loaded successfully")
    except Exception as e:
        print(f"❌ Module '{mod}' FAILED: {e}")
