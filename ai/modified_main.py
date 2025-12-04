import functions_framework
from flask import jsonify
import osmnx as ox
import heapq
import requests

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