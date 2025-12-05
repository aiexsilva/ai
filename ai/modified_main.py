import functions_framework
from flask import jsonify
import osmnx as ox
import heapq
import requests

print("Loading NLP model...")
model = SentenceTransformer('all-MiniLM-L6-v2')
print("NLP model loaded.")

CATEGORIES = ["car_dealer","car_rental","car_repair","car_wash","electric_vehicle_charging_station","gas_station","parking","rest_stop","corporate_office","farm","ranch","art_gallery","art_studio","auditorium","cultural_landmark","historical_place","monument","museum","performing_arts_theater","sculpture","library","preschool","primary_school","school","secondary_school","university","adventure_sports_center","amphitheatre","amusement_center","amusement_park","aquarium","banquet_hall","barbecue_area","botanical_garden","bowling_alley","casino","childrens_camp","comedy_club","community_center","concert_hall","convention_center","cultural_center","cycling_park","dance_hall","dog_park","event_venue","ferris_wheel","garden","hiking_area","historical_landmark","internet_cafe","karaoke","marina","movie_rental","movie_theater","national_park","night_club","observation_deck","off_roading_area","opera_house","park","philharmonic_hall","picnic_ground","planetarium","plaza","roller_coaster","skateboard_park","state_park","tourist_attraction","video_arcade","visitor_center","water_park","wedding_venue","wildlife_park","wildlife_refuge","zoo","public_bath","public_bathroom","stable","accounting","atm","bank","acai_shop","afghani_restaurant","african_restaurant","american_restaurant","asian_restaurant","bagel_shop","bakery","bar","bar_and_grill","barbecue_restaurant","brazilian_restaurant","breakfast_restaurant","brunch_restaurant","buffet_restaurant","cafe","cafeteria","candy_store","cat_cafe","chinese_restaurant","chocolate_factory","chocolate_shop","coffee_shop","confectionery","deli","dessert_restaurant","dessert_shop","diner","dog_cafe","donut_shop","fast_food_restaurant","fine_dining_restaurant","food_court","french_restaurant","greek_restaurant","hamburger_restaurant","ice_cream_shop","indian_restaurant","indonesian_restaurant","italian_restaurant","japanese_restaurant","juice_shop","korean_restaurant","lebanese_restaurant","meal_delivery","meal_takeaway","mediterranean_restaurant","mexican_restaurant","middle_eastern_restaurant","pizza_restaurant","pub","ramen_restaurant","restaurant","sandwich_shop","seafood_restaurant","spanish_restaurant","steak_house","sushi_restaurant","tea_house","thai_restaurant","turkish_restaurant","vegan_restaurant","vegetarian_restaurant","vietnamese_restaurant","wine_bar","administrative_area_level_1","administrative_area_level_2","country","locality","postal_code","school_district","city_hall","courthouse","embassy","fire_station","government_office","local_government_office","neighborhood_police_station","police","post_office","chiropractor","dental_clinic","dentist","doctor","drugstore","hospital","massage","medical_lab","pharmacy","physiotherapist","sauna","skin_care_clinic","spa","tanning_studio","wellness_center","yoga_studio","apartment_building","apartment_complex","condominium_complex","housing_complex","bed_and_breakfast","budget_japanese_inn","campground","camping_cabin","cottage","extended_stay_hotel","farmstay","guest_house","hostel","hotel","inn","japanese_inn","lodging","mobile_home_park","motel","private_guest_room","resort_hotel","rv_park","beach","church","hindu_temple","mosque","synagogue","astrologer","barber_shop","beautician","beauty_salon","body_art_service","catering_service","cemetery","child_care_agency","consultant","courier_service","electrician","florist","food_delivery","foot_care","funeral_home","hair_care","hair_salon","insurance_agency","laundry","lawyer","locksmith","makeup_artist","moving_company","nail_salon","painter","plumber","psychic","real_estate_agency","roofing_contractor","storage","summer_camp_organizer","tailor","telecommunications_service_provider","tour_agency","tourist_information_center","travel_agency","veterinary_care","asian_grocery_store","auto_parts_store","bicycle_store","book_store","butcher_shop","cell_phone_store","clothing_store","convenience_store","department_store","discount_store","electronics_store","food_store","furniture_store","gift_shop","grocery_store","hardware_store","home_goods_store","home_improvement_store","jewelry_store","liquor_store","market","pet_store","shoe_store","shopping_mall","sporting_goods_store","store","supermarket","warehouse_store","wholesaler","arena","athletic_field","fishing_charter","fishing_pond","fitness_center","golf_course","gym","ice_skating_rink","playground","ski_resort","sports_activity_location","sports_club","sports_coaching","sports_complex","stadium","swimming_pool","airport","airstrip","bus_station","bus_stop","ferry_terminal","heliport","international_airport","light_rail_station"]
CATEGORY_EMBEDDINGS = model.encode(CATEGORIES, convert_to_tensor=True)

def log(msg):
    print(f"[RouteFinder] {msg}")


def dijkstra(graph, start_node, end_node):
    previous = {v: None for v in graph.keys()}
    distances = {v: float('inf') for v in graph.keys()}
    distances[start_node] = 0
    queue = [(0, start_node)]

    while queue:
        current_distance, current_node = heapq.heappop(queue)
        
        if current_node == end_node:
            break
        
        if current_distance > distances[current_node]:
            continue
            
        if current_node in graph:
            for neighbor, weight in graph[current_node]:
                distance = current_distance + weight
                if distance < distances[neighbor]:
                    distances[neighbor] = distance
                    previous[neighbor] = current_node
                    heapq.heappush(queue, (distance, neighbor))

    path = []
    current_node = end_node
    
    if distances[end_node] == float('inf'):
        return float('inf'), []

    while current_node != start_node:
        path.append(current_node)
        current_node = previous.get(current_node)
        if current_node is None:
            return float('inf'), []
            
    path.append(start_node)
    path.reverse()
    return distances[end_node], path

@functions_framework.http
def get_route(request):
    if request.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Max-Age': '3600'
        }
        return ('', 204, headers)

    headers = {'Access-Control-Allow-Origin': '*'}

    request_json = request.get_json(silent=True)
    if not request_json:
        return (jsonify({"error": "No JSON provided"}), 400, headers)

    try:
        start_lat = request_json['start_lat']
        start_lng = request_json['start_lng']
        end_lat = request_json['end_lat']
        end_lng = request_json['end_lng']
    except KeyError as e:
        return (jsonify({"error": f"Missing field: {e}"}), 400, headers)

    try:
        my_location = (start_lat, start_lng)
        plot = ox.graph_from_point(my_location, dist=1000, dist_type="bbox", network_type="walk")   
    except Exception as e:
        return (jsonify({"error": f"Could not generate graph: {str(e)}"}), 500, headers)

    start_node = ox.nearest_nodes(plot, start_lng, start_lat)

    url = "https://nominatim.openstreetmap.org/search"
    req_headers = {'User-Agent': 'SchoolProjectApp/1.0'}
    params = {
        'q': destination_query,
        'format': 'json',
        'limit': 1,
        'viewbox': f"{start_lng-0.1},{start_lat-0.1},{start_lng+0.1},{start_lat+0.1}", # Bounding box hint
        'bounded': 1
    }

    try:
        resp = requests.get(url, headers=req_headers, params=params)
        data = resp.json()
        if not data:
             return (jsonify({"error": "Destination not found near location"}), 404, headers)
        
        end_lat = float(data[0]['lat'])
        end_lng = float(data[0]['lon'])
    except Exception as e:
        return (jsonify({"error": f"Geocoding error: {str(e)}"}), 500, headers)

    end_node = ox.nearest_nodes(plot, end_lng, end_lat)

    adj_list = {}
    adj_list = {}
    for u, v, data in plot.edges(data=True):
        weight = data.get('length', 1)
        if u not in adj_list:
            adj_list[u] = []

        adj_list[u].append((v, weight)) 
        

    total_dist, path_nodes = dijkstra(adj_list, start_node, end_node)

    if not path_nodes:
        return (jsonify({"error": "No path found"}), 404, headers)
    
    route_coords = []
    for node_id in path_nodes:
        node_data = plot.nodes[node_id]
        route_coords.append({
            "lat": node_data['y'], 
            "lng": node_data['x']
        })

    return (jsonify({
        "distance": total_dist,
        "route": route_coords
    }), 200, headers)

def get_best_category_nlp(user_text):
    log(f"Input: '{user_text}'")
    user_embedding = model.encode(user_text, convert_to_tensor=True)
    cosine_scores = util.cos_sim(user_embedding, CATEGORY_EMBEDDINGS)[0]

    log(f"Cosine scores: {cosine_scores}")
    best_score_ind = torch.argmax(cosine_scores).item()
    best_score = cosine_scores[best_score_ind].item()
    
    log(f"Best score index: {best_score_ind}")
    best_category = CATEGORIES[best_score_ind]
    
    log(f"Input: '{user_text}' | Match: '{best_category}' | Score: {best_score:.4f}")
    
    return best_category

@functions_framework.http
def match_keywords(request):

    if request.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Max-Age': '3600'
        }
        return ('', 204, headers)

    headers = {'Access-Control-Allow-Origin': '*'}

    request_json = request.get_json(silent=True)
    if not request_json:
        return (jsonify({"error": "No JSON provided"}), 400, headers)

    try:
        keywords = request_json['keywords']
    except KeyError as e:
        return (jsonify({"error": f"Missing field: {e}"}), 400, headers)

    if not isinstance(keywords, list) or not all(isinstance(k, str) for k in keywords):
        return (jsonify({"error": "Keywords must be a list of strings"}), 400, headers)

    best_category = get_best_category_nlp(keywords)

    return (jsonify({"category": best_category}), 200, headers)
    