Voici le détail complet des calculs utilisés pour isoler chaque partie du visage dans le système de détection Hermona AI.

Tous ces calculs sont basés sur les proportions du visage détecté ($x, y$ pour la position, $w$ pour la largeur et $h$ pour la hauteur).

🛠️ Architecture du Zoom (backend/app/main.py)
python
def get_face_crops(image_np):
    # ... détection du visage principal ...
    x, y, w, h = face_principale
    
    crops = []
    
    # 1. FRONT (Forehead)
    # On prend le haut du visage avec une petite marge au-dessus
    y1, y2 = max(0, y - int(h * 0.1)), min(img_h, y + int(h * 0.35))
    x1, x2 = max(0, x - int(w * 0.1)), min(img_w, x + w + int(w * 0.1))
    crops.append(("Front", image_np[y1:y2, x1:x2]))
        
    # 2. JOUE DROITE (Right Cheek)
    # On cible la zone latérale droite entre les yeux et le menton
    y1, y2 = max(0, y + int(h * 0.3)), min(img_h, y + int(h * 0.8))
    x1, x2 = max(0, x - int(w * 0.1)), min(img_w, x + int(w * 0.5))
    crops.append(("Joue Droite", image_np[y1:y2, x1:x2]))
        
    # 3. JOUE GAUCHE (Left Cheek)
    # Symétrique à la joue droite
    y1, y2 = max(0, y + int(h * 0.3)), min(img_h, y + int(h * 0.8))
    x1, x2 = max(0, x + int(w * 0.5)), min(img_w, x + w + int(w * 0.1))
    crops.append(("Joue Gauche", image_np[y1:y2, x1:x2]))
        
    # 4. MENTON (Chin)
    # On cible la zone basse et centrale du visage
    y1, y2 = max(0, y + int(h * 0.7)), min(img_h, y + int(h * 1.15))
    x1, x2 = max(0, x + int(w * 0.2)), min(img_w, x + int(w * 0.8))
    crops.append(("Menton", image_np[y1:y2, x1:x2]))
        
    # 5. NEZ (Nose) - Nouveau !
    # On cible le centre exact du visage
    y1, y2 = max(0, y + int(h * 0.35)), min(img_h, y + int(h * 0.7))
    x1, x2 = max(0, x + int(w * 0.25)), min(img_w, x + int(w * 0.75))
    crops.append(("Nez", image_np[y1:y2, x1:x2]))
        
    return crops
📋 Résumé des zones :
Zone	Hauteur (Y)	Largeur (X)	Objectif
Front	0% à 35%	0% à 100%	Capturer les rides d'expression et l'acné frontale.
Joues	30% à 80%	0-50% / 50-100%	Zones les plus sensibles aux imperfections hormonales.
Menton	70% à 115%	20% à 80%	Zone critique pour l'acné adulte (mâchoire).
Nez	35% à 70%	25% à 75%	Zone T, souvent sujette aux points noirs.
Chaque "crop" est ensuite envoyé individuellement au modèle de détection YOLO pour compter précisément les lésions dans chaque partie du visage. et ca pour toute les positionnement de toutes les parties du visage (front , menton , joue gauche ,joue droite , nez et front)