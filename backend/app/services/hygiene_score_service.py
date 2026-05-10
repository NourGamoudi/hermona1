from typing import List, Dict, Any

class HygieneScoreService:
    @staticmethod
    def calculate(data: dict) -> dict:
        """
        Calculates a heuristic hygiene score based on expert rules.
        """
        if not data:
            data = {}
            
        print(f"DEBUG HYGIENE: Received data {data}")
        score = 100
        breakdown = {
            "sleep": 0,
            "stress": 0,
            "hydration": 0,
            "diet": 0,
            "care": 0
        }

        try:
            # --- 1. SOMMEIL (Base 8h) ---
            try:
                sleep_hours = float(data.get('sleep', 8))
            except:
                sleep_hours = 8.0
                
            try:
                sleep_quality = int(data.get('sleep_quality', 3))
            except:
                sleep_quality = 3

            # Impact durée (plus sévère)
            if sleep_hours < 5:
                diff = -25
            elif sleep_hours < 6:
                diff = -15
            elif sleep_hours < 7:
                diff = -10
            elif sleep_hours > 9:
                diff = -5
            else:
                diff = 0
            
            # Impact qualité
            quality_map = {1: -20, 2: -10, 3: 0, 4: 5}
            diff += quality_map.get(sleep_quality, 0)
            
            score += diff
            breakdown["sleep"] = diff

            # --- 2. STRESS (1-10) ---
            try:
                stress_level = int(data.get('stress', 5))
            except:
                stress_level = 5
                
            if stress_level > 8:
                diff = -25
            elif stress_level > 6:
                diff = -15
            elif stress_level < 3:
                diff = 5
            else:
                diff = 0
            
            score += diff
            breakdown["stress"] = diff

            # --- 3. HYDRATATION ---
            try:
                water = int(data.get('hydration', 8))
            except:
                water = 8
                
            if water < 4:
                diff = -20
            elif water < 6:
                diff = -10
            elif water >= 10:
                diff = 5
            else:
                diff = 0
                
            score += diff
            breakdown["hydration"] = diff

            # --- 4. ALIMENTATION ---
            diet_tags = data.get('diet', [])
            if not isinstance(diet_tags, list):
                diet_tags = []
                
            diet_impact = 0
            negatives = {"fast-food": -15, "sucre": -10, "laitages": -5, "alcool": -10}
            positives = {"fruits": 5, "legumes": 5, "equilibree": 10}

            for tag in diet_tags:
                if not tag: continue
                t = str(tag).lower()
                if t in negatives: diet_impact += negatives[t]
                elif t in positives: diet_impact += positives[t]

            diet_impact = max(-30, min(15, diet_impact))
            score += diet_impact
            breakdown["diet"] = diet_impact

            # --- 5. SOINS (SPF & Nettoyage) ---
            care_impact = 0
            spf = data.get('spf_used', True)
            if spf is False or str(spf).lower() == 'false': 
                care_impact -= 10
            
            cleansing = str(data.get('cleansing', '2x/jour')).lower()
            if 'rarement' in cleansing: care_impact -= 15
            elif '1x' in cleansing: care_impact -= 5

            score += care_impact
            breakdown["care"] = care_impact

        except Exception as e:
            print(f"CRITICAL ERROR IN HYGIENE CALC: {e}")
            # Safe fallback if everything fails
            pass

        # --- FINAL SCORE ---
        final_score = max(0, min(100, score))
        
        return {
            "score": int(final_score),
            "status": "Excellent" if final_score > 85 else ("Bon" if final_score > 65 else ("Moyen" if final_score > 40 else "Critique")),
            "breakdown": breakdown,
            "message": "Continuez vos efforts !" if final_score > 70 else "Des ajustements sont nécessaires."
        }
