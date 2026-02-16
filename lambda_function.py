import json
import boto3
import base64

# -------------------------------
# AWS Clients
# -------------------------------
bedrock = boto3.client("bedrock-runtime", region_name="us-west-2")


# -------------------------------
# Extract dishes using Vision
# -------------------------------
def extract_dishes_from_image(image_bytes):
    """
    Uses Claude's vision to directly extract dishes from menu image
    """
    image_b64 = base64.b64encode(image_bytes).decode('utf-8')
    
    prompt = """Analyze this restaurant menu image and extract all actual food and drink items that customers can order.

INCLUDE:
- Specific dishes (e.g., "Breakfast Sandwich", "Caesar Salad", "Margherita Pizza")
- Beverages (e.g., "Coffee", "Orange Juice", "Coca-Cola")
- Appetizers, entrees, desserts, sides

EXCLUDE:
- Section headers (e.g., "BREAKFAST", "LUNCH", "APPETIZERS")
- Marketing slogans (e.g., "GETS YOU RUNNING")
- Combo deal names (e.g., "COFFEE COMBOS")
- Prices and price modifiers
- Descriptions or ingredients lists

Return ONLY valid JSON with no other text:
{"dishes": ["Item 1", "Item 2", "Item 3"]}"""

    body = json.dumps({
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 2000,
        "temperature": 0,
        "messages": [{
            "role": "user",
            "content": [
                {
                    "type": "image",
                    "source": {
                        "type": "base64",
                        "media_type": "image/jpeg",
                        "data": image_b64
                    }
                },
                {
                    "type": "text",
                    "text": prompt
                }
            ]
        }]
    })

    try:
        response = bedrock.invoke_model(
            modelId="anthropic.claude-3-5-sonnet-20241022-v2:0",  # CHANGED: Use Sonnet for vision
            body=body,
            contentType="application/json",
            accept="application/json"
        )

        result = json.loads(response["body"].read())
        text_output = result["content"][0]["text"]
        
        print(f"Dishes extraction response: {text_output}")

        # Parse JSON response
        text_output = text_output.strip()
        
        if "```json" in text_output:
            text_output = text_output.split("```json")[1].split("```")[0]
        elif "```" in text_output:
            text_output = text_output.split("```")[1].split("```")[0]
        
        text_output = text_output.strip()
        
        parsed = json.loads(text_output)
        return parsed.get("dishes", [])
        
    except Exception as e:
        print(f"Error extracting dishes: {str(e)}")
        import traceback
        traceback.print_exc()
        return []

# -------------------------------
# AI → Ingredients + Allergen Safety (Combined)
# -------------------------------
def get_ingredients_and_safety(dish_name, allergens_to_avoid):
    """
    Single AI call that returns:
    - Ingredients
    - Safety classification
    """

    prompt = f"""
You are a food allergen safety assistant.

User wants to avoid:
{allergens_to_avoid}

For the dish: "{dish_name}"

Return:

1) Main ingredients
2) Safety classification:
   - SAFE
   - UNSAFE
   - MODIFIABLE

Return ONLY JSON:

{{
  "dish": "{dish_name}",
  "ingredients": ["ingredient1","ingredient2"],
  "safety": {{
      "status": "SAFE | UNSAFE | MODIFIABLE",
      "reason": "if unsafe",
      "suggestion": "if modifiable"
  }}
}}
"""

    body = json.dumps({
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 600,
        "temperature": 0,
        "messages": [{
            "role": "user",
            "content": [{"type": "text", "text": prompt}]
        }]
    })

    try:
        response = bedrock.invoke_model(
            modelId="anthropic.claude-3-haiku-20240307-v1:0",
            body=body,
            contentType="application/json",
            accept="application/json"
        )

        result = json.loads(response["body"].read())
        text_output = result["content"][0]["text"].strip()

        # Remove markdown if present
        if "```json" in text_output:
            text_output = text_output.split("```json")[1].split("```")[0]
        elif "```" in text_output:
            text_output = text_output.split("```")[1].split("```")[0]

        return json.loads(text_output)

    except Exception as e:
        print(f"Error analyzing {dish_name}: {str(e)}")
        return {
            "dish": dish_name,
            "ingredients": [],
            "safety": {
                "status": "UNKNOWN"
            }
        }


# -------------------------------
# Lambda Handler
# -------------------------------
def lambda_handler(event, context):
    """
    Main Lambda handler
    """
    try:
        # Parse API Gateway body
        if "body" in event:
            body = json.loads(event["body"])
        else:
            body = event

        # Validate input
        if "image_base64" not in body:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "Missing image_base64 in request body"})
            }

        # Decode image
        try:
            image_bytes = base64.b64decode(body["image_base64"])
        except Exception as e:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": f"Invalid base64 image: {str(e)}"})
            }

        # -------------------------------
        # Allergens from POST body
        # -------------------------------
        try:
            allergens_to_avoid = body.get("allergens_to_avoid", [])

            if not isinstance(allergens_to_avoid, list):
                raise ValueError("allergens_to_avoid must be a list")

            allergens_to_avoid = [
                a.lower().strip()
                for a in allergens_to_avoid
            ]
            print("Allergens received:", allergens_to_avoid)


        except Exception as e:
            return {
                "statusCode": 400,
                "body": json.dumps({
                    "error": "Invalid allergens_to_avoid format",
                    "details": str(e)
                })
            }

        print(f"Processing image of size: {len(image_bytes)} bytes")

        # -------------------------------
        # Extract dishes using vision
        # -------------------------------
        dishes = extract_dishes_from_image(image_bytes)
        
        print(f"Extracted {len(dishes)} dishes: {dishes}")

        if not dishes:
            return {
                "statusCode": 200,
                "body": json.dumps({
                    "message": "No dishes detected in the menu image",
                    "dishes_detected": [],
                    "ingredients": []
                })
            }

        # -------------------------------
        # Get ingredients for each dish
        # -------------------------------
        '''ingredients_results = []

        for dish in dishes:
            ingredients_data = get_ingredients_json(dish)
            ingredients_results.append(ingredients_data)'''
        
        ingredients_results = []

        for dish in dishes:
            data = get_ingredients_and_safety(
                dish,
                allergens_to_avoid
            )
            ingredients_results.append(data)

        # -------------------------------
        # Build Safety Summary (No AI call)
        # -------------------------------
        safety_results = {
            "safe": [],
            "unsafe": [],
            "modifiable": []
        }

        for item in ingredients_results:

            status = item.get("safety", {}).get("status", "UNKNOWN")

            if status == "SAFE":
                safety_results["safe"].append({
                    "dish": item["dish"]
                })

            elif status == "UNSAFE":
                safety_results["unsafe"].append({
                    "dish": item["dish"],
                    "reason": item["safety"].get("reason", "")
                })

            elif status == "MODIFIABLE":
                safety_results["modifiable"].append({
                    "dish": item["dish"],
                    "suggestion": item["safety"].get("suggestion", "")
                })

        '''# -------------------------------
        # AI Safety Analysis
        # -------------------------------
        safety_results = analyze_allergen_safety(
        ingredients_results,
        allergens_to_avoid
        )'''

        

        # -------------------------------
        # Final Response
        # -------------------------------
        response_data = {
            "dishes_count": len(dishes),
            "dishes_detected": dishes,
            "ingredients": ingredients_results,
            "allergens_to_avoid": allergens_to_avoid,
            "safety_analysis": safety_results
        }

        return {
            "statusCode": 200,
            "body": json.dumps(response_data, indent=2)
        }

    except Exception as e:
        print(f"Lambda error: {str(e)}")
        import traceback
        traceback.print_exc()
        
        return {
            "statusCode": 500,
            "body": json.dumps({
                "error": "Internal server error",
                "details": str(e)
            })
        }