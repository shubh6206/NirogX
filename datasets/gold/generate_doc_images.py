import os

gold_img_dir = os.path.join(os.path.dirname(__file__), "images")
os.makedirs(gold_img_dir, exist_ok=True)

# Generate dummy placeholder document images (SVG or text token)
for i in range(1, 16):
    img_path = os.path.join(gold_img_dir, f"doc_{i:02d}.png")
    if not os.path.exists(img_path):
        with open(img_path, "wb") as f:
            # 1x1 transparent PNG header
            f.write(b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15c4\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82')
print("Document image fixtures ready.")
