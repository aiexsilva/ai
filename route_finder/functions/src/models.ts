export interface Location {
  address: string;
  coordinates: Coordinates;
}

export interface Coordinates {
  latitude: number;
  longitude: number;
}

export interface Node {
  id: number;
  lat: number;
  lon: number;
}

export interface Edge {
  nodeId: number;
  weight: number;
}

export interface Graph {
  [nodeId: number]: Edge[];
}

export interface OverpassElement {
  type: "node" | "way";
  id: number;
  lat?: number;
  lon?: number;
  nodes?: number[];
  tags?: { [key: string]: string };
}

export interface OverpassResponse {
  elements: OverpassElement[];
}