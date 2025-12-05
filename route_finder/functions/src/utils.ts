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