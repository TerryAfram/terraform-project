import os
from flask import Flask, jsonify
from flask_cors import CORS

app = Flask(__name__)

# Allow requests from your custom Cloudflare domain
CORS(app, origins=["https://compliance.terryaframkumi.com"])

# 1. Add the root route here:
@app.route('/', methods=['GET'])
def home():
    return jsonify({"status": "online", "service": "Terraform Project API"})

# 2. Your existing health check or other API routes:
@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy", "message": "Render backend is live!"})

if __name__ == '__main__':
    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port)
