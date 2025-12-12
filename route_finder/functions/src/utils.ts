export function isValidLocation(location: any): boolean {
  return (
    location &&
    typeof location === "object" &&
    typeof location.address === "string" && location.address.trim() !== "" &&
    typeof location.coordinates === "object" && location.coordinates !== null &&
    typeof location.coordinates.latitude === "number" &&
    typeof location.coordinates.longitude === "number"
  );
}

export async function encodePolylinePoints(points: { lat: number; lng: number }[]): Promise<string> {
  let encodedString = "";
  let lat = 0;
  let lng = 0;

  for (const point of points) {
    const newLat = Math.round(point.lat * 1e5);
    const newLng = Math.round(point.lng * 1e5);

    let dy = newLat - lat;
    let dx = newLng - lng;

    lat = newLat;
    lng = newLng;

    dy = (dy << 1) ^ (dy >> 31);
    dx = (dx << 1) ^ (dx >> 31);

    encodedString += encode(dy);
    encodedString += encode(dx);
  }

  return encodedString;
}

function encode(value: number): string {
  let str = "";
  while (value >= 0x20) {
    str += String.fromCharCode((0x20 | (value & 0x1f)) + 63);
    value >>= 5;
  }
  str += String.fromCharCode(value + 63);
  return str;
}

export async function calculateTotalDistance(route: any) {
  let totalDistance = 0;
  for (let i = 0; i < route.length - 1; i++) {
    totalDistance += haversineDistance(route[i], route[i + 1]);
  }
  return totalDistance;
}

export function haversineDistance(arg0: any, arg1: any) {
  const R = 6371;
  const lat1 = arg0.latitude ?? arg0.lat;
  const lon1 = arg0.longitude ?? arg0.lng;
  const lat2 = arg1.latitude ?? arg1.lat;
  const lon2 = arg1.longitude ?? arg1.lng;
  const dLat = (lat2 - lat1) * (Math.PI / 180);
  const dLon = (lon2 - lon1) * (Math.PI / 180);
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * (Math.PI / 180)) * Math.cos(lat2 * (Math.PI / 180)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}
