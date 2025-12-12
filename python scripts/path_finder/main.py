import functions_framework
from flask import jsonify
import osmnx as ox
import heapq
import itertools
import math

# --- LOGGING SETUP ---
# Cloud Run captures stdout/stderr
def log(msg):
    print(f"[RouteFinder] {msg}")

# --- YOUR CUSTOM ALGORITHM ---
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

# --- HELPER: CALCULATE CENTER & RADIUS ---
def get_graph_center_dist(points_list):
    # Extract lats and lngs
    lats = [float(p[0]) for p in points_list]
    lngs = [float(p[1]) for p in points_list]
    
    min_lat, max_lat = min(lats), max(lats)
    min_lng, max_lng = min(lngs), max(lngs)
    
    # Calculate Center
    center_lat = (min_lat + max_lat) / 2
    center_lng = (min_lng + max_lng) / 2
    
    # Calculate rough distance from center to corners (in meters)
    # 1 deg lat ~= 111km
    # 1 deg lng ~= 111km * cos(lat)
    lat_diff_m = (max_lat - min_lat) * 111000
    lng_diff_m = (max_lng - min_lng) * 111000 * 0.75 # approx cos(41)
    
    # Max dimension (height or width)
    max_dim_m = max(lat_diff_m, lng_diff_m)
    
    # Radius = half the dimension + buffer (e.g., 200m buffer)
    dist = (max_dim_m / 2) + 200
    
    # Safety: ensure minimum radius of 500m
    return (center_lat, center_lng), max(dist, 500)

# --- THE SERVER HANDLER ---
@functions_framework.http
def get_route(request):
    # CORS Headers
    if request.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Max-Age': '3600'
        }
        return ('', 204, headers)
    headers = {'Access-Control-Allow-Origin': '*'}

    # Parsing
    req = request.get_json(silent=True)
    if not req:
        return (jsonify({"error": "No JSON provided"}), 400, headers)

    try:
        log("Received request")
        start_pt = (req['start']['lat'], req['start']['lng'])
        end_pt = (req['end']['lat'], req['end']['lng'])
        
        # Safe Waypoint Handling
        raw_waypoints = req.get('waypoints') or []
        waypoints_pts = [(w['lat'], w['lng']) for w in raw_waypoints]
        
        log(f"Points: Start={start_pt}, End={end_pt}, Waypoints={len(waypoints_pts)}")
        
    except Exception as e:
        log(f"Parsing error: {e}")
        return (jsonify({"error": f"Data parsing error: {str(e)}"}), 400, headers)

    # Graph Generation
    all_points = [start_pt, end_pt] + waypoints_pts
    center_point, dist_meters = get_graph_center_dist(all_points)
    
    log(f"Downloading Graph. Center={center_point}, Dist={dist_meters}m")

    try:
        # Use graph_from_point (safer than bbox)
        # dist_type='bbox' creates a square bounding box around the point
        plot = ox.graph_from_point(center_point, dist=dist_meters, dist_type='bbox', network_type="walk")
        log(f"Graph downloaded. Nodes: {len(plot.nodes)}, Edges: {len(plot.edges)}")
    except Exception as e:
        log(f"OSMnx error: {e}")
        return (jsonify({"error": f"Graph generation failed: {str(e)}"}), 500, headers)

    # Finding Nodes
    points_map = {}
    points_map['start'] = ox.nearest_nodes(plot, start_pt[1], start_pt[0])
    points_map['end'] = ox.nearest_nodes(plot, end_pt[1], end_pt[0])
    
    for i, pt in enumerate(waypoints_pts):
        points_map[i] = ox.nearest_nodes(plot, pt[1], pt[0])

    # Build Adjacency List for Dijkstra
    adj_list = {}
    for u, v, data in plot.edges(data=True):
        weight = data.get('length', 1)
        if u not in adj_list: adj_list[u] = []
        adj_list[u].append((v, weight))

    # Distance Matrix & TSP
    path_matrix = {}
    keys = ['start', 'end'] + list(range(len(waypoints_pts)))
    sources = ['start'] + list(range(len(waypoints_pts)))
    targets = ['end'] + list(range(len(waypoints_pts)))
    
    log("Calculating Distance Matrix...")
    
    for src in sources:
        for tgt in targets:
            if src == tgt: continue 
            
            start_node = points_map[src]
            end_node = points_map[tgt]
            
            try:
                dist, path = dijkstra(adj_list, start_node, end_node)
                path_matrix[(src, tgt)] = (dist, path)
            except Exception:
                path_matrix[(src, tgt)] = (float('inf'), [])

    # Permutations
    waypoint_indices = list(range(len(waypoints_pts)))
    permutations = list(itertools.permutations(waypoint_indices))
    
    best_distance = float('inf')
    best_order = [] 
    
    if not waypoint_indices:
        dist, path = path_matrix.get(('start', 'end'), (float('inf'), []))
        if dist != float('inf'):
            best_distance = dist
            best_order = ['start', 'end']
    else:
        for perm in permutations:
            current_dist = 0
            sequence = ['start'] + list(perm) + ['end']
            valid_perm = True
            for i in range(len(sequence) - 1):
                u, v = sequence[i], sequence[i+1]
                d, _ = path_matrix.get((u, v), (float('inf'), []))
                if d == float('inf'):
                    valid_perm = False
                    break
                current_dist += d
            
            if valid_perm and current_dist < best_distance:
                best_distance = current_dist
                best_order = sequence

    if best_distance == float('inf'):
        log("No path found")
        return (jsonify({"error": "No valid route found"}), 404, headers)

    # Stitching
    full_node_path = []
    for i in range(len(best_order) - 1):
        u, v = best_order[i], best_order[i+1]
        _, segment_path = path_matrix[(u, v)]
        if i > 0:
            full_node_path.extend(segment_path[1:])
        else:
            full_node_path.extend(segment_path)

    # Convert to Coords
    route_coords = []
    for node_id in full_node_path:
        if node_id in plot.nodes:
            node_data = plot.nodes[node_id]
            route_coords.append({
                "lat": node_data['y'], 
                "lng": node_data['x']
            })

    log(f"Returning route with {len(route_coords)} points")
    return (jsonify({
        "distance": best_distance,
        "route": route_coords
    }), 200, headers)