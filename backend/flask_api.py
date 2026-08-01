"""
GFLO Flask API (moved from gflo-backend)
"""

from flask import Flask, jsonify

app = Flask(__name__)

@app.route("/health")
def health():
    return jsonify({"status": "ok"})

# TODO: flesh out API endpoints from original gflo-backend
