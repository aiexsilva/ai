import flet as ft
import geocoder
import osmnx as ox
import heapq  #used for priority queue implementation
import requests
import info


def dijkstra(graph, start_node, end_node):
    #will keep track of nodes so we can then reconstruct the path
    previous = {v: None for v in graph.keys()}
    #will keep track of distances in order to calculate shortest path
    distances = {v:float('inf') for v in graph.keys()}
    #defines the start distance for start node as 0
    distances [start_node] = 0
    queue = [(0, start_node)]

    while queue:
        current_distance, current_node = heapq.heappop(queue)
        if current_node == end_node:
            break
        if current_distance > distances[current_node]:
            continue
        for neighbor, weight in graph[current_node]:
            distance = current_distance + weight
            if distance < distances[neighbor]:
                distances[neighbor] = distance
                previous[neighbor] = current_node
                heapq.heappush(queue, (distance, neighbor))

    path = []
    #take end node and backtrack using the previous dict
    current_node = end_node
    #while current node isn't the starting one then add node to path array
    while current_node != start_node:
        path.append(current_node)
        current_node = previous[current_node]
    path.append(start_node)
    #path reverse to have to going from start to end instead of end to start
    path.reverse()
    return distances[end_node], path

def main():
    #uses geocoder to obtain current location via ip
    g = geocoder.ip('me')
    if g is None:
        print("unable to find location")
    print(g.latlng)
    #saves long and lat into a tuple
    my_location = tuple(g.latlng)

    #allows u to choose the radius of the search
    print("Choose radius:")
    area = float(input())

    #here it's gonna use the osmnx package to get location within the defined radius and the streets(edges) and respective nodes
    #its possible to change between walkable streets, drivable streets, or bike paths, you simply change the "walk" param
    plot = ox.graph_from_point(my_location, dist= area, dist_type="bbox", network_type="walk")
    #makes a plot with the street and nodes
    ox.plot_graph(plot, node_color="r", figsize=(5, 5))

    #defines the starting node of every search as ur location by finding the nearest node to ur defined location
    start_node = ox.nearest_nodes(plot, my_location[1], my_location[0])  # lng, lat

    #lets u define the destination/end node
    place_name = input("Enter a destination: ")

    # nominatim api request rules
    url = "https://nominatim.openstreetmap.org/search"
    headers = {
        'User-Agent': f'MyAPP/1.0 ({info.email})'
    }
    params = {
        'q': place_name,
        'format': 'json',
        'limit': 1
    }

    try:
        response = requests.get(url, headers=headers, params=params)
        response.raise_for_status()
        data = response.json()
    except requests.RequestException as e:
        print("Error fetching location:", e)
        return

    if not data:
        print(f"Location '{place_name}' not found.")
        return

    end_lat = float(data[0]['lat'])
    end_lng = float(data[0]['lon'])
    print(f"Coordinates of {place_name}:")
    print("Latitude:", end_lat)
    print("Longitude:", end_lng)

    end_node = ox.nearest_nodes(plot, end_lng, end_lat)

    print("Start location:", start_node)
    print("End location:", end_node)

    # dictionary with nodes from plotted graph
    adj_list = {}

    for start_point, end_point, data in plot.edges(data=True):
        weight = data.get('length', 1)  # 1 if no length associated
        if start_point not in adj_list:
            adj_list[start_point] = []
        adj_list[start_point].append((end_point, weight))

    graph = adj_list
    distances, path = dijkstra(graph, start_node, end_node)
    # will print shortest distance from start point to end point
    print(distances)
    ox.plot_graph_route(plot, path, route_color='green', route_linewidth=3, node_size=0)

if __name__ == "__main__":
    main()

