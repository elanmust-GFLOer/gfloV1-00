#!/usr/bin/env python3
from typer import Typer
from scripts.emit_flow import Node, Flow
from core.loop import process_flow
from core.reward import reward_loop

app = Typer()

@app.command()
def emit(cost: int = 1, ethical: bool = True):
    test_address = "0x742d35Cc6634C0532925a3b844Bc454e4438f44e"
    flow = Flow(node_id=test_address)
    flow.cost = cost
    trace, state = process_flow(flow)
    regen_gain, state = reward_loop(cost, ethical)
    print("🌬️ FLOW EMITTED")
    print(f"ADDRESS: {test_address}")
    print("TRACE:", trace.hash)
    print("STATE:", state)
    print("REGEN GAIN:", regen_gain)

if __name__ == "__main__":
    app()
