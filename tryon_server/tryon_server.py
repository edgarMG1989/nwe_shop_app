from flask import Flask, request, jsonify
from flask_cors import CORS
from PIL import Image
from gradio_client import Client, handle_file
from dotenv import load_dotenv   # <--- IMPORTANTE
import tempfile
import base64
import os
import io

# Carga variables del .env
load_dotenv()

app = Flask(__name__)
CORS(app)

print("🔥 Servidor Try-On (IDM-VTON) iniciado")

HF_TOKEN = os.getenv("HF_TOKEN")

if not HF_TOKEN:
    raise Exception("❌ No se encontró HF_TOKEN en el archivo .env")

# Pasar token por variable de entorno (forma compatible con todas las versiones)
os.environ["HF_TOKEN"] = HF_TOKEN

# Crear cliente

print("🔐 Cliente conectado con token HF")

client = Client("https://yisol-idm-vton.hf.space")

def save_temp(img, name):
    path = os.path.join(tempfile.gettempdir(), f"{name}_{os.getpid()}.png")
    img.save(path, format="PNG", quality=95)
    return path

@app.route("/tryon", methods=["POST"])
def try_on():
    try:
        if "userImage" not in request.files or "garmentImage" not in request.files:
            return jsonify({"success": False, "message": "Faltan imágenes"}), 400

        user_img = Image.open(request.files["userImage"]).convert("RGB")
        garment_img = Image.open(request.files["garmentImage"]).convert("RGB")

        garment_description = request.form.get("description")

        print("🧵 Description recibido:", garment_description)
        print("📄 Todo el form:", request.form)

        print("📸 Imágenes y descripción recibidas")

        user_path = save_temp(user_img, "user")
        garment_path = save_temp(garment_img, "cloth")

        print("🚀 Enviando al modelo IDM-VTON...")

        output, masked = client.predict(
            {
                "background": handle_file(user_path),
                "layers": [],          # <--- LISTA VACÍA, no None
                "composite": None
            },
            handle_file(garment_path),  # garm_img
            garment_description,        # garment_des
            True,                      # is_checked
            False,                     # is_checked_crop
            30,                        # denoise_steps
            42,                        # seed
            api_name="/tryon"
        )



        result_img = Image.open(output)
        buffer = io.BytesIO()
        result_img.save(buffer, format="PNG")
        encoded = base64.b64encode(buffer.getvalue()).decode()

        print("✅ Imagen generada")

        return jsonify({
            "success": True,
            "image": f"data:image/png;base64,{encoded}"
        })

    except Exception as e:
        import traceback
        traceback.print_exc()
        print("❌ ERROR:", e)
        return jsonify({"success": False, "message": str(e)}), 500



@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "model": "IDM-VTON"})


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5001))
    app.run(host="0.0.0.0", port=port)

